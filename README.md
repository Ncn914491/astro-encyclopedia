# Astro Encyclopedia

A production-grade Astronomy Encyclopedia with offline-first architecture.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Flutter Mobile App                      │
├─────────────────────────────────────────────────────────────┤
│  1. LOCAL BUNDLE (assets/offline/)  ──► Fastest, in APK     │
│  2. CLOUDFLARE WORKER               ──► Dynamic search/APOD │
└─────────────────────────────────────────────────────────────┘
```

**Key Rule**: The app NEVER talks to `api.nasa.gov`. All NASA data flows through the Cloudflare Worker.

## Project Structure

```
astro-encyclopedia/
├── backend-proxy/     # Cloudflare Worker (Dynamic API)
├── mobile-app/        # Flutter Application
├── data/              # Static JSON (bundled in APK + GitHub Pages backup)
├── scripts/           # Data generation scripts
└── docs/              # Architecture documentation
```

## Deployment

### 1. Cloudflare Worker (Required)

```bash
cd backend-proxy
npm install
npx wrangler login
npx wrangler deploy
```

**Dashboard Settings** (if using Git integration):
- **Root Directory**: `backend-proxy`

### 2. GitHub Pages (Optional Remote Fallback)

The workflow `.github/workflows/deploy_data.yml` automatically deploys the `data/` folder to GitHub Pages on push.

**Enable it**:
1. Go to your repo **Settings** > **Pages**.
2. Set **Source** to **GitHub Actions**.

Result: `https://<username>.github.io/astro-encyclopedia/tier_a/sun.json`

### 3. Flutter App

Static data is already bundled in `mobile-app/assets/offline/`. Just build normally:

```bash
cd mobile-app
flutter build apk
```

## Local Development

```bash
# Seed Tier-A data and images
node scripts/seed_database.js

# Run Worker locally
cd backend-proxy && npm start

# Run Flutter app
cd mobile-app && flutter run
```
