import {configured,currentUser,supabase} from '@/lib/supabase';
import {sameOrigin,tradingEnabled,fail} from '@/lib/guards';
const headers={'Cache-Control':'private, no-store'};
async function support(){if(!configured()||!tradingEnabled()||!await currentUser())return null;const db=await supabase();const {data,error}=await db.rpc('order_support_access');return !error&&data===true?db:null}
export async function GET(){const db=await support();if(!db)return fail('Kein Zugang zu Verkaufsproblemen.',403);const {data,error}=await db.rpc('order_issue_feed');return error?fail('Verkaufsprobleme können gerade nicht geladen werden.',503):Response.json(data,{headers})}
export async function POST(req:Request){
 if(!sameOrigin(req))return fail('Ungültige Anfrage.',403);const db=await support();if(!db)return fail('Kein Zugang zu Verkaufsproblemen.',403);
 try{const text=await req.text();if(text.length>6000)return fail('Anfrage zu gross.',413);const body=JSON.parse(text);if(!body||typeof body!=='object'||Array.isArray(body))return fail('Ungültige Anfrage.');const {data,error}=await db.rpc('order_issue_review',{p_body:body});return error?fail(error.code==='P0001'?error.message:'Bitte die Angaben prüfen.'):Response.json(data,{headers})}catch{return fail('Prüfung konnte nicht gespeichert werden.');}
}
