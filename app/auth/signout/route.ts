import {supabase} from '@/lib/supabase';
import {sameOrigin,fail} from '@/lib/guards';
import {NextResponse} from 'next/server';
export async function POST(req:Request){if(!sameOrigin(req))return fail('Ungültige Anfrage.',403);const db=await supabase();await db.auth.signOut();return NextResponse.redirect(new URL('/',req.url),303);}
