import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:astro_encyclopedia/core/constants/api_constants.dart';
import 'package:astro_encyclopedia/features/home/domain/entities/space_object.dart';
import 'package:astro_encyclopedia/services/network_service.dart';

/// Exception thrown when data is not found in any source
class DataNotFoundException implements Exception {
  final String id;
  final String message;

  DataNotFoundException(this.id, [this.message = 'Data not found']);

  @override
  String toString() => 'DataNotFoundException: $message (id: $id)';
}

/// DataRepository implements the offline-first pattern:
/// 1. Load from local (Assets/Hive) IMMEDIATELY
/// 2. Fetch from remote silently in background
/// 3. Update local cache if remote has newer data
class DataRepository {
  final NetworkService _networkService;
  final Dio _staticDio;
  late Box<String> _cacheBox;
  bool _isInitialized = false;

  static const String _cacheBoxName = 'astro_cache';
  static const String _contentIndexKey = 'content_index';

  DataRepository({NetworkService? networkService})
      : _networkService = networkService ?? NetworkService(),
        _staticDio = Dio(BaseOptions(
          baseUrl: ApiConstants.staticDataUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ));

  /// Initialize Hive cache
  Future<void> init() async {
    if (_isInitialized) return;
    _cacheBox = await Hive.openBox<String>(_cacheBoxName);
    _isInitialized = true;
  }

  /// Get object by ID with offline-first strategy
  /// Returns data immediately from local, then updates in background
  Future<Map<String, dynamic>> getObject(
    String id, {
    Function(Map<String, dynamic>)? onUpdate,
  }) async {
    await init();

    // 1. Try loading from bundled assets first (fastest)
    Map<String, dynamic>? localData = await _loadFromAssets(id);

    // 2. If not in assets, try Hive cache
    localData ??= _loadFromCache(id);

    // 3. If we have local data, return it immediately
    if (localData != null) {
      // Fire background fetch to check for updates
      _fetchAndUpdateInBackground(id, onUpdate);
      return localData;
    }

    // 4. No local data - must fetch from network
    return await _fetchFromNetwork(id);
  }

