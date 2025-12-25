import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:astro_encyclopedia/features/home/domain/entities/space_object.dart';

/// Local Data Service - Loads bundled assets instantly
/// 
/// This service loads data from the APK bundle (assets/)
/// No network calls, no async waiting - instant data.
class LocalDataService {
  static List<SpaceObject>? _cachedObjects;

  /// Load featured objects from bundled content_index.json
  /// Returns cached data on subsequent calls
  static Future<List<SpaceObject>> getFeaturedObjects() async {
    if (_cachedObjects != null) {
      return _cachedObjects!;
    }

    try {
      final jsonString = await rootBundle.loadString('assets/data/content_index.json');
      final List<dynamic> jsonList = jsonDecode(jsonString);
      
      _cachedObjects = jsonList
          .map((json) => SpaceObject.fromIndexJson(json as Map<String, dynamic>))
          .toList();
      
      return _cachedObjects!;
    } catch (e) {
      // If asset loading fails, return empty list
      return [];
    }
  }

  /// Get a specific object by ID from bundled tier_a data
  static Future<SpaceObject?> getObject(String id) async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/tier_a/$id.json');
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return SpaceObject.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// Get objects filtered by type
  static Future<List<SpaceObject>> getObjectsByType(String type) async {
    final all = await getFeaturedObjects();
    return all.where((obj) => obj.type == type).toList();
  }

  /// Clear cache (useful for testing)
  static void clearCache() {
    _cachedObjects = null;
  }
}
