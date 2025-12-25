import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class SmartImage extends StatelessWidget {
  final String id;
  final String imageUrl;
  final BoxFit fit;

  const SmartImage({
    super.key,
    required this.id,
    required this.imageUrl,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    // Try to load from offline bundle first
    return Image.asset(
      'assets/offline/$id.jpg',
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        // If not found in assets, use cached network image
        return CachedNetworkImage(
          imageUrl: imageUrl,
          fit: fit,
          placeholder: (context, url) => Container(
            color: Colors.black12,
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[900],
            child: const Icon(Icons.broken_image, color: Colors.white24),
          ),
        );
      },
    );
  }
}
