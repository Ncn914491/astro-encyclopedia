import 'dart:convert';
import 'package:flutter/painting.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// StorageManager - Manages local cache and storage
/// 
/// Features:
/// - Auto-deletes old cache entries when box exceeds limit
/// - Provides cache statistics
/// - Clears image cache
/// - Manages app settings in Hive
class StorageManager {
  static const String _settingsBoxName = 'app_settings';
  static const String _cacheBoxName = 'astro_cache';
  static const int _maxCacheItems = 500;
  
  // Settings keys
  static const String darkModeKey = 'dark_mode';
  static const String lastCacheCleanKey = 'last_cache_clean';
  
  static Box<dynamic>? _settingsBox;
  static Box<String>? _cacheBox;
  static bool _isInitialized = false;

  /// Initialize storage manager
  static Future<void> init() async {
    if (_isInitialized) return;
    
    _settingsBox = await Hive.openBox(_settingsBoxName);
    _cacheBox = await Hive.openBox<String>(_cacheBoxName);
    _isInitialized = true;
    
    // Run cleanup on init
    await _cleanupIfNeeded();
  }

  /// Ensure initialized before operations
  static Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await init();
    }
  }

  // ============ Settings Management ============

  /// Get dark mode setting (defaults to true for space theme)
  static Future<bool> getDarkMode() async {
    await _ensureInitialized();
    return _settingsBox?.get(darkModeKey, defaultValue: true) ?? true;
  }

  /// Set dark mode setting
  static Future<void> setDarkMode(bool value) async {
    await _ensureInitialized();
    await _settingsBox?.put(darkModeKey, value);
  }

  /// Get any setting
  static Future<T?> getSetting<T>(String key, {T? defaultValue}) async {
    await _ensureInitialized();
    return _settingsBox?.get(key, defaultValue: defaultValue);
  }

  /// Set any setting
  static Future<void> setSetting<T>(String key, T value) async {
    await _ensureInitialized();
    await _settingsBox?.put(key, value);
  }

  // ============ Cache Management ============

  /// Save data to cache
  static Future<void> cacheData(String key, Map<String, dynamic> data) async {
    await _ensureInitialized();
    await _cacheBox?.put(key, jsonEncode(data));
    
    // Trigger cleanup if we're over the limit
    await _cleanupIfNeeded();
  }

  /// Get data from cache
  static Future<Map<String, dynamic>?> getCachedData(String key) async {
    await _ensureInitialized();
    final cached = _cacheBox?.get(key);
    if (cached != null) {
      return jsonDecode(cached) as Map<String, dynamic>;
    }
    return null;
  }

  /// Check if key exists in cache
  static Future<bool> hasCachedData(String key) async {
    await _ensureInitialized();
    return _cacheBox?.containsKey(key) ?? false;
  }

  /// Get cache item count
  static Future<int> getCacheItemCount() async {
    await _ensureInitialized();
    return _cacheBox?.length ?? 0;
  }

  /// Get approximate cache size in bytes
  static Future<int> getCacheSizeBytes() async {
    await _ensureInitialized();
    int totalSize = 0;
    _cacheBox?.values.forEach((value) {
      totalSize += value.length * 2; // Approximate UTF-16 size
    });
    return totalSize;
  }

  /// Get formatted cache size string
  static Future<String> getFormattedCacheSize() async {
    final bytes = await getCacheSizeBytes();
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Cleanup old cache entries if over limit
  static Future<void> _cleanupIfNeeded() async {
    final count = _cacheBox?.length ?? 0;
    if (count <= _maxCacheItems) return;

    // Delete oldest entries (first in = oldest)
    final keysToDelete = <String>[];
    final deleteCount = count - _maxCacheItems + 50; // Delete extra 50 for buffer
    
    int deleted = 0;
    for (final key in _cacheBox?.keys ?? []) {
      if (deleted >= deleteCount) break;
      keysToDelete.add(key as String);
      deleted++;
    }

    for (final key in keysToDelete) {
      await _cacheBox?.delete(key);
    }

    await _settingsBox?.put(lastCacheCleanKey, DateTime.now().toIso8601String());
  }

  /// Clear all cached data (keeps settings)
  static Future<void> clearDataCache() async {
    await _ensureInitialized();
    await _cacheBox?.clear();
  }

  /// Clear image cache from CachedNetworkImage
  static Future<void> clearImageCache() async {
    await DefaultCacheManager().emptyCache();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  /// Clear all caches (data + images)
  static Future<void> clearAllCaches() async {
    await clearDataCache();
    await clearImageCache();
  }

  /// Get last cache cleanup time
  static Future<DateTime?> getLastCacheClean() async {
    await _ensureInitialized();
    final lastClean = _settingsBox?.get(lastCacheCleanKey);
    if (lastClean != null) {
      return DateTime.tryParse(lastClean);
    }
    return null;
  }

  // ============ Library Version ============

  /// Get offline library version from cached index
  static Future<String> getOfflineLibraryVersion() async {
    await _ensureInitialized();
    
    // Try to read version from cached content index
    final cached = _cacheBox?.get('content_index');
    if (cached != null) {
      try {
        final data = jsonDecode(cached);
        if (data is Map && data.containsKey('data_version')) {
          return data['data_version'].toString();
        }
        if (data is List) {
          return 'v1.0 (${data.length} objects)';
        }
      } catch (_) {}
    }
    
    // Fallback to counting cached objects
    final count = await getCacheItemCount();
    return 'Local Cache: $count items';
  }

  // ============ Statistics ============

  /// Get storage statistics
  static Future<Map<String, dynamic>> getStorageStats() async {
    await _ensureInitialized();
    
    return {
      'cacheItemCount': await getCacheItemCount(),
      'cacheSizeBytes': await getCacheSizeBytes(),
      'formattedSize': await getFormattedCacheSize(),
      'maxItems': _maxCacheItems,
      'lastClean': await getLastCacheClean(),
      'libraryVersion': await getOfflineLibraryVersion(),
    };
  }
}
