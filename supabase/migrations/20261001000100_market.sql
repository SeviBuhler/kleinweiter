-- Run once in a fresh Supabase project. Monetary values are integer CHF cents.
create table public.profiles(id uuid primary key references auth.users(id) on delete cascade, name text not null check(length(name) between 2 and 60));
create table public.uploads(id uuid primary key, owner uuid not null references auth.users(id), path text unique not null, created timestamptz not null default now());
create table public.listings(
 id uuid primary key default gen_random_uuid(), seller uuid not null references public.profiles(id),
 title text not null check(length(title) between 5 and 100), description text not null check(length(description) between 20 and 3000),
 age int not null check(age between 0 and 4), category text not null check(category in ('Kleidung','Spielsachen','Bücher','Sport & unterwegs','Ausstattung')),
 condition text not null check(condition in ('Wie neu','Sehr gut','Gut','Gebraucht')), size text not null check(length(size) between 1 and 60),
 location text not null check(length(location) between 2 and 80), delivery text not null check(length(delivery) between 3 and 300),
 shipping int not null check(shipping between 0 and 100000), image uuid not null references public.uploads(id),
 start int not null check(start between 100 and 10000000), price int not null, buy int check(buy>start and buy<=10000000),
 bid_count int not null default 0, bidder uuid references auth.users(id), "end" bigint not null,
 status text not null default 'active' check(status in ('active','sold','expired')), created bigint not null,
 revision int not null default 0
);
create table public.bids(id uuid primary key default gen_random_uuid(), listing uuid not null references public.listings(id), bidder uuid not null references auth.users(id), amount int not null, created bigint not null);
create index on public.listings(age,status,"end");
create index on public.listings(seller);
create index on public.bids(bidder,listing);
alter table public.profiles enable row level security;
alter table public.uploads enable row level security;
alter table public.listings enable row level security;
alter table public.bids enable row level security;
revoke all on public.profiles, public.uploads, public.listings, public.bids from anon, authenticated;
grant select,insert on public.uploads to authenticated;
create policy upload_read on public.uploads for select to authenticated using(owner=(select auth.uid()));
create policy upload_insert on public.uploads for insert to authenticated with check(owner=(select auth.uid()) and path=owner::text||'/'||id::text);

create function public.require_member() returns uuid language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid(); begin
 if uid is null or not exists(select 1 from auth.users where id=uid and email_confirmed_at is not null) then raise exception 'Bitte mit bestätigter E-Mail anmelden.'; end if;
 return uid;
end $$;

create function public.market_feed(p_age int default null,p_mine boolean default false) returns jsonb language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid(); result jsonb; contacts jsonb:='[]'; clock bigint:=floor(extract(epoch from clock_timestamp())*1000);
begin
 if p_mine and uid is null then raise exception 'Bitte anmelden.'; end if;
 if not p_mine and (p_age is null or p_age not between 0 and 4) then raise exception 'Bitte eine Altersgruppe wählen.'; end if;
 update public.listings set status=case when bidder is null then 'expired' else 'sold' end where status='active' and "end"<=clock;
 select coalesce(jsonb_agg(rowdata),'[]') into result from (
 select (to_jsonb(l)-'bidder')||jsonb_build_object('seller_name',p.name)||case when p_mine then jsonb_build_object('bidder',l.bidder) else '{}'::jsonb end rowdata
 from public.listings l join public.profiles p on p.id=l.seller
 where case when p_mine then (l.seller=uid or l.bidder=uid or exists(select 1 from public.bids b where b.listing=l.id and b.bidder=uid)) else l.age=p_age and l.status='active' end
 order by l.created desc limit 250) s;
 if p_mine then select coalesce(jsonb_agg(jsonb_build_object('id',l.id,'email',u.email)),'[]') into contacts
 from public.listings l join auth.users u on u.id=case when l.seller=uid then l.bidder else l.seller end
 where l.status='sold' and (l.seller=uid or l.bidder=uid); end if;
 return jsonb_build_object('items',result,'contacts',contacts);
end $$;

