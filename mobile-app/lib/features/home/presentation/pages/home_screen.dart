import 'package:flutter/material.dart';
import 'package:astro_encyclopedia/features/home/domain/entities/apod_entity.dart';
import 'package:astro_encyclopedia/features/home/domain/entities/space_object.dart';
import 'package:astro_encyclopedia/features/home/presentation/widgets/apod_hero.dart';
import 'package:astro_encyclopedia/features/home/presentation/widgets/featured_objects_list.dart';
import 'package:astro_encyclopedia/services/local_data_service.dart';
import 'package:astro_encyclopedia/services/network_service.dart';
import 'package:astro_encyclopedia/core/router/app_router.dart';

/// Home Screen - Main landing page
/// 
/// Architecture:
/// - Renders from Offline Bundle in <1 frame
/// - Fetches fresh APOD in background
/// - CustomScrollView with collapsible APOD header
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NetworkService _networkService = NetworkService();
  
  // State
  List<SpaceObject> _featuredObjects = [];
  ApodEntity? _apod;
  bool _isLoadingApod = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // 1. Load featured objects from bundle IMMEDIATELY (sync-like speed)
    _loadFeaturedObjects();
    
    // 2. Fetch APOD from network (async, background)
    _fetchApod();
  }

  Future<void> _loadFeaturedObjects() async {
    final objects = await LocalDataService.getFeaturedObjects();
    if (mounted) {
      setState(() => _featuredObjects = objects);
    }
  }

  Future<void> _fetchApod() async {
    try {
      final data = await _networkService.fetchApod();
      if (mounted) {
        setState(() {
          _apod = ApodEntity.fromJson(data);
          _isLoadingApod = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingApod = false;
          _error = e.toString();
        });
      }
    }
  }

  void _onApodTap() {
    Navigator.pushNamed(context, AppRouter.apod);
  }

  void _onObjectTap(SpaceObject object) {
    Navigator.pushNamed(context, AppRouter.detailsRoute(object.id));
  }

  void _onSearchTap() {
    Navigator.pushNamed(context, AppRouter.search);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0D17),
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
        slivers: [
          // Collapsible APOD Header
          _buildSliverAppBar(),

          // Section: Explore the Cosmos
          _buildSectionTitle('Explore the Cosmos', Icons.auto_awesome),

          // Featured Objects Horizontal List
          SliverToBoxAdapter(
            child: FeaturedObjectsList(
              objects: _featuredObjects,
              onObjectTap: _onObjectTap,
            ),
          ),

          // Section: By Category
          _buildSectionTitle('By Category', Icons.category),

          // Category Grid (Planets, Stars, Galaxies, Nebulae)
          SliverToBoxAdapter(
            child: _buildCategoryGrid(),
          ),

          // Bottom Padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      floating: false,
      pinned: true,
      stretch: true,
      backgroundColor: const Color(0xFF0B0D17),
      elevation: 0,
      
      // Transparent AppBar with actions
      title: const Text(
        'Astro Encyclopedia',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: _onSearchTap,
        ),
      ],
      
      flexibleSpace: FlexibleSpaceBar(
        background: ApodHero(
          apod: _apod,
          isLoading: _isLoadingApod,
          onTap: _onApodTap,
        ),
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Row(
          children: [
            Icon(icon, color: Colors.amber, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    final categories = [
      _CategoryItem('Planets', '🪐', Colors.blue, 'planet'),
      _CategoryItem('Stars', '⭐', Colors.amber, 'star'),
      _CategoryItem('Galaxies', '🌌', Colors.purple, 'galaxy'),
      _CategoryItem('Nebulae', '✨', Colors.pink, 'nebula'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.5,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          return _buildCategoryCard(cat);
        },
      ),
    );
  }

  Widget _buildCategoryCard(_CategoryItem category) {
    // Filter objects by this category
    final count = _featuredObjects.where((o) => o.type == category.type).length;

    return GestureDetector(
      onTap: () {
        // TODO: Navigate to category screen
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              category.color.withOpacity(0.3),
              category.color.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: category.color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Text(category.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      category.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '$count items',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.3),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryItem {
  final String name;
  final String emoji;
  final Color color;
  final String type;

  _CategoryItem(this.name, this.emoji, this.color, this.type);
}
