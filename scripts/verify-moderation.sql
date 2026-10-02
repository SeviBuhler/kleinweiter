-- Run as postgres in Supabase SQL Editor. All identities and data roll back.
begin;
select set_config('kw.seller',gen_random_uuid()::text,true),set_config('kw.buyer',gen_random_uuid()::text,true),set_config('kw.mod',gen_random_uuid()::text,true),set_config('kw.image',gen_random_uuid()::text,true);
insert into auth.users(id,instance_id,aud,role,email,email_confirmed_at,raw_app_meta_data,raw_user_meta_data,created_at,updated_at)
select current_setting('kw.'||x)::uuid,'00000000-0000-0000-0000-000000000000','authenticated','authenticated','sql-'||x||'@example.test',now(),'{"provider":"email","providers":["email"]}','{}',now(),now() from unnest(array['seller','buyer','mod']) x;
insert into public.moderators(id) values(current_setting('kw.mod')::uuid);
set local role authenticated;
select set_config('request.jwt.claim.sub',current_setting('kw.seller'),true);
select public.register_upload(current_setting('kw.image')::uuid);
insert into storage.objects(bucket_id,name,metadata) values('product-images',current_setting('kw.seller')||'/'||current_setting('kw.image'),'{"mimetype":"image/png","size":128}');
select set_config('kw.listing',(public.market_action(jsonb_build_object('action','create','title','SQL Moderationstest','description','Nur transienter Funktionstest, kein reales Verkaufsangebot.','age',1,'category','Spielsachen','condition','Gut','size','3 Jahre','location','Zürich','delivery','Keine echte Übergabe','shipping',0,'start',1000,'buy',3000,'days',1,'image',current_setting('kw.image'),'childrenOnly',true))->>'id'),true);
select set_config('request.jwt.claim.sub',current_setting('kw.buyer'),true);
select public.report_listing(jsonb_build_object('id',current_setting('kw.listing'),'reason','Sonstiges','details','Nur ein technischer Moderationstest.'));
select public.market_action(jsonb_build_object('action','bid','id',current_setting('kw.listing'),'amount',1000,'confirm',true));
do $$ begin
 if public.moderation_access() then raise exception 'USER_ACCESS_FAILED'; end if;
 if has_table_privilege('authenticated','public.moderators','INSERT') or has_table_privilege('authenticated','public.moderation_events','SELECT') then raise exception 'DIRECT_ACCESS_FAILED'; end if;
 begin perform public.moderation_feed(); raise exception 'USER_FEED_FAILED'; exception when raise_exception then if sqlerrm not like '%Kein Moderationszugang%' then raise; end if; end;
end $$;
select set_config('request.jwt.claim.sub',current_setting('kw.mod'),true);
select set_config('kw.report',(select r->>'id' from jsonb_array_elements(public.moderation_feed()->'reports') r where r->'listing'->>'id'=current_setting('kw.listing')),true);
do $$ begin
 if not public.moderation_access() then raise exception 'MOD_ACCESS_FAILED'; end if;
 begin perform public.moderation_action(jsonb_build_object('id',current_setting('kw.report'),'action','block','revision',0,'note','Technischer Test der Sperrfunktion','confirm',true)); raise exception 'STALE_REVISION_FAILED'; exception when raise_exception then if sqlerrm not like '%inzwischen geändert%' then raise; end if; end;
end $$;
select public.moderation_action(jsonb_build_object('id',current_setting('kw.report'),'action','block','revision',1,'note','Technischer Test: Auktion gestoppt','confirm',true));
select set_config('request.jwt.claim.sub',current_setting('kw.buyer'),true);
do $$ begin
 if exists(select 1 from jsonb_array_elements(public.market_feed(null,true)->'contacts') c where c->>'id'=current_setting('kw.listing')) then raise exception 'BLOCKED_CONTACT_FAILED'; end if;
 begin perform public.market_action(jsonb_build_object('action','buy','id',current_setting('kw.listing'),'confirm',true)); raise exception 'BLOCKED_BUY_FAILED'; exception when raise_exception then if sqlerrm not like '%nicht mehr verfügbar%' then raise; end if; end;
 begin perform public.market_action(jsonb_build_object('action','bid','id',current_setting('kw.listing'),'amount',1100,'confirm',true)); raise exception 'BLOCKED_BID_FAILED'; exception when raise_exception then if sqlerrm not like '%nicht mehr verfügbar%' then raise; end if; end;
end $$;
set local role anon;
select set_config('request.jwt.claim.sub','',true);
do $$ begin
 if public.can_read_image(current_setting('kw.seller')||'/'||current_setting('kw.image')) then raise exception 'BLOCKED_PHOTO_PUBLIC'; end if;
 if exists(select 1 from jsonb_array_elements(public.market_feed(1,false)->'items') i where i->>'id'=current_setting('kw.listing')) then raise exception 'BLOCKED_LISTING_PUBLIC'; end if;
end $$;
reset role;
do $$ begin
 if not exists(select 1 from public.listings where id=current_setting('kw.listing')::uuid and status='blocked' and bid_count=1 and price=1000) then raise exception 'BLOCKED_HISTORY_FAILED'; end if;
 if not exists(select 1 from public.moderation_events where report=current_setting('kw.report')::uuid and moderator=current_setting('kw.mod')::uuid and action='block') then raise exception 'AUDIT_FAILED'; end if;
end $$;
delete from public.moderators where id=current_setting('kw.mod')::uuid;
set local role authenticated;
select set_config('request.jwt.claim.sub',current_setting('kw.mod'),true);
do $$ begin
 if public.moderation_access() then raise exception 'ROLE_REVOCATION_FAILED'; end if;
end $$;
reset role;
rollback;
select 'PASS: Moderation roles, stale forms, auction blocking with bids, privacy, photos, audit and revocation. All data rolled back.' as result;
