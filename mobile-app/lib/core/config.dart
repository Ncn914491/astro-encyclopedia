class AppConfig {
  /// The dynamic Cloudflare Worker for search, image proxy, and fresh APOD
  static const String workerBaseUrl = 'https://backend-proxy.chaitanyanaidunarisetti.workers.dev';
  
  /// GitHub Pages URL for remote static data fallback (optional)
  /// Format: https://<username>.github.io/<repo-name>
  static const String staticDataUrl = 'https://ncn914491.github.io/astro-encyclopedia';
}
