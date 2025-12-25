/// SpaceObject Entity - Represents any astronomical object
/// 
/// Used for galaxies, stars, planets, nebulae, etc.
class SpaceObject {
  final String id;
  final String title;
  final String type;
  final String? thumbnailPath;
  final String? imageUrl;
  final String? description;

  const SpaceObject({
    required this.id,
    required this.title,
    required this.type,
    this.thumbnailPath,
    this.imageUrl,
    this.description,
  });

  /// Create from content_index.json format
  factory SpaceObject.fromIndexJson(Map<String, dynamic> json) {
    return SpaceObject(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      type: json['type'] ?? 'other',
      thumbnailPath: json['path'],
    );
  }

  /// Create from full object JSON (tier_a/*.json)
  factory SpaceObject.fromJson(Map<String, dynamic> json) {
    return SpaceObject(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      type: json['type'] ?? 'other',
      imageUrl: json['imageUrl'],
      description: json['description'],
    );
  }

  /// Get display icon based on type
  String get typeIcon {
    switch (type) {
      case 'galaxy':
        return '🌌';
      case 'star':
        return '⭐';
      case 'planet':
        return '🪐';
      case 'nebula':
        return '✨';
      default:
        return '🔭';
    }
  }

  /// Get display color based on type
  int get typeColor {
    switch (type) {
      case 'galaxy':
        return 0xFF7C4DFF; // Purple
      case 'star':
        return 0xFFFFD54F; // Amber
      case 'planet':
        return 0xFF42A5F5; // Blue
      case 'nebula':
        return 0xFFE91E63; // Pink
      default:
        return 0xFF78909C; // Blue Grey
    }
  }
}
