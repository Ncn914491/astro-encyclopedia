const fs = require('fs');
const path = require('path');
const https = require('https');

// --- CONFIGURATION ---
const TIER_A_ITEMS = [
    'Sun', 'Moon', 'Mercury', 'Venus', 'Earth', 'Mars', 'Jupiter', 'Saturn', 'Uranus', 'Neptune',
    'Pluto', 'Andromeda Galaxy', 'Orion Nebula', 'Black Hole', 'International Space Station',
    'Hubble Space Telescope', 'Milky Way', 'Pillars of Creation', 'Crab Nebula', 'Sombrero Galaxy'
];

// Paths
const DATA_DIR = path.join(__dirname, '../data');
const TIER_A_DIR = path.join(DATA_DIR, 'tier_a');
const CONTENT_INDEX_PATH = path.join(DATA_DIR, 'content_index.json');
// Targeting the mobile app's offline asset folder specifically so they ship with the APK
const IMAGES_DIR = path.join(__dirname, '../mobile-app/assets/offline');
const NASA_IMAGE_API_URL = 'https://images-api.nasa.gov';

// --- HELPERS ---

async function fetchNasaData(query) {
    const url = `${NASA_IMAGE_API_URL}/search?q=${encodeURIComponent(query)}&media_type=image`;
    try {
        const res = await fetch(url);
        if (!res.ok) throw new Error(`API Error: ${res.statusText}`);
        const data = await res.json();
        const items = data.collection?.items || [];
        if (items.length === 0) return null;
        return items[0]; // Best match
    } catch (e) {
        console.error(`Failed to fetch metadata for ${query}`, e);
        return null;
    }
}

async function downloadImage(url, filename) {
    return new Promise((resolve, reject) => {
        const dest = path.join(IMAGES_DIR, filename);
        const file = fs.createWriteStream(dest);
        https.get(url, (response) => {
            if (response.statusCode !== 200) {
                reject(new Error(`Failed to download image: ${response.statusCode}`));
                return;
            }
            response.pipe(file);
            file.on('finish', () => {
                file.close(() => resolve(dest));
            });
        }).on('error', (err) => {
            fs.unlink(dest, () => { });
            reject(err);
        });
    });
}

function normalizeSchema(id, query, nasaItem) {
    const datum = nasaItem.data?.[0] || {};
    const links = nasaItem.links || [];
    const imageLink = links.find(l => l.render === 'image')?.href || '';

    let type = 'other';
    const lowerTitle = (datum.title + ' ' + (datum.keywords?.join(' ') || '')).toLowerCase();

    if (lowerTitle.includes('galaxy')) type = 'galaxy';
    else if (lowerTitle.includes('star')) type = 'star';
    else if (lowerTitle.includes('planet')) type = 'planet';
    else if (lowerTitle.includes('nebula')) type = 'nebula';

    return {
        id: id,
        title: datum.title || query,
        description: datum.description || datum.description_508 || 'No description available.',
        imageUrl: `https://backend-proxy.astro-encyclopedia.workers.dev/image-proxy?url=${encodeURIComponent(imageLink)}`,
        type: type,
        metadata: {
            distance: 'Unknown',
            constellation: 'Unknown'
        },
        source: 'NASA'
    };
}

// --- MAIN SCRIPT ---

async function main() {
    console.log('--- Starting Data Bootstrapping ---');

    // Ensure directories exist
    [TIER_A_DIR, IMAGES_DIR].forEach(dir => {
        if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    });

    const index = [];

    for (const query of TIER_A_ITEMS) {
        const id = query.toLowerCase().replace(/ /g, '-');
        console.log(`Processing: ${query} (${id})...`);

        const nasaItem = await fetchNasaData(query);
        if (!nasaItem) {
            console.warn(`Skipping ${query}: No data found.`);
            continue;
        }

        const schema = normalizeSchema(id, query, nasaItem);

        // 1. Download Thumbnail for Offline Bundle
        // We try to find a small thumbnail if available, or just use the main image but save it locally
        // The previous SmartImage widget expects 'assets/offline/{id}.jpg'
        const thumbnailLink = nasaItem.links?.find(l => l.rel === 'preview' || l.render === 'image')?.href;

        if (thumbnailLink) {
            try {
                await downloadImage(thumbnailLink, `${id}.jpg`);
                console.log(`  - Image downloaded to assets/offline/${id}.jpg`);
            } catch (e) {
                console.error(`  - Failed to download image for ${query}:`, e.message);
            }
        } else {
            console.warn(`  - No image link found for ${query}`);
        }

        // 2. Save JSON Tier-A Data
        fs.writeFileSync(path.join(TIER_A_DIR, `${id}.json`), JSON.stringify(schema, null, 2));

        // 3. Add to Index
        index.push({
            id: schema.id,
            title: schema.title,
            type: schema.type,
            path: `tier_a/${id}.json`
        });
    }

    // 4. Update Content Index
    fs.writeFileSync(CONTENT_INDEX_PATH, JSON.stringify(index, null, 2));
    console.log(`\nSuccess! Generated ${index.length} items.`);
    console.log(`Content Index saved to: ${CONTENT_INDEX_PATH}`);
}

main().catch(err => console.error(err));
