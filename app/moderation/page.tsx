import {redirect,notFound} from 'next/navigation';
import {currentUser,supabase} from '@/lib/supabase';
import Moderation from './panel';
export const dynamic='force-dynamic';
export default async function Page(){
 if(!await currentUser())redirect('/login');
 const db=await supabase();const {data:allowed,error}=await db.rpc('moderation_access');
 if(error||allowed!==true)notFound();
 return <Moderation/>;
}
