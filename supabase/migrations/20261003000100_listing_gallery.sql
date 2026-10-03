-- Ordered galleries; first image remains the cover for legacy clients.
alter table public.listings add column images uuid[];
update public.listings set images=array[image];
alter table public.listings alter column images set not null;
alter table public.listings add constraint listings_gallery_check check(cardinality(images) between 1 and 5 and array_position(images,null) is null and image=images[1]);
create index listings_gallery_idx on public.listings using gin(images);
create function public.guard_listing_gallery() returns trigger language plpgsql security definer set search_path='' as $$
begin
 if tg_op='INSERT' and new.images is null then new.images:=array[new.image]; end if;
 if tg_op='UPDATE' then
  if new.image is distinct from old.image and new.images is not distinct from old.images then new.images:=array[new.image]; end if;
  if new.images is distinct from old.images or new.image is distinct from old.image then
   if old.status<>'active' or old.bid_count<>0 or old."end"<=floor(extract(epoch from clock_timestamp())*1000) then raise exception 'Fotos können nur bei laufenden Inseraten vor dem ersten Gebot geändert werden.'; end if;
  end if;
 end if;
 return new;
end $$;
revoke all on function public.guard_listing_gallery() from public,anon,authenticated;
create trigger listing_gallery_guard before insert or update on public.listings for each row execute function public.guard_listing_gallery();

alter function public.market_action(jsonb) rename to market_single_photo_action;
revoke all on function public.market_single_photo_action(jsonb) from public,anon,authenticated;
create function public.market_action(p_body jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare uid uuid; ids uuid[]; ident uuid; result jsonb; old_listing public.listings; operation text:=p_body->>'action';
begin
 if operation is null or operation not in ('create','edit') then return public.market_single_photo_action(p_body); end if;
 uid:=public.require_member();perform pg_advisory_xact_lock(hashtext(uid::text));
 if operation='edit' then
  select * into old_listing from public.listings where id=(p_body->>'id')::uuid for update;
 end if;
 if p_body ? 'images' then
  if jsonb_typeof(p_body->'images')<>'array' then raise exception 'Bitte ein bis fünf Fotos auswählen.'; end if;
  select array_agg(x::uuid order by n) into ids from jsonb_array_elements_text(p_body->'images') with ordinality as a(x,n);
 else
  -- Legacy text edits preserve the existing gallery when the cover stays the same.
  ids:=case when operation='edit' and old_listing.image=(p_body->>'image')::uuid then old_listing.images else array[(p_body->>'image')::uuid] end;
 end if;
 if ids is null or cardinality(ids) not between 1 and 5 or array_position(ids,null) is not null or (select count(distinct x) from unnest(ids) x)<>cardinality(ids) then raise exception 'Bitte ein bis fünf unterschiedliche Fotos auswählen.'; end if;
 if exists(select 1 from unnest(ids) x where not exists(select 1 from public.uploads u join storage.objects o on o.name=u.path and o.bucket_id='product-images' where u.id=x and u.owner=uid)) then raise exception 'Bitte ausschliesslich eigene, vollständig hochgeladene Fotos verwenden.'; end if;
 result:=public.market_single_photo_action(p_body||jsonb_build_object('image',ids[1]));
 ident:=case when operation='create' then (result->>'id')::uuid else (p_body->>'id')::uuid end;
 update public.listings set images=ids,image=ids[1] where id=ident;
 return result;
end $$;
revoke all on function public.market_action(jsonb) from public,anon,authenticated;
grant execute on function public.market_action(jsonb) to authenticated;

create or replace function public.can_read_image(p_path text) returns boolean language sql security definer set search_path='' as $$
 select exists(select 1 from public.uploads u where u.path=p_path and
 (u.owner=auth.uid() or
  (public.moderation_access() and (exists(select 1 from public.listings l where u.id=any(l.images)) or exists(select 1 from public.listing_reports r where r.snapshot->>'image'=u.id::text or r.snapshot->'images' @> jsonb_build_array(u.id::text)))) or
  exists(select 1 from public.listings l where u.id=any(l.images) and l.status<>'blocked')))
$$;
