import {currentUser,supabase} from '@/lib/supabase';
import {sameOrigin,tradingEnabled,fail} from '@/lib/guards';
import {imageType} from '@/lib/image.mjs';
export async function POST(req:Request){
 if(!sameOrigin(req))return fail('Ungültige Anfrage.',403);
 if(!tradingEnabled())return fail('Designvorschau: Uploads sind deaktiviert.',403);
 const user=await currentUser();if(!user)return fail('Bitte anmelden.',401);
 if(Number(req.headers.get('content-length')||0)>4500000)return fail('Foto zu gross. Maximal 4 MB.',413);
 try{const form=await req.formData(),file=form.get('image');if(!(file instanceof File)||file.size>4000000||file.size===0)return fail('Bitte ein Foto bis 4 MB wählen.');const bytes=new Uint8Array(await file.arrayBuffer()),type=imageType(bytes);if(!type)return fail('Bitte JPG, PNG oder WebP hochladen.');
 const db=await supabase(),id=crypto.randomUUID();
 const {data:reservation,error:reserveError}=await db.rpc('register_upload',{p_id:id});
 if(reserveError){console.error(reserveError);return fail(reserveError.code==='P0001'?reserveError.message:'Bildspeicher nicht eingerichtet.',reserveError.code==='P0001'?400:503);}
 const path=reservation.path;
 const {error}=await db.storage.from('product-images').upload(path,bytes,{contentType:type,upsert:false});if(error)throw error;
 return Response.json({id});}catch(e){console.error(e);return fail('Upload fehlgeschlagen. Bitte erneut versuchen.',503);}
}
