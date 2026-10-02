import {configured,currentUser,supabase} from '@/lib/supabase';
import {sameOrigin,tradingEnabled,fail} from '@/lib/guards';
const headers={'Cache-Control':'private, no-store'};
async function member(){if(!configured()||!tradingEnabled()||!await currentUser())return null;return supabase()}
export async function GET(req:Request){
 const db=await member();if(!db)return fail('Bitte anmelden.',401);
 const id=new URL(req.url).searchParams.get('listing');
 if(id&&!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(id))return fail('Ungültiger Verkauf.');
 const {data,error}=await db.rpc('order_feed',{p_listing:id});
 return error?fail('Abwicklung kann gerade nicht geladen werden.',503):Response.json(data,{headers});
}
export async function POST(req:Request){
 if(!sameOrigin(req))return fail('Ungültige Anfrage.',403);
 const db=await member();if(!db)return fail('Bitte anmelden.',401);
 try{const text=await req.text();if(text.length>6000)return fail('Anfrage zu gross.',413);const body=JSON.parse(text);if(!body||typeof body!=='object'||Array.isArray(body))return fail('Ungültige Anfrage.');
 const {data,error}=await db.rpc('order_action',{p_body:body});return error?fail(error.code==='P0001'?error.message:'Bitte die Angaben prüfen.'):Response.json(data,{headers});
 }catch{return fail('Abwicklung konnte nicht gespeichert werden.');}
}
