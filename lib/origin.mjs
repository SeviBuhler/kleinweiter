export function appOrigin(){
 const value=process.env.NEXT_PUBLIC_SITE_URL||(process.env.VERCEL_PROJECT_PRODUCTION_URL?'https://'+process.env.VERCEL_PROJECT_PRODUCTION_URL:'http://localhost:3000');
 const url=new URL(value);
 if(!['http:','https:'].includes(url.protocol)||url.username||url.password)throw Error('Ungültige App-Adresse.');
 if(url.protocol==='http:'&&!['localhost','127.0.0.1'].includes(url.hostname))throw Error('Die veröffentlichte App muss HTTPS verwenden.');
 return url.origin;
}
