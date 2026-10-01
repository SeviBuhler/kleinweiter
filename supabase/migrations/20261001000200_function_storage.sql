-- All application writes, including upload reservations, go through functions.
revoke all on public.uploads from anon,authenticated;
create index uploads_owner_created_idx on public.uploads(owner,created);
create index listings_image_idx on public.listings(image);
create index listings_bidder_idx on public.listings(bidder);
update storage.buckets set file_size_limit=4000000 where id='product-images';

create function public.register_upload(p_id uuid) returns jsonb
language plpgsql security definer set search_path='' as $$
declare uid uuid:=public.require_member(); image_path text;
begin
 if p_id is null then raise exception 'Ungültige Bild-ID.'; end if;
 perform pg_advisory_xact_lock(hashtext(uid::text));
 if (select count(*) from public.uploads where owner=uid and created>clock_timestamp()-interval '24 hours')>=40 then
  raise exception 'Maximal 40 Foto-Uploads pro Tag.';
 end if;
 image_path:=uid::text||'/'||p_id::text;
 insert into public.uploads(id,owner,path) values(p_id,uid,image_path);
 return jsonb_build_object('id',p_id,'path',image_path);
end $$;

create function public.can_upload_image(p_path text) returns boolean
language sql security definer set search_path='' as $$
 select exists(select 1 from public.uploads u join auth.users a on a.id=u.owner
 where u.path=p_path and u.owner=auth.uid() and a.email_confirmed_at is not null
 and u.created>clock_timestamp()-interval '10 minutes')
$$;

create function public.can_read_image(p_path text) returns boolean
language sql security definer set search_path='' as $$
 select exists(select 1 from public.uploads u where u.path=p_path
 and (u.owner=auth.uid() or exists(select 1 from public.listings l where l.image=u.id)))
$$;

alter policy image_insert on storage.objects with check(bucket_id='product-images' and public.can_upload_image(name));
alter policy image_select on storage.objects using(bucket_id='product-images' and public.can_read_image(name));
revoke all on function public.register_upload(uuid),public.can_upload_image(text),public.can_read_image(text) from public,anon,authenticated;
revoke all on function public.image_paths() from public,anon,authenticated;
grant execute on function public.register_upload(uuid),public.can_upload_image(text) to authenticated;
grant execute on function public.can_read_image(text) to anon,authenticated;

create function public.handle_new_member() returns trigger
language plpgsql security definer set search_path='' as $$
begin
 insert into public.profiles(id,name) values(new.id,'Mitglied') on conflict do nothing;
 return new;
end $$;
revoke all on function public.handle_new_member() from public,anon,authenticated;
create trigger kleinweiter_new_member after insert on auth.users for each row execute function public.handle_new_member();
insert into public.profiles(id,name) select id,'Mitglied' from auth.users on conflict do nothing;
