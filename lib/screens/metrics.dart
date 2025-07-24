// lib/screens/metrics.dart

import 'package:arfit_app/models/workout_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class MetricsScreen extends StatelessWidget {
  const MetricsScreen({super.key});

  Future<List<Workout>> _fetchWorkoutData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('workouts')
        .where('lastCompleted', isNotEqualTo: null)
        .orderBy('lastCompleted', descending: true)
        .get();

    return snapshot.docs.map((doc) => Workout.fromSnapshot(doc)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final panelColor = const Color(0xFF0E1216);
    final accent = const Color(0xFFF06500);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Your Metrics', style: GoogleFonts.exo()),
        backgroundColor: panelColor,
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<List<Workout>>(
        future: _fetchWorkoutData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: accent));
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                "No completed workouts yet.\nGo finish a workout to see your stats!",
                textAlign: TextAlign.center,
                style: GoogleFonts.exo(color: Colors.white70, fontSize: 18),
              ),
            );
          }

          final workouts = snapshot.data!;
          return _buildMetricsDashboard(context, workouts, accent, panelColor);
        },
      ),
    );
  }

  Widget _buildMetricsDashboard(BuildContext context, List<Workout> workouts, Color accent, Color panelColor) {
    num totalSeconds = 0;
    for (var workout in workouts) {
      totalSeconds += workout.durationInSeconds;
    }
    String totalTimeTrained = '${(totalSeconds ~/ 3600)}h ${((totalSeconds % 3600) ~/ 60)}m';

    final weeklyData = _prepareWeeklyChartData(workouts);
    final typeData = _prepareTypePieChartData(workouts);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("All-Time Stats", style: GoogleFonts.exo(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard("Workouts Done", workouts.length.toString(), Icons.fitness_center, accent)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard("Total Time", totalTimeTrained, Icons.timer, accent)),
            ],
          ),
          const SizedBox(height: 30),
          Text("Manual Tracking", style: GoogleFonts.exo(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildNavigationCard(context, label: 'Body Weight', icon: Icons.monitor_weight, routeName: '/body-weight')),
              const SizedBox(width: 16),
              Expanded(child: _buildNavigationCard(context, label: 'Calorie Intake', icon: Icons.local_fire_department, routeName: '/calories')),
            ],
          ),
          const SizedBox(height: 30),
          Text("Weekly Activity", style: GoogleFonts.exo(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildWeeklyChart(weeklyData, accent, panelColor),
          const SizedBox(height: 30),
          Text("Workout Breakdown", style: GoogleFonts.exo(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildTypePieChart(typeData, panelColor),
          const SizedBox(height: 30),
          Text("History", style: GoogleFonts.exo(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildHistoryList(workouts, panelColor),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color accent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF0E1216), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 28),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.exo(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
          Text(label, style: GoogleFonts.exo(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildNavigationCard(BuildContext context, {required String label, required IconData icon, required String routeName}) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, routeName),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(label, style: GoogleFonts.exo(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
  
  Map<int, int> _prepareWeeklyChartData(List<Workout> workouts) {
    final Map<int, int> data = { for (int i = 0; i < 7; i++) i: 0 };
    final now = DateTime.now();
    
    for (var workout in workouts) {
      if (workout.lastCompleted != null) {
        final completedDate = workout.lastCompleted!.toDate();
        final differenceInDays = now.difference(completedDate).inDays;
        
        if (differenceInDays >= 0 && differenceInDays < 7) {
          final dayOfWeek = completedDate.weekday; // Monday is 1, Sunday is 7
          data[dayOfWeek - 1] = (data[dayOfWeek - 1] ?? 0) + 1;
        }
      }
    }
    return data;
  }

  Widget _buildWeeklyChart(Map<int, int> weeklyData, Color accent, Color panelColor) {
     final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
     return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      decoration: BoxDecoration(color: panelColor, borderRadius: BorderRadius.circular(12)),
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return SideTitleWidget(axisSide: meta.axisSide, child: Text(days[value.toInt()], style: GoogleFonts.exo(color: Colors.grey)));
                },
                reservedSize: 24,
              ),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: weeklyData.entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [BarChartRodData(toY: entry.value.toDouble(), color: accent, width: 18, borderRadius: BorderRadius.circular(4))],
            );
          }).toList(),
        ),
      ),
    );
  }

  Map<String, double> _prepareTypePieChartData(List<Workout> workouts) {
    final Map<String, double> data = {};
    for (var workout in workouts) {
      data[workout.workoutType] = (data[workout.workoutType] ?? 0) + 1;
    }
    return data;
  }

  Widget _buildTypePieChart(Map<String, double> typeData, Color panelColor) {
    final List<Color> colors = [
      const Color(0xFFF06500),
      Colors.cyan.shade600,
      Colors.pink.shade400,
      Colors.greenAccent.shade400,
      Colors.amber.shade600,
    ];
    int colorIndex = 0;
    
    if (typeData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: panelColor, borderRadius: BorderRadius.circular(12)),
        height: 200,
        child: Center(child: Text("Complete workouts to see breakdown.", style: GoogleFonts.exo(color: Colors.white70))),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: panelColor, borderRadius: BorderRadius.circular(12)),
      height: 200,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: PieChart(
              PieChartData(
                sections: typeData.entries.map((entry) {
                  final color = colors[colorIndex % colors.length];
                  colorIndex++;
                  return PieChartSectionData(
                    value: entry.value,
                    title: '${entry.value.toInt()}',
                    color: color,
                    radius: 60,
                    titleStyle: GoogleFonts.exo(fontWeight: FontWeight.bold, color: Colors.black),
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: typeData.keys.map((type) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(children: [
                    Container(width: 12, height: 12, color: colors[typeData.keys.toList().indexOf(type) % colors.length]),
                    const SizedBox(width: 8),
                    Text(type, style: GoogleFonts.exo(color: Colors.white)),
                  ]),
                );
              }).toList(),
            ),
          )
        ],
      ),
    );
  }
  
  Map<String, List<Workout>> _groupWorkoutsByDate(List<Workout> workouts) {
    final Map<String, List<Workout>> groupedWorkouts = {};
    for (var workout in workouts) {
      if (workout.lastCompleted != null) {
        final date = workout.lastCompleted!.toDate();
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final yesterday = DateTime(now.year, now.month, now.day - 1);
        
        String dayKey;
        if (date.year == today.year && date.month == today.month && date.day == today.day) {
          dayKey = 'Today';
        } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
          dayKey = 'Yesterday';
        } else {
          dayKey = DateFormat('MMMM d, yyyy').format(date);
        }

        if (groupedWorkouts[dayKey] == null) {
          groupedWorkouts[dayKey] = [];
        }
        groupedWorkouts[dayKey]!.add(workout);
      }
    }
    return groupedWorkouts;
  }

  Widget _buildHistoryList(List<Workout> workouts, Color panelColor) {
    final groupedWorkouts = _groupWorkoutsByDate(workouts);
    final dateKeys = groupedWorkouts.keys.toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: dateKeys.length,
      itemBuilder: (context, index) {
        final dateKey = dateKeys[index];
        final workoutsForDay = groupedWorkouts[dateKey]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
              child: Text(
                dateKey,
                style: GoogleFonts.exo(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            ...workoutsForDay.map((workout) {
              return Card(
                color: panelColor,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(workout.name, style: GoogleFonts.exo(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${workout.sets} sets x ${workout.reps} reps',
                    style: GoogleFonts.exo(color: Colors.grey[400]),
                  ),
                  trailing: Text(
                    DateFormat('h:mm a').format(workout.lastCompleted!.toDate()),
                    style: GoogleFonts.exo(color: Colors.grey[400]),
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }
}