  /// Load from bundled assets (tier_a JSON files)
  Future<Map<String, dynamic>?> _loadFromAssets(String id) async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/tier_a/$id.json');
      return jsonDecode(jsonString);
    } catch (e) {
      // Asset not found, that's okay
      return null;
    }
  }

  /// Load from Hive cache
  Map<String, dynamic>? _loadFromCache(String id) {
    final cached = _cacheBox.get(id);
    if (cached != null) {
      return jsonDecode(cached);
    }
    return null;
  }

  /// Fetch from network and update cache
  Future<Map<String, dynamic>> _fetchFromNetwork(String id) async {
    // Try static data first (GitHub Pages)
    try {
      final response = await _staticDio.get('${ApiConstants.tierAPath}/$id.json');
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        await _saveToCache(id, data);
        return data;
      }
    } catch (e) {
      // Static data not found, fall through to dynamic
    }

    // Fall back to dynamic Worker lookup
    final data = await _networkService.lookup(id);
    await _saveToCache(id, data);
    return data;
  }

  /// Background fetch to check for updates
  Future<void> _fetchAndUpdateInBackground(
    String id,
    Function(Map<String, dynamic>)? onUpdate,
  ) async {
    try {
      // Check static data for updates
      final response = await _staticDio.get('${ApiConstants.tierAPath}/$id.json');
      if (response.statusCode == 200) {
        final remoteData = response.data as Map<String, dynamic>;
        final cachedData = _loadFromCache(id);

        // Simple comparison - in production, use version/timestamp
        if (cachedData == null || jsonEncode(cachedData) != jsonEncode(remoteData)) {
          await _saveToCache(id, remoteData);
          onUpdate?.call(remoteData);
        }
      }
    } catch (e) {
      // Background fetch failed silently - that's okay
    }
  }

  /// Save to Hive cache
  Future<void> _saveToCache(String id, Map<String, dynamic> data) async {
    await _cacheBox.put(id, jsonEncode(data));
  }

  /// Get content index (list of all available objects)
  Future<List<Map<String, dynamic>>> getContentIndex() async {
    await init();

    // Try cache first
    final cached = _cacheBox.get(_contentIndexKey);
    if (cached != null) {
      _refreshContentIndexInBackground();
      return List<Map<String, dynamic>>.from(jsonDecode(cached));
    }

    // Fetch from remote
    return await _fetchContentIndex();
  }

  Future<List<Map<String, dynamic>>> _fetchContentIndex() async {
    try {
      final response = await _staticDio.get(ApiConstants.contentIndexPath);
      if (response.statusCode == 200) {
        final data = List<Map<String, dynamic>>.from(response.data);
        await _cacheBox.put(_contentIndexKey, jsonEncode(data));
        return data;
      }
    } catch (e) {
      // Return empty if fetch fails
    }
    return [];
  }

  Future<void> _refreshContentIndexInBackground() async {
    try {
      await _fetchContentIndex();
    } catch (e) {
      // Silent fail
    }
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    await init();
    await _cacheBox.clear();
  }

  /// Get full object details with offline-first strategy
  /// 
  /// Loading Priority:
  /// 1. Local asset bundle (assets/data/objects/{id}.json or tier_a/{id}.json)
  /// 2. Hive cache
  /// 3. Network fetch from GitHub Pages
  /// 
  /// Throws [DataNotFoundException] if object is not found in any source.
  Future<SpaceObject> getObjectDetails(String id) async {
    await init();

    Map<String, dynamic>? data;

    // 1. Try loading from bundled assets first (fastest)
    // Check both 'objects' and 'tier_a' folders for compatibility
    data = await _loadObjectFromAssets(id);
    if (data != null) {
      // Still try to fetch latest in background
      _fetchObjectInBackground(id);
      return SpaceObject.fromJson(data);
    }

    // 2. Try Hive cache
    data = _loadFromCache('object_$id');
    if (data != null) {
      // Try to refresh in background
      _fetchObjectInBackground(id);
      return SpaceObject.fromJson(data);
    }

    // 3. If online, fetch from network
    try {
      data = await _fetchObjectFromNetwork(id);
      if (data != null) {
        return SpaceObject.fromJson(data);
      }
    } catch (e) {
      // Network fetch failed
    }

    // Object not found anywhere
    throw DataNotFoundException(id, 'Object "$id" not found in local storage, cache, or network');
  }

  /// Load object from bundled assets
  Future<Map<String, dynamic>?> _loadObjectFromAssets(String id) async {
    // Try 'objects' folder first (new structure)
    try {
      final jsonString = await rootBundle.loadString('assets/data/objects/$id.json');
      return jsonDecode(jsonString);
    } catch (_) {
      // Not found in objects folder
    }

    // Fall back to 'tier_a' folder (current structure)
    try {
      final jsonString = await rootBundle.loadString('assets/data/tier_a/$id.json');
      return jsonDecode(jsonString);
    } catch (_) {
      // Not found
    }

    return null;
  }

  /// Fetch object from network and cache it
  Future<Map<String, dynamic>?> _fetchObjectFromNetwork(String id) async {
    // Try GitHub Pages static data
    try {
      final response = await _staticDio.get('/objects/$id.json');
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        await _saveToCache('object_$id', data);
        return data;
      }
    } catch (_) {
      // Not in /objects path
    }

    // Try tier_a path
    try {
      final response = await _staticDio.get('${ApiConstants.tierAPath}/$id.json');
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        await _saveToCache('object_$id', data);
        return data;
      }
    } catch (_) {
      // Not in tier_a path
    }

    // Fall back to dynamic Worker lookup
    try {
      final data = await _networkService.lookup(id);
      await _saveToCache('object_$id', data);
      return data;
    } catch (e) {
      return null;
    }
  }

  /// Background fetch to update cache silently
  Future<void> _fetchObjectInBackground(String id) async {
    try {
      await _fetchObjectFromNetwork(id);
    } catch (_) {
      // Silent fail - background update is optional
    }
  }
}
