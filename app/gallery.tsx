'use client';
import {useState} from 'react';
export default function Gallery({images,title}:{images:string[];title:string}){
 const [index,setIndex]=useState(0);const active=Math.min(index,images.length-1);
 return <div className="gallery"><img className="detail-image" src={'/api/image/'+images[active]} alt={`${title} · Foto ${active+1}`}/>{images.length>1&&<><div className="gallery-controls"><button type="button" className="secondary" aria-label="Vorheriges Foto" onClick={()=>setIndex((active+images.length-1)%images.length)}>←</button><span aria-live="polite">Foto {active+1} von {images.length}</span><button type="button" className="secondary" aria-label="Nächstes Foto" onClick={()=>setIndex((active+1)%images.length)}>→</button></div><div className="gallery-thumbnails" aria-label="Produktbilder">{images.map((id,i)=><button key={id} type="button" className={active===i?'selected':''} aria-label={`Foto ${i+1} anzeigen`} aria-pressed={active===i} onClick={()=>setIndex(i)}><img src={'/api/image/'+id} alt={`${title} · Foto ${i+1}`}/></button>)}</div></>}</div>;
}
