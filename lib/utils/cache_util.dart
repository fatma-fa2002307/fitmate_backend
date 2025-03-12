// Simple utility class to clear image cache in Flutter app
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CacheUtil {
  /// Clears all image caches in the application
  static Future<void> clearImageCache(BuildContext context) async {
    try {
      // Clear the in-memory image cache
      imageCache.clear();
      imageCache.clearLiveImages();
      
      // Clear the disk cache for network images
      await DefaultCacheManager().emptyCache();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image cache cleared successfully'),
          backgroundColor: Color(0xFFD2EB50),
          duration: Duration(seconds: 2),
        ),
      );
      
      debugPrint('Image cache cleared');
    } catch (e) {
      debugPrint('Error clearing cache: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to clear cache: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  /// Create a network image URL with cache busting
  static String getCacheBustedUrl(String originalUrl) {
    // Add timestamp query parameter to force refresh
    return '$originalUrl?t=${DateTime.now().millisecondsSinceEpoch}';
  }
  
  /// Display a button to clear cache
  static Widget clearCacheButton(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.cleaning_services),
      label: const Text('Clear Image Cache'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFD2EB50),
        foregroundColor: Colors.white,
      ),
      onPressed: () => clearImageCache(context),
    );
  }
}