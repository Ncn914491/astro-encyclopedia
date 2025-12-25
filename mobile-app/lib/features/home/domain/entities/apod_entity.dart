/// APOD Entity - Astronomy Picture of the Day
/// 
/// Represents the normalized data from our Worker's /apod endpoint.
class ApodEntity {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String type;
  final ApodMetadata metadata;
  final String source;
  final DateTime? date;

  const ApodEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.type = 'other',
    required this.metadata,
    this.source = 'NASA',
    this.date,
  });

  factory ApodEntity.fromJson(Map<String, dynamic> json) {
    return ApodEntity(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Astronomy Picture of the Day',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      type: json['type'] ?? 'other',
      metadata: ApodMetadata.fromJson(json['metadata'] ?? {}),
      source: json['source'] ?? 'NASA',
      date: json['id'] != null ? DateTime.tryParse(json['id']) : null,
    );
  }

  /// Fallback APOD for offline/error states
  static ApodEntity fallback() {
    return const ApodEntity(
      id: 'fallback',
      title: 'Welcome to the Cosmos',
      description: 'Explore the wonders of the universe. Connect to the internet to see today\'s Astronomy Picture of the Day.',
      imageUrl: '', // Will use local asset
      type: 'galaxy',
      metadata: ApodMetadata(distance: 'Unknown', constellation: 'Unknown'),
      source: 'Local',
    );
  }

  bool get isFallback => id == 'fallback';
}

class ApodMetadata {
  final String distance;
  final String constellation;

  const ApodMetadata({
    this.distance = 'Unknown',
    this.constellation = 'Unknown',
  });

  factory ApodMetadata.fromJson(Map<String, dynamic> json) {
    return ApodMetadata(
      distance: json['distance'] ?? 'Unknown',
      constellation: json['constellation'] ?? 'Unknown',
    );
  }
}
