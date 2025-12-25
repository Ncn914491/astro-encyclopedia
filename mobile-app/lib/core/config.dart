class AppConfig {
  /// The dynamic Cloudflare Worker for search, image proxy, and fresh APOD
  static const String workerBaseUrl = 'https://backend-proxy.chaitanyanaidunarisetti.workers.dev';
  
  /// The static Cloudflare Pages URL for curated "Tier-A" data
  /// Replace this with your actual Pages URL after deployment
  static const String staticDataUrl = 'https://astro-data.pages.dev';
}
