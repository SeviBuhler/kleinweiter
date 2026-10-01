import Market from './market';
import {currentUser,configured} from '@/lib/supabase';
export const dynamic='force-dynamic';
export default async function Home(){const user=await currentUser();return <Market preview={!configured()||process.env.NEXT_PUBLIC_DEMO_MODE==='true'} user={user?{id:user.id,name:user.user_metadata.display_name||'Mein Konto'}:null}/>;}
