import {supabase,configured} from '@/lib/supabase';
import {appOrigin} from '@/lib/origin.mjs';
import {NextResponse} from 'next/server';
export async function GET(req:Request){
 const url=new URL(req.url),code=url.searchParams.get('code'),flowId=url.searchParams.get('sb_flow_id');
 if(configured()&&process.env.NEXT_PUBLIC_DEMO_MODE!=='true'&&code){
  const db=await supabase();const {error}=await db.auth.exchangeCodeForSession(code,flowId?{flowId}:undefined);
  if(!error)return NextResponse.redirect(new URL('/',appOrigin()),{headers:{'Cache-Control':'private, no-store','Referrer-Policy':'no-referrer'}});
 }
 return NextResponse.redirect(new URL('/login?error=callback',appOrigin()),{headers:{'Cache-Control':'private, no-store','Referrer-Policy':'no-referrer'}});
}
