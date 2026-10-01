import {test} from 'node:test';
import assert from 'node:assert/strict';
import {appOrigin} from '../lib/origin.mjs';
test('Login redirect uses configured origin; rejects credentials and insecure remote URLs',()=>{
 const saved=process.env.NEXT_PUBLIC_SITE_URL;
 try{
  process.env.NEXT_PUBLIC_SITE_URL='https://kleinweiter.example/path';assert.equal(appOrigin(),'https://kleinweiter.example');
  process.env.NEXT_PUBLIC_SITE_URL='http://localhost:3000';assert.equal(appOrigin(),'http://localhost:3000');
  for(const value of ['http://untrusted.example','https://user:password@example.test','javascript:alert(1)']){process.env.NEXT_PUBLIC_SITE_URL=value;assert.throws(appOrigin);}
 }finally{if(saved===undefined)delete process.env.NEXT_PUBLIC_SITE_URL;else process.env.NEXT_PUBLIC_SITE_URL=saved;}
});
