# Deployment Guide (Simplified)

## Overview

We use a **single Cloudflare Worker** for all dynamic NASA data. Static Tier-A content is **bundled inside the APK** for instant offline access.

---

## Step 1: Deploy the Cloudflare Worker

### Option A: CLI (Recommended)

```bash
cd backend-proxy
npm install
npx wrangler login   # Opens browser, login once
npx wrangler deploy
```

Done! Your worker is live at:
`https://backend-proxy.<your-subdomain>.workers.dev`

### Option B: Cloudflare Dashboard (Git Integration)

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com) > **Workers & Pages**.
2. Click **Create** > **Import a repository**.
3. Select `astro-encyclopedia`.
4. **IMPORTANT**: Set **Root Directory** to `backend-proxy`.
5. Deploy.

---

## Step 2: (Optional) Enable GitHub Pages for Remote Data

If you want a remote backup of your static data (not required since it's in the APK):

1. Go to your GitHub repo **Settings** > **Pages**.
2. Under **Build and deployment**, set **Source** to **GitHub Actions**.
3. Push to `master`. The workflow will deploy `data/` to Pages.
4. Access at: `https://<username>.github.io/astro-encyclopedia/tier_a/sun.json`

---

## Step 3: Build the Flutter App

The static data is already bundled in `assets/offline/`. Just build:

```bash
cd mobile-app
flutter build apk --release
```

---

## Architecture Flow

```
User opens app
    │
    ▼
┌─────────────────────────────┐
│  SmartImage checks:         │
│  1. assets/offline/sun.jpg  │  ◄── IN APK (instant)
│     Found? Use it.          │
│                             │
│  2. CachedNetworkImage      │  ◄── From Worker, cached forever
│     GET /image-proxy?url=...│
└─────────────────────────────┘
    │
    ▼
┌─────────────────────────────┐
│  DataRepository checks:     │
│  1. Local JSON (optional)   │
│  2. Worker /lookup?q=...    │  ◄── Cloudflare Worker → NASA
└─────────────────────────────┘
```

**Result**: Blazing fast, offline-capable, no NASA API keys in the app.
