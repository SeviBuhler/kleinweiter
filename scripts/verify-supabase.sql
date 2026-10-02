-- Run in Supabase SQL Editor as postgres. Everything is rolled back.
-- These are transient database identities, not actual login accounts or photos.
begin;
select set_config('kw.seller',gen_random_uuid()::text,true),set_config('kw.buyer',gen_random_uuid()::text,true),set_config('kw.image',gen_random_uuid()::text,true);
insert into auth.users(id,instance_id,aud,role,email,email_confirmed_at,raw_app_meta_data,raw_user_meta_data,created_at,updated_at)
values(current_setting('kw.seller')::uuid,'00000000-0000-0000-0000-000000000000','authenticated','authenticated','sql-seller@example.test',now(),'{"provider":"email","providers":["email"]}','{}',now(),now()),
(current_setting('kw.buyer')::uuid,'00000000-0000-0000-0000-000000000000','authenticated','authenticated','sql-buyer@example.test',now(),'{"provider":"email","providers":["email"]}','{}',now(),now());
set local role authenticated;
select set_config('request.jwt.claim.sub',current_setting('kw.seller'),true);
select public.register_upload(current_setting('kw.image')::uuid);
insert into storage.objects(bucket_id,name,metadata) values('product-images',current_setting('kw.seller')||'/'||current_setting('kw.image'),'{"mimetype":"image/png","size":128}');
select set_config('kw.listing',(public.market_action(jsonb_build_object('action','create','title','SQL Test Jacke','description','Nur ein transienter Testartikel ohne echte Verkaufsabsicht.','age',1,'category','Kleidung','condition','Gut','size','104','location','Zürich','delivery','Nur Datenbanktest','shipping',0,'start',1000,'buy',3000,'days',1,'image',current_setting('kw.image'),'childrenOnly',true))->>'id'),true);
select public.market_action((public.market_feed(null,true)->'items'->0)||jsonb_build_object('action','edit','childrenOnly',true,'title','SQL Test bearbeitet'));
do $$ begin
 if public.market_feed(null,true)->'items'->0->>'title' is distinct from 'SQL Test bearbeitet' then raise exception 'EDIT_CHECK_FAILED'; end if;
 if has_function_privilege('authenticated','public.market_trade_action(jsonb)','EXECUTE') then raise exception 'INTERNAL_FUNCTION_EXPOSED'; end if;
end $$;
do $$ begin
 if has_table_privilege('authenticated','public.listings','INSERT') or has_table_privilege('authenticated','public.uploads','INSERT') then raise exception 'Direkte Schreibrechte vorhanden'; end if;
 begin perform public.market_action(jsonb_build_object('action','bid','id',current_setting('kw.listing'),'amount',1000,'confirm',true));raise exception 'OWN_BID_CHECK_FAILED';
 exception when raise_exception then if sqlerrm not like '%eigenes Angebot%' then raise; end if; end;
end $$;
select set_config('request.jwt.claim.sub',current_setting('kw.buyer'),true);
do $$ begin
 if jsonb_array_length(public.market_feed(null,true)->'contacts')<>0 then raise exception 'Kontakt vor Kauf offengelegt'; end if;
 if public.can_upload_image(current_setting('kw.seller')||'/'||current_setting('kw.image')) then raise exception 'Fremder Upload erlaubt'; end if;
 begin perform public.market_action(jsonb_build_object('action','bid','id',current_setting('kw.listing'),'amount',999,'confirm',true));raise exception 'LOW_BID_CHECK_FAILED';
 exception when raise_exception then if sqlerrm not like '%niedrig%' then raise; end if; end;
end $$;
select public.market_action(jsonb_build_object('action','bid','id',current_setting('kw.listing'),'amount',1000,'confirm',true));
select set_config('request.jwt.claim.sub',current_setting('kw.seller'),true);
do $$ begin
 begin perform public.market_action(jsonb_build_object('action','withdraw','id',current_setting('kw.listing'),'revision',2,'confirm',true));raise exception 'BID_WITHDRAW_CHECK_FAILED';
 exception when raise_exception then if sqlerrm not like '%ersten Gebot%' then raise; end if; end;
end $$;
select set_config('request.jwt.claim.sub',current_setting('kw.buyer'),true);
select public.market_action(jsonb_build_object('action','buy','id',current_setting('kw.listing'),'confirm',true));
do $$ begin
 if public.market_feed(null,true)->'contacts'->0->>'email' is distinct from 'sql-seller@example.test' then raise exception 'Käuferkontakt fehlt'; end if;
 begin perform public.market_action(jsonb_build_object('action','buy','id',current_setting('kw.listing'),'confirm',true));raise exception 'DOUBLE_BUY_CHECK_FAILED';
 exception when raise_exception then if sqlerrm not like '%nicht mehr verfügbar%' then raise; end if; end;
end $$;
select set_config('request.jwt.claim.sub',current_setting('kw.seller'),true);
do $$ begin
 if public.market_feed(null,true)->'contacts'->0->>'email' is distinct from 'sql-buyer@example.test' then raise exception 'Verkäuferkontakt fehlt'; end if;
end $$;
set local role anon;
select set_config('request.jwt.claim.sub','',true);
do $$ begin
 if has_function_privilege('anon','public.market_action(jsonb)','EXECUTE') or has_function_privilege('anon','public.register_upload(uuid)','EXECUTE') then raise exception 'Anonyme Schreibrechte vorhanden'; end if;
 if jsonb_array_length(public.market_feed(1,false)->'contacts')<>0 then raise exception 'Öffentliche Kontakte'; end if;
end $$;
reset role;
rollback;
select 'PASS: PostgreSQL functions, editing, ownership, bid withdrawal protection, bids, purchase, privacy and grants. All test data rolled back.' as result;
