import type { Metadata } from 'next';
import './globals.css';
export const metadata:Metadata={title:'KleinWeiter · Secondhand für Kinder',description:'Kinderkleidung, Spielsachen und mehr ersteigern und weitergeben. Der Schweizer Marktplatz für Lieblingsstücke.',icons:{icon:'/favicon.svg'}};
export default function RootLayout({children}:{children:React.ReactNode}){return <html lang="de-CH"><body>{children}</body></html>}
