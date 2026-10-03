-- Transactional integration test; synthetic data and all changes roll back.
begin;
select set_config('kw.seller',gen_random_uuid()::text,true),set_config('kw.buyer',gen_random_uuid()::text,true),set_config('kw.image',gen_random_uuid()::text,true);
insert into auth.users(id,instance_id,aud,role,email,email_confirmed_at,raw_app_meta_data,raw_user_meta_data,created_at,updated_at)
select current_setting('kw.'||x)::uuid,'00000000-0000-0000-0000-000000000000','authenticated','authenticated','cron-'||x||'@example.test',now(),'{"provider":"email","providers":["email"]}','{}',now(),now() from unnest(array['seller','buyer']) x;
set local role authenticated;
select set_config('request.jwt.claim.sub',current_setting('kw.seller'),true);
select public.register_upload(current_setting('kw.image')::uuid);
insert into storage.objects(bucket_id,name,metadata) values('product-images',current_setting('kw.seller')||'/'||current_setting('kw.image'),'{"mimetype":"image/png","size":128}');
select set_config('kw.body',jsonb_build_object('action','create','title','SQL Cron Funktionstest','description','Nur transienter Funktionstest ohne echten Verkauf.','age',1,'category','Spielsachen','condition','Gut','size','3 Jahre','location','Zürich','delivery','Keine echte Übergabe','shipping',500,'start',100,'days',1,'image',current_setting('kw.image'),'childrenOnly',true)::text,true);
select set_config('kw.won',public.market_action(current_setting('kw.body')::jsonb)->>'id',true),set_config('kw.empty',public.market_action(current_setting('kw.body')::jsonb)->>'id',true),set_config('kw.future',public.market_action(current_setting('kw.body')::jsonb)->>'id',true);
select set_config('request.jwt.claim.sub',current_setting('kw.buyer'),true);
select public.market_action(jsonb_build_object('action','bid','id',current_setting('kw.won'),'amount',100,'confirm',true));
reset role;
update public.listings set "end"=0 where id in(current_setting('kw.won')::uuid,current_setting('kw.empty')::uuid);
select public.settle_due_auctions();
select public.settle_due_auctions();
do $$ begin
 if (select status from public.listings where id=current_setting('kw.won')::uuid)<>'sold' then raise exception 'WINNER_NOT_SETTLED';end if;
 if (select status from public.listings where id=current_setting('kw.empty')::uuid)<>'expired' then raise exception 'EMPTY_NOT_EXPIRED';end if;
 if (select status from public.listings where id=current_setting('kw.future')::uuid)<>'active' then raise exception 'FUTURE_CHANGED';end if;
 if (select count(*) from public.orders where listing=current_setting('kw.won')::uuid and price=100 and shipping=500)<>1 then raise exception 'ORDER_SNAPSHOT';end if;
 if exists(select 1 from public.orders where listing=current_setting('kw.empty')::uuid) then raise exception 'EMPTY_ORDER';end if;
 if (select count(*) from public.notifications where listing=current_setting('kw.won')::uuid and kind in('won','sold'))<>2 then raise exception 'WIN_NOTICES';end if;
 if (select count(*) from public.notifications where listing=current_setting('kw.empty')::uuid and kind='expired')<>1 then raise exception 'EXPIRY_NOTICE';end if;
 if has_function_privilege('authenticated','public.settle_due_auctions()','EXECUTE') or has_function_privilege('anon','public.settle_due_auctions()','EXECUTE') then raise exception 'PUBLIC_SCHEDULER_ACCESS';end if;
end $$;
rollback;
select 'PASS: auction winner, expiry without bids, future auction unchanged, one order with fixed shipping, exactly-once notifications, private function. All changes rolled back.' as result;
