import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class WorkoutStreakWidget extends StatefulWidget {
  const WorkoutStreakWidget({Key? key}) : super(key: key);

  @override
  State<WorkoutStreakWidget> createState() => _WorkoutStreakWidgetState();
}

class _WorkoutStreakWidgetState extends State<WorkoutStreakWidget> {
  List<bool> _workoutDays = List.generate(30, (_) => false); // Last 30 days
  int _currentStreak = 0;
  int _strikes = 0;
  bool _isLoading = true;
  String _longestStreakText = "";
  int _completedWorkoutsThisMonth = 0;
  final ScrollController _scrollController = ScrollController();

  // User's selected workout days (e.g., [1, 3, 5] for Mon, Wed, Fri)
  List<int> _selectedWorkoutDays = [];
  int _weeklyWorkoutGoal = 0;

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();

    // Scroll to today's date after rendering
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserPreferences() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userData.exists && userData.data() is Map<String, dynamic>) {
          Map<String, dynamic> data = userData.data() as Map<String, dynamic>;

          // Load user's preferred workout days
          if (data.containsKey('workoutDays') && data['workoutDays'] is List) {
            setState(() {
              _selectedWorkoutDays = List<int>.from(data['workoutDays']);
              _weeklyWorkoutGoal = _selectedWorkoutDays.length;
            });
          } else {
            // Default to 3 days per week if not set
            setState(() {
              _selectedWorkoutDays = [1, 3, 5]; // Mon, Wed, Fri
              _weeklyWorkoutGoal = 3;
            });
          }

          // Load strike count if available
          if (data.containsKey('strikes')) {
            setState(() {
              _strikes = data['strikes'] as int;
            });
          }

          // Now load workout history with the user preferences
          await _loadWorkoutStreak();
        } else {
          // Default values if user data doesn't exist
          setState(() {
            _selectedWorkoutDays = [1, 3, 5]; // Mon, Wed, Fri as default
            _weeklyWorkoutGoal = 3;
            _isLoading = false;
          });
          await _loadWorkoutStreak();
        }
      } catch (e) {
        print('Error loading user preferences: $e');
        setState(() {
          _selectedWorkoutDays = [1, 3, 5]; // Default to Mon, Wed, Fri
          _weeklyWorkoutGoal = 3;
          _isLoading = false;
        });
        await _loadWorkoutStreak();
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadWorkoutStreak() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userData.exists && userData.data() is Map<String, dynamic>) {
          Map<String, dynamic> data = userData.data() as Map<String, dynamic>;

          if (data.containsKey('workoutHistory') && data['workoutHistory'] is List) {
            List<dynamic> workoutHistory = data['workoutHistory'];
            DateTime now = DateTime.now();
            DateTime thirtyDaysAgo = now.subtract(const Duration(days: 30));
            DateTime startOfMonth = DateTime(now.year, now.month, 1);

            List<bool> workoutDays = List.generate(30, (index) => false);
            int workoutsThisMonth = 0;
            Set<String> workoutDateStrings = {};

            // Process workout history
            for (var workoutEntry in workoutHistory) {
              if (workoutEntry is Map<String, dynamic> && workoutEntry.containsKey('date')) {
                DateTime workoutDate = (workoutEntry['date'] as Timestamp).toDate();
                String dateString = DateFormat('yyyy-MM-dd').format(workoutDate);
                workoutDateStrings.add(dateString);

                if (workoutDate.isAfter(startOfMonth)) {
                  workoutsThisMonth++;
                }

                if (workoutDate.isAfter(thirtyDaysAgo)) {
                  int daysAgo = now.difference(workoutDate).inDays;
                  if (daysAgo < 30) {
                    workoutDays[29 - daysAgo] = true;
                  }
                }
              }
            }

            // Calculate streaks
            int streak = _calculateCurrentStreak(workoutDateStrings);
            int longestStreak = _calculateLongestStreak(workoutDateStrings);

            // Calculate strikes
            int strikes = await _calculateStrikes(workoutDateStrings);

            String longestStreakText = "Longest: $longestStreak ${longestStreak == 1 ? 'week' : 'weeks'}";

            if (mounted) {
              setState(() {
                _workoutDays = workoutDays;
                _currentStreak = streak;
                _longestStreakText = longestStreakText;
                _completedWorkoutsThisMonth = workoutsThisMonth;
                _strikes = strikes;
                _isLoading = false;
              });

              // Update strikes in Firestore
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .update({'strikes': strikes});
            }
          } else {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          }
        } else {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      } catch (e) {
        print('Error loading workout streak: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Calculate current streak based on weekly workout goals
  int _calculateCurrentStreak(Set<String> workoutDates) {
    if (workoutDates.isEmpty || _weeklyWorkoutGoal == 0) return 0;

    // Get current date and find the start of the most recently completed week
    DateTime now = DateTime.now();

    // Find the start of the current week (Sunday)
    DateTime startOfCurrentWeek = now.subtract(Duration(days: now.weekday % 7));

    // Sort all workout dates in descending order (most recent first)
    List<DateTime> sortedDates = workoutDates
        .map((dateStr) => DateTime.parse(dateStr))
        .toList()
      ..sort((a, b) => b.compareTo(a));

    // Group workouts by week
    Map<String, List<DateTime>> workoutsByWeek = {};

    for (DateTime date in sortedDates) {
      // Find the start of the week for this workout (Sunday)
      DateTime weekStart = date.subtract(Duration(days: date.weekday % 7));
      String weekKey = DateFormat('yyyy-MM-dd').format(weekStart);

      if (!workoutsByWeek.containsKey(weekKey)) {
        workoutsByWeek[weekKey] = [];
      }
      workoutsByWeek[weekKey]!.add(date);
    }

    // Get completed weeks in descending order (most recent first)
    List<String> completedWeeks = workoutsByWeek.keys
        .where((weekKey) {
      DateTime weekStart = DateTime.parse(weekKey);
      // Only include weeks that have fully completed (not current week)
      return weekStart.isBefore(startOfCurrentWeek);
    })
        .toList()
      ..sort((a, b) => b.compareTo(a));

    // Calculate streak
    int streak = 0;
    DateTime? lastWeekStart;

    for (String weekKey in completedWeeks) {
      DateTime weekStart = DateTime.parse(weekKey);
      List<DateTime> workouts = workoutsByWeek[weekKey]!;

      // Check if this week met the goal
      if (workouts.length >= _weeklyWorkoutGoal) {
        // For the first week in our counting
        if (lastWeekStart == null) {
          streak = 1;
          lastWeekStart = weekStart;
          continue;
        }

        // Check if weeks are consecutive
        int daysDifference = lastWeekStart.difference(weekStart).inDays;
        if (daysDifference == 7) {
          // Weeks are consecutive
          streak++;
          lastWeekStart = weekStart;
        } else {
          // Not consecutive, break the streak
          break;
        }
      } else {
        // Goal not met, streak ends
        break;
      }
    }

    // Special case: Check if current week has already met the goal (bonus!)
    String currentWeekKey = DateFormat('yyyy-MM-dd').format(startOfCurrentWeek);
    if (workoutsByWeek.containsKey(currentWeekKey) &&
        workoutsByWeek[currentWeekKey]!.length >= _weeklyWorkoutGoal) {
      // If there was no streak before and current week meets goal
      if (streak == 0) {
        streak = 1;
      }
      // If there was already a streak and this week is consecutive
      else if (lastWeekStart != null) {
        int daysDifference = startOfCurrentWeek.difference(lastWeekStart).inDays;
        if (daysDifference == 7) {
          streak++;
        }
      }
    }

    return streak;
  }

  // Count workouts in a specific date range
  int _countWorkoutsInDateRange(Set<String> workoutDates, DateTime start, DateTime end) {
    int count = 0;

    // Convert start and end to beginning/end of day to avoid time issues
    DateTime startDay = DateTime(start.year, start.month, start.day);
    DateTime endDay = DateTime(end.year, end.month, end.day, 23, 59, 59);

    for (String dateStr in workoutDates) {
      DateTime date = DateTime.parse(dateStr);
      if (date.isAfter(startDay.subtract(const Duration(seconds: 1))) &&
          date.isBefore(endDay.add(const Duration(seconds: 1)))) {
        count++;
      }
    }

    return count;
  }

  // Calculate longest streak
  int _calculateLongestStreak(Set<String> workoutDates) {
    if (workoutDates.isEmpty || _weeklyWorkoutGoal == 0) return 0;

    // Parse all workout dates
    List<DateTime> dates = workoutDates
        .map((dateStr) => DateTime.parse(dateStr))
        .toList();

    // Group workouts by week
    Map<String, List<DateTime>> workoutsByWeek = {};

    for (DateTime date in dates) {
      // Find the start of the week for this workout (Sunday)
      DateTime weekStart = date.subtract(Duration(days: date.weekday % 7));
      String weekKey = DateFormat('yyyy-MM-dd').format(weekStart);

      if (!workoutsByWeek.containsKey(weekKey)) {
        workoutsByWeek[weekKey] = [];
      }
      workoutsByWeek[weekKey]!.add(date);
    }

    // Get week keys in chronological order
    List<String> weekKeys = workoutsByWeek.keys.toList()..sort();

    int longestStreak = 0;
    int currentStreak = 0;
    DateTime? lastWeekStart;

    for (String weekKey in weekKeys) {
      DateTime weekStart = DateTime.parse(weekKey);
      List<DateTime> workouts = workoutsByWeek[weekKey]!;

      // Check if this week met the goal
      if (workouts.length >= _weeklyWorkoutGoal) {
        // For the first successful week
        if (lastWeekStart == null) {
          currentStreak = 1;
          lastWeekStart = weekStart;
          continue;
        }

        // Check if weeks are consecutive
        int daysDifference = weekStart.difference(lastWeekStart).inDays;
        if (daysDifference == 7) {
          // Weeks are consecutive
          currentStreak++;
          lastWeekStart = weekStart;
        } else {
          // Not consecutive, start a new streak
          longestStreak = longestStreak > currentStreak ? longestStreak : currentStreak;
          currentStreak = 1;
          lastWeekStart = weekStart;
        }
      } else {
        // Week didn't meet goal, reset streak
        longestStreak = longestStreak > currentStreak ? longestStreak : currentStreak;
        currentStreak = 0;
        lastWeekStart = null;
      }
    }
    // Check once more after loop completes
    longestStreak = longestStreak > currentStreak ? longestStreak : currentStreak;

    return longestStreak;
  }

  // Calculate strikes - weeks where user missed their goal or can't possibly reach it
  // Strikes reset each month or after reaching 3 strikes
  Future<int> _calculateStrikes(Set<String> workoutDates) async {
    if (_weeklyWorkoutGoal == 0) return 0;

    DateTime now = DateTime.now();
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;

    // Find the start of the current week (Sunday)
    DateTime startOfCurrentWeek = now.subtract(Duration(days: now.weekday % 7));

    // Find the end of the current week (Saturday)
    DateTime endOfCurrentWeek = startOfCurrentWeek.add(const Duration(days: 6));

    // Parse all workout dates
    List<DateTime> dates = workoutDates
        .map((dateStr) => DateTime.parse(dateStr))
        .toList();

    // Group workouts by week
    Map<String, List<DateTime>> workoutsByWeek = {};

    for (DateTime date in dates) {
      // Find the start of the week for this workout (Sunday)
      DateTime weekStart = date.subtract(Duration(days: date.weekday % 7));
      String weekKey = DateFormat('yyyy-MM-dd').format(weekStart);

      if (!workoutsByWeek.containsKey(weekKey)) {
        workoutsByWeek[weekKey] = [];
      }
      workoutsByWeek[weekKey]!.add(date);
    }

    // Check for last strike reset
    DateTime? lastStrikeReset;
    try {
      DocumentSnapshot userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userData.exists && userData.data() is Map<String, dynamic>) {
        Map<String, dynamic> data = userData.data() as Map<String, dynamic>;
        if (data.containsKey('lastStrikeReset')) {
          lastStrikeReset = (data['lastStrikeReset'] as Timestamp).toDate();
        }
      }
    } catch (e) {
      print('Error getting last strike reset: $e');
    }

    // If no record of last reset, or it was in a different month, reset strikes
    if (lastStrikeReset == null ||
        lastStrikeReset.month != now.month ||
        lastStrikeReset.year != now.year) {

      // Update the last reset timestamp
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'lastStrikeReset': Timestamp.fromDate(now)});
      } catch (e) {
        print('Error updating last strike reset: $e');
      }

      return 0; // Reset strikes to zero for new month
    }

    // Special handling for current week
    String currentWeekKey = DateFormat('yyyy-MM-dd').format(startOfCurrentWeek);
    int workoutsThisWeek = workoutsByWeek[currentWeekKey]?.length ?? 0;

    // Calculate days remaining in current week
    int daysRemainingThisWeek = endOfCurrentWeek.difference(now).inDays + 1;

    // Check if it's still possible to meet the goal this week
    int maximumPossibleWorkouts = workoutsThisWeek + daysRemainingThisWeek;
    bool canMeetGoalThisWeek = maximumPossibleWorkouts >= _weeklyWorkoutGoal;

    int strikes = 0;

    // If goal can't be met in current week, add a strike
    if (!canMeetGoalThisWeek) {
      strikes = 1;
    }

    // Check past 2 completed weeks
    for (int weekOffset = 1; weekOffset <= 2; weekOffset++) {
      DateTime pastWeekStart = startOfCurrentWeek.subtract(Duration(days: 7 * weekOffset));
      String weekKey = DateFormat('yyyy-MM-dd').format(pastWeekStart);

      int workoutsInPastWeek = workoutsByWeek[weekKey]?.length ?? 0;

      // Add strike if goal wasn't met
      if (workoutsInPastWeek < _weeklyWorkoutGoal) {
        strikes++;
        // Maximum of 3 strikes
        if (strikes >= 3) {
          // When strikes reach 3, record that they were "out" to track when to reset
          try {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .update({'lastStrikeOut': Timestamp.fromDate(now)});
          } catch (e) {
            print('Error updating last strike out: $e');
          }
          return 3;
        }
      } else {
        // Reset strikes if any week meets the goal
        return 0;
      }
    }

    return strikes;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: 0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildCalendarStrip(),
          const SizedBox(height: 12),
          _buildStrikesIndicator(),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: 0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      height: 160,
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD2EB50)),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    String progressText = "";
    if (_weeklyWorkoutGoal > 0) {
      // Find workouts this week
      DateTime now = DateTime.now();
      DateTime weekStart = now.subtract(Duration(days: now.weekday % 7));
      int workoutsThisWeek = _countWorkoutsInDateRange(
          _workoutDays.asMap().entries
              .where((entry) => entry.value)
              .map((entry) {
            DateTime date = DateTime.now().subtract(
                Duration(days: _workoutDays.length - 1 - entry.key));
            return DateFormat('yyyy-MM-dd').format(date);
          })
              .toSet(),
          weekStart,
          now);

      progressText = "$workoutsThisWeek/$_weeklyWorkoutGoal this week";
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            _buildStreakBadge(),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$_currentStreak ${_currentStreak == 1 ? 'Week' : 'Weeks'} Streak",
                  style: GoogleFonts.bebasNeue(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (progressText.isNotEmpty)
                  Text(
                    progressText,
                    style: GoogleFonts.bebasNeue(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
              ],
            ),
          ],
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            _longestStreakText,
            style: GoogleFonts.bebasNeue(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStreakBadge() {
    Color getStreakColor() {
      if (_currentStreak >= 4) return Colors.orange;
      if (_currentStreak >= 2) return Colors.orange.shade300;
      return Color(0xFFD2EB50);
    }

    IconData getStreakIcon() {
      if (_currentStreak >= 4) return Icons.whatshot;
      return Icons.local_fire_department;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: getStreakColor(),
        boxShadow: [
          BoxShadow(
            color: getStreakColor().withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        getStreakIcon(),
        color: Colors.white,
        size: 24,
      ),
    );
  }

  Widget _buildCalendarStrip() {
    return Container(
      height: 82,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: _workoutDays.length,
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 12),
        itemBuilder: (context, index) {
          DateTime date = DateTime.now().subtract(Duration(days: _workoutDays.length - 1 - index));
          bool isWorkoutDay = _workoutDays[index];
          bool isToday = index == _workoutDays.length - 1;
          bool isScheduledDay = _selectedWorkoutDays.contains(date.weekday % 7);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('E').format(date).substring(0, 1),
                  style: GoogleFonts.bebasNeue(
                    fontSize: 12,
                    color: isToday
                        ? Colors.black
                        : isScheduledDay
                        ? Color(0xFF78A92A)
                        : Colors.grey.shade600,
                    fontWeight: isScheduledDay ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isWorkoutDay
                        ? Color(0xFFD2EB50)
                        : isScheduledDay
                        ? Colors.grey.shade300
                        : Colors.grey.shade200,
                    shape: BoxShape.circle,
                    border: isToday
                        ? Border.all(color: Colors.black, width: 2)
                        : null,
                  ),
                  child: isWorkoutDay
                      ? Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
                const SizedBox(height: 4),
                Text(
                  date.day.toString(),
                  style: GoogleFonts.bebasNeue(
                    fontSize: 12,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStrikesIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Strikes: ",
          style: GoogleFonts.bebasNeue(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        Row(
          children: List.generate(3, (index) {
            bool isActive = index < _strikes;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Icon(
                Icons.close_rounded,
                color: isActive ? Colors.red.shade400 : Colors.grey.shade300,
                size: 18,
              ),
            );
          }),
        ),
        if (_strikes >= 3)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              "Reset needed!",
              style: GoogleFonts.bebasNeue(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade400,
              ),
            ),
          ),
      ],
    );
  }
}