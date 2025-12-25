import 'package:flutter/material.dart';
import 'package:astro_encyclopedia/widgets/smart_image.dart';

/// ParallaxHeader Widget - Creates a parallax scrolling effect
/// 
/// Features:
/// - SliverAppBar with 400px expanded height
/// - FlexibleSpaceBar for the parallax effect
/// - SmartImage for intelligent image loading
/// - Gradient overlay for text readability
class ParallaxHeader extends StatelessWidget {
  final String? imageUrl;
  final String? imageId;
  final String title;
  final VoidCallback? onBackPressed;

  const ParallaxHeader({
    super.key,
    this.imageUrl,
    this.imageId,
    required this.title,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 400,
      floating: false,
      pinned: true,
      stretch: true,
      backgroundColor: const Color(0xFF0B0D17),
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        onPressed: onBackPressed ?? () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black87,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
              Shadow(
                color: Colors.black54,
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        titlePadding: const EdgeInsets.only(left: 56, right: 56, bottom: 16),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image with SmartImage
            SmartImage(
              id: imageId,
              imageUrl: imageUrl,
              fit: BoxFit.cover,
            ),

            // Multi-layer gradient for better text readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    const Color(0xFF0B0D17).withOpacity(0.3),
                    const Color(0xFF0B0D17).withOpacity(0.7),
                    const Color(0xFF0B0D17),
                  ],
                  stops: const [0.0, 0.4, 0.6, 0.8, 1.0],
                ),
              ),
            ),

            // Top gradient for status bar readability
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 120,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
          StretchMode.fadeTitle,
        ],
      ),
    );
  }
}
