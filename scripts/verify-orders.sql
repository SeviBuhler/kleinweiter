-- Run in SQL Editor; all synthetic identities, declarations and access roll back.
begin;
select set_config('kw.seller',gen_random_uuid()::text,true),set_config('kw.buyer',gen_random_uuid()::text,true),set_config('kw.other',gen_random_uuid()::text,true),set_config('kw.image',gen_random_uuid()::text,true);
insert into auth.users(id,instance_id,aud,role,email,email_confirmed_at,raw_app_meta_data,raw_user_meta_data,created_at,updated_at)
select current_setting('kw.'||x)::uuid,'00000000-0000-0000-0000-000000000000','authenticated','authenticated','orders-'||x||'@example.test',now(),'{"provider":"email","providers":["email"]}','{}',now(),now() from unnest(array['seller','buyer','other']) x;
insert into public.moderators(id,order_support) values(current_setting('kw.other')::uuid,true);
set local role authenticated;
select set_config('request.jwt.claim.sub',current_setting('kw.seller'),true);
select public.register_upload(current_setting('kw.image')::uuid);
insert into storage.objects(bucket_id,name,metadata) values('product-images',current_setting('kw.seller')||'/'||current_setting('kw.image'),'{"mimetype":"image/png","size":128}');
select set_config('kw.listing',(public.market_action(jsonb_build_object('action','create','title','SQL Abwicklungstest','description','Nur transienter Funktionstest, kein reales Verkaufsangebot.','age',1,'category','Spielsachen','condition','Gut','size','3 Jahre','location','Zürich','delivery','Keine echte Zahlung oder Übergabe','shipping',700,'start',100,'buy',3000,'days',1,'image',current_setting('kw.image'),'childrenOnly',true))->>'id'),true);
select set_config('request.jwt.claim.sub',current_setting('kw.buyer'),true);
select public.market_action(jsonb_build_object('action','buy','id',current_setting('kw.listing'),'confirm',true));
do $$ begin
 if (select (o->>'price')::int from jsonb_array_elements(public.order_feed(current_setting('kw.listing')::uuid)->'orders') o)<>3000 then raise exception 'SNAPSHOT_PRICE';end if;
 if has_table_privilege('authenticated','public.orders','SELECT') or has_table_privilege('authenticated','public.order_issues','INSERT') then raise exception 'DIRECT_ACCESS';end if;
 begin perform public.order_action(jsonb_build_object('id',current_setting('kw.listing'),'revision',0,'action','sent','confirm',true));raise exception 'WRONG_ROLE';exception when raise_exception then if sqlerrm not like '%zuständige%' then raise;end if;end;
end $$;
select public.order_action(jsonb_build_object('id',current_setting('kw.listing'),'revision',0,'action','paid','confirm',true));
do $$ begin
 begin perform public.order_action(jsonb_build_object('id',current_setting('kw.listing'),'revision',0,'action','received','confirm',true));raise exception 'STALE_FORM';exception when raise_exception then if sqlerrm not like '%inzwischen%' then raise;end if;end;
end $$;
select public.order_action(jsonb_build_object('id',current_setting('kw.listing'),'revision',1,'action','issue','reason','Sonstiges','details','Nur technische Testmeldung, kein echtes Problem.','confirm',true));
select public.order_action(jsonb_build_object('id',current_setting('kw.listing'),'revision',2,'action','received','confirm',true));
select set_config('kw.issue',(select o->'issues'->0->>'id' from jsonb_array_elements(public.order_feed(current_setting('kw.listing')::uuid)->'orders') o),true);
select set_config('request.jwt.claim.sub',current_setting('kw.seller'),true);
select public.order_action(jsonb_build_object('id',current_setting('kw.listing'),'revision',3,'action','payment_received','confirm',true));
select public.order_action(jsonb_build_object('id',current_setting('kw.listing'),'revision',4,'action','sent','confirm',true));
do $$ begin
 if exists(select 1 from jsonb_array_elements(public.order_feed(current_setting('kw.listing')::uuid)->'orders') o where o->>'completed_at' is not null) then raise exception 'OPEN_PROBLEM_COMPLETED';end if;
 begin perform public.order_issue_feed();raise exception 'SUPPORT_ACCESS';exception when raise_exception then if sqlerrm not like '%Kein Zugang%' then raise;end if;end;
end $$;
select set_config('request.jwt.claim.sub',current_setting('kw.other'),true);
do $$ begin
 if jsonb_array_length(public.order_feed(current_setting('kw.listing')::uuid)->'orders')<>0 then raise exception 'FOREIGN_ORDER_READ';end if;
 if not exists(select 1 from jsonb_array_elements(public.order_issue_feed()->'orders') o where o->>'listing'=current_setting('kw.listing')) then raise exception 'SUPPORT_QUEUE';end if;
end $$;
select public.order_issue_review(jsonb_build_object('id',current_setting('kw.issue'),'revision',5,'note','Technischer Test geprüft und abgeschlossen.','confirm',true));
select set_config('request.jwt.claim.sub',current_setting('kw.buyer'),true);
do $$ begin
 if not exists(select 1 from jsonb_array_elements(public.order_feed(current_setting('kw.listing')::uuid)->'orders') o where o->>'completed_at' is not null and o->'issues'->0->>'status'='closed') then raise exception 'COMPLETE_FAILED';end if;
 if not exists(select 1 from jsonb_array_elements(public.notification_feed()->'items') n where n->>'listing'=current_setting('kw.listing') and n->>'kind'='order_review') then raise exception 'REVIEW_NOTIFICATION';end if;
end $$;
reset role;
rollback;
select 'PASS: sale snapshot, roles, stale forms, problem/completion rules, support access, review and notifications. All test data rolled back.' as result;
