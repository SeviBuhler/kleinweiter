export function sameOrigin(req:Request){return req.headers.get('origin')===new URL(req.url).origin;}
export function tradingEnabled(){return process.env.NEXT_PUBLIC_DEMO_MODE!=='true';}
export const fail=(error:string,status=400)=>Response.json({error},{status});
