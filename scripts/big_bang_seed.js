#!/usr/bin/env node
/**
 * 🚀 BIG BANG SEED - Offline Encyclopedia Data Populator
 * 
 * This script fetches real data from NASA's Image and Video Library API
 * and saves it locally for offline use in the Astro Encyclopedia app.
 * 
 * Features:
 * - Fetches metadata from NASA API
 * - Downloads medium-quality images for offline use
 * - Generates individual JSON files for each object
 * - Builds a unified index for the home screen
 * 
 * Usage: node scripts/big_bang_seed.js
 */

const fs = require('fs');
const path = require('path');
const https = require('https');
const http = require('http');

// ============================================================================
// 🌟 CONFIGURATION - "Must Have" Objects for the Encyclopedia
// ============================================================================

const MUST_HAVE_OBJECTS = {
    // 🪐 Planets (Our Solar System)
    planets: [
        { id: 'mercury', query: 'Mercury planet', type: 'planet' },
        { id: 'venus', query: 'Venus planet', type: 'planet' },
        { id: 'earth', query: 'Earth from space', type: 'planet' },
        { id: 'mars', query: 'Mars planet rover', type: 'planet' },
        { id: 'jupiter', query: 'Jupiter planet', type: 'planet' },
        { id: 'saturn', query: 'Saturn rings', type: 'planet' },
        { id: 'uranus', query: 'Uranus planet', type: 'planet' },
        { id: 'neptune', query: 'Neptune planet', type: 'planet' },
        { id: 'pluto', query: 'Pluto New Horizons', type: 'planet' },
    ],

    // ⭐ Stars
    stars: [
        { id: 'sun', query: 'Sun solar', type: 'star' },
        { id: 'sirius', query: 'Sirius star', type: 'star' },
        { id: 'betelgeuse', query: 'Betelgeuse star', type: 'star' },
        { id: 'rigel', query: 'Rigel star Orion', type: 'star' },
        { id: 'vega', query: 'Vega star', type: 'star' },
        { id: 'alpha-centauri', query: 'Alpha Centauri', type: 'star' },
    ],

    // 🌌 Deep Space Objects
    deepSpace: [
        { id: 'andromeda', query: 'Andromeda Galaxy', type: 'galaxy' },
        { id: 'milky-way', query: 'Milky Way galaxy', type: 'galaxy' },
        { id: 'orion-nebula', query: 'Orion Nebula', type: 'nebula' },
        { id: 'crab-nebula', query: 'Crab Nebula', type: 'nebula' },
        { id: 'pillars-of-creation', query: 'Pillars of Creation', type: 'nebula' },
        { id: 'black-hole-m87', query: 'M87 black hole', type: 'other' },
    ],
};

// ============================================================================
// 📁 PATHS CONFIGURATION
// ============================================================================

const SCRIPT_DIR = __dirname;
const PROJECT_ROOT = path.join(SCRIPT_DIR, '..');
const DATA_DIR = path.join(PROJECT_ROOT, 'data');
const OBJECTS_DIR = path.join(DATA_DIR, 'objects');
const INDEX_PATH = path.join(DATA_DIR, 'index.json');

// Mobile app assets for offline use
const MOBILE_ASSETS_DIR = path.join(PROJECT_ROOT, 'mobile-app', 'assets');
const IMAGES_DIR = path.join(MOBILE_ASSETS_DIR, 'images');

// NASA API
const NASA_IMAGE_API_URL = 'https://images-api.nasa.gov';

// Backend proxy for CORS (used in imageUrl field)
const BACKEND_PROXY_URL = 'https://backend-proxy.chaitanyanaidunarisetti.workers.dev';

// ============================================================================
// 🛠️ UTILITY FUNCTIONS
// ============================================================================

/**
 * Ensure a directory exists, create if not
 */
function ensureDir(dirPath) {
    if (!fs.existsSync(dirPath)) {
        fs.mkdirSync(dirPath, { recursive: true });
        console.log(`📁 Created directory: ${dirPath}`);
    }
}

/**
 * Sleep for a given number of milliseconds (rate limiting)
 */
function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

/**
 * Fetch data from NASA Image and Video Library API
 */
async function fetchNasaData(query) {
    const url = `${NASA_IMAGE_API_URL}/search?q=${encodeURIComponent(query)}&media_type=image`;

    try {
        const response = await fetch(url);

        if (!response.ok) {
            throw new Error(`NASA API returned ${response.status}: ${response.statusText}`);
        }

        const data = await response.json();
        const items = data.collection?.items || [];

        if (items.length === 0) {
            console.warn(`  ⚠️  No results found for: "${query}"`);
            return null;
        }

        // Return the best match (first result)
        return items[0];
    } catch (error) {
        console.error(`  ❌ Failed to fetch data for "${query}":`, error.message);
        return null;
    }
}

/**
 * Download an image from a URL to a local file
 */
async function downloadImage(imageUrl, destPath) {
    return new Promise((resolve, reject) => {
        const protocol = imageUrl.startsWith('https') ? https : http;

        const file = fs.createWriteStream(destPath);

        protocol.get(imageUrl, (response) => {
            // Handle redirects
            if (response.statusCode === 301 || response.statusCode === 302) {
                const redirectUrl = response.headers.location;
                file.close();
                fs.unlinkSync(destPath);
                return downloadImage(redirectUrl, destPath).then(resolve).catch(reject);
            }

            if (response.statusCode !== 200) {
                file.close();
                fs.unlinkSync(destPath);
                reject(new Error(`HTTP ${response.statusCode}`));
                return;
            }

            response.pipe(file);

            file.on('finish', () => {
                file.close(() => resolve(destPath));
            });

            file.on('error', (err) => {
                fs.unlinkSync(destPath);
                reject(err);
            });
        }).on('error', (err) => {
            file.close();
            if (fs.existsSync(destPath)) fs.unlinkSync(destPath);
            reject(err);
        });
    });
}

