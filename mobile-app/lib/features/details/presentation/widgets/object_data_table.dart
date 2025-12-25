import 'package:flutter/material.dart';

/// ObjectDataTable Widget - Displays metadata in a clean two-column layout
/// 
/// Features:
/// - Alternating row backgrounds for readability
/// - Auto-formats various data types
/// - Handles nested metadata objects
class ObjectDataTable extends StatelessWidget {
  final Map<String, dynamic> metadata;
  final String? title;

  const ObjectDataTable({
    super.key,
    required this.metadata,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    // Filter out null values and format entries
    final entries = _prepareEntries();
    
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
        ],
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: entries.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return _buildRow(
                item.key,
                item.value,
                isAlternate: index.isOdd,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  List<MapEntry<String, String>> _prepareEntries() {
    final List<MapEntry<String, String>> entries = [];
    
    metadata.forEach((key, value) {
      if (value == null || value.toString().isEmpty || value.toString() == 'null') {
        return; // Skip null/empty values
      }
      
      // Skip complex nested objects for now, unless it's metadata
      if (value is Map && key.toLowerCase() == 'metadata') {
        (value as Map<String, dynamic>).forEach((subKey, subValue) {
          if (subValue != null && subValue.toString().isNotEmpty && subValue.toString() != 'null') {
            entries.add(MapEntry(_formatKey(subKey), _formatValue(subValue)));
          }
        });
      } else if (value is! Map && value is! List) {
        // Skip internal fields and already displayed fields
        if (!_shouldSkipField(key)) {
          entries.add(MapEntry(_formatKey(key), _formatValue(value)));
        }
      }
    });
    
    return entries;
  }

  bool _shouldSkipField(String key) {
    // Skip fields that are already displayed elsewhere or are internal
    const skipFields = {
      'id', 'title', 'description', 'imageUrl', 'thumbnailPath', 
      'type', 'path', 'source', 'metadata'
    };
    return skipFields.contains(key.toLowerCase());
  }

  String _formatKey(String key) {
    // Convert camelCase or snake_case to Title Case with emoji
    final Map<String, String> keyIcons = {
      'distance': '📏',
      'mass': '⚖️',
      'radius': '📐',
      'diameter': '📐',
      'size': '📐',
      'temperature': '🌡️',
      'discovered': '🔭',
      'discoveredBy': '🔭',
      'discoveredYear': '📅',
      'age': '⏳',
      'constellation': '✨',
      'type': '🏷️',
      'magnitude': '💫',
      'orbitalPeriod': '🔄',
      'rotationPeriod': '🔄',
      'moons': '🌙',
      'gravity': '🌍',
      'atmosphere': '💨',
    };

    final icon = keyIcons[key.toLowerCase()] ?? '•';
    
    // Convert camelCase/snake_case to Title Case
    final formatted = key
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
    
    return '$icon $formatted';
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'Unknown';
    
    if (value is num) {
      // Format large numbers with commas
      if (value >= 1000000) {
        return '${(value / 1000000).toStringAsFixed(1)}M';
      } else if (value >= 1000) {
        return '${(value / 1000).toStringAsFixed(1)}K';
      }
      return value.toString();
    }
    
    return value.toString();
  }

  Widget _buildRow(String label, String value, {bool isAlternate = false}) {
    return Container(
      color: isAlternate 
          ? Colors.white.withOpacity(0.03) 
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
