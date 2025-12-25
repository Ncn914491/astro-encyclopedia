import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// SmartImage Widget - Intelligent image loading with offline support
/// 
/// Loading Priority:
/// 1. Local asset bundle (assets/offline/{id}.jpg)
/// 2. Cached network image (from Worker proxy)
/// 3. Placeholder on error
class SmartImage extends StatelessWidget {
  final String? id;
  final String? imageUrl;
  final String? fallbackAsset;
  final BoxFit fit;
  final double? width;
  final double? height;

  const SmartImage({
    super.key,
    this.id,
    this.imageUrl,
    this.fallbackAsset,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    // If we have an ID, try local asset first
    if (id != null && id!.isNotEmpty) {
      return Image.asset(
        'assets/offline/$id.jpg',
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) {
          return _buildNetworkImage();
        },
      );
    }

    return _buildNetworkImage();
  }

  Widget _buildNetworkImage() {
    // If we have a network URL, use CachedNetworkImage
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: fit,
        width: width,
        height: height,
        placeholder: (context, url) => _buildPlaceholder(),
        errorWidget: (context, url, error) => _buildFallback(),
      );
    }

    // No URL available, use fallback
    return _buildFallback();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.indigo.shade900,
            Colors.purple.shade900,
          ],
        ),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
          ),
        ),
      ),
    );
  }

  Widget _buildFallback() {
    // Try using custom fallback asset
    if (fallbackAsset != null) {
      return Image.asset(
        fallbackAsset!,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) => _buildDefaultFallback(),
      );
    }

    // Try milky-way as default fallback
    return Image.asset(
      'assets/offline/milky-way.jpg',
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) => _buildDefaultFallback(),
    );
  }

  Widget _buildDefaultFallback() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.indigo.shade900,
            Colors.black,
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.auto_awesome,
          color: Colors.white24,
          size: 48,
        ),
      ),
    );
  }
}
