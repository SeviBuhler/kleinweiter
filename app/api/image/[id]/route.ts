import {configured,supabase} from '@/lib/supabase';
export async function GET(_req:Request,{params}:{params:Promise<{id:string}>}){
 const {id}=await params;if(!configured()||! /^[a-f0-9-]{36}$/i.test(id))return new Response('Nicht gefunden',{status:404});
 try{const db=await supabase();const {data:path,error}=await db.rpc('image_path',{p_id:id});if(error||!path)return new Response('Nicht gefunden',{status:404});const {data,error:downloadError}=await db.storage.from('product-images').download(path);if(downloadError||!data)return new Response('Nicht gefunden',{status:404});return new Response(data,{headers:{'Content-Type':data.type,'X-Content-Type-Options':'nosniff','Cache-Control':'private, max-age=60'}});}catch{return new Response('Bild nicht verfügbar',{status:503});}
}
