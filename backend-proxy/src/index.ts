
export interface Env {
    NASA_API_KEY: string;
    NASA_IMAGE_API_URL: string;
}

interface AstroObject {
    id: string;
    title: string;
    description: string;
    imageUrl: string;
    type: 'galaxy' | 'star' | 'planet' | 'nebula' | 'other';
    metadata: {
        distance: string;
        constellation: string;
    };
    source: 'NASA';
}

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
                return await handleApod(request, env, ctx, url.origin, corsHeaders);
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

async function handleApod(request: Request, env: Env, ctx: ExecutionContext, origin: string, corsHeaders: any): Promise<Response> {
    const cacheUrl = new URL(request.url);
    const cacheKey = new Request(cacheUrl.toString(), request);
    const cache = caches.default;

    // Try to find in cache first
    let response = await cache.match(cacheKey);
    if (response) {
        return response;
    }

    try {
        const nasaRes = await fetch(`https://api.nasa.gov/planetary/apod?api_key=${env.NASA_API_KEY}`);
        if (!nasaRes.ok) throw new Error(`NASA API error: ${nasaRes.statusText}`);

        const data: any = await nasaRes.json();

        const astroObject: AstroObject = {
            id: data.date,
            title: data.title,
            description: data.explanation,
            imageUrl: `${origin}/image-proxy?url=${encodeURIComponent(data.hdurl || data.url)}`,
            type: 'other', // APOD can be anything, default to other or infer? 'type' field in schema restricted to specific values, but let's stick to contract
            metadata: {
                distance: 'Unknown',
                constellation: 'Unknown'
            },
            source: 'NASA'
        };

        // If media_type is video, we might need special handling, but contract says imageUrl. 
        // For now, if video, we might use thumbnail if available or fallback. 
        // NASA APOD 'url' is sometimes youtube.
        if (data.media_type === 'video') {
            // Basic fallback for video, though schema expects imageUrl. 
            // In a real app we'd get a thumbnail.
            astroObject.imageUrl = `${origin}/image-proxy?url=${encodeURIComponent(data.thumbnail_url || data.url)}`;
        }

        response = new Response(JSON.stringify(astroObject), {
            headers: {
                ...corsHeaders,
                'Content-Type': 'application/json',
                'Cache-Control': 'public, max-age=43200' // 12 hours
            }
        });

        ctx.waitUntil(cache.put(cacheKey, response.clone()));
        return response;

    } catch (e) {
        // Error handling: serve stale if possible? 
        // With Cache API match() at top, we already checked cache. 
        // If we are here, cache miss AND fetch failed.
        // If we had a Stale-While-Revalidate pattern or KV backup, we could do more.
        // Given constraints, we return error if both fail.
        throw e;
    }
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
