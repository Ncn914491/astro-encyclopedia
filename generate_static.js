const fs = require('fs');
const path = require('path');

// Configuration
const NASA_API_KEY = process.env.NASA_API_KEY || 'JpTSzNvJlxgum9TVYqR2O3zk03utfp2EryV92Z7x';
const NASA_IMAGE_API_URL = 'https://images-api.nasa.gov';
const PROXY_BASE_URL = process.env.PROXY_BASE_URL || 'https://backend-proxy.astro-app.workers.dev';
const OUTPUT_DIR = path.join(__dirname, 'data');

// List of objects to generate (Sample of 50)
const objects = [
    'Mercury', 'Venus', 'Earth', 'Mars', 'Jupiter', 'Saturn', 'Uranus', 'Neptune',
    'Sun', 'Moon',
    'Andromeda Galaxy', 'Triangulum Galaxy',
    'Crab Nebula', 'Eagle Nebula', 'Orion Nebula', 'Ring Nebula',
    'Pillars of Creation',
    'M1', 'M13', 'M31', 'M42', 'M45', 'M51', 'M87', 'M104',
    'Betelgeuse', 'Rigel', 'Sirius', 'Vega', 'Polaris'
    // Add more as needed to reach 50
];

async function fetchNasaData(query) {
    const searchUrl = `${NASA_IMAGE_API_URL}/search?q=${encodeURIComponent(query)}&media_type=image`;

    try {
        const response = await fetch(searchUrl);
        if (!response.ok) {
            console.error(`Error fetching ${query}: ${response.statusText}`);
            return null;
        }

        const data = await response.json();
        const items = data.collection?.items || [];

        if (items.length === 0) {
            console.warn(`No results found for ${query}`);
            return null;
        }

        return items[0]; // Best match
    } catch (error) {
        console.error(`Failed to fetch ${query}:`, error);
        return null;
    }
}

function normalizeToSchema(query, nasaItem) {
    if (!nasaItem) return null;

    const datum = nasaItem.data?.[0] || {};
    const links = nasaItem.links || [];
    const imageLink = links.find(l => l.render === 'image')?.href || '';

    // Infer type
    let type = 'other';
    const lowerTitle = (datum.title + ' ' + (datum.keywords?.join(' ') || '')).toLowerCase();

    if (lowerTitle.includes('galaxy')) type = 'galaxy';
    else if (lowerTitle.includes('star')) type = 'star';
    else if (lowerTitle.includes('planet')) type = 'planet';
    else if (lowerTitle.includes('nebula')) type = 'nebula';

    return {
        id: datum.nasa_id || query.replace(/\s+/g, '-').toLowerCase(),
        title: datum.title || query,
        description: datum.description || datum.description_508 || 'No description available',
        imageUrl: `${PROXY_BASE_URL}/image-proxy?url=${encodeURIComponent(imageLink)}`,
        type: type,
        metadata: {
            distance: 'Unknown', // NASA Image API doesn't usually provide this structured data
            constellation: 'Unknown'
        },
        source: 'NASA'
    };
}

async function main() {
    if (!fs.existsSync(OUTPUT_DIR)) {
        fs.mkdirSync(OUTPUT_DIR);
    }

    console.log(`Generating static data for ${objects.length} objects...`);

    for (const objName of objects) {
        console.log(`Processing ${objName}...`);
        const nasaItem = await fetchNasaData(objName);
        const schema = normalizeToSchema(objName, nasaItem);

        if (schema) {
            const filename = path.join(OUTPUT_DIR, `${objName.replace(/\s+/g, '_')}.json`);
            fs.writeFileSync(filename, JSON.stringify(schema, null, 2));
            console.log(`Saved ${filename}`);
        }

        // Polite delay
        await new Promise(resolve => setTimeout(resolve, 500));
    }

    console.log('Done.');
}

main();
