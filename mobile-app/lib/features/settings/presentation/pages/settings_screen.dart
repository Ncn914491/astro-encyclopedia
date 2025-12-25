import 'package:flutter/material.dart';
import 'package:astro_encyclopedia/services/storage_manager.dart';

/// Settings Screen - App configuration and cache management
/// 
/// Features:
/// - Dark Mode toggle (persisted in Hive)
/// - Clear Image Cache action
/// - Offline Library Version display
/// - Storage statistics
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = true;
  bool _isClearing = false;
  String _libraryVersion = 'Loading...';
  String _cacheSize = 'Calculating...';
  int _cacheItems = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final darkMode = await StorageManager.getDarkMode();
    final version = await StorageManager.getOfflineLibraryVersion();
    final stats = await StorageManager.getStorageStats();
    
    if (mounted) {
      setState(() {
        _isDarkMode = darkMode;
        _libraryVersion = version;
        _cacheSize = stats['formattedSize'] ?? 'Unknown';
        _cacheItems = stats['cacheItemCount'] ?? 0;
      });
    }
  }

  Future<void> _toggleDarkMode(bool value) async {
    setState(() => _isDarkMode = value);
    await StorageManager.setDarkMode(value);
    
    // Show snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? 'Dark mode enabled' : 'Light mode enabled (restart required)'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1A1D2E),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _clearImageCache() async {
    setState(() => _isClearing = true);
    
    try {
      await StorageManager.clearImageCache();
      await _loadSettings(); // Refresh stats
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Image cache cleared successfully'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFF1A1D2E),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear cache: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isClearing = false);
      }
    }
  }

  Future<void> _clearAllCaches() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear All Caches?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will remove all cached images and data. You may need to re-download content when browsing.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isClearing = true);
      
      try {
        await StorageManager.clearAllCaches();
        await _loadSettings();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('All caches cleared'),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Color(0xFF1A1D2E),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isClearing = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0D17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0D17),
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Appearance Section
          _buildSectionHeader('Appearance', Icons.palette),
          const SizedBox(height: 8),
          _buildSettingCard(
            children: [
              _buildSwitchTile(
                title: 'Dark Mode',
                subtitle: 'Use dark theme for the app',
                icon: Icons.dark_mode,
                value: _isDarkMode,
                onChanged: _toggleDarkMode,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Storage Section
          _buildSectionHeader('Storage', Icons.storage),
          const SizedBox(height: 8),
          _buildSettingCard(
            children: [
              _buildInfoTile(
                title: 'Cached Data',
                subtitle: '$_cacheItems items • $_cacheSize',
                icon: Icons.data_usage,
              ),
              const Divider(color: Colors.white12, height: 1),
              _buildActionTile(
                title: 'Clear Image Cache',
                subtitle: 'Free up space by removing cached images',
                icon: Icons.image,
                iconColor: Colors.orange,
                isLoading: _isClearing,
                onTap: _clearImageCache,
              ),
              const Divider(color: Colors.white12, height: 1),
              _buildActionTile(
                title: 'Clear All Caches',
                subtitle: 'Remove all cached data and images',
                icon: Icons.delete_sweep,
                iconColor: Colors.red,
                isLoading: _isClearing,
                onTap: _clearAllCaches,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Library Section
          _buildSectionHeader('Offline Library', Icons.library_books),
          const SizedBox(height: 8),
          _buildSettingCard(
            children: [
              _buildInfoTile(
                title: 'Library Version',
                subtitle: _libraryVersion,
                icon: Icons.info_outline,
              ),
              const Divider(color: Colors.white12, height: 1),
              _buildInfoTile(
                title: 'Max Cache Items',
                subtitle: '500 items (auto-cleanup enabled)',
                icon: Icons.auto_delete,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // About Section
          _buildSectionHeader('About', Icons.info),
          const SizedBox(height: 8),
          _buildSettingCard(
            children: [
              _buildInfoTile(
                title: 'Astro Encyclopedia',
                subtitle: 'Version 1.0.0',
                icon: Icons.rocket_launch,
              ),
              const Divider(color: Colors.white12, height: 1),
              _buildInfoTile(
                title: 'Data Source',
                subtitle: 'NASA Image and Video Library',
                icon: Icons.public,
              ),
              const Divider(color: Colors.white12, height: 1),
              _buildActionTile(
                title: 'Open Source Licenses',
                subtitle: 'View third-party licenses',
                icon: Icons.article,
                iconColor: Colors.blue,
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'Astro Encyclopedia',
                  applicationVersion: '1.0.0',
                  applicationIcon: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Icon(Icons.rocket_launch, size: 48, color: Colors.indigo),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Footer
          Center(
            child: Column(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white24, size: 32),
                const SizedBox(height: 8),
                Text(
                  'Made with ❤️ for space enthusiasts',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.indigo.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.indigo.shade300, size: 22),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.indigo,
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
      trailing: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
            )
          : Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.3)),
      onTap: isLoading ? null : onTap,
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blueGrey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.blueGrey.shade300, size: 22),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
    );
  }
}
