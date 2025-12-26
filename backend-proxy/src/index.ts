
export interface Env {
    NASA_API_KEY: string;
    NASA_IMAGE_API_URL: string;
    ASTRO_CACHE: KVNamespace; // KV binding for caching
}

// APOD response from NASA API
interface NasaApodResponse {
    date: string;
    title: string;
    explanation: string;
    url: string;
    hdurl?: string;
    media_type: 'image' | 'video';
    thumbnail_url?: string;
    copyright?: string;
}

// Our normalized app schema
interface AstroObject {
    id: string;
    title: string;
    description: string;
    imageUrl: string;
    type: 'galaxy' | 'star' | 'planet' | 'nebula' | 'other';
    metadata: {
        distance: string;
        constellation: string;
        copyright?: string;
        date?: string;
        mediaType?: string;
    };
    source: 'NASA';
}

// Fallback image when APOD is a video without thumbnail
const FALLBACK_APOD_IMAGE = 'https://apod.nasa.gov/apod/image/2312/SpaceTree_Gualandi_2000.jpg';

// KV cache key for today's APOD
const APOD_CACHE_KEY = 'apod_today';

// TTL for APOD cache: 24 hours in seconds
const APOD_CACHE_TTL = 86400;

export default {
    async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
        const url = new URL(request.url);

        // CORS headers
        const corsHeaders = {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET,HEAD,OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type',
        };

        if (request.method === 'OPTIONS') {
            return new Response(null, { headers: corsHeaders });
        }

        try {
            if (url.pathname === '/apod') {
                return await handleApod(env, url.origin, corsHeaders);
            } else if (url.pathname === '/lookup') {
                return await handleLookup(request, env, ctx, url.origin, corsHeaders);
            } else if (url.pathname === '/image-proxy') {
                return await handleImageProxy(request, env, ctx, corsHeaders);
            }

            return new Response('Not Found', { status: 404, headers: corsHeaders });
        } catch (error: any) {
            return new Response(JSON.stringify({ error: error.message }), {
                status: 500,
                headers: { ...corsHeaders, 'Content-Type': 'application/json' }
            });
        }
    },
};

/**
 * Handle GET /apod - Returns Astronomy Picture of the Day
 * Uses KV storage for caching with 24-hour TTL
 * 
 * Cache hit: ~10ms response time
 * Cache miss: Fetches from NASA API, normalizes, stores in KV
 */
async function handleApod(env: Env, origin: string, corsHeaders: Record<string, string>): Promise<Response> {
    // Step 1: Check KV cache first (fast path ~10ms)
    const cachedData = await env.ASTRO_CACHE.get(APOD_CACHE_KEY);

    if (cachedData) {
        // Cache hit! Return immediately
        return new Response(cachedData, {
            headers: {
                ...corsHeaders,
                'Content-Type': 'application/json',
                'X-Cache': 'HIT',
                'Cache-Control': 'public, max-age=3600' // Browser can cache for 1 hour
            }
        });
    }

    // Step 2: Cache miss - Fetch from NASA API
    const nasaRes = await fetch(`https://api.nasa.gov/planetary/apod?api_key=${env.NASA_API_KEY}`);

    if (!nasaRes.ok) {
        throw new Error(`NASA API error: ${nasaRes.status} ${nasaRes.statusText}`);
    }

    const data: NasaApodResponse = await nasaRes.json();

    // Step 3: Normalize to our app's schema
    const astroObject = normalizeApodToAstroObject(data, origin);

    // Step 4: Serialize and store in KV with 24-hour TTL
    const jsonString = JSON.stringify(astroObject);

    // Non-blocking write to KV (don't await, let it complete in background)
    await env.ASTRO_CACHE.put(APOD_CACHE_KEY, jsonString, {
        expirationTtl: APOD_CACHE_TTL
    });

    // Step 5: Return the response
    return new Response(jsonString, {
        headers: {
            ...corsHeaders,
            'Content-Type': 'application/json',
            'X-Cache': 'MISS',
            'Cache-Control': 'public, max-age=3600'
        }
    });
}

/**
 * Normalize NASA APOD response to our app's AstroObject schema
 * Handles video case by using thumbnail or fallback image
 */