/**
 * Extract medium-sized image URL from NASA API response
 * NASA images follow a pattern: the preview links often have ~thumb, ~small, ~medium variants
 */
function extractMediumImageUrl(nasaItem) {
    const links = nasaItem.links || [];

    // First, try to find an explicit preview/image link
    let imageLink = links.find(l => l.render === 'image')?.href;

    if (imageLink) {
        // NASA images have patterns like: image~thumb.jpg, image~small.jpg, image~medium.jpg
        // The default preview is often ~thumb, we want ~medium
        imageLink = imageLink.replace('~thumb.jpg', '~medium.jpg');
        imageLink = imageLink.replace('~small.jpg', '~medium.jpg');
    }

    return imageLink || null;
}

/**
 * Normalize NASA API data to our app's schema
 */
function normalizeToAppSchema(id, query, type, nasaItem) {
    const datum = nasaItem.data?.[0] || {};
    const imageUrl = extractMediumImageUrl(nasaItem);

    // Truncate description to 500 characters
    let description = datum.description || datum.description_508 || 'No description available.';
    if (description.length > 500) {
        description = description.substring(0, 497) + '...';
    }

    // Build proxied image URL for the app
    const proxiedImageUrl = imageUrl
        ? `${BACKEND_PROXY_URL}/image-proxy?url=${encodeURIComponent(imageUrl)}`
        : null;

    return {
        id,
        title: datum.title || query,
        description,
        imageUrl: proxiedImageUrl,
        localImagePath: `assets/images/${id}.jpg`, // For offline fallback
        type,
        metadata: {
            distance: 'Unknown',
            constellation: datum.keywords?.find(k => /constellation/i.test(k)) || 'Unknown',
            nasaId: datum.nasa_id || null,
            dateCreated: datum.date_created || null,
            center: datum.center || 'NASA',
        },
        source: 'NASA',
        keywords: datum.keywords || [],
    };
}

/**
 * Build a summary entry for the index
 */
function buildIndexEntry(objectData) {
    return {
        id: objectData.id,
        title: objectData.title,
        type: objectData.type,
        thumbnailPath: objectData.localImagePath,
        path: `objects/${objectData.id}.json`,
    };
}

// ============================================================================
// 🚀 MAIN EXECUTION
// ============================================================================

async function main() {
    console.log('\n' + '='.repeat(60));
    console.log('🌟 BIG BANG SEED - Astro Encyclopedia Data Populator');
    console.log('='.repeat(60) + '\n');

    // Ensure all directories exist
    console.log('📂 Setting up directories...');
    ensureDir(DATA_DIR);
    ensureDir(OBJECTS_DIR);
    ensureDir(IMAGES_DIR);

    // Flatten all objects into a single list
    const allObjects = [
        ...MUST_HAVE_OBJECTS.planets,
        ...MUST_HAVE_OBJECTS.stars,
        ...MUST_HAVE_OBJECTS.deepSpace,
    ];

    console.log(`\n🔍 Processing ${allObjects.length} objects...\n`);

    const index = [];
    const stats = { success: 0, failed: 0, imagesDownloaded: 0 };

    for (let i = 0; i < allObjects.length; i++) {
        const { id, query, type } = allObjects[i];
        console.log(`[${i + 1}/${allObjects.length}] 🔄 Processing: ${id}`);

        // Fetch data from NASA
        const nasaItem = await fetchNasaData(query);

        if (!nasaItem) {
            console.log(`  ⏭️  Skipping ${id} (no data found)\n`);
            stats.failed++;
            continue;
        }

        // Normalize to our schema
        const objectData = normalizeToAppSchema(id, query, type, nasaItem);
        console.log(`  ✅ Title: "${objectData.title}"`);

        // Download image locally for offline use
        const imageUrl = extractMediumImageUrl(nasaItem);
        if (imageUrl) {
            const imagePath = path.join(IMAGES_DIR, `${id}.jpg`);
            try {
                await downloadImage(imageUrl, imagePath);
                console.log(`  📸 Image saved: assets/images/${id}.jpg`);
                stats.imagesDownloaded++;
            } catch (err) {
                console.warn(`  ⚠️  Image download failed: ${err.message}`);
            }
        } else {
            console.warn(`  ⚠️  No image URL found`);
        }

        // Save individual object JSON
        const objectPath = path.join(OBJECTS_DIR, `${id}.json`);
        fs.writeFileSync(objectPath, JSON.stringify(objectData, null, 2));
        console.log(`  💾 Saved: data/objects/${id}.json\n`);

        // Add to index
        index.push(buildIndexEntry(objectData));
        stats.success++;

        // Rate limiting: small delay between requests
        await sleep(300);
    }

    // Save the unified index
    fs.writeFileSync(INDEX_PATH, JSON.stringify(index, null, 2));
    console.log(`\n📋 Index saved: data/index.json (${index.length} entries)`);

    // Print summary
    console.log('\n' + '='.repeat(60));
    console.log('📊 SUMMARY');
    console.log('='.repeat(60));
    console.log(`  ✅ Successfully processed: ${stats.success}`);
    console.log(`  ❌ Failed/Skipped:         ${stats.failed}`);
    console.log(`  📸 Images downloaded:      ${stats.imagesDownloaded}`);
    console.log(`  📋 Index entries:          ${index.length}`);
    console.log('='.repeat(60));
    console.log('\n🎉 Big Bang Seed complete! Your encyclopedia is ready.\n');
}

// Run the script
main().catch((err) => {
    console.error('\n❌ Fatal error:', err);
    process.exit(1);
});
