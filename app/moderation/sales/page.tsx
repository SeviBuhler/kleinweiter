import {redirect,notFound} from 'next/navigation';
import {currentUser,supabase} from '@/lib/supabase';
import Orders from '@/app/orders';
export const dynamic='force-dynamic';
export default async function Page(){
 if(!await currentUser())redirect('/login');
 const db=await supabase();const {data,error}=await db.rpc('order_support_access');if(error||data!==true)notFound();
 return <div className="market moderation"><header><a href="/" className="brand">klein<span>weiter</span></a><a className="secondary" href="/moderation">Zu Inseratmeldungen</a></header><main><span className="eyebrow">BETREIBERBEREICH</span><h1>Verkaufsprobleme prüfen.</h1><p>Probleme dokumentieren und Prüfungen begründet abschliessen. Kauf, Zahlungsbestätigungen und Übergabestatus bleiben erhalten. Kein automatischer Käuferschutz oder Rückzahlungsdienst.</p><Orders support/></main></div>;
}
