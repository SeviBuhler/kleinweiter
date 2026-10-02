-- Roles are granted/revoked only by the database owner, never by the app.
create table public.moderators(id uuid primary key references auth.users(id),created timestamptz not null default clock_timestamp());
alter table public.moderators enable row level security;
revoke all on public.moderators from public,anon,authenticated;
create function public.moderation_access() returns boolean language sql security definer set search_path='' as $$
 select exists(select 1 from public.moderators m join auth.users u on u.id=m.id where m.id=auth.uid() and u.email_confirmed_at is not null)
$$;
revoke all on function public.moderation_access() from public,anon,authenticated;
grant execute on function public.moderation_access() to anon,authenticated;

alter table public.listings drop constraint listings_status_check;
alter table public.listings add constraint listings_status_check check(status in ('active','sold','expired','withdrawn','blocked'));
alter table public.listings add column moderation_note text;
alter table public.listing_reports add column reviewed_by uuid references auth.users(id);
create table public.moderation_events(
 id uuid primary key default gen_random_uuid(),moderator uuid not null references auth.users(id),
 report uuid not null references public.listing_reports(id),listing uuid not null references public.listings(id),
 action text not null check(action in ('reviewed','dismissed','block')),note text not null,
 bid_count int not null,price int not null,created timestamptz not null default clock_timestamp()
);
alter table public.moderation_events enable row level security;
revoke all on public.moderation_events from public,anon,authenticated;

create function public.moderation_feed() returns jsonb language plpgsql security definer set search_path='' as $$
declare result jsonb;
begin
 if not public.moderation_access() then raise exception 'Kein Moderationszugang.'; end if;
 select coalesce(jsonb_agg(rowdata),'[]') into result from (
  select jsonb_build_object('id',r.id,'reason',r.reason,'details',r.details,'snapshot',r.snapshot-'seller',
   'status',r.status,'review_note',r.review_note,'created',r.created,'reviewed_at',r.reviewed_at,
   'listing',(to_jsonb(l)-'bidder'-'seller')||jsonb_build_object('seller_name',p.name)) rowdata
  from public.listing_reports r join public.listings l on l.id=r.listing join public.profiles p on p.id=l.seller
  order by (r.status='open') desc,r.created desc limit 200
 ) s;
 return jsonb_build_object('reports',result);
end $$;
revoke all on function public.moderation_feed() from public,anon,authenticated;
grant execute on function public.moderation_feed() to authenticated;

create function public.moderation_action(p_body jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare uid uuid:=public.require_member(); r public.listing_reports; l public.listings; ident uuid;
 operation text:=p_body->>'action'; note text:=trim(p_body->>'note'); clock bigint;
begin
 if not public.moderation_access() then raise exception 'Kein Moderationszugang.'; end if;
 if operation is null or operation not in ('reviewed','dismissed','block') or note is null or length(note) not between 10 and 1000 then raise exception 'Entscheidung und Begründung (10–1000 Zeichen) fehlen.'; end if;
 if p_body->'confirm' is distinct from 'true'::jsonb then raise exception 'Bitte die Entscheidung bestätigen.'; end if;
 perform pg_advisory_xact_lock(hashtext(uid::text));
 select listing into ident from public.listing_reports where id=(p_body->>'id')::uuid;
 -- Same listing lock as bidding/purchase. Clock is checked after lock wait.
 select * into l from public.listings where id=ident for update;
 select * into r from public.listing_reports where id=(p_body->>'id')::uuid for update;
 clock:=floor(extract(epoch from clock_timestamp())*1000);
 if r.id is null or r.status<>'open' then raise exception 'Offene Meldung nicht gefunden. Bitte aktualisieren.'; end if;
 if operation='block' then
  if l.status<>'active' or l."end"<=clock then raise exception 'Nur laufende Auktionen können gesperrt werden. Bereits abgeschlossene Käufe bleiben bestehen.'; end if;
  if (p_body->>'revision')::int is distinct from l.revision then raise exception 'Das Angebot wurde inzwischen geändert. Bitte aktualisieren und erneut prüfen.'; end if;
  update public.listings set status='blocked',moderation_note=note,revision=revision+1 where id=l.id;
 end if;
 update public.listing_reports set status=case when operation='dismissed' then 'dismissed' else 'reviewed' end,
  review_note=note,reviewed_at=clock_timestamp(),reviewed_by=uid where id=r.id;
 insert into public.moderation_events(moderator,report,listing,action,note,bid_count,price)
 values(uid,r.id,l.id,operation,note,l.bid_count,l.price);
 return jsonb_build_object('ok',true,'message',case when operation='block' then 'Inserat gesperrt. Die Auktion wurde gestoppt; Beteiligte sehen die Begründung in ihrem Konto.' else 'Prüfung dokumentiert.' end);
end $$;
revoke all on function public.moderation_action(jsonb) from public,anon,authenticated;
grant execute on function public.moderation_action(jsonb) to authenticated;

-- A blocked photo is hidden publicly; owner and moderators retain access.
-- Moderators can also examine the original photo stored in a report snapshot.
create or replace function public.can_read_image(p_path text) returns boolean language sql security definer set search_path='' as $$
 select exists(select 1 from public.uploads u where u.path=p_path and
 (u.owner=auth.uid() or (public.moderation_access() and (exists(select 1 from public.listings l where l.image=u.id) or exists(select 1 from public.listing_reports r where r.snapshot->>'image'=u.id::text))) or exists(select 1 from public.listings l where l.image=u.id and l.status<>'blocked')))
$$;
create or replace function public.image_path(p_id uuid) returns text language sql security definer set search_path='' as $$
 select u.path from public.uploads u where u.id=p_id and public.can_read_image(u.path)
$$;
