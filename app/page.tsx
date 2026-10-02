import Market from './market';
import {currentUser,configured,supabase} from '@/lib/supabase';
export const dynamic='force-dynamic';
export default async function Home(){const user=await currentUser();let moderator=false;if(user){const db=await supabase();const {data,error}=await db.rpc('moderation_access');moderator=!error&&data===true}return <Market moderator={moderator} preview={!configured()||process.env.NEXT_PUBLIC_DEMO_MODE==='true'} user={user?{id:user.id,name:user.user_metadata.display_name||'Mein Konto'}:null}/>;}
