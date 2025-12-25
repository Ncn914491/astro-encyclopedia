import 'package:flutter/material.dart';
import 'package:astro_encyclopedia/features/search/presentation/pages/search_screen.dart';
import 'package:astro_encyclopedia/features/details/presentation/pages/details_screen.dart';
import 'package:astro_encyclopedia/features/settings/presentation/pages/settings_screen.dart';

/// App Router - Centralized navigation
/// 
/// Route naming convention:
/// - /home - Home screen
/// - /details/:id - Object detail screen
/// - /search - Search screen
/// - /settings - Settings screen
/// - /apod - Full APOD screen
class AppRouter {
  static const String home = '/';
  static const String details = '/details';
  static const String search = '/search';
  static const String settings = '/settings';
  static const String apod = '/apod';

  /// Generate route for object details
  static String detailsRoute(String id) => '$details/$id';

  /// Route generator for MaterialApp.onGenerateRoute
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '/');
    
    switch (uri.pathSegments.firstOrNull ?? '') {
      case '':
        // Home route handled by MaterialApp.home
        return _buildRoute(settings, const _PlaceholderScreen(title: 'Home'));
      
      case 'details':
        final id = uri.pathSegments.length > 1 ? uri.pathSegments[1] : null;
        if (id == null) {
          return _buildRoute(settings, const _PlaceholderScreen(title: 'Invalid ID'));
        }
        return _buildRoute(
          settings,
          DetailsScreen(objectId: id),
        );
      
      case 'search':
        return _buildRoute(settings, const SearchScreen());
      
      case 'settings':
        return _buildRoute(settings, const SettingsScreen());
      
      case 'apod':
        return _buildRoute(settings, const _PlaceholderScreen(title: 'APOD'));
      
      default:
        return _buildRoute(settings, const _PlaceholderScreen(title: '404'));
    }
  }

  static MaterialPageRoute _buildRoute(RouteSettings settings, Widget screen) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => screen,
    );
  }
}

/// Placeholder for screens not yet implemented
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 64, color: Colors.amber),
            const SizedBox(height: 16),
            Text(
              '$title - Coming Soon',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      ),
    );
  }
}
