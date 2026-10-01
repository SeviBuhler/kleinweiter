import {currentUser,supabase} from '@/lib/supabase';
import {sameOrigin,tradingEnabled,fail} from '@/lib/guards';
import {imageType} from '@/lib/image.mjs';
export async function POST(req:Request){
 if(!sameOrigin(req))return fail('Ungültige Anfrage.',403);
 if(!tradingEnabled())return fail('Designvorschau: Uploads sind deaktiviert.',403);
 const user=await currentUser();if(!user)return fail('Bitte anmelden.',401);
 if(Number(req.headers.get('content-length')||0)>4500000)return fail('Foto zu gross. Maximal 4 MB.',413);
 try{const form=await req.formData(),file=form.get('image');if(!(file instanceof File)||file.size>4000000||file.size===0)return fail('Bitte ein Foto bis 4 MB wählen.');const bytes=new Uint8Array(await file.arrayBuffer()),type=imageType(bytes);if(!type)return fail('Bitte JPG, PNG oder WebP hochladen.');
 const db=await supabase(),id=crypto.randomUUID(),path=user.id+'/'+id;
 const {error:limitError,count}=await db.from('uploads').select('id',{count:'exact',head:true}).gte('created',new Date(Date.now()-86400000).toISOString());
 if(limitError)return fail('Bildspeicher nicht eingerichtet.',503);if((count||0)>=40)return fail('Maximal 40 Fotos pro Tag.',429);
 const {error}=await db.storage.from('product-images').upload(path,bytes,{contentType:type,upsert:false});if(error)throw error;
 const {error:record}=await db.from('uploads').insert({id,owner:user.id,path});if(record)throw record;
 return Response.json({id});}catch(e){console.error(e);return fail('Upload fehlgeschlagen. Bitte erneut versuchen.',503);}
}
