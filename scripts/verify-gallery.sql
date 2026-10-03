-- Synthetic identities and storage metadata only; every change rolls back.
begin;
select set_config('kw.seller',gen_random_uuid()::text,true),set_config('kw.buyer',gen_random_uuid()::text,true),set_config('kw.photo1',gen_random_uuid()::text,true),set_config('kw.photo2',gen_random_uuid()::text,true);
insert into auth.users(id,instance_id,aud,role,email,email_confirmed_at,raw_app_meta_data,raw_user_meta_data,created_at,updated_at)
select current_setting('kw.'||x)::uuid,'00000000-0000-0000-0000-000000000000','authenticated','authenticated','gallery-'||x||'@example.test',now(),'{"provider":"email","providers":["email"]}','{}',now(),now() from unnest(array['seller','buyer']) x;
set local role authenticated;
select set_config('request.jwt.claim.sub',current_setting('kw.seller'),true);
select public.register_upload(current_setting('kw.'||x)::uuid) from unnest(array['photo1','photo2']) x;
insert into storage.objects(bucket_id,name,metadata) select 'product-images',current_setting('kw.seller')||'/'||current_setting('kw.'||x),'{"mimetype":"image/png","size":128}' from unnest(array['photo1','photo2']) x;
select set_config('kw.body',jsonb_build_object('action','create','title','SQL Galerietest','description','Transienter Funktionstest ohne echten Verkauf.','age',1,'category','Spielsachen','condition','Gut','size','3 Jahre','location','Zürich','delivery','Keine Übergabe','shipping',0,'start',100,'buy',3000,'days',1,'images',jsonb_build_array(current_setting('kw.photo1'),current_setting('kw.photo2')),'childrenOnly',true)::text,true);
select set_config('kw.listing',public.market_action(current_setting('kw.body')::jsonb)->>'id',true);
set local role anon;
select set_config('request.jwt.claim.sub','',true);
do $$ begin
 if public.image_path(current_setting('kw.photo1')::uuid) is null or public.image_path(current_setting('kw.photo2')::uuid) is null then raise exception 'GALLERY_VISIBILITY';end if;
end $$;
set local role authenticated;
select set_config('request.jwt.claim.sub',current_setting('kw.seller'),true);
select public.market_action(current_setting('kw.body')::jsonb||jsonb_build_object('action','edit','id',current_setting('kw.listing'),'revision',0,'images',jsonb_build_array(current_setting('kw.photo2'),current_setting('kw.photo1'))));
do $$ declare item jsonb;begin
 select i into item from jsonb_array_elements(public.market_feed(null,true)->'items') i where i->>'id'=current_setting('kw.listing');
 if item->>'image'<>current_setting('kw.photo2') or item->'images'->>1<>current_setting('kw.photo1') then raise exception 'ORDER_OR_COVER';end if;
end $$;
select set_config('request.jwt.claim.sub',current_setting('kw.buyer'),true);
do $$ begin
 begin perform public.market_action(current_setting('kw.body')::jsonb);raise exception 'FOREIGN_PHOTOS_ACCEPTED';exception when raise_exception then if sqlerrm not like '%eigene%' then raise;end if;end;
end $$;
select public.market_action(jsonb_build_object('action','bid','id',current_setting('kw.listing'),'amount',100,'confirm',true));
select set_config('request.jwt.claim.sub',current_setting('kw.seller'),true);
do $$ begin
 begin perform public.market_action(current_setting('kw.body')::jsonb||jsonb_build_object('action','edit','id',current_setting('kw.listing'),'revision',2));raise exception 'BID_LOCK_FAILED';exception when raise_exception then if sqlerrm not like '%ersten Gebot%' then raise;end if;end;
 if has_function_privilege('authenticated','public.market_single_photo_action(jsonb)','EXECUTE') then raise exception 'INNER_FUNCTION_EXPOSED';end if;
end $$;
reset role;
rollback;
select 'PASS: multiple photos, public access, cover/reordering, ownership, bid lock and restricted inner function. All synthetic test data rolled back.' as result;
