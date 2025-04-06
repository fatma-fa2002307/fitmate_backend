import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CaloriesSummaryWidget extends StatelessWidget {
  final double totalCalories;
  final double dailyCaloriesGoal;

  const CaloriesSummaryWidget({
    Key? key,
    required this.totalCalories,
    required this.dailyCaloriesGoal,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive calculations
    final screenSize = MediaQuery.of(context).size;
    final percentage = (totalCalories / dailyCaloriesGoal * 100).toInt();
    final isWithinGoal = totalCalories <= dailyCaloriesGoal;
    final percentageRatio = (totalCalories / dailyCaloriesGoal).clamp(0.0, 1.0);

    // Use the original colors
    final Color accentColor = const Color(0xFFD2EB50);
    final Color accentLight = const Color(0xFFE9F5A6);
    final Color accentDark = const Color(0xFFB5CB30);
    final Color warningColor = const Color(0xFFFF9D54);
    final Color warningDark = const Color(0xFFE67E22);

    // Calculate responsive sizes - bigger circle on the left
    final double cardPadding = screenSize.width * 0.04;
    final double circleSize = screenSize.width * 0.28; // Bigger circle
    final double progressStrokeWidth = circleSize * 0.10;

    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenSize.width * 0.04),
      ),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Circle on the left
            Container(
              width: circleSize,
              height: circleSize,
              margin: EdgeInsets.only(right: screenSize.width * 0.04),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[100],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: circleSize,
                    height: circleSize,
                    child: CircularProgressIndicator(
                      value: percentageRatio,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isWithinGoal ? accentColor : warningColor,
                      ),
                      strokeWidth: progressStrokeWidth,
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "$percentage%",
                        style: GoogleFonts.bebasNeue(
                          fontSize: circleSize * 0.25,
                          fontWeight: FontWeight.bold,
                          color: isWithinGoal ? accentDark : warningDark,
                        ),
                      ),

                      Text(
                        "of goal",
                        style: GoogleFonts.bebasNeue(
                          fontSize: circleSize * 0.12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Details on the right
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Calories count
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        "${totalCalories.toInt()}",
                        style: GoogleFonts.bebasNeue(
                          fontSize: screenSize.width * 0.07,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(width: screenSize.width * 0.01),
                      Text(
                        "kcal",
                        style: GoogleFonts.bebasNeue(
                          fontSize: screenSize.width * 0.035,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: screenSize.height * 0.018),

                  // Daily goal
                  Row(
                    children: [
                      Icon(
                        Icons.flag_outlined,
                        size: screenSize.width * 0.035,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: screenSize.width * 0.01),
                      Text(
                        "Daily Goal:",
                        style: GoogleFonts.bebasNeue(
                          fontSize: screenSize.width * 0.03,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(width: screenSize.width * 0.01),
                      Text(
                        "${dailyCaloriesGoal.toInt()} kcal",
                        style: GoogleFonts.bebasNeue(
                          fontSize: screenSize.width * 0.03,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: screenSize.height * 0.015),

                  // Message
                  Text(
                    isWithinGoal
                        ? "You're on track! Keep going!"
                        : "You've exceeded your calorie goal for today.",
                    style: TextStyle(
                      fontSize: screenSize.width * 0.028,
                      color: isWithinGoal ? accentDark : warningDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}