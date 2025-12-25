import 'package:flutter/material.dart';
import 'package:astro_encyclopedia/features/home/domain/entities/space_object.dart';
import 'package:astro_encyclopedia/widgets/smart_image.dart';

/// Featured Objects Horizontal Scroller
/// 
/// Displays a horizontally scrollable list of space objects.
/// Data loads instantly from bundled assets - no network wait.
class FeaturedObjectsList extends StatelessWidget {
  final List<SpaceObject> objects;
  final Function(SpaceObject)? onObjectTap;
  final String? title;

  const FeaturedObjectsList({
    super.key,
    required this.objects,
    this.onObjectTap,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    if (objects.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        if (title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Row(
              children: [
                Text(
                  title!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white38,
                  size: 14,
                ),
              ],
            ),
          ),

        // Horizontal List
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: objects.length,
            itemBuilder: (context, index) {
              return _FeaturedObjectCard(
                object: objects[index],
                onTap: () => onObjectTap?.call(objects[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FeaturedObjectCard extends StatelessWidget {
  final SpaceObject object;
  final VoidCallback? onTap;

  const _FeaturedObjectCard({
    required this.object,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Card(
          elevation: 8,
          shadowColor: Color(object.typeColor).withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image
              SmartImage(
                id: object.id,
                imageUrl: object.imageUrl,
                fit: BoxFit.cover,
              ),

              // Gradient Overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),
              ),

              // Type Badge
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(object.typeColor).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    object.typeIcon,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),

              // Title
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Text(
                  object.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
