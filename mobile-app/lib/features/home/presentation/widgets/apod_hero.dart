import 'package:flutter/material.dart';
import 'package:astro_encyclopedia/features/home/domain/entities/apod_entity.dart';
import 'package:astro_encyclopedia/widgets/smart_image.dart';

/// APOD Hero Widget - Featured astronomy picture at the top of Home Screen
/// 
/// Features:
/// - Full-width image with gradient overlay
/// - "Today's Pick" badge
/// - Title and date overlay
/// - Graceful offline fallback (never shows spinner > 200ms)
class ApodHero extends StatefulWidget {
  final ApodEntity? apod;
  final bool isLoading;
  final VoidCallback? onTap;

  const ApodHero({
    super.key,
    this.apod,
    this.isLoading = false,
    this.onTap,
  });

  @override
  State<ApodHero> createState() => _ApodHeroState();
}

class _ApodHeroState extends State<ApodHero> {
  bool _showFallback = false;

  @override
  void initState() {
    super.initState();
    // If loading, start a 200ms timer to show fallback if data is slow
    if (widget.isLoading) {
      _startFallbackTimer();
    }
  }

  @override
  void didUpdateWidget(ApodHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !oldWidget.isLoading) {
      _startFallbackTimer();
    } else if (!widget.isLoading) {
      _showFallback = false;
    }
  }

  void _startFallbackTimer() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted && widget.isLoading && widget.apod == null) {
        setState(() => _showFallback = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine which APOD to show
    final apod = widget.apod ?? 
        (widget.isLoading && !_showFallback ? null : ApodEntity.fallback());

    // Brief loading state (< 200ms)
    if (apod == null) {
      return _buildLoadingShimmer();
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        height: 280,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            _buildImage(apod),

            // Gradient Overlay
            _buildGradientOverlay(),

            // "Today's Pick" Badge
            _buildBadge(apod),

            // Title & Date
            _buildTitleSection(apod),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(ApodEntity apod) {
    if (apod.isFallback) {
      return SmartImage(
        id: 'milky-way',
        fallbackAsset: 'assets/offline/milky-way.jpg',
        fit: BoxFit.cover,
      );
    }

    return SmartImage(
      id: apod.id,
      imageUrl: apod.imageUrl,
      fallbackAsset: 'assets/offline/milky-way.jpg',
      fit: BoxFit.cover,
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.transparent,
              Colors.black.withOpacity(0.3),
              Colors.black.withOpacity(0.8),
            ],
            stops: const [0.0, 0.4, 0.7, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(ApodEntity apod) {
    return Positioned(
      top: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: apod.isFallback 
              ? Colors.indigo.withOpacity(0.9)
              : Colors.amber.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              apod.isFallback ? Icons.offline_bolt : Icons.auto_awesome,
              color: Colors.white,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              apod.isFallback ? 'Offline' : "Today's Pick",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSection(ApodEntity apod) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Date
          if (apod.date != null)
            Text(
              _formatDate(apod.date!),
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          
          const SizedBox(height: 4),
          
          // Title
          Text(
            apod.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.2,
              shadows: [
                Shadow(
                  color: Colors.black54,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 8),
          
          // Tap hint
          Row(
            children: [
              Icon(
                Icons.touch_app,
                color: Colors.white.withOpacity(0.6),
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                'Tap to explore',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Container(
      height: 280,
      width: double.infinity,
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
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
