import 'package:dio/dio.dart';
import 'package:astro_encyclopedia/core/constants/api_constants.dart';

/// NetworkService handles all HTTP requests to our Cloudflare Worker.
/// 
/// This is the ONLY class that makes external API calls.
/// All requests go through our Worker proxy - never directly to NASA.
class NetworkService {
  late final Dio _dio;

  NetworkService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseApiUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/json',
        },
      ),
    );
  }

  Dio get dio => _dio;

  /// Generic GET request
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Fetch APOD (Astronomy Picture of the Day)
  Future<Map<String, dynamic>> fetchApod() async {
    return await get(ApiConstants.apodEndpoint);
  }

  /// Search for an object by query - returns single best match
  Future<Map<String, dynamic>> lookup(String query) async {
    return await get(ApiConstants.lookupEndpoint, queryParameters: {'q': query});
  }

  /// Search objects - wraps lookup for search functionality
  /// Returns the result as a list (single item from our Worker)
  Future<List<Map<String, dynamic>>> searchObjects(String query) async {
    try {
      final result = await lookup(query);
      // Our Worker returns single best match, wrap in list
      return [result];
    } catch (e) {
      rethrow;
    }
  }

  /// Get the proxied image URL for a given NASA URL
  String getProxiedImageUrl(String nasaUrl) {
    return '${ApiConstants.baseApiUrl}${ApiConstants.imageProxyEndpoint}?url=${Uri.encodeComponent(nasaUrl)}';
  }

  Exception _handleError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return Exception('Connection timeout. Please check your internet.');
    }
    if (e.type == DioExceptionType.connectionError) {
      return Exception('No internet connection.');
    }
    if (e.response?.statusCode == 404) {
      return Exception('Resource not found.');
    }
    return Exception(e.message ?? 'Network error occurred.');
  }
}
