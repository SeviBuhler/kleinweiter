import {configured,currentUser,supabase} from '@/lib/supabase';
import {sameOrigin,tradingEnabled,fail} from '@/lib/guards';

async function moderator(){
 if(!configured()||!tradingEnabled())return null;
 if(!await currentUser())return null;
 const db=await supabase();const {data,error}=await db.rpc('moderation_access');
 return !error&&data===true?db:null;
}
export async function GET(){
 const db=await moderator();if(!db)return fail('Kein Moderationszugang.',403);
 const {data,error}=await db.rpc('moderation_feed');
 if(error)return fail('Meldungen können gerade nicht geladen werden.',503);
 return Response.json(data,{headers:{'Cache-Control':'private, no-store'}});
}
export async function POST(req:Request){
 if(!sameOrigin(req))return fail('Ungültige Anfrage.',403);
 const db=await moderator();if(!db)return fail('Kein Moderationszugang.',403);
 try{
  const text=await req.text();if(text.length>8000)return fail('Anfrage zu gross.',413);
  const body=JSON.parse(text);if(!body||typeof body!=='object'||Array.isArray(body))return fail('Ungültige Anfrage.');
  const {data,error}=await db.rpc('moderation_action',{p_body:body});
  if(error)return fail(error.code==='P0001'?error.message:'Bitte die Angaben prüfen.',400);
  return Response.json(data,{headers:{'Cache-Control':'private, no-store'}});
 }catch{return fail('Entscheidung konnte nicht gespeichert werden.');}
}
