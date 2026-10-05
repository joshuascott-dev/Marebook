# Turning on real accounts (Supabase)

1. Create a Supabase project (name: marebook, region: US Central/East). The owner should be a Marebook company email.
2. In the project's **SQL Editor**, run `schema.sql`. It's safe to run again.
3. **Authentication → URL Configuration**: set Site URL to `https://marebook.netlify.app` (later `https://marebook.com`) and add it to Redirect URLs.
4. **Project Settings → API**: copy the Project URL and the `anon` public key into `config.js`:
   ```js
   window.MAREBOOK_CONFIG = { supabaseUrl: "https://xxxx.supabase.co", supabaseAnonKey: "eyJ…" };
   ```
5. Push. Netlify redeploys, and the site switches from on-device preview to real accounts.
6. Make yourself a site admin so you can see sign-ups:
   ```sql
   insert into site_admins select id from auth.users where email = 'you@example.com';
   ```

## How it's put together
| Table | What it holds |
|---|---|
| `barns` | Each customer's barn, with a 6-character team join code |
| `barn_members` | Who belongs to which barn, with a role. Owner, Barn manager, Staff, Vet and Trainer can edit; Viewer is read-only |
| `docs` | Every record (mares, foals, stallions, tasks, costs, settings), one row each, synced live to every phone |
| `signups` | Public sign-ups and Contact us messages, readable by site admins only |
| storage `media` | Photos, videos and pedigrees, in one folder per barn |

Stallion listings are readable by everyone, so Stallion Search works across barns and on the public site. Set `unlisted: true` on a stallion to hide him.

Row-level security was tested against Postgres 16:
- Outsiders can't read or write another barn.
- Viewers can't edit.
- Only owners change roles.
- Only admins read sign-ups.
- Uploads are limited to your own barn's folder.