create function public.market_action(p_body jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare uid uuid:=public.require_member(); l public.listings; ident uuid; clock bigint:=floor(extract(epoch from clock_timestamp())*1000); amount int; minimum int; isbuy boolean; days int; action text:=p_body->>'action';
begin
 perform pg_advisory_xact_lock(hashtext(uid::text));
 insert into public.profiles(id,name) values(uid,'Mitglied') on conflict do nothing;
 if action='profile' then update public.profiles set name=trim(p_body->>'name') where id=uid; return '{"ok":true}'; end if;
 if action='create' then
 if p_body->'childrenOnly' is distinct from 'true'::jsonb then raise exception 'Bitte Kinderartikel bestätigen.'; end if;
 days:=(p_body->>'days')::int;
 if days not in (1,3,5,7,10) then raise exception 'Ungültige Auktionsdauer.'; end if;
 if not exists(select 1 from public.uploads u join storage.objects o on o.name=u.path and o.bucket_id='product-images' where u.id=(p_body->>'image')::uuid and u.owner=uid) then raise exception 'Bitte ein eigenes Produktfoto hochladen.'; end if;
 if (select count(*) from public.listings where seller=uid and created>clock-86400000)>=20 then raise exception 'Maximal 20 neue Inserate pro Tag.'; end if;
 insert into public.listings(seller,title,description,age,category,condition,size,location,delivery,shipping,image,start,price,buy,"end",created)
 values(uid,trim(p_body->>'title'),trim(p_body->>'description'),(p_body->>'age')::int,p_body->>'category',p_body->>'condition',trim(p_body->>'size'),trim(p_body->>'location'),trim(p_body->>'delivery'),(p_body->>'shipping')::int,(p_body->>'image')::uuid,(p_body->>'start')::int,(p_body->>'start')::int,(p_body->>'buy')::int,clock+days::bigint*86400000,clock) returning id into ident;
 return jsonb_build_object('ok',true,'id',ident);
 end if;
 if action not in ('bid','buy') or action is null then raise exception 'Unbekannte Aktion.'; end if;
 if p_body->'confirm' is distinct from 'true'::jsonb then raise exception 'Bitte den verbindlichen Kauf bestätigen.'; end if;
 select * into l from public.listings where id=(p_body->>'id')::uuid for update;
 -- Re-read wall clock AFTER acquiring the lock, including any lock wait.
 clock:=floor(extract(epoch from clock_timestamp())*1000);
 if l.id is null or l.status<>'active' or l."end"<=clock then raise exception 'Dieses Angebot ist nicht mehr verfügbar.'; end if;
 if l.seller=uid then raise exception 'Du kannst nicht auf dein eigenes Angebot bieten.'; end if;
 isbuy:=action='buy';
 if isbuy and l.buy is null then raise exception 'Sofortkauf ist nicht verfügbar.'; end if;
 amount:=case when isbuy then l.buy else (p_body->>'amount')::int end;
 minimum:=case when l.bid_count=0 then l.start else l.price+100 end;
 if amount is null or (not isbuy and (amount<minimum or (l.buy is not null and amount>=l.buy))) then raise exception 'Gebot zu niedrig oder über dem Sofortkaufpreis. Bitte neu laden.'; end if;
 update public.listings set price=amount,bidder=uid,bid_count=bid_count+1,revision=revision+1,status=case when isbuy then 'sold' else 'active' end where id=l.id;
 insert into public.bids(listing,bidder,amount,created) values(l.id,uid,amount,clock);
 return jsonb_build_object('ok',true,'message',case when isbuy then 'Gekauft. Die Kontaktdaten findest du in deinem Konto.' else 'Dein Gebot wurde gespeichert.' end);
end $$;
revoke all on function public.require_member(),public.market_feed(int,boolean),public.market_action(jsonb) from public,anon,authenticated;
grant execute on function public.market_feed(int,boolean) to anon,authenticated;
grant execute on function public.market_action(jsonb) to authenticated;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('product-images','product-images',false,5000000,array['image/jpeg','image/png','image/webp']);
create function public.image_paths() returns table(path text) language sql security definer set search_path='' as $$
 select u.path from public.uploads u where exists(select 1 from public.listings l where l.image=u.id)
$$;
create function public.image_path(p_id uuid) returns text language sql security definer set search_path='' as $$
 select u.path from public.uploads u where u.id=p_id and (u.owner=auth.uid() or exists(select 1 from public.listings l where l.image=u.id))
$$;
revoke all on function public.image_paths(),public.image_path(uuid) from public;
grant execute on function public.image_paths(),public.image_path(uuid) to anon,authenticated;
create policy image_insert on storage.objects for insert to authenticated with check(bucket_id='product-images' and (storage.foldername(name))[1]=(select auth.uid())::text);
create policy image_select on storage.objects for select to anon,authenticated using(bucket_id='product-images' and ((storage.foldername(name))[1]=(select auth.uid())::text or exists(select 1 from public.image_paths() p where p.path=name)));
