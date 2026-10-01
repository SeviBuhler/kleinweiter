# Google-Anmeldung für kleinweiter

Der Google-Login ist implementiert und verwendet den bestehenden PKCE-Callback mit httpOnly-Sitzungscookies. Produktionsbuild und bestehende Tests bestehen. Noch nicht aktiviert: Supabase benötigt eine Google-OAuth-Client-ID und ein Client-Secret. Die Google-Konsole wartet auf die Anmeldung des Nutzers.

## Google Auth Platform

1. Projekt kleinweiter auswählen oder anlegen. Branding: kleinweiter; Support-/Kontaktadresse selbst wählen.
2. Audience: External. Für den ersten Test den Status Testing und die eigenen Google-Testkonten verwenden. Die beiden bisherigen E-Mail-Testadressen funktionieren nur, wenn sie mit Google-Konten verbunden sind.
3. Scopes: ausschliesslich openid, userinfo.email und userinfo.profile.
4. OAuth-Client vom Typ Web application anlegen. Origin: https://kleinweiter.vercel.app. Authorized redirect URI: https://bhogyeublnutiyfjwmou.supabase.co/auth/v1/callback.
5. Client-ID und Client-Secret direkt in Supabase unter Authentication → Sign In / Providers → Google eintragen. Das Secret niemals in Git, Chat oder Vercel speichern. Sicherheitsoptionen Skip nonce checks und Allow users without an email deaktiviert lassen.
6. Nach bestätigter Provider-Einrichtung in Vercel NEXT_PUBLIC_GOOGLE_AUTH_ENABLED=true setzen und den neuen Commit deployen. Der Schalter bleibt bis dahin false; die vorhandene Anmeldung bleibt verfügbar.
7. Zwei echte Konten testen: Login, Profil, eigenes Foto, Inserat, Gebot, Sofortkauf, Kontaktfreigabe und Logout. Erst danach den Test als vollständig abgeschlossen melden.

Offizielle Anleitung: https://supabase.com/docs/guides/auth/social-login/auth-google
