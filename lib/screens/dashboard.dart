// lib/screens/dashboard.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home.dart';
import 'all_workouts.dart';
import 'calendar.dart';
import 'metrics.dart'; // Import the Metrics screen

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  // MODIFIED: The AR screen is removed, Metrics is added.
  final List<Widget> _pages = const [
    HomeScreen(),
    AllWorkoutsScreen(),
    MetricsScreen(),
    CalendarScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        backgroundColor: const Color(0xFF0E1216),
        selectedItemColor: const Color(0xFFF06500),
        unselectedItemColor: const Color(0xFFA1A1AA),
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Workouts'),
          // ✅ NEW: Replaced "AR Training" with "Metrics"
          BottomNavigationBarItem(
            icon: Icon(Icons.insights),
            label: 'Metrics',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Calendar'),
        ],
      ),
    );
  }
}