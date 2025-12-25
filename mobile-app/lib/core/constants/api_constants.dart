/// API Constants for Astro Encyclopedia
/// 
/// The app NEVER talks to NASA directly.
/// All data flows through our controlled infrastructure.
class ApiConstants {
  ApiConstants._();

  /// Cloudflare Worker - Dynamic API
  /// Handles: /apod, /lookup, /image-proxy
  static const String baseApiUrl = 'https://backend-proxy.chaitanyanaidunarisetti.workers.dev';

  /// GitHub Pages - Static Tier-A Data
  /// Serves pre-generated JSON for popular objects
  static const String staticDataUrl = 'https://ncn914491.github.io/astro-encyclopedia';

  /// API Endpoints (relative to baseApiUrl)
  static const String apodEndpoint = '/apod';
  static const String lookupEndpoint = '/lookup';
  static const String imageProxyEndpoint = '/image-proxy';

  /// Static Data Paths (relative to staticDataUrl)
  static const String tierAPath = '/tier_a';
  static const String contentIndexPath = '/content_index.json';
}
