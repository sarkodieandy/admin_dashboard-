# Finger Licking Admin (Static)

This admin dashboard is a **static HTML/CSS/JS** app (no Next.js, no TypeScript).

## Configure Supabase

### Netlify (recommended)

Set these environment variables in Netlify:
- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`

Netlify runs `netlify/build-env.sh` during deploy to generate `assets/env.js`.

### Local quick test

Edit `index.html` and replace:
- `__SUPABASE_URL__`
- `__SUPABASE_ANON_KEY__`

## Run locally

Use any static server (examples):

```bash
python3 -m http.server 5173
```

Then open `http://localhost:5173`.

## Deploy (Netlify)

- Publish directory: `.`
- Build command: `bash netlify/build-env.sh`
