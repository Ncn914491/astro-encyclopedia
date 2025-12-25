# Deployment Guide

## Part 1: Deploy Backend Worker (Universal Proxy)

The Worker handles dynamic search, APOD, and image proxying.

1.  Open your terminal and navigate to the worker directory:
    ```bash
    cd backend-proxy
    ```

2.  Install dependencies (if you haven't yet):
    ```bash
    npm install
    ```

3.  Login to Cloudflare (a browser window will open):
    ```bash
    npx wrangler login
    ```

4.  Deploy the worker:
    ```bash
    npx wrangler deploy
    ```

5.  **IMPORTANT**: The terminal will output your Worker URL (e.g., `https://backend-proxy.your-subdomain.workers.dev`). **Copy this URL.**

---

## Part 2: Deploy Static Data (Cloudflare Pages)

The Pages project hosts your curated "Tier-A" JSON files.

1.  Log in to the [Cloudflare Dashboard](https://dash.cloudflare.com).
2.  Go to **Workers & Pages** > **Create application** > **Pages** > **Connect to Git**.
3.  Select the `astro-encyclopedia` repository you just created.
4.  Configure the build settings exactly like this:
    *   **Project Name**: `astro-encyclopedia-data` (or similar)
    *   **Production Branch**: `main`
    *   **Framework Preset**: `None`
    *   **Build command**: `bash build.sh`
    *   **Build output directory**: `dist`
5.  Click **Save and Deploy**.
6.  Once finished, Cloudflare will give you a domain (e.g., `https://astro-encyclopedia-data.pages.dev`). **Copy this URL.**

---

## Part 3: Connect Mobile App

Now that you have both URLs, update your Flutter app configuration.

1.  Open `mobile-app/lib/core/config.dart`.
2.  Paste your new URLs:

```dart
class AppConfig {
  static const String workerBaseUrl = 'https://backend-proxy.<YOUR_SUBDOMAIN>.workers.dev';
  static const String staticDataUrl = 'https://<YOUR_PAGES_PROJECT>.pages.dev';
}
```

3.  That's it! Your app now pulls Tier-A data from the Edge (Pages) and searches via the Proxy (Worker).
