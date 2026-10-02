import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFile,readdir} from 'node:fs/promises';
import {PGlite} from '@electric-sql/pglite';

test('Transactional notifications: recipients, privacy, marking and auction settlement',async()=>{
 const db=new PGlite();
 try{
 await db.exec(`create role anon; create role authenticated; create schema auth; create schema storage;
 create table auth.users(id uuid primary key,email text,email_confirmed_at timestamptz);
 create function auth.uid() returns uuid language sql as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
 grant usage on schema auth,storage,public to anon,authenticated; grant execute on function auth.uid() to anon,authenticated;
 create table storage.buckets(id text primary key,name text,public boolean,file_size_limit bigint,allowed_mime_types text[]);
 create table storage.objects(id uuid default gen_random_uuid(),bucket_id text,name text);
 alter table storage.objects enable row level security; grant select,insert on storage.objects to anon,authenticated;
 create function storage.foldername(name text) returns text[] language sql as $$select string_to_array(name,'/')$$;`);
 const dir=new URL('../supabase/migrations/',import.meta.url);
 for(const f of (await readdir(dir)).filter(x=>x.endsWith('.sql')).sort())await db.exec(await readFile(new URL(f,dir),'utf8'));
 const seller='11111111-1111-4111-8111-111111111111',buyer='22222222-2222-4222-8222-222222222222',other='33333333-3333-4333-8333-333333333333',image='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
 await db.query('insert into auth.users values($1,$2,now()),($3,$4,now()),($5,$6,now())',[seller,'seller@example.test',buyer,'buyer@example.test',other,'other@example.test']);
 await db.query('insert into public.moderators(id) values($1)',[other]);
 async function identity(id){await db.exec('reset role');await db.query("select set_config('request.jwt.claim.sub',$1,false)",[id]);await db.exec(id?'set role authenticated':'set role anon')}
 const rpc=async(name,args=[],placeholders='')=>(await db.query(`select public.${name}(${placeholders}) result`,args)).rows[0].result;
 const action=body=>rpc('market_action',[JSON.stringify(body)],'$1::jsonb');
 const inbox=()=>rpc('notification_feed');
 const mark=id=>rpc('notification_read',[id],'$1::uuid');
 const listing={action:'create',title:'TEST Bausteine Benachrichtigungen',description:'Technischer Test ohne Produkt, Zahlung oder Übergabe.',age:1,category:'Spielsachen',condition:'Gut',size:'3 bis unter 6',location:'Zürich',delivery:'Keine Zahlung im Test',shipping:0,start:100,buy:3000,days:1,image,childrenOnly:true};
 await identity(seller);await rpc('register_upload',[image],'$1::uuid');await db.query("insert into storage.objects(bucket_id,name) values('product-images',$1)",[seller+'/'+image]);
 const {id}=await action(listing);assert.equal((await inbox()).items.length,0);
 await identity(buyer);await action({action:'bid',id,amount:100,confirm:true});assert.equal((await inbox()).unread,0);
 await action({action:'bid',id,amount:200,confirm:true});assert.equal((await inbox()).unread,0); // own higher bid
 await identity(other);await action({action:'bid',id,amount:300,confirm:true});assert.equal((await inbox()).unread,0);
 await identity(buyer);let feed=await inbox();assert.equal(feed.unread,1);assert.equal(feed.items[0].kind,'outbid');assert.equal('recipient' in feed.items[0],false);assert.equal(JSON.stringify(feed).includes('example.test'),false);
 const firstNotice=feed.items[0].id;
 await assert.rejects(db.query('select * from public.notifications'),/permission denied/);
 await assert.rejects(db.query("insert into public.notifications(recipient,listing,kind,title,body,revision) values($1,$2,'outbid','Fake','Fake',999)",[buyer,id]),/permission denied/);
 await assert.rejects(db.query('select public.notify_listing_transition()'),/permission denied/);
 await identity(other);await assert.rejects(mark(firstNotice),/nicht gefunden/);await mark(null);
 await identity(buyer);assert.equal((await inbox()).unread,1);await mark(firstNotice);assert.equal((await inbox()).unread,0);const readAt=(await inbox()).items[0].read_at;await mark(firstNotice);assert.equal((await inbox()).items[0].read_at,readAt);
 await action({action:'buy',id,confirm:true});await assert.rejects(action({action:'buy',id,confirm:true}),/nicht mehr/);
 assert.equal((await inbox()).items.filter(n=>n.kind==='purchased').length,1);
 await identity(other);assert.equal((await inbox()).items.filter(n=>n.kind==='outbid').length,1);
 await identity(seller);assert.equal((await inbox()).items.filter(n=>n.kind==='sold').length,1);
 const expired=await action({...listing,buy:null});const won=await action({...listing,buy:null});
 await identity(buyer);await action({action:'bid',id:won.id,amount:100,confirm:true});
 await db.exec('reset role');await db.query('update public.listings set "end"=0 where id in ($1,$2)',[expired.id,won.id]);
 await identity(buyer);assert.equal((await inbox()).items.filter(n=>n.kind==='won').length,1);assert.equal((await inbox()).items.filter(n=>n.kind==='won').length,1);
 await identity(seller);assert.equal((await inbox()).items.filter(n=>n.kind==='expired').length,1);assert.equal((await inbox()).items.filter(n=>n.kind==='sold').length,2);
 const blocked=await action(listing);
 await identity(buyer);await action({action:'bid',id:blocked.id,amount:100,confirm:true});
 await identity(other);await action({action:'bid',id:blocked.id,amount:200,confirm:true});
 await rpc('report_listing',[JSON.stringify({id:blocked.id,reason:'Sonstiges',details:'Technischer Test einer Sperrnachricht'})],'$1::jsonb');
 const report=(await rpc('moderation_feed')).reports.find(r=>r.listing.id===blocked.id);
 await rpc('moderation_action',[JSON.stringify({id:report.id,action:'block',revision:2,note:'Technischer Test, keine reale Beanstandung',confirm:true})],'$1::jsonb');
 for(const uid of [seller,buyer,other]){await identity(uid);const rows=(await inbox()).items.filter(n=>n.listing===blocked.id&&n.kind==='blocked');assert.equal(rows.length,1);assert.match(rows[0].body,/keine reale Beanstandung/)}
 await identity(buyer);await mark(null);assert.equal((await inbox()).unread,0);assert.ok((await inbox()).items.length>0);
 await identity(seller);assert.ok((await inbox()).unread>0); // bulk marking does not affect another account
 await identity('');await assert.rejects(inbox(),/permission denied/);await assert.rejects(mark(null),/permission denied/);
 await db.exec('reset role');await db.query('update auth.users set email_confirmed_at=null where id=$1',[buyer]);await identity(buyer);await assert.rejects(inbox(),/bestätigter/);
 }finally{await db.close()}
});
