-- Reports are private moderation records, never part of the public feed.
create table public.listing_reports (
 id uuid primary key default gen_random_uuid(),
 listing uuid not null references public.listings(id),
 reporter uuid not null references auth.users(id),
 reason text not null check(reason in ('Kein Kinderartikel','Unpassender Inhalt','Verdacht auf Betrug','Sonstiges')),
 details text not null check(length(details) between 10 and 1000),
 snapshot jsonb not null,
 status text not null default 'open' check(status in ('open','reviewed','dismissed')),
 review_note text check(length(review_note) between 3 and 1000),
 created timestamptz not null default clock_timestamp(),
 reviewed_at timestamptz,
 unique(listing,reporter)
);
create index listing_reports_queue_idx on public.listing_reports(status,created);
create index listing_reports_reporter_created_idx on public.listing_reports(reporter,created);
alter table public.listing_reports enable row level security;
revoke all on public.listing_reports from public,anon,authenticated;

create function public.report_listing(p_body jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare uid uuid:=public.require_member(); l public.listings; clock bigint;
begin
 perform pg_advisory_xact_lock(hashtext(uid::text));
 select * into l from public.listings where id=(p_body->>'id')::uuid for share;
 clock:=floor(extract(epoch from clock_timestamp())*1000);
 if l.id is null or l.status<>'active' or l."end"<=clock then raise exception 'Dieses Angebot ist nicht mehr verfügbar.'; end if;
 if l.seller=uid then raise exception 'Eigene Inserate können nicht gemeldet werden. Nutze Bearbeiten oder Zurückziehen.'; end if;
 if exists(select 1 from public.listing_reports where listing=l.id and reporter=uid) then raise exception 'Du hast dieses Inserat bereits gemeldet.'; end if;
 if (select count(*) from public.listing_reports where reporter=uid and created>clock_timestamp()-interval '24 hours')>=10 then raise exception 'Maximal 10 Meldungen pro Tag.'; end if;
 insert into public.listing_reports(listing,reporter,reason,details,snapshot)
 values(l.id,uid,p_body->>'reason',trim(p_body->>'details'),to_jsonb(l)-'bidder');
 return '{"ok":true,"message":"Danke. Deine Meldung wurde gespeichert und wird manuell geprüft."}';
end $$;
revoke all on function public.report_listing(jsonb) from public,anon,authenticated;
grant execute on function public.report_listing(jsonb) to authenticated;

-- Only the database owner can complete a review; no browser admin key needed.
-- This records the decision, without cancelling auctions or modifying bids.
create function public.review_listing_report(p_id uuid,p_status text,p_note text) returns jsonb language plpgsql security definer set search_path='' as $$
begin
 if p_status is null or p_status not in ('reviewed','dismissed') or p_note is null or length(trim(p_note)) not between 3 and 1000 then raise exception 'Prüfergebnis und Begründung fehlen.'; end if;
 update public.listing_reports set status=p_status,review_note=trim(p_note),reviewed_at=clock_timestamp() where id=p_id and status='open';
 if not found then raise exception 'Offene Meldung nicht gefunden.'; end if;
 return '{"ok":true}';
end $$;
revoke all on function public.review_listing_report(uuid,text,text) from public,anon,authenticated;
