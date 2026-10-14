# Bonkd: free web setup

## 1. Waffle Board database (Supabase, free, no card)
1. Sign up at https://supabase.com and create a new project (Free plan).
2. Authentication > Sign In / Providers: turn on **Allow anonymous sign-ins**.
3. SQL Editor > New query: paste all of `supabase-setup.sql` and click Run. (Safe to run again after updates.)
4. Project Settings > API: copy the **Project URL** and the **anon public** key.
5. Put the Project URL and anon key into `SUPABASE_URL` and `SUPABASE_KEY` near the Waffle Board section of `index.html`.
   (The anon key is meant to be public; the database rules only let each player change their own row.)

Free Supabase projects pause after about a week with no visitors. Open the Supabase dashboard and click Restore if that happens.

## 2. Put the game online (Netlify, free, no card)
1. Go to https://app.netlify.com/drop and sign up with email or GitHub.
2. Drag this whole `bonkd-web` folder onto the page.
3. Site configuration > Change site name: try `bonkd` (gives https://bonkd.netlify.app).
4. To update later: Deploys > drag the folder in again.

## 3. Play it like an app
- iPhone: open the link in Safari > Share > **Add to Home Screen**.
- Android: open in Chrome > menu > **Install app**.
