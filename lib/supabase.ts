import {createServerClient} from '@supabase/ssr';
import {cookies} from 'next/headers';
export const configured=()=>Boolean(process.env.NEXT_PUBLIC_SUPABASE_URL&&process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY);
export async function supabase(){
 if(!configured())throw new Error('Supabase ist noch nicht eingerichtet.');
 const jar=await cookies();
 return createServerClient(process.env.NEXT_PUBLIC_SUPABASE_URL!,process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY!,{cookieOptions:{httpOnly:true,sameSite:'lax',secure:process.env.NODE_ENV==='production'},cookies:{getAll:()=>jar.getAll(),setAll:entries=>{try{entries.forEach(({name,value,options})=>jar.set(name,value,options));}catch{/* Server components rely on proxy refresh. */}}}});
}
export async function currentUser(){if(!configured()||process.env.NEXT_PUBLIC_DEMO_MODE==='true')return null;const db=await supabase();const {data,error}=await db.auth.getUser();return error?null:data.user;}
