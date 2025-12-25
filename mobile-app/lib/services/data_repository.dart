import 'package:dio/dio.dart';
import 'package:astro_encyclopedia/core/config.dart';

class DataRepository {
  final Dio _dio;
  
  DataRepository() : _dio = Dio();

  /// Fetch object data trying static source first (Tier-A), then dynamic source
  Future<Map<String, dynamic>> getObject(String id) async {
    // 1. Try fetching from Static Data (Cloudflare Pages)
    // This is fast, free, and works for our curated "Tier-A" objects
    try {
      final response = await _dio.get('${AppConfig.staticDataUrl}/tier_a/$id.json');
      if (response.statusCode == 200) {
        print('Loaded $id from Static Edge');
        return response.data;
      }
    } catch (e) {
      // Ignore 404s or network errors from static source, fall through to dynamic
      print('Static data miss for $id, falling back to dynamic worker');
    }

    // 2. Fallback to Dynamic Worker (Cloudflare Worker -> NASA)
    // This handles search queries or objects we haven't manually curated
    try {
      final response = await _dio.get('${AppConfig.workerBaseUrl}/lookup', queryParameters: {'q': id});
      return response.data;
    } catch (e) {
      throw Exception('Failed to load object data: $e');
    }
  }
}
