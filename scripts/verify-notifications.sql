-- Production-safe transaction: all synthetic identities and events roll back.
begin;
select set_config('kw.seller',gen_random_uuid()::text,true),set_config('kw.buyer',gen_random_uuid()::text,true),set_config('kw.other',gen_random_uuid()::text,true),set_config('kw.image',gen_random_uuid()::text,true);
insert into auth.users(id,instance_id,aud,role,email,email_confirmed_at,raw_app_meta_data,raw_user_meta_data,created_at,updated_at)
select current_setting('kw.'||x)::uuid,'00000000-0000-0000-0000-000000000000','authenticated','authenticated','notifications-'||x||'@example.test',now(),'{"provider":"email","providers":["email"]}','{}',now(),now() from unnest(array['seller','buyer','other']) x;
set local role authenticated;
select set_config('request.jwt.claim.sub',current_setting('kw.seller'),true);
select public.register_upload(current_setting('kw.image')::uuid);
insert into storage.objects(bucket_id,name,metadata) values('product-images',current_setting('kw.seller')||'/'||current_setting('kw.image'),'{"mimetype":"image/png","size":128}');
select set_config('kw.listing',(public.market_action(jsonb_build_object('action','create','title','SQL Benachrichtigungstest','description','Nur transienter Funktionstest, kein reales Verkaufsangebot.','age',1,'category','Spielsachen','condition','Gut','size','3 Jahre','location','Zürich','delivery','Keine echte Übergabe','shipping',0,'start',100,'buy',3000,'days',1,'image',current_setting('kw.image'),'childrenOnly',true))->>'id'),true);
select set_config('request.jwt.claim.sub',current_setting('kw.buyer'),true);
select public.market_action(jsonb_build_object('action','bid','id',current_setting('kw.listing'),'amount',100,'confirm',true));
select set_config('request.jwt.claim.sub',current_setting('kw.other'),true);
select public.market_action(jsonb_build_object('action','bid','id',current_setting('kw.listing'),'amount',200,'confirm',true));
select set_config('request.jwt.claim.sub',current_setting('kw.buyer'),true);
select set_config('kw.notice',(select n->>'id' from jsonb_array_elements(public.notification_feed()->'items') n where n->>'listing'=current_setting('kw.listing') and n->>'kind'='outbid'),true);
do $$ begin
 if current_setting('kw.notice') is null or current_setting('kw.notice')='' then raise exception 'OUTBID_MISSING'; end if;
 if has_table_privilege('authenticated','public.notifications','SELECT') or has_table_privilege('authenticated','public.notifications','INSERT') or has_table_privilege('anon','public.notifications','SELECT') then raise exception 'DIRECT_ACCESS'; end if;
end $$;
select set_config('request.jwt.claim.sub',current_setting('kw.other'),true);
do $$ begin
 begin perform public.notification_read(current_setting('kw.notice')::uuid);raise exception 'FOREIGN_MARK';exception when raise_exception then if sqlerrm not like '%nicht gefunden%' then raise;end if;end;
 if exists(select 1 from jsonb_array_elements(public.notification_feed()->'items') n where n->>'id'=current_setting('kw.notice')) then raise exception 'FOREIGN_READ';end if;
end $$;
select set_config('request.jwt.claim.sub',current_setting('kw.buyer'),true);
select public.notification_read(current_setting('kw.notice')::uuid);
select public.market_action(jsonb_build_object('action','buy','id',current_setting('kw.listing'),'confirm',true));
do $$ begin
 if (select count(*) from jsonb_array_elements(public.notification_feed()->'items') n where n->>'listing'=current_setting('kw.listing') and n->>'kind'='purchased')<>1 then raise exception 'PURCHASE_MISSING';end if;
end $$;
select public.notification_read(null);
do $$ begin if (public.notification_feed()->>'unread')::int<>0 then raise exception 'READ_ALL';end if;end $$;
select set_config('request.jwt.claim.sub',current_setting('kw.seller'),true);
do $$ begin
 if (select count(*) from jsonb_array_elements(public.notification_feed()->'items') n where n->>'listing'=current_setting('kw.listing') and n->>'kind'='sold')<>1 then raise exception 'SELLER_MISSING';end if;
end $$;
reset role;
do $$ begin if (select count(*) from public.notifications where listing=current_setting('kw.listing')::uuid)<>4 then raise exception 'EVENT_COUNT';end if;end $$;
rollback;
select 'PASS: outbid, purchase, seller notice, private inbox, own read marking and duplicate prevention. All test data rolled back.' as result;