function normalizeApodToAstroObject(data: NasaApodResponse, origin: string): AstroObject {
    let imageUrl: string;

    if (data.media_type === 'video') {
        // Video case: Use thumbnail if available, otherwise use fallback
        if (data.thumbnail_url) {
            imageUrl = `${origin}/image-proxy?url=${encodeURIComponent(data.thumbnail_url)}`;
        } else {
            // No thumbnail available - use fallback image
            imageUrl = `${origin}/image-proxy?url=${encodeURIComponent(FALLBACK_APOD_IMAGE)}`;
        }
    } else {
        // Image case: Prefer HD URL, fallback to regular URL
        const sourceUrl = data.hdurl || data.url;
        imageUrl = `${origin}/image-proxy?url=${encodeURIComponent(sourceUrl)}`;
    }

    return {
        id: data.date,
        title: data.title,
        description: data.explanation,
        imageUrl,
        type: 'other', // APOD can be various types, default to 'other'
        metadata: {
            distance: 'Unknown',
            constellation: 'Unknown',
            copyright: data.copyright || 'Public Domain',
            date: data.date,
            mediaType: data.media_type
        },
        source: 'NASA'
    };
}

async function handleLookup(request: Request, env: Env, ctx: ExecutionContext, origin: string, corsHeaders: any): Promise<Response> {
    const url = new URL(request.url);
    const query = url.searchParams.get('q');
    if (!query) return new Response('Missing query', { status: 400, headers: corsHeaders });

    // Cache key specific to query
    const cacheKey = new Request(url.toString(), request);
    const cache = caches.default;
    let response = await cache.match(cacheKey);
    if (response) return response;

    try {
        const searchUrl = `${env.NASA_IMAGE_API_URL}/search?q=${encodeURIComponent(query)}&media_type=image`;
        const nasaRes = await fetch(searchUrl);
        if (!nasaRes.ok) throw new Error('NASA Image API error');

        const data: any = await nasaRes.json();
        const items = data.collection?.items || [];

        // Find best match - taking the first one for simplicity as per "find the best matching image"
        const item = items[0];
        if (!item) return new Response(JSON.stringify({ error: 'No results found' }), { status: 404, headers: corsHeaders });

        const link = item.links?.find((l: any) => l.render === 'image')?.href || '';
        const datum = item.data?.[0] || {};

        const astroObject: AstroObject = {
            id: datum.nasa_id || query,
            title: datum.title || query,
            description: datum.description || datum.description_508 || 'No description available',
            imageUrl: `${origin}/image-proxy?url=${encodeURIComponent(link)}`,
            type: 'other', // Infer type if possible, e.g. from keywords
            metadata: {
                distance: 'Unknown',
                constellation: 'Unknown'
            },
            source: 'NASA'
        };

        // Simple heuristic for type
        const lowerTitle = (datum.title + ' ' + (datum.keywords?.join(' ') || '')).toLowerCase();
        if (lowerTitle.includes('galaxy')) astroObject.type = 'galaxy';
        else if (lowerTitle.includes('star')) astroObject.type = 'star';
        else if (lowerTitle.includes('planet')) astroObject.type = 'planet';
        else if (lowerTitle.includes('nebula')) astroObject.type = 'nebula';


        response = new Response(JSON.stringify(astroObject), {
            headers: {
                ...corsHeaders,
                'Content-Type': 'application/json',
                'Cache-Control': 'public, max-age=86400' // 24 hours
            }
        });

        ctx.waitUntil(cache.put(cacheKey, response.clone()));
        return response;
    } catch (e) {
        throw e;
    }
}

async function handleImageProxy(request: Request, env: Env, ctx: ExecutionContext, corsHeaders: any): Promise<Response> {
    const url = new URL(request.url);
    const targetUrl = url.searchParams.get('url');

    if (!targetUrl) return new Response('Missing url param', { status: 400, headers: corsHeaders });

    // Cache based on the target URL
    const cacheKey = new Request(url.toString(), request);
    const cache = caches.default;
    let response = await cache.match(cacheKey);
    if (response) return response;

    try {
        const imageRes = await fetch(targetUrl, {
            headers: {
                'User-Agent': 'AstroEncyclopedia/1.0' // Good practice
            }
        });

        if (!imageRes.ok) return new Response('Failed to fetch image', { status: 502, headers: corsHeaders });

        // Stream body back
        response = new Response(imageRes.body, {
            headers: {
                ...corsHeaders,
                'Content-Type': imageRes.headers.get('Content-Type') || 'image/jpeg',
                'Cache-Control': 'public, max-age=31536000, immutable' // 1 year immutable
            }
        });

        ctx.waitUntil(cache.put(cacheKey, response.clone()));
        return response;
    } catch (e) {
        return new Response('Error fetching image', { status: 500, headers: corsHeaders });
    }
}
