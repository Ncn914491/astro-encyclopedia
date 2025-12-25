import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:astro_encyclopedia/features/home/domain/entities/space_object.dart';
import 'package:astro_encyclopedia/services/network_service.dart';
import 'package:astro_encyclopedia/services/local_data_service.dart';
import 'package:astro_encyclopedia/widgets/smart_image.dart';
import 'package:astro_encyclopedia/core/router/app_router.dart';

/// Search Screen - Full-featured search with offline support
/// 
/// Features:
/// - Debounced search (500ms)
/// - Popular categories chips
/// - Offline mode with local filtering
/// - Results caching to Hive
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final NetworkService _networkService = NetworkService();
  final FocusNode _focusNode = FocusNode();
  
  Timer? _debounceTimer;
  List<SpaceObject> _results = [];
  List<SpaceObject> _localObjects = [];
  bool _isLoading = false;
  bool _isOffline = false;
  String? _error;
  String _lastQuery = '';

  // Popular categories for empty state
  final List<_CategoryChip> _categories = [
    _CategoryChip('Planets', '🪐', Colors.blue),
    _CategoryChip('Galaxies', '🌌', Colors.purple),
    _CategoryChip('Nebulae', '✨', Colors.pink),
    _CategoryChip('Stars', '⭐', Colors.amber),
    _CategoryChip('Black Holes', '🕳️', Colors.grey),
    _CategoryChip('Moon', '🌙', Colors.blueGrey),
  ];

  @override
  void initState() {
    super.initState();
    _loadLocalObjects();
    // Auto-focus search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadLocalObjects() async {
    _localObjects = await LocalDataService.getFeaturedObjects();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _lastQuery = '';
        _error = null;
      });
      return;
    }

    // Debounce: wait 500ms after user stops typing
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
      _isOffline = false;
      _lastQuery = query;
    });

    try {
      // Try online search first
      final results = await _networkService.searchObjects(query);
      final objects = results.map((json) => SpaceObject.fromJson(json)).toList();
      
      // Cache new results to Hive for offline use
      await _cacheResults(objects, results);
      
      if (mounted) {
        setState(() {
          _results = objects;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Offline mode: search local data
      if (mounted) {
        setState(() {
          _isOffline = true;
          _results = _searchLocalObjects(query);
          _isLoading = false;
          if (_results.isEmpty) {
            _error = 'No local results found for "$query"';
          }
        });
      }
    }
  }

  List<SpaceObject> _searchLocalObjects(String query) {
    final lowerQuery = query.toLowerCase();
    return _localObjects.where((obj) {
      return obj.title.toLowerCase().contains(lowerQuery) ||
             obj.type.toLowerCase().contains(lowerQuery) ||
             obj.id.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  Future<void> _cacheResults(List<SpaceObject> objects, List<Map<String, dynamic>> rawData) async {
    try {
      // Use astro_cache for consistency with DataRepository
      final box = await Hive.openBox<String>('astro_cache');
      for (int i = 0; i < objects.length; i++) {
        await box.put('object_${objects[i].id}', jsonEncode(rawData[i]));
      }
    } catch (e) {
      // Caching failed, continue silently
    }
  }

  void _onCategoryTap(String category) {
    _searchController.text = category;
    _performSearch(category);
  }

  void _onResultTap(SpaceObject object) {
    Navigator.pushNamed(context, AppRouter.detailsRoute(object.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0D17),
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0B0D17),
      elevation: 0,
      title: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        onChanged: _onSearchChanged,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Search the cosmos...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          border: InputBorder.none,
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white54),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
        ),
      ),
      actions: [
        if (_isOffline)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Chip(
              label: const Text('Offline', style: TextStyle(fontSize: 10)),
              backgroundColor: Colors.orange.withValues(alpha: 0.3),
              side: BorderSide.none,
              padding: EdgeInsets.zero,
            ),
          ),
      ],
    );
  }

  Widget _buildBody() {
    // Loading state
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white54),
            SizedBox(height: 16),
            Text(
              'Searching the universe...',
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      );
    }

    // Empty state - show categories
    if (_lastQuery.isEmpty) {
      return _buildEmptyState();
    }

    // Error state
    if (_error != null && _results.isEmpty) {
      return _buildErrorState();
    }

    // Results
    return _buildResults();
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Offline banner
          if (_isOffline)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Offline Mode: Searching local library only',
                      style: TextStyle(color: Colors.orange, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          const Text(
            'Popular Categories',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((cat) => _buildCategoryChip(cat)).toList(),
          ),

          const SizedBox(height: 32),

          const Text(
            'Recent Searches',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Center(
            child: Column(
              children: [
                Icon(Icons.history, color: Colors.white.withValues(alpha: 0.3), size: 48),
                const SizedBox(height: 8),
                Text(
                  'Your recent searches will appear here',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(_CategoryChip category) {
    return ActionChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(category.emoji),
          const SizedBox(width: 6),
          Text(category.name),
        ],
      ),
      backgroundColor: category.color.withValues(alpha: 0.2),
      side: BorderSide(color: category.color.withValues(alpha: 0.4)),
      labelStyle: const TextStyle(color: Colors.white),
      onPressed: () => _onCategoryTap(category.name),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isOffline ? Icons.wifi_off : Icons.error_outline,
              color: Colors.white38,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _isOffline 
                  ? 'Offline Mode'
                  : 'Search Failed',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'An error occurred',
              style: const TextStyle(color: Colors.white54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _performSearch(_lastQuery),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Results header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                '${_results.length} result${_results.length != 1 ? 's' : ''} for "$_lastQuery"',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              if (_isOffline) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Local',
                    style: TextStyle(color: Colors.orange, fontSize: 11),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Results list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _results.length,
            itemBuilder: (context, index) {
              return _buildResultCard(_results[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(SpaceObject object) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF1A1D2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _onResultTap(object),
        child: SizedBox(
          height: 100,
          child: Row(
            children: [
              // Thumbnail
              SizedBox(
                width: 100,
                height: 100,
                child: SmartImage(
                  id: object.id,
                  imageUrl: object.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),

              // Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Type badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Color(object.typeColor).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${object.typeIcon} ${object.type.toUpperCase()}',
                          style: TextStyle(
                            color: Color(object.typeColor),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      
                      // Title
                      Text(
                        object.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      // Description preview
                      if (object.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          object.description!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Arrow
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withValues(alpha: 0.3),
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChip {
  final String name;
  final String emoji;
  final Color color;

  _CategoryChip(this.name, this.emoji, this.color);
}
