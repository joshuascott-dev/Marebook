# Marebook

Mare, foal and stallion records with a breeding calendar that runs itself.

- `index.html` — the whole app (single file).
- `netlify.toml` — Netlify publishes this folder as-is; no build step.

Outside the Claude artifact host, the app runs in demo mode: it loads a sample barn and changes are not saved. The Supabase backend in the build plan adds logins and saving.
