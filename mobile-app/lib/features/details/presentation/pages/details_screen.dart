import 'package:flutter/material.dart';
import 'package:astro_encyclopedia/features/home/domain/entities/space_object.dart';
import 'package:astro_encyclopedia/features/details/presentation/widgets/parallax_header.dart';
import 'package:astro_encyclopedia/features/details/presentation/widgets/object_data_table.dart';
import 'package:astro_encyclopedia/features/details/presentation/widgets/description_text.dart';
import 'package:astro_encyclopedia/services/data_repository.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

/// ObjectDetailScreen - Full detail view for a space object
/// 
/// Architecture:
/// - Uses DataRepository.getObjectDetails() for offline-first loading
/// - Parallax header with immersive image
/// - Quick facts data table
/// - Rich description with Markdown support
/// - Source attribution footer
class DetailsScreen extends StatefulWidget {
  final String objectId;

  const DetailsScreen({
    super.key,
    required this.objectId,
  });

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  final DataRepository _repository = DataRepository();
  
  SpaceObject? _object;
  Map<String, dynamic>? _fullData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadObjectData();
  }

  Future<void> _loadObjectData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Use repository's offline-first getObjectDetails method
      final object = await _repository.getObjectDetails(widget.objectId);
      
      // Also try to load full JSON data for metadata
      final fullData = await _loadFullData();
      
      if (mounted) {
        setState(() {
          _object = object;
          _fullData = fullData;
          _isLoading = false;
        });
      }
    } on DataNotFoundException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Object not found: ${e.id}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load object details';
        });
      }
    }
  }

  /// Load full JSON data including metadata
  Future<Map<String, dynamic>?> _loadFullData() async {
    // Try tier_a first
    try {
      final jsonString = await rootBundle.loadString('assets/data/tier_a/${widget.objectId}.json');
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (_) {}

    // Try objects folder
    try {
      final jsonString = await rootBundle.loadString('assets/data/objects/${widget.objectId}.json');
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (_) {}

    // Try Hive cache
    try {
      final box = await Hive.openBox<String>('astro_cache');
      final cached = box.get('object_${widget.objectId}');
      if (cached != null) {
        return jsonDecode(cached) as Map<String, dynamic>;
      }
    } catch (_) {}

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0D17),
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.indigo.shade900.withOpacity(0.3),
            const Color(0xFF0B0D17),
          ],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                color: Colors.white54,
                strokeWidth: 2,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Loading details...',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'An error occurred',
              style: const TextStyle(color: Colors.white54, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _loadObjectData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_object == null) {
      return _buildErrorState();
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Parallax Header with immersive image
        ParallaxHeader(
          title: _object!.title,
          imageId: widget.objectId,
          imageUrl: _object!.imageUrl,
        ),

        // Main Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type Badge
                _buildTypeBadge(),
                const SizedBox(height: 24),

                // Quick Facts Section (Data Table)
                if (_fullData != null) ...[
                  ObjectDataTable(
                    metadata: _extractMetadata(),
                    title: '📊 Quick Facts',
                  ),
                  const SizedBox(height: 32),
                ],

                // Description Section
                if (_object!.description != null && _object!.description!.isNotEmpty) ...[
                  DescriptionText(
                    description: _object!.description!,
                    title: '📖 Overview',
                  ),
                  const SizedBox(height: 32),
                ],

                // Source Attribution Footer
                _buildSourceFooter(),
                
                // Bottom padding for safe area
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeBadge() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Color(_object!.typeColor).withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Color(_object!.typeColor).withOpacity(0.4),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _object!.typeIcon,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 8),
              Text(
                _object!.type.toUpperCase(),
                style: TextStyle(
                  color: Color(_object!.typeColor),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Extract metadata for the data table
  Map<String, dynamic> _extractMetadata() {
    final metadata = <String, dynamic>{};
    
    if (_fullData == null) return metadata;

    // Add top-level fields that are relevant
    final relevantFields = [
      'distance', 'mass', 'radius', 'diameter', 'size',
      'temperature', 'discovered', 'discoveredBy', 'age',
      'constellation', 'magnitude', 'orbitalPeriod', 
      'rotationPeriod', 'moons', 'gravity', 'atmosphere'
    ];

    for (final field in relevantFields) {
      if (_fullData!.containsKey(field) && _fullData![field] != null) {
        metadata[field] = _fullData![field];
      }
    }

    // Include nested metadata if present
    if (_fullData!.containsKey('metadata') && _fullData!['metadata'] is Map) {
      final nested = _fullData!['metadata'] as Map<String, dynamic>;
      nested.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty && value.toString() != 'Unknown') {
          metadata[key] = value;
        }
      });
    }

    return metadata;
  }

  Widget _buildSourceFooter() {
    final source = _fullData?['source'] ?? 'NASA';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified,
              color: Colors.lightBlueAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Data Source',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
                Text(
                  source.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.open_in_new,
            color: Colors.white24,
            size: 16,
          ),
        ],
      ),
    );
  }
}
