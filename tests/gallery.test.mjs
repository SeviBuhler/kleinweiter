import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFile,readdir} from 'node:fs/promises';
import {PGlite} from '@electric-sql/pglite';
test('Gallery ownership, ordering, bid locks, migration and moderation snapshots',async()=>{
 const db=new PGlite();try{
 await db.exec(`create role anon;create role authenticated;create schema auth;create schema storage;
 create table auth.users(id uuid primary key,email text,email_confirmed_at timestamptz);
 create function auth.uid() returns uuid language sql as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
 grant usage on schema auth,storage,public to anon,authenticated;grant execute on function auth.uid() to anon,authenticated;
 create table storage.buckets(id text primary key,name text,public boolean,file_size_limit bigint,allowed_mime_types text[]);
 create table storage.objects(id uuid default gen_random_uuid(),bucket_id text,name text);alter table storage.objects enable row level security;grant select,insert on storage.objects to anon,authenticated;
 create function storage.foldername(name text) returns text[] language sql as $$select string_to_array(name,'/')$$;`);
 const dir=new URL('../supabase/migrations/',import.meta.url),files=(await readdir(dir)).filter(f=>f.endsWith('.sql')).sort();
 for(const f of files.slice(0,-1))await db.exec(await readFile(new URL(f,dir),'utf8'));
 const seller='11111111-1111-4111-8111-111111111111',buyer='22222222-2222-4222-8222-222222222222',mod='33333333-3333-4333-8333-333333333333';
 await db.query('insert into auth.users values($1,$2,now()),($3,$4,now()),($5,$6,now())',[seller,'seller@example.test',buyer,'buyer@example.test',mod,'mod@example.test']);await db.query('insert into public.moderators(id) values($1)',[mod]);
 const ids=Array.from({length:7},(_,i)=>`aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa${i}`);
 async function identity(id){await db.exec('reset role');await db.query("select set_config('request.jwt.claim.sub',$1,false)",[id]);await db.exec(id?'set role authenticated':'set role anon')}
 const action=async(body)=>(await db.query('select public.market_action($1::jsonb) result',[JSON.stringify(body)])).rows[0].result;
 const feed=async(mine=false)=>(await db.query('select public.market_feed($1,$2) result',[mine?null:1,mine])).rows[0].result;
 const visible=async(id)=>(await db.query('select public.image_path($1) path',[id])).rows[0].path;
 await identity(seller);for(const id of ids.slice(0,6)){await db.query('select public.register_upload($1)',[id]);await db.query("insert into storage.objects(bucket_id,name) values('product-images',$1)",[seller+'/'+id])}
 const listing={action:'create',title:'TEST Galerie ohne Verkaufsangebot',description:'Technischer Test ohne Produkt, Zahlung oder Lieferung.',age:1,category:'Spielsachen',condition:'Gut',size:'3 Jahre',location:'Zürich',delivery:'Keine Übergabe im Test',shipping:0,start:100,buy:3000,days:1,image:ids[0],childrenOnly:true};
 const legacy=await action(listing);
 await db.exec('reset role');await db.exec(await readFile(new URL(files.at(-1),dir),'utf8'));
 await identity(seller);assert.deepEqual((await feed(true)).items.find(i=>i.id===legacy.id).images,[ids[0]]);
 await assert.rejects(action({...listing,images:[]}));await assert.rejects(action({...listing,images:null}));await assert.rejects(action({...listing,images:[ids[1],ids[1]]}),/unterschiedliche/);await assert.rejects(action({...listing,images:ids.slice(0,6)}),/fünf/);
 await identity(buyer);await db.query('select public.register_upload($1)',[ids[6]]);await db.query("insert into storage.objects(bucket_id,name) values('product-images',$1)",[buyer+'/'+ids[6]]);
 await identity(seller);await assert.rejects(action({...listing,images:[ids[1],ids[6]]}),/eigene/);
 const created=await action({...listing,images:ids.slice(1,6)});
 let item=(await feed(true)).items.find(i=>i.id===created.id);assert.deepEqual(item.images,ids.slice(1,6));assert.equal(item.image,ids[1]);
 await identity('');for(const id of ids.slice(1,6))assert.equal(await visible(id),seller+'/'+id);
 await identity(buyer);await db.query('select public.report_listing($1::jsonb)',[JSON.stringify({id:created.id,reason:'Sonstiges',details:'Nur technischer Test einer Galerie-Meldung'})]);
 await identity(seller);await action({...listing,action:'edit',id:created.id,revision:0,images:[ids[5],ids[4],ids[3],ids[2]]});
 item=(await feed(true)).items.find(i=>i.id===created.id);assert.equal(item.image,ids[5]);assert.equal(item.revision,1);
 await assert.rejects(action({...listing,action:'edit',id:created.id,revision:0,images:[ids[2]]}),/inzwischen/);
 // Legacy text edit with unchanged cover retains all photos.
 await action({...listing,action:'edit',id:created.id,revision:1,image:ids[5]});item=(await feed(true)).items.find(i=>i.id===created.id);assert.deepEqual(item.images,[ids[5],ids[4],ids[3],ids[2]]);
 await identity('');assert.equal(await visible(ids[1]),null);
 await identity(mod);assert.equal(await visible(ids[1]),seller+'/'+ids[1]);const queue=(await db.query('select public.moderation_feed() result')).rows[0].result.reports;const report=queue.find(r=>r.listing.id===created.id);assert.deepEqual(report.snapshot.images,ids.slice(1,6));
 await identity(buyer);await action({action:'bid',id:created.id,amount:100,confirm:true});
 await identity(seller);await assert.rejects(action({...listing,action:'edit',id:created.id,revision:3,images:[ids[3]]}),/ersten Gebot/);
 await assert.rejects(db.query('select public.market_single_photo_action($1::jsonb)',[JSON.stringify(listing)]),/permission denied/);
 await identity(mod);await db.query('select public.moderation_action($1::jsonb)',[JSON.stringify({id:report.id,action:'block',revision:3,note:'Technischer Galerietest ohne echte Beanstandung',confirm:true})]);
 await identity('');for(const id of ids.slice(1,6))assert.equal(await visible(id),null);
 await identity(mod);for(const id of ids.slice(1,6))assert.equal(await visible(id),seller+'/'+id);
 await identity(seller);assert.equal(await visible(ids[5]),seller+'/'+ids[5]);
 }finally{await db.close()}
});
