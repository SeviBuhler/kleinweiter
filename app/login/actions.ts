'use server';
import {supabase,configured} from '@/lib/supabase';
import {redirect} from 'next/navigation';
export async function sendCode(_state:{message:string;sent:boolean},form:FormData){
 if(!configured()||process.env.NEXT_PUBLIC_DEMO_MODE==='true')return {message:'Die Anmeldung ist in dieser Vorschau noch nicht freigeschaltet.',sent:false};
 const email=String(form.get('email')||'').trim();
 if(! /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)||email.length>254)return {message:'Bitte eine gültige E-Mail eingeben.',sent:false};
 const db=await supabase();const {error}=await db.auth.signInWithOtp({email,options:{shouldCreateUser:true}});
 if(error){console.error(error.code);return {message:'Der Code konnte nicht gesendet werden. Bitte später erneut versuchen.',sent:false};}
 return {message:'Prüfe deinen Posteingang und gib den Anmeldecode ein.',sent:true};
}
export async function verifyCode(_state:{message:string},form:FormData){
 if(!configured()||process.env.NEXT_PUBLIC_DEMO_MODE==='true')return {message:'Anmeldung noch nicht freigeschaltet.'};
 const email=String(form.get('email')||'').trim(),token=String(form.get('token')||'').trim();
 if(! /^\d{6,10}$/.test(token))return {message:'Bitte den Code aus deiner E-Mail eingeben.'};
 const db=await supabase();const {error}=await db.auth.verifyOtp({email,token,type:'email'});
 if(error)return {message:'Der Code ist ungültig oder abgelaufen. Fordere einen neuen Code an.'};
 redirect('/');
}
