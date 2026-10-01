import {configured,currentUser,supabase} from '@/lib/supabase';
import {sameOrigin,tradingEnabled,fail} from '@/lib/guards';
export async function GET(req:Request){
 const url=new URL(req.url),mine=url.searchParams.get('mine')==='1';
 if(!mine&&(!url.searchParams.has('age')||! /^[0-4]$/.test(url.searchParams.get('age')!)))return fail('Bitte eine Altersgruppe wählen.');
 if(!configured()||!tradingEnabled())return mine?fail('Bitte zuerst Supabase einrichten.',503):Response.json({items:[],contacts:[]});
 try{if(mine&&!await currentUser())return fail('Bitte anmelden.',401);const db=await supabase();const {data,error}=await db.rpc('market_feed',{p_age:mine?null:Number(url.searchParams.get('age')),p_mine:mine});if(error){console.error(error);return fail('Angebote können gerade nicht geladen werden.',503);}return Response.json(data,{headers:{'Cache-Control':'private, no-store'}});}catch{return fail('Angebote können gerade nicht geladen werden.',503);}
}
export async function POST(req:Request){
 if(!sameOrigin(req))return fail('Ungültige Anfrage.',403);
 if(!tradingEnabled()||!configured())return fail('Dies ist eine Designvorschau. Verkäufe sind noch nicht freigeschaltet.',503);
 if(!await currentUser())return fail('Bitte anmelden.',401);
 if(Number(req.headers.get('content-length')||0)>15000)return fail('Anfrage zu gross.',413);
 try{const body=await req.json();if(!body||typeof body!=='object'||Array.isArray(body))return fail('Ungültige Anfrage.');const db=await supabase();const {data,error}=await db.rpc('market_action',{p_body:body});if(error){console.error(error);return fail(error.code==='P0001'?error.message:'Bitte alle Pflichtfelder vollständig und korrekt ausfüllen.',400);}return Response.json(data);}catch{return fail('Speichern fehlgeschlagen.');}
}
