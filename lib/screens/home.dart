// lib/screens/home.dart

import 'dart:async';
import 'package:arfit_app/models/workout_model.dart';
import 'package:arfit_app/screens/all_workouts.dart';
import 'package:arfit_app/screens/pose_detector_view.dart';
import 'package:arfit_app/screens/workout.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _username = 'Athlete';
  String? _profileImageUrl;
  bool _isLoading = true;

  StreamSubscription? _workoutSubscription;
  List<Workout> _allWorkouts = [];
  int _workoutsThisWeek = 0;
  String _timeTrained = "0s";

  @override
  void initState() {
    super.initState();
    _initializeHomeScreen();
  }

  @override
  void dispose() {
    _workoutSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeHomeScreen() async {
    setState(() => _isLoading = true);
    await _fetchUserData();
    _setupWorkoutListener();
    setState(() => _isLoading = false);
  }

  Future<void> _fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && mounted) {
          _username = doc.data()?['username'] ?? 'Athlete';
          _profileImageUrl = doc.data()?['profileImageUrl'];
        }
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    }
  }

  void _setupWorkoutListener() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final stream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('workouts')
        .orderBy('lastOpened', descending: true)
        .snapshots();

    _workoutSubscription = stream.listen((snapshot) {
      if (!mounted) return;

      _allWorkouts = snapshot.docs.map((doc) => Workout.fromSnapshot(doc)).toList();

      final oneWeekAgo = Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 7)));
      final weeklyCompletedWorkouts = _allWorkouts.where((workout) {
        return workout.lastCompleted != null && workout.lastCompleted!.compareTo(oneWeekAgo) >= 0;
      }).toList();

      _workoutsThisWeek = weeklyCompletedWorkouts.length;

      num totalSeconds = 0;
      for (var workout in weeklyCompletedWorkouts) {
        totalSeconds += workout.durationInSeconds;
      }
      _timeTrained = _formatTime(totalSeconds);

      setState(() {});
    });
  }

 void _promptForReps(BuildContext context, WorkoutType type) {
  // Use a state variable for the rep counter inside the dialog
  int targetReps = 10; 

  showDialog(
    context: context,
    builder: (context) {
      // Use a StatefulBuilder to allow the dialog's content to update
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Text('Set Target Reps', style: TextStyle(color: Colors.white)),
            
            // ✅ NEW: Stepper UI instead of a text field
            content: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle, color: Color(0xFFF06500), size: 36),
                  onPressed: () {
                    setState(() {
                      if (targetReps > 1) targetReps--;
                    });
                  },
                ),
                Text(
                  targetReps.toString(),
                  style: GoogleFonts.exo(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Color(0xFFF06500), size: 36),
                  onPressed: () {
                    setState(() {
                      targetReps++;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close the dialog
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PoseDetectorView(workoutType: type, targetReps: targetReps)),
                  );
                },
                child: const Text('Start', style: TextStyle(color: Colors.cyanAccent)),
              ),
            ],
          );
        },
      );
    },
  );
}

  Future<void> _startWorkout(BuildContext context, Workout workout) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance.collection('users').doc(user.uid).collection('workouts').doc(workout.id).update({'lastOpened': Timestamp.now()});
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WorkoutScreen(docId: workout.id, workout: workout)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFFF06500);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1216),
        title: _isLoading ? Text('Loading...', style: GoogleFonts.exo()) : Text('Welcome back, $_username', style: GoogleFonts.exo()),
        actions: [
          IconButton(
            onPressed: () async {
              await Navigator.pushNamed(context, '/profile');
              _fetchUserData();
            },
            icon: _profileImageUrl != null
                ? CircleAvatar(backgroundImage: NetworkImage(_profileImageUrl!))
                : const CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.person, color: Colors.white)),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: accent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWeeklySummary(_workoutsThisWeek, _timeTrained),
                  const SizedBox(height: 30),
                  
                  _allWorkouts.isNotEmpty
                     ? _buildContinueWorkout(context, _allWorkouts.first)
                     : _buildEmptyContinueWorkout(),
                     
                  const SizedBox(height: 30),
                  _buildArTrainingSection(context),
                  const SizedBox(height: 30),
                  _buildFavouriteWorkoutsSection(context),
                ],
              ),
            ),
    );
  }

  Widget _buildWeeklySummary(int workoutsThisWeek, String timeTrained) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Weekly Summary", style: GoogleFonts.exo(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF0E1216),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn("Workouts Done", workoutsThisWeek.toString()),
              Container(height: 50, width: 1, color: Colors.grey[800]),
              _buildStatColumn("Time Trained", timeTrained),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.exo(fontSize: 24, color: const Color(0xFFF06500), fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.exo(color: Colors.white70)),
      ],
    );
  }

  Widget _buildContinueWorkout(BuildContext context, Workout workout) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Continue Where You Left Off", style: GoogleFonts.exo(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Card(
          color: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(workout.name, style: GoogleFonts.exo(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                Text(
                  '${workout.sets} sets x ${workout.reps} reps ${workout.isBodyweight ? '(Bodyweight)' : '@ ${workout.weight} ${workout.weightUnit}'}',
                  style: GoogleFonts.exo(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _startWorkout(context, workout),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF06500),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('Start Workout', style: GoogleFonts.exo(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyContinueWorkout() {
     return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Start a Workout", style: GoogleFonts.exo(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Card(
          color: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
            child: Center(
              child: Text(
                "Go to the 'Workouts' tab to create your first workout plan!",
                textAlign: TextAlign.center,
                style: GoogleFonts.exo(color: Colors.white70, height: 1.5)
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildArTrainingSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("AR Form Tracking", style: GoogleFonts.exo(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text("Get real-time feedback on your form with our AI coach.", style: GoogleFonts.exo(color: Colors.white70)),
        const SizedBox(height: 16),
        SizedBox(
          height: 150,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildArCard(context, "Push-Ups", "assets/icons/pushup.png", () => _promptForReps(context, WorkoutType.pushups)),
              _buildArCard(context, "Squats", "assets/icons/squat.png", () => _promptForReps(context, WorkoutType.squats)),
              _buildArCard(context, "Bicep Curls", "assets/icons/bicep.png", () => _promptForReps(context, WorkoutType.bicepCurls)),
              _buildArCard(context, "Shoulder Press", "assets/icons/shoulder.png", () => _promptForReps(context, WorkoutType.shoulderPress)),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildArCard(BuildContext context, String title, String imagePath, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              height: 60,
              color: Colors.white,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.fitness_center, color: Colors.grey, size: 60);
              },
            ),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: GoogleFonts.exo(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildFavouriteWorkoutsSection(BuildContext context) {
    final favouriteWorkouts = _allWorkouts.where((w) => w.isFavourite).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Your Favourite Workouts", style: GoogleFonts.exo(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllWorkoutsScreen())),
              child: const Text("See All"),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (favouriteWorkouts.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              "Tap the star on a workout screen to add a favourite.",
              textAlign: TextAlign.center,
              style: GoogleFonts.exo(color: Colors.white70),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: favouriteWorkouts.length > 3 ? 3 : favouriteWorkouts.length,
            itemBuilder: (context, index) {
              final workout = favouriteWorkouts[index];
              return Card(
                color: const Color(0xFF1E1E1E),
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(workout.name, style: GoogleFonts.exo(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text('${workout.sets} sets x ${workout.reps} reps', style: GoogleFonts.exo(color: Colors.white70)),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                  onTap: () => _startWorkout(context, workout),
                ),
              );
            },
          ),
      ],
    );
  }
  
  String _formatTime(num seconds) {
    if (seconds == 0) return "0s";
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    final parts = [];
    if (h > 0) parts.add('${h}h');
    if (m > 0) parts.add('${m}m');
    if (s > 0) parts.add('${s.round()}s');
    return parts.join(' ');
  }
}