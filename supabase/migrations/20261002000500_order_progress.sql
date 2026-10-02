-- Immutable sale terms and participant declarations; no payment processing.
create table public.orders(
 listing uuid primary key references public.listings(id),seller uuid not null references auth.users(id),buyer uuid not null references auth.users(id),
 title text not null,price int not null,shipping int not null,delivery text not null,
 created timestamptz not null default clock_timestamp(),revision int not null default 0,
 paid_at timestamptz,payment_received_at timestamptz,sent_at timestamptz,received_at timestamptz,completed_at timestamptz,
 check(seller<>buyer)
);
create index orders_seller on public.orders(seller,created desc);
create index orders_buyer on public.orders(buyer,created desc);
create table public.order_issues(
 id uuid primary key default gen_random_uuid(),listing uuid not null references public.orders(listing),reporter uuid not null references auth.users(id),
 reason text not null check(reason in ('Zahlung','Versand oder Übergabe','Artikel entspricht nicht dem Angebot','Sonstiges')),
 details text not null check(length(details) between 10 and 1000),created timestamptz not null default clock_timestamp(),
 status text not null default 'open' check(status in ('open','closed')),review_note text,reviewed_at timestamptz,reviewed_by uuid references auth.users(id),
 unique(listing,reporter)
);
create table public.order_events(
 id uuid primary key default gen_random_uuid(),listing uuid not null references public.orders(listing),actor uuid not null references auth.users(id),
 action text not null,created timestamptz not null default clock_timestamp(),revision int not null,
 unique(listing,revision)
);
alter table public.orders enable row level security;
alter table public.order_issues enable row level security;
alter table public.order_events enable row level security;
revoke all on public.orders,public.order_issues,public.order_events from public,anon,authenticated;
alter table public.moderators add column order_support boolean not null default false;
create function public.order_support_access() returns boolean language sql security definer set search_path='' as $$
 select public.moderation_access() and exists(select 1 from public.moderators where id=auth.uid() and order_support)
$$;
revoke all on function public.order_support_access() from public,anon,authenticated;
grant execute on function public.order_support_access() to authenticated;

create function public.create_sale_order() returns trigger language plpgsql security definer set search_path='' as $$
begin
 if old.status='active' and new.status='sold' then
  insert into public.orders(listing,seller,buyer,title,price,shipping,delivery)
  values(new.id,new.seller,new.bidder,new.title,new.price,new.shipping,new.delivery) on conflict do nothing;
 end if;
 return new;
end $$;
revoke all on function public.create_sale_order() from public,anon,authenticated;
create trigger sale_order after update on public.listings for each row execute function public.create_sale_order();
-- Existing sales get an open workflow, never assumed paid or delivered.
insert into public.orders(listing,seller,buyer,title,price,shipping,delivery,created)
select id,seller,bidder,title,price,shipping,delivery,to_timestamp(created/1000.0) from public.listings where status='sold' and bidder is not null;

alter table public.notifications drop constraint notifications_kind_check;
alter table public.notifications add constraint notifications_kind_check check(kind in ('outbid','purchased','won','sold','blocked','expired','order_update','order_issue','order_review'));

-- Internal serializer: callers separately enforce participant/support membership.
create function public.order_json(o public.orders) returns jsonb language sql security definer set search_path='' as $$
 select (to_jsonb(o)-'seller'-'buyer')||jsonb_build_object(
  'role',case when o.seller=auth.uid() then 'seller' when o.buyer=auth.uid() then 'buyer' else 'support' end,
  'seller_name',(select name from public.profiles where id=o.seller),'buyer_name',(select name from public.profiles where id=o.buyer),
  'issues',coalesce((select jsonb_agg(jsonb_build_object('id',r.id,'role',case when r.reporter=o.buyer then 'buyer' else 'seller' end,'reason',r.reason,'details',r.details,'created',r.created,'status',r.status,'review_note',r.review_note,'reviewed_at',r.reviewed_at,'review_role',case when r.reviewed_by=o.buyer then 'buyer' when r.reviewed_by=o.seller then 'seller' else 'support' end) order by r.created) from public.order_issues r where r.listing=o.listing),'[]'),
  'events',coalesce((select jsonb_agg(jsonb_build_object('action',e.action,'created',e.created,'role',case when e.actor=o.buyer then 'buyer' when e.actor=o.seller then 'seller' else 'support' end) order by e.revision) from public.order_events e where e.listing=o.listing),'[]'))
