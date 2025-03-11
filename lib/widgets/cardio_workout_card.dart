import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fitmate/services/api_service.dart';

class CardioWorkoutCard extends StatelessWidget {
  final Map<String, dynamic> workout;
  
  const CardioWorkoutCard({Key? key, required this.workout}) : super(key: key);

  void _showDetailsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  workout["workout"],
                  style: GoogleFonts.montserrat(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                // Direct Image without caching
                Image.network(
                  ApiService.baseUrl + workout["image"],
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 150,
                      color: Colors.grey[300],
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFD2EB50),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    print("Error loading cardio image: ${ApiService.baseUrl}${workout["image"]} - $error");
                    return Container(
                      height: 150,
                      color: Colors.grey[200],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.directions_run, size: 60, color: Colors.grey[700]),
                          Text('Image not available', style: TextStyle(color: Colors.grey[700])),
                          Text('Path: ${workout["image"]}', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                _buildDetailRow(Icons.timer, "Duration", workout["duration"] ?? "30 min"),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.whatshot, "Intensity", workout["intensity"] ?? "Moderate"),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.loop, "Format", workout["format"] ?? "Steady-state"),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.local_fire_department, "Est. Calories", workout["calories"] ?? "300-350"),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    workout["description"] ?? "Perform at a comfortable pace, focusing on maintaining proper form throughout.",
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD2EB50),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'GOT IT',
                    style: GoogleFonts.bebasNeue(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFD2EB50), size: 20),
        const SizedBox(width: 12),
        Text(
          "$label:",
          style: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: Colors.black,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Debug logging
    print("DEBUG: Cardio workout image path: ${workout["image"]}");
    print("DEBUG: Full URL: ${ApiService.baseUrl}${workout["image"]}");
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      elevation: 3,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _showDetailsDialog(context),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card header with workout name
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFD2EB50),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.directions_run, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      workout["workout"],
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Card body with workout image and details
            Stack(
              children: [
                // Cardio Image - Direct without caching
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  child: Image.network(
                    ApiService.baseUrl + workout["image"],
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 180,
                        color: Colors.grey[300],
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFD2EB50),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      print("Card Error loading cardio image: ${ApiService.baseUrl}${workout["image"]} - $error");
                      return Container(
                        height: 180,
                        color: Colors.grey[200],
                        child: Icon(Icons.directions_run, size: 60, color: Colors.grey[700]),
                      );
                    },
                  ),
                ),
                // Overlay with key workout details
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.8),
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStat(Icons.timer, workout["duration"] ?? "30 min"),
                            _buildStat(Icons.whatshot, workout["intensity"] ?? "Moderate"),
                            _buildStat(Icons.local_fire_department, workout["calories"] ?? "300-350 cal"),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStat(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 4),
        Text(
          value,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}