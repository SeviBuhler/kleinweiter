import Market from './market';
import {currentUser,configured,supabase} from '@/lib/supabase';
export const dynamic='force-dynamic';
export default async function Home({searchParams}:{searchParams:Promise<{offer?:string|string[]}>}){const params=await searchParams;const offer=typeof params.offer==='string'&&/^[0-9a-f-]{36}$/i.test(params.offer)?params.offer:undefined;const user=await currentUser();let moderator=false;if(user){const db=await supabase();const {data,error}=await db.rpc('moderation_access');moderator=!error&&data===true}return <Market initialOffer={offer} moderator={moderator} preview={!configured()||process.env.NEXT_PUBLIC_DEMO_MODE==='true'} user={user?{id:user.id,name:user.user_metadata.display_name||'Mein Konto'}:null}/>;}
