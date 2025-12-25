import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:astro_encyclopedia/services/network_service.dart';
import 'package:astro_encyclopedia/widgets/smart_image.dart';
import 'package:astro_encyclopedia/core/config.dart';

void main() async {
  await Hive.initFlutter();
  runApp(const AstroApp());
}

class AstroApp extends StatelessWidget {
  const AstroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Astro Encyclopedia',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B0D17),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3D5AFE),
          secondary: Color(0xFF00E5FF),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _networkService = NetworkService();
  Map<String, dynamic>? _apodData;
  bool _loading = false;

  Future<void> _fetchApod() async {
    setState(() => _loading = true);
    try {
      // In a real app, use a Repository and Models
      final data = await _networkService.get('/apod');
      setState(() => _apodData = data);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Astro Encyclopedia')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_loading) const CircularProgressIndicator(),
            if (_apodData != null) ...[
              SizedBox(
                height: 300,
                width: double.infinity,
                child: SmartImage(
                  id: _apodData!['id'] ?? 'apod',
                  imageUrl: _apodData!['imageUrl'] ?? '',
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _apodData!['title'],
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ],
            if (!_loading && _apodData == null)
              ElevatedButton(
                onPressed: _fetchApod,
                child: const Text('Load APOD'),
              ),
          ],
        ),
      ),
    );
  }
}
