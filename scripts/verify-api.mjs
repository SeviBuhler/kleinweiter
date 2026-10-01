import assert from 'node:assert/strict';
const base=process.env.NEXT_PUBLIC_SUPABASE_URL,key=process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;
if(!base||!key)throw Error('Supabase environment variables missing.');
const headers={apikey:key,'Content-Type':'application/json'};
const feed=await fetch(base+'/rest/v1/rpc/market_feed',{method:'POST',headers,body:JSON.stringify({p_age:1,p_mine:false})});
assert.equal(feed.status,200);const data=await feed.json();assert(Array.isArray(data.items));assert.equal(data.contacts.length,0);
for(const table of ['profiles','uploads','listings','bids']){
 const response=await fetch(base+'/rest/v1/'+table+'?select=*',{headers});assert([401,403].includes(response.status),'Anonymous table read unexpectedly allowed: '+table);
}
for(const [name,body] of [['market_action',{p_body:{action:'profile',name:'Unauthorized'}}],['register_upload',{p_id:crypto.randomUUID()}]]){
 const response=await fetch(base+'/rest/v1/rpc/'+name,{method:'POST',headers,body:JSON.stringify(body)});assert([401,403].includes(response.status),'Anonymous write unexpectedly allowed: '+name);
}
console.log('PASS: live public feed, private tables and denied anonymous writes.');
