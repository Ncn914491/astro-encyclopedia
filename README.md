# Astro Encyclopedia

## Project Structure
*   **`backend-proxy/`**: Cloudflare Worker code (Dynamic API & Image Proxy).
*   **`data/`**: Static "Tier-A" JSON data (hosted on Pages).
*   **`mobile-app/`**: Flutter application.
*   **`docs/`**: Documentation & Architecture rules.

## Deployment Instructions

### 1. Backend Worker (Dynamic)
*   **Project Name**: `backend-proxy` (or `astro-worker`)
*   **Type**: Cloudflare Worker
*   **Settings**:
    *   **Root Directory**: `backend-proxy` (Crucial!)
    *   **Build System Version**: 2
*   **Environment Variables**:
    *   `NASA_API_KEY`: [Your Key]
    *   `NASA_IMAGE_API_URL`: `https://images-api.nasa.gov`

### 2. Static Data (Pages)
*   **Project Name**: `astro-data`
*   **Type**: Cloudflare Pages
*   **Settings**:
    *   **Build Command**: `bash build.sh`
    *   **Build Output Directory**: `dist`
    *   **Root Directory**: `/` (Leave empty)

## Local Development
1.  **Seed Data**: `node scripts/seed_database.js`
2.  **Run Worker**: `cd backend-proxy && npm start`
3.  **Run App**: `cd mobile-app && flutter run`
