-- Transactional inbox: only trusted listing transitions can create messages.
create table public.notifications(
 id uuid primary key default gen_random_uuid(),recipient uuid not null references auth.users(id),
 listing uuid not null references public.listings(id),kind text not null check(kind in ('outbid','purchased','won','sold','blocked','expired')),
 title text not null,body text not null,revision int not null,
 created timestamptz not null default clock_timestamp(),read_at timestamptz,
 unique(recipient,listing,kind,revision)
);
create index notifications_inbox on public.notifications(recipient,created desc,id desc);
create index notifications_unread on public.notifications(recipient) where read_at is null;
alter table public.notifications enable row level security;
revoke all on public.notifications from public,anon,authenticated;

create function public.notify_listing_transition() returns trigger language plpgsql security definer set search_path='' as $$
declare who uuid; is_purchase boolean;
begin
 if old.status<>'active' then return new; end if;
 if new.bidder is distinct from old.bidder and old.bidder is not null and new.status in ('active','sold') then
  insert into public.notifications(recipient,listing,kind,title,body,revision)
  values(old.bidder,new.id,'outbid',new.title,case when new.status='sold' then 'Ein anderes Mitglied hat den Artikel sofort gekauft. Dein Gebot hat nicht gewonnen.' else 'Du wurdest überboten. Sieh dir das Angebot an, wenn du nochmals bieten möchtest.' end,new.revision) on conflict do nothing;
 end if;
 if new.status='sold' and old.status<>new.status then
  is_purchase:=new."end">floor(extract(epoch from clock_timestamp())*1000);
  insert into public.notifications(recipient,listing,kind,title,body,revision)
  values(new.bidder,new.id,case when is_purchase then 'purchased' else 'won' end,new.title,
   case when is_purchase then 'Dein Sofortkauf war erfolgreich.' else 'Du hast die Auktion gewonnen.' end||' Kontaktdaten sowie Zahlung und Übergabe findest du in deinem Konto.',new.revision),
   (new.seller,new.id,'sold',new.title,'Dein Artikel wurde verkauft. Kontaktiere den Käufer über dein Konto, um Zahlung und Übergabe zu vereinbaren.',new.revision) on conflict do nothing;
 elsif new.status='expired' and old.status<>new.status then
  insert into public.notifications(recipient,listing,kind,title,body,revision)
  values(new.seller,new.id,'expired',new.title,'Deine Auktion ist ohne Gebot beendet.',new.revision) on conflict do nothing;
 elsif new.status='blocked' and old.status<>new.status then
  for who in select new.seller union select b.bidder from public.bids b where b.listing=new.id loop
   insert into public.notifications(recipient,listing,kind,title,body,revision)
   values(who,new.id,'blocked',new.title,'Die Moderation hat diese Auktion gestoppt. Begründung: '||coalesce(new.moderation_note,'Siehe dein Konto.'),new.revision) on conflict do nothing;
  end loop;
 end if;
 return new;
end $$;
revoke all on function public.notify_listing_transition() from public,anon,authenticated;
create trigger listing_notifications after update on public.listings for each row execute function public.notify_listing_transition();

create function public.notification_feed() returns jsonb language plpgsql security definer set search_path='' as $$
declare uid uuid:=public.require_member(); result jsonb; unread bigint; clock bigint;
begin
 -- Same lazy settlement as market_feed; no background scheduler is configured.
 clock:=floor(extract(epoch from clock_timestamp())*1000);
 update public.listings set status=case when bidder is null then 'expired' else 'sold' end where status='active' and "end"<=clock;
 select count(*) into unread from public.notifications where recipient=uid and read_at is null;
 select coalesce(jsonb_agg(rowdata),'[]') into result from (
  select jsonb_build_object('id',n.id,'listing',n.listing,'kind',n.kind,'title',n.title,'body',n.body,'created',n.created,'read_at',n.read_at) rowdata
  from public.notifications n where n.recipient=uid order by (n.read_at is null) desc,n.created desc,n.id desc limit 100
 ) s;
 return jsonb_build_object('items',result,'unread',unread);
end $$;
create function public.notification_read(p_id uuid) returns jsonb language plpgsql security definer set search_path='' as $$
declare uid uuid:=public.require_member();
begin
 if p_id is null then
  update public.notifications set read_at=clock_timestamp() where recipient=uid and read_at is null;
 else
  update public.notifications set read_at=coalesce(read_at,clock_timestamp()) where recipient=uid and id=p_id;
  if not found then raise exception 'Benachrichtigung nicht gefunden.'; end if;
 end if;
 return '{"ok":true}';
end $$;
revoke all on function public.notification_feed(),public.notification_read(uuid) from public,anon,authenticated;
grant execute on function public.notification_feed(),public.notification_read(uuid) to authenticated;
