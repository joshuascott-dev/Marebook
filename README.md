# Marebook

Mare, foal and stallion records with a breeding calendar that runs itself.

- `index.html` — the whole app (single file).
- `netlify.toml` — Netlify publishes this folder as-is; no build step.

Outside the Claude artifact host, the app runs in demo mode: it loads a sample barn and changes are not saved. The Supabase backend in the build plan adds logins and saving.


## Platform ownership (from the Marebook Platform & Ownership Checklist)
| Piece | Target | Today |
|---|---|---|
| Business | Texas LLC: Hixson Group Enterprises LLC, d/b/a Marebook | In place |
| Source code | GitHub, owned by Marebook | This repo |
| Domain | Cloudflare Registrar (marebook.com) | Not yet pointed |
| Website hosting | Vercel or Netlify | Netlify (marebook.netlify.app) |
| App | Flutter: iOS, Android, web | Web preview (this file) |
| Backend, auth, database | Supabase (PostgreSQL) | Device storage in the preview |
| Push notifications | Firebase | Calendar file and in-app alerts |
| Payments | Stripe (subscriptions, stallion shipments) | Plan picker and payment-portal placeholder |
| Store accounts | Apple Developer ($99/yr), Google Play ($25 once) | Not yet |

See CHANGELOG.md for what changed in each version.
