import Link from 'next/link';
export default function LegalFooter(){return <div className="legal-footer"><nav aria-label="Betreiber und Datenschutz"><Link href="/betreiber" prefetch={false}>Betreiber & Kontakt</Link><Link href="/datenschutz" prefetch={false}>Datenschutz</Link></nav></div>}
