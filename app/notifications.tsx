'use client';
import {useCallback,useEffect,useRef,useState} from 'react';
import {Bell,Check} from 'lucide-react';
import {Dialog,DialogContent,DialogTitle,DialogDescription} from '@/components/ui/dialog';
type Message={id:string;listing:string;kind:string;title:string;body:string;created:string;read_at:string|null};
const labels:Record<string,string>={outbid:'Überboten',purchased:'Sofortkauf bestätigt',won:'Auktion gewonnen',sold:'Artikel verkauft',blocked:'Auktion gesperrt',expired:'Ohne Gebot beendet'};
export default function Notifications(){
 const [open,setOpen]=useState(false),[items,setItems]=useState<Message[]>([]),[unread,setUnread]=useState(0),[error,setError]=useState(''),[loaded,setLoaded]=useState(false),[busy,setBusy]=useState(false);
 const sequence=useRef(0);
 const load=useCallback(async()=>{
  const attempt=++sequence.current;
  try{const r=await fetch('/api/notifications',{cache:'no-store'}),d=await r.json();if(!r.ok)throw Error(d.error);if(attempt===sequence.current){setItems(d.items);setUnread(d.unread);setError('');setLoaded(true)}}
  catch(e){if(attempt===sequence.current)setError(e instanceof Error?e.message:'Laden fehlgeschlagen.')}
 },[]);
 useEffect(()=>{
  void load();const refresh=()=>{if(document.visibilityState==='visible')void load()};
  const timer=setInterval(refresh,30000);document.addEventListener('visibilitychange',refresh);window.addEventListener('focus',refresh);window.addEventListener('market-updated',refresh);
  return()=>{++sequence.current;clearInterval(timer);document.removeEventListener('visibilitychange',refresh);window.removeEventListener('focus',refresh);window.removeEventListener('market-updated',refresh)};
 },[load]);
 async function read(id?:string){
  setBusy(true);++sequence.current;
  try{const r=await fetch('/api/notifications',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({action:id?'read':'read_all',id})}),d=await r.json();if(!r.ok)throw Error(d.error);await load()}
  catch(e){setError(e instanceof Error?e.message:'Nicht gespeichert.')}
  finally{setBusy(false)}
 }
 return <><button className="plain notification-button" aria-label={error?'Benachrichtigungen – Laden fehlgeschlagen':`Benachrichtigungen${unread?`, ${unread} ungelesen`:''}`} onClick={()=>{setOpen(true);void load()}}><Bell size={20}/>{unread>0&&<span className="notification-count">{unread>99?'99+':unread}</span>}{error&&<span className="notification-error">!</span>}</button>
 <Dialog open={open} onOpenChange={setOpen}><DialogContent className="market-dialog notification-dialog"><DialogTitle>Deine Benachrichtigungen</DialogTitle><DialogDescription>Neuigkeiten zu deinen Angeboten und Geboten. Nachrichten werden bei geöffnetem Marktplatz etwa alle 30 Sekunden aktualisiert.</DialogDescription>
 <div className="actions"><button className="plain" onClick={()=>void load()} disabled={busy}>Aktualisieren</button><button className="secondary" onClick={()=>void read()} disabled={busy||unread===0}>Alle als gelesen markieren</button></div>
 {error&&<p className="error" role="alert">{error}</p>}{!loaded&&!error&&<p role="status">Nachrichten werden geladen …</p>}
 {loaded&&<p className="hint" role="status">{unread} ungelesen · bis zu 100 Nachrichten, ungelesene zuerst</p>}
 <div className="notification-list">{items.map(n=><article key={n.id} className={n.read_at?'':'unread'}><div className="notification-meta"><strong>{labels[n.kind]||'Neuigkeit'}</strong><time dateTime={n.created}>{new Date(n.created).toLocaleString('de-CH',{timeZone:'Europe/Zurich',dateStyle:'short',timeStyle:'short'})}</time></div><h3>{n.title}</h3><p>{n.body}</p><div className="actions"><a className="secondary" href={'/?offer='+n.listing}>Angebot im Konto ansehen</a>{!n.read_at?<button className="plain" disabled={busy} onClick={()=>void read(n.id)}>Als gelesen markieren</button>:<span className="read-label"><Check size={14}/>Gelesen</span>}</div></article>)}</div>
 {loaded&&!items.length&&<div className="empty"><Bell/><h2>Hier landen deine Neuigkeiten.</h2><p>Du erhältst Nachrichten bei Übergeboten, Verkäufen, Auktionsabschlüssen und Sperren.</p></div>}
 </DialogContent></Dialog></>;
}
