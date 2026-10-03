import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFile,readdir} from 'node:fs/promises';
import {PGlite} from '@electric-sql/pglite';

test('Sale workflow: frozen terms, participant permissions, disputes and completion',async()=>{
 const db=new PGlite();
 try{
 await db.exec(`create role anon;create role authenticated;create schema auth;create schema storage;
 create table auth.users(id uuid primary key,email text,email_confirmed_at timestamptz);
 create function auth.uid() returns uuid language sql as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
 grant usage on schema auth,storage,public to anon,authenticated;grant execute on function auth.uid() to anon,authenticated;
 create table storage.buckets(id text primary key,name text,public boolean,file_size_limit bigint,allowed_mime_types text[]);
 create table storage.objects(id uuid default gen_random_uuid(),bucket_id text,name text);alter table storage.objects enable row level security;grant select,insert on storage.objects to anon,authenticated;
 create function storage.foldername(name text) returns text[] language sql as $$select string_to_array(name,'/')$$;`);
 const dir=new URL('../supabase/migrations/',import.meta.url),files=(await readdir(dir)).filter(f=>f.endsWith('.sql')).sort();
 for(const f of files.filter(f=>f<'20261002000500_order_progress.sql'))await db.exec(await readFile(new URL(f,dir),'utf8'));
 const seller='11111111-1111-4111-8111-111111111111',buyer='22222222-2222-4222-8222-222222222222',loser='33333333-3333-4333-8333-333333333333',mod='44444444-4444-4444-8444-444444444444',image='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
 for(const [uid,email] of [[seller,'seller@example.test'],[buyer,'buyer@example.test'],[loser,'loser@example.test'],[mod,'mod@example.test']])await db.query('insert into auth.users values($1,$2,now())',[uid,email]);
 async function identity(id){await db.exec('reset role');await db.query("select set_config('request.jwt.claim.sub',$1,false)",[id]);await db.exec(id?'set role authenticated':'set role anon')}
 const rpc=async(name,args=[],parameters='')=>(await db.query(`select public.${name}(${parameters}) result`,args)).rows[0].result;
 const market=body=>rpc('market_action',[JSON.stringify(body)],'$1::jsonb');
 const orders=id=>rpc('order_feed',[id||null],'$1::uuid');
 const action=body=>rpc('order_action',[JSON.stringify(body)],'$1::jsonb');
 const review=body=>rpc('order_issue_review',[JSON.stringify(body)],'$1::jsonb');
 const listing={action:'create',title:'TEST Abwicklung ohne Verkauf',description:'Nur technischer Test ohne Zahlung, Produkt oder Lieferung.',age:1,category:'Spielsachen',condition:'Gut',size:'3 Jahre',location:'Zürich',delivery:'Abholung nach Absprache',shipping:700,start:100,buy:3000,days:1,image,childrenOnly:true};
 await identity(seller);await rpc('register_upload',[image],'$1::uuid');await db.query("insert into storage.objects(bucket_id,name) values('product-images',$1)",[seller+'/'+image]);
 const legacy=await market(listing);await identity(buyer);await market({action:'buy',id:legacy.id,confirm:true});
 await db.exec('reset role');await db.exec(await readFile(new URL('20261002000500_order_progress.sql',dir),'utf8'));
 for(const f of files.filter(f=>f>'20261002000500_order_progress.sql'))await db.exec(await readFile(new URL(f,dir),'utf8'));
 await db.query('insert into public.moderators(id) values($1),($2)',[mod,seller]);
 await identity(buyer);let order=(await orders(legacy.id)).orders[0];assert.equal(order.price,3000);assert.equal(order.shipping,700);assert.equal(order.role,'buyer');assert.equal(order.completed_at,null);assert.equal(order.paid_at,null);assert.equal(order.contact,'seller@example.test');
 await identity(seller);const sold=await market(listing),active=await market(listing);assert.equal((await orders(active.id)).orders.length,0);
 await identity(loser);await market({action:'bid',id:sold.id,amount:100,confirm:true});await identity(buyer);await market({action:'buy',id:sold.id,confirm:true});
 await assert.rejects(action({id:sold.id,action:'payment_received',revision:0,confirm:true}),/zuständige/);
 await assert.rejects(action({id:sold.id,action:'paid',revision:0,confirm:false}),/bestätigen/);
 await action({id:sold.id,action:'paid',revision:0,confirm:true});
 await assert.rejects(action({id:sold.id,action:'received',revision:0,confirm:true}),/inzwischen/);
 await assert.rejects(action({id:sold.id,action:'paid',revision:1,confirm:true}),/bereits/);
 await assert.rejects(db.query('select * from public.orders'),/permission denied/);
 await assert.rejects(db.query('select * from public.order_issues'),/permission denied/);
 await identity(loser);assert.equal((await orders(sold.id)).orders.length,0);await assert.rejects(action({id:sold.id,action:'received',revision:1,confirm:true}),/nicht gefunden/);
 await identity(seller);order=(await orders(sold.id)).orders[0];assert.ok(order.paid_at);assert.equal(order.role,'seller');assert.equal(order.contact,'buyer@example.test');
 await assert.rejects(action({id:sold.id,action:'received',revision:1,confirm:true}),/zuständige/);
 await action({id:sold.id,action:'payment_received',revision:1,confirm:true});await action({id:sold.id,action:'sent',revision:2,confirm:true});
 await identity(buyer);await action({id:sold.id,action:'issue',revision:3,confirm:true,reason:'Sonstiges',details:'Technische Testmeldung ohne echte Beanstandung'});
 await action({id:sold.id,action:'received',revision:4,confirm:true});order=(await orders(sold.id)).orders[0];assert.equal(order.completed_at,null);assert.equal(order.issues.length,1);assert.equal(order.events.length,5);
 await assert.rejects(action({id:sold.id,action:'issue',revision:5,confirm:true,reason:'Sonstiges',details:'Zweite Meldung desselben Kontos'}),/bereits/);
 const issue=order.issues[0].id;
 await identity(seller);await assert.rejects(action({id:sold.id,action:'resolve_issue',issue_id:issue,revision:5,note:'Nicht meine Meldung gelöst',confirm:true}),/meldende/);
 assert.equal(await rpc('order_support_access'),false);await assert.rejects(rpc('order_issue_feed'),/Kein Zugang/);
 await identity(mod);assert.equal(await rpc('order_support_access'),false);
 await db.exec('reset role');await db.query('update public.moderators set order_support=true where id in ($1,$2)',[mod,seller]);
 await identity(seller);await assert.rejects(review({id:issue,revision:5,note:'Eigener Verkauf nicht selbst prüfen',confirm:true}),/eigenen Verkäufen/);
 await identity(mod);const queue=(await rpc('order_issue_feed')).orders;assert.equal(queue[0].listing,sold.id);assert.equal('contact' in queue[0],false);assert.equal(JSON.stringify(queue).includes('example.test'),false);
 await assert.rejects(review({id:issue,revision:4,note:'Veraltete Entscheidung ablehnen',confirm:true}),/inzwischen/);
 await review({id:issue,revision:5,note:'Nur technische Testprüfung abgeschlossen',confirm:true});
 await assert.rejects(review({id:issue,revision:6,note:'Doppelte Prüfung ablehnen',confirm:true}),/Offene/);
 await identity(buyer);order=(await orders(sold.id)).orders[0];assert.ok(order.completed_at);assert.equal(order.issues[0].status,'closed');assert.equal(order.issues[0].review_role,'support');assert.equal(order.price,3000);assert.equal(order.shipping,700);
 await identity(seller);await action({id:sold.id,action:'issue',revision:6,confirm:true,reason:'Zahlung',details:'Weiterer technischer Test, kein echtes Problem'});
 order=(await orders(sold.id)).orders[0];const own=order.issues.find(i=>i.role==='seller');await action({id:sold.id,action:'resolve_issue',issue_id:own.id,revision:7,confirm:true,note:'Technischer Test durch meldende Person gelöst'});
 order=(await orders(sold.id)).orders[0];assert.equal(order.issues.every(i=>i.status==='closed'),true);assert.equal(order.issues[1].review_role,'seller');assert.ok(order.completed_at);
 await db.exec('reset role');await db.query("update public.listings set price=9000,shipping=900 where id=$1",[sold.id]); // simulate operator correction; frozen sale remains
 await identity(buyer);assert.equal((await orders(sold.id)).orders[0].price,3000);assert.equal((await orders(sold.id)).orders[0].shipping,700);
 const notices=(await rpc('notification_feed')).items;assert.ok(notices.some(n=>n.kind==='order_update'));assert.ok(notices.some(n=>n.kind==='order_issue'));assert.ok(notices.some(n=>n.kind==='order_review'));
 await identity('');await assert.rejects(orders(sold.id),/permission denied/);await assert.rejects(action({id:sold.id,action:'paid',revision:8,confirm:true}),/permission denied/);
 await db.exec('reset role');await db.query('update public.moderators set order_support=false where id=$1',[mod]);await identity(mod);await assert.rejects(rpc('order_issue_feed'),/Kein Zugang/);
 }finally{await db.close()}
});