$$;
revoke all on function public.order_json(public.orders) from public,anon,authenticated;

create function public.order_feed(p_listing uuid default null) returns jsonb language plpgsql security definer set search_path='' as $$
declare uid uuid:=public.require_member(); result jsonb;
begin
 select coalesce(jsonb_agg(rowdata),'[]') into result from (
  select public.order_json(o)||jsonb_build_object('contact',(select email from auth.users where id=case when o.seller=uid then o.buyer else o.seller end)) rowdata
  from public.orders o where (o.seller=uid or o.buyer=uid) and (p_listing is null or o.listing=p_listing)
  order by o.created desc,o.listing limit 250
 ) s;
 return jsonb_build_object('orders',result);
end $$;
revoke all on function public.order_feed(uuid) from public,anon,authenticated;
grant execute on function public.order_feed(uuid) to authenticated;

create function public.order_action(p_body jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare uid uuid:=public.require_member(); o public.orders; operation text:=p_body->>'action'; clock timestamptz; peer uuid; body text; r public.order_issues; note text;
begin
 if operation is null or operation not in ('paid','payment_received','sent','received','issue','resolve_issue') then raise exception 'Unbekannte Aktion.'; end if;
 if p_body->'confirm' is distinct from 'true'::jsonb then raise exception 'Bitte die Angabe bestätigen.'; end if;
 perform pg_advisory_xact_lock(hashtext(uid::text));
 select * into o from public.orders where listing=(p_body->>'id')::uuid for update;
 if o.listing is null or uid not in (o.seller,o.buyer) then raise exception 'Verkauf nicht gefunden.'; end if;
 if (p_body->>'revision')::int is distinct from o.revision then raise exception 'Die Abwicklung wurde inzwischen geändert. Bitte aktualisieren.'; end if;
 if (operation in ('paid','received') and uid<>o.buyer) or (operation in ('payment_received','sent') and uid<>o.seller) then raise exception 'Nur die zuständige Person darf diese Angabe bestätigen.'; end if;
 if (operation='paid' and o.paid_at is not null) or (operation='payment_received' and o.payment_received_at is not null) or (operation='sent' and o.sent_at is not null) or (operation='received' and o.received_at is not null) then raise exception 'Diese Angabe wurde bereits bestätigt.'; end if;
 clock:=clock_timestamp();peer:=case when uid=o.seller then o.buyer else o.seller end;
 if operation='resolve_issue' then
  note:=trim(p_body->>'note');
  if note is null or length(note) not between 10 and 1000 then raise exception 'Bitte die Lösung beschreiben (10–1000 Zeichen).'; end if;
  select * into r from public.order_issues where id=(p_body->>'issue_id')::uuid and listing=o.listing for update;
  if r.id is null or r.reporter<>uid or r.status<>'open' then raise exception 'Nur die meldende Person kann ihr offenes Problem als gelöst bestätigen.'; end if;
  update public.order_issues set status='closed',review_note=note,reviewed_at=clock,reviewed_by=uid where id=r.id;
  body:='Die meldende Person hat ihr Problem als gelöst bestätigt. Die Begründung findest du in der Abwicklung.';
 elsif operation='issue' then
  if p_body->>'reason' is null or p_body->>'reason' not in ('Zahlung','Versand oder Übergabe','Artikel entspricht nicht dem Angebot','Sonstiges') or length(trim(p_body->>'details')) not between 10 and 1000 or p_body->>'details' is null then raise exception 'Grund und Beschreibung (10–1000 Zeichen) fehlen.'; end if;
  if exists(select 1 from public.order_issues where listing=o.listing and reporter=uid) then raise exception 'Du hast bereits ein Problem zu diesem Verkauf gemeldet.'; end if;
  insert into public.order_issues(listing,reporter,reason,details) values(o.listing,uid,p_body->>'reason',trim(p_body->>'details'));
  body:='Zu diesem Verkauf wurde ein Problem gemeldet. Lies die Beschreibung in der Abwicklung.';
 else
  update public.orders set paid_at=case when operation='paid' then clock else paid_at end,
   payment_received_at=case when operation='payment_received' then clock else payment_received_at end,
   sent_at=case when operation='sent' then clock else sent_at end,received_at=case when operation='received' then clock else received_at end where listing=o.listing;
  body:=case operation when 'paid' then 'Der Käufer hat die Zahlung als veranlasst bestätigt.' when 'payment_received' then 'Der Verkäufer hat den Zahlungseingang bestätigt.' when 'sent' then 'Der Verkäufer hat Versand oder Übergabe bestätigt.' else 'Der Käufer hat den Erhalt des Artikels bestätigt.' end;
 end if;
 update public.orders set revision=revision+1 where listing=o.listing;
 update public.orders set completed_at=coalesce(completed_at,clock) where listing=o.listing and paid_at is not null and payment_received_at is not null and sent_at is not null and received_at is not null and not exists(select 1 from public.order_issues where listing=o.listing and status='open');
 select * into o from public.orders where listing=o.listing;
 insert into public.order_events(listing,actor,action,revision) values(o.listing,uid,operation,o.revision);
 insert into public.notifications(recipient,listing,kind,title,body,revision)
 values(peer,o.listing,case when operation='issue' then 'order_issue' else 'order_update' end,o.title,body,o.revision);
 return jsonb_build_object('ok',true,'message',case when operation='issue' then 'Problem gespeichert. Beide Beteiligte und freigeschalteter Support können es sehen.' else 'Bestätigung gespeichert.' end);
end $$;
revoke all on function public.order_action(jsonb) from public,anon,authenticated;
grant execute on function public.order_action(jsonb) to authenticated;

create function public.order_issue_feed() returns jsonb language plpgsql security definer set search_path='' as $$
declare result jsonb;
begin
 if not public.order_support_access() then raise exception 'Kein Zugang zu Verkaufsproblemen.'; end if;
 select coalesce(jsonb_agg(rowdata),'[]') into result from (
  select public.order_json(o) rowdata from public.orders o where exists(select 1 from public.order_issues where listing=o.listing)
  order by exists(select 1 from public.order_issues where listing=o.listing and status='open') desc,o.created desc limit 200
 ) s;
 return jsonb_build_object('orders',result);
end $$;
create function public.order_issue_review(p_body jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare uid uuid:=public.require_member(); o public.orders; r public.order_issues; ident uuid; note text:=trim(p_body->>'note');clock timestamptz;
begin
 if not public.order_support_access() then raise exception 'Kein Zugang zu Verkaufsproblemen.'; end if;
 if p_body->'confirm' is distinct from 'true'::jsonb or note is null or length(note) not between 10 and 1000 then raise exception 'Bestätigung und Begründung (10–1000 Zeichen) fehlen.'; end if;
 perform pg_advisory_xact_lock(hashtext(uid::text));
 select listing into ident from public.order_issues where id=(p_body->>'id')::uuid;
 select * into o from public.orders where listing=ident for update;
 -- Support participants must not close their own sale's dispute.
 if uid in (o.seller,o.buyer) then raise exception 'Probleme zu eigenen Verkäufen darf nur ein anderer Support-Betreiber abschliessen.'; end if;
 select * into r from public.order_issues where id=(p_body->>'id')::uuid for update;
 if r.id is null or r.status<>'open' then raise exception 'Offene Problemmeldung nicht gefunden.'; end if;
 if (p_body->>'revision')::int is distinct from o.revision then raise exception 'Die Abwicklung wurde inzwischen geändert. Bitte aktualisieren.'; end if;
 clock:=clock_timestamp();
 update public.order_issues set status='closed',review_note=note,reviewed_at=clock,reviewed_by=uid where id=r.id;
 update public.orders set revision=revision+1 where listing=o.listing;
 update public.orders set completed_at=coalesce(completed_at,clock) where listing=o.listing and paid_at is not null and payment_received_at is not null and sent_at is not null and received_at is not null and not exists(select 1 from public.order_issues where listing=o.listing and status='open');
 select * into o from public.orders where listing=o.listing;
 insert into public.order_events(listing,actor,action,revision) values(o.listing,uid,'issue_closed',o.revision);
 insert into public.notifications(recipient,listing,kind,title,body,revision)
 values(o.seller,o.listing,'order_review',o.title,'Der Support hat die Problemmeldung abgeschlossen. Die Begründung findest du in der Abwicklung.',o.revision),
 (o.buyer,o.listing,'order_review',o.title,'Der Support hat die Problemmeldung abgeschlossen. Die Begründung findest du in der Abwicklung.',o.revision);
 return '{"ok":true,"message":"Problemmeldung abgeschlossen. Kauf und Bestätigungen bleiben unverändert."}';
end $$;
revoke all on function public.order_issue_feed(),public.order_issue_review(jsonb) from public,anon,authenticated;
grant execute on function public.order_issue_feed(),public.order_issue_review(jsonb) to authenticated;
