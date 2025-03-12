import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:fitmate/utils/cache_util.dart';
import 'package:fitmate/widgets/bottom_nav_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitmate/services/api_service.dart';
import 'package:http/http.dart' as http;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedIndex = 3;
  bool _isLoading = false;
  String _cacheSizeInfo = "Unknown";
  final List<String> _testResults = [];

  @override
  void initState() {
    super.initState();
    _getCacheSize();
  }

  Future<void> _getCacheSize() async {
    try {
      final cache = await DefaultCacheManager().emptyCache();
      setState(() {
        _cacheSizeInfo = "Cache cleared";
      });
    } catch (e) {
      setState(() {
        _cacheSizeInfo = "Error: $e";
      });
      debugPrint('Error getting cache size: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _clearAllCaches() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Clear image cache
      imageCache.clear();
      imageCache.clearLiveImages();
      
      // Clear network image cache
      await DefaultCacheManager().emptyCache();
      
      // Force rebuild UI
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All caches cleared successfully')),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error clearing caches: $e')),
      );
      
      debugPrint('Error clearing caches: $e');
    }
  }

  Future<void> _testCardioImages() async {
    setState(() {
      _isLoading = true;
      _testResults.clear();
    });

    try {
      final testPaths = [
        '/workout-images/cardio/treadmill.jpg',
        '/workout-images/cardio/running.heic',
        '/workout-images/cardio/bicycle.png',
        '/workout-images/cardio/exercise-bike.jpg',
        '/workout-images/cardio/jumping-rope.jpg',
        '/workout-images/cardio/swimming.avif',
        '/workout-images/cardio/hiking.jpg',
        '/workout-images/cardio/cardio.webp',
      ];

      for (var path in testPaths) {
        final url = '${ApiService.baseUrl}$path';
        try {
          final response = await http.get(Uri.parse(url));
          final result = '${path}: ${response.statusCode == 200 ? "✅" : "❌"} (${response.statusCode})';
          setState(() {
            _testResults.add(result);
          });
        } catch (e) {
          setState(() {
            _testResults.add('$path: ❌ Error: $e');
          });
        }
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SETTINGS',
          style: GoogleFonts.bebasNeue(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cache Management',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Image Cache',
                            style: GoogleFonts.dmSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Clear the image cache if you\'re experiencing issues with images not loading correctly.',
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          ElevatedButton.icon(
                            onPressed: _clearAllCaches,
                            icon: const Icon(Icons.delete_sweep),
                            label: const Text('Clear Image Cache'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD2EB50),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Text(
                    'Diagnostics',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Image Loading Tests',
                            style: GoogleFonts.dmSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Test if cardio images can be loaded from the server.',
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          ElevatedButton.icon(
                            onPressed: _testCardioImages,
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Test Cardio Images'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                            ),
                          ),
                          
                          if (_testResults.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 8),
                            Text(
                              'Test Results:',
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...List.generate(
                              _testResults.length,
                              (index) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text(
                                  _testResults[index],
                                  style: GoogleFonts.dmSans(fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Text(
                    'Account',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              FirebaseAuth.instance.signOut().then((_) {
                                Navigator.pushReplacementNamed(context, '/login');
                              });
                            },
                            icon: const Icon(Icons.logout),
                            label: const Text('Log Out'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}