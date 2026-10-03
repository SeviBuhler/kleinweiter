import Link from 'next/link';
export default function InfoShell({title,children}:{title:string;children:React.ReactNode}){
 return <div className="info-page"><header><Link className="brand" href="/">klein<span>weiter</span></Link><Link className="plain" href="/">Zum Marktplatz</Link></header><main><span className="eyebrow">GUT ZU WISSEN</span><h1>{title}</h1>{children}</main></div>;
}
