import {configured,currentUser,supabase} from '@/lib/supabase';
import {sameOrigin,tradingEnabled,fail} from '@/lib/guards';

async function member(){
 if(!configured()||!tradingEnabled()||!await currentUser())return null;
 return supabase();
}
const headers={'Cache-Control':'private, no-store'};
export async function GET(){
 const db=await member();if(!db)return fail('Bitte anmelden.',401);
 const {data,error}=await db.rpc('notification_feed');
 return error?fail('Benachrichtigungen können gerade nicht geladen werden.',503):Response.json(data,{headers});
}
export async function POST(req:Request){
 if(!sameOrigin(req))return fail('Ungültige Anfrage.',403);
 const db=await member();if(!db)return fail('Bitte anmelden.',401);
 try{
  const text=await req.text();if(text.length>500)return fail('Anfrage zu gross.',413);
  const body=JSON.parse(text);
  if(!body||typeof body!=='object'||Array.isArray(body)||
   (body.action!=='read'&&body.action!=='read_all')||
   (body.action==='read'&&(typeof body.id!=='string'||!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(body.id))))return fail('Ungültige Anfrage.');
  const {data,error}=await db.rpc('notification_read',{p_id:body.action==='read_all'?null:body.id});
  return error?fail(error.code==='P0001'?error.message:'Nicht gespeichert.'):Response.json(data,{headers});
 }catch{return fail('Benachrichtigung konnte nicht aktualisiert werden.');}
}
