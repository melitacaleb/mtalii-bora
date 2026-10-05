# Mtalii Bora — Next.js + Supabase
Verified tour guides and safari drivers in Kenya: search, availability, booking management. (PHP prototype lives in `legacy-php/`.)

## 1. Supabase (one time)
1. Create a project at supabase.com.
2. SQL Editor: paste and run `supabase/schema.sql` (tables, security rules, Kenya destinations).
3. Authentication > URL Configuration: Site URL `http://localhost:3000`, add redirect URL `http://localhost:3000/auth/callback`.
4. For quick local testing, Authentication > Providers > Email: turn off "Confirm email" (otherwise users must click the email link).
5. Google sign-in: Authentication > Providers > Google. Create an OAuth client in Google Cloud (Web application) with redirect URI `https://YOUR-REF.supabase.co/auth/v1/callback`, then paste the client ID and secret into Supabase.
6. Project Settings > API: copy the Project URL and the anon public key.

## 2. Run
    cp .env.local.example .env.local      # paste the URL and anon key
    npm install
    npm run dev                           # http://localhost:3000

## 3. First admin
Register an account, then in the SQL Editor:
`update profiles set role = 'admin' where id = (select id from auth.users where email = 'YOUR_EMAIL');`

Do not commit `.env.local`. Never put the Supabase service_role key in this app.
