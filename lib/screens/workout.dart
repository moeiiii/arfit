// lib/screens/workout.dart

import 'dart:async';
import 'package:arfit_app/models/workout_model.dart';
import 'package:arfit_app/screens/pose_detector_view.dart';
import 'package:arfit_app/screens/tutorial.dart';
import 'package:arfit_app/screens/workout_tracking_selection_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WorkoutScreen extends StatefulWidget {
  final String docId;
  final Workout workout;

  const WorkoutScreen({
    super.key,
    required this.docId,
    required this.workout,
  });

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  late int reps;
  late int sets;
  late bool isFavourite;
  int completedSets = 0;
  late int restSeconds;

  Timer? _workoutTimer;
  int _elapsedSeconds = 0;
  bool _isWorkoutPaused = false;
  
  Timer? _restTimer;
  late int _restSecondsRemaining;
  bool _isResting = false;
  
  Duration _totalDuration = const Duration(minutes: 30);
  final List<String> _formTrackingExercises = ['push ups', 'squats', 'bicep curls', 'shoulder press'];

  @override
  void initState() {
    super.initState();
    reps = widget.workout.reps;
    sets = widget.workout.sets;
    isFavourite = widget.workout.isFavourite;
    restSeconds = widget.workout.restTime;
    _restSecondsRemaining = restSeconds;
    _startWorkoutTimer();
  }

  @override
  void dispose() {
    _workoutTimer?.cancel();
    _restTimer?.cancel();
    super.dispose();
  }

  void _startWorkoutTimer() {
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !_isWorkoutPaused) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
  }

  void _toggleWorkoutPause() {
    setState(() {
      _isWorkoutPaused = !_isWorkoutPaused;
    });
  }
  
  void _startRestTimer() {
    setState(() {
      _isResting = true;
      _restSecondsRemaining = restSeconds; 
    });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restSecondsRemaining > 0) {
        if (mounted) {
          setState(() {
            _restSecondsRemaining--;
          });
        }
      } else {
        _restTimer?.cancel();
        if (mounted) {
          setState(() {
            _isResting = false;
            _isWorkoutPaused = false;
          });
        }
      }
    });
  }

  void _logSet() {
    if (completedSets >= sets || _isResting) return;

    setState(() {
      completedSets++;
    });

    if (completedSets >= sets) {
      _workoutTimer?.cancel();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('workouts')
            .doc(widget.docId)
            .update({
          'lastCompleted': Timestamp.now(),
          'durationInSeconds': _elapsedSeconds,
        });
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text("Workout Complete!", style: GoogleFonts.exo(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text("Great job finishing all your sets.", style: GoogleFonts.exo(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
              },
              child: Text("Finish", style: GoogleFonts.exo(color: const Color(0xFFF06500))),
            ),
          ],
        ),
      );
    } else {
      _startRestTimer();
    }
  }

  // This method goes inside both _HomeScreenState and _WorkoutScreenState

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

  void _toggleFavourite() {
    setState(() {
      isFavourite = !isFavourite;
    });
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('workouts')
          .doc(widget.docId)
          .update({'isFavourite': isFavourite});
    }
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFFF06500);
    bool canTrackForm = _formTrackingExercises.contains(widget.workout.name.toLowerCase());
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Workout', style: GoogleFonts.exo()),
        actions: [
          IconButton(
            icon: Icon(
              isFavourite ? Icons.star : Icons.star_border,
              color: isFavourite ? accent : Colors.grey,
              size: 28,
            ),
            onPressed: _toggleFavourite,
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            Text(widget.workout.name, style: GoogleFonts.exo(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Reps: $reps', style: GoogleFonts.exo(fontSize: 24, color: Colors.white70)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Completed Sets: $completedSets/$sets', style: GoogleFonts.exo(fontSize: 18, color: Colors.white)),
                if (!widget.workout.isBodyweight)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(20)),
                    child: Text('Weight: ${widget.workout.weight} ${widget.workout.weightUnit}', style: GoogleFonts.exo(color: Colors.white)),
                  ),
              ],
            ),
            const SizedBox(height: 30),
            
            _isResting
                ? _buildRestTimerUI(accent)
                : _buildMainTimerUI(accent),

            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isResting || completedSets >= sets ? null : _logSet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  disabledBackgroundColor: Colors.grey[800],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _isResting ? 'Resting...' : (completedSets >= sets ? 'Workout Complete' : 'Log Completed Set'),
                  style: GoogleFonts.exo(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            const Spacer(),
            
            Row(
              children: [
                Expanded(child: _buildStepper(label: 'Reps', value: reps, onDecrement: () => setState(() { if (reps > 1) reps--; }), onIncrement: () => setState(() => reps++))),
                const SizedBox(width: 12),
                Expanded(child: _buildStepper(label: 'Sets', value: sets, onDecrement: () => setState(() { if (sets > 1) sets--; }), onIncrement: () => setState(() => sets++))),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStepper(
                    label: 'Time (min)',
                    value: _totalDuration.inMinutes,
                    onDecrement: () => setState(() { if (_totalDuration.inMinutes > 1) _totalDuration -= const Duration(minutes: 1); }),
                    onIncrement: () => setState(() => _totalDuration += const Duration(minutes: 1)),
                  ),
                ),
              ],
            ),
            const Spacer(),
            
            if (canTrackForm)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: ElevatedButton.icon(
                  onPressed: () {
                    WorkoutType workoutType;
                    switch (widget.workout.name.toLowerCase()) {
                      case 'push ups':
                        workoutType = WorkoutType.pushups;
                        break;
                      case 'squats':
                        workoutType = WorkoutType.squats;
                        break;
                      case 'bicep curls':
                        workoutType = WorkoutType.bicepCurls;
                        break;
                      case 'shoulder press':
                        workoutType = WorkoutType.shoulderPress;
                        break;
                      default:
                        return;
                    }
                    _promptForReps(context, workoutType);
                  },
                  icon: const Icon(Icons.camera),
                  label: Text('AR Form Tracking', style: GoogleFonts.exo(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFF1E1E1E),
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TutorialScreen(exerciseName: widget.workout.name))),
              child: Text('Watch Tutorial Video', style: GoogleFonts.exo(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: accent.withOpacity(0.8),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMainTimerUI(Color accent) {
    final double progress = _totalDuration.inSeconds > 0 ? _elapsedSeconds / _totalDuration.inSeconds : 0.0;
    return Column(
      children: [
        LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: Colors.grey[800],
          color: accent,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_formatDuration(_elapsedSeconds), style: GoogleFonts.exo(color: Colors.white70)),
            Text(
              '${_totalDuration.inHours.toString().padLeft(2, '0')}:${(_totalDuration.inMinutes % 60).toString().padLeft(2, '0')}',
              style: GoogleFonts.exo(color: Colors.white70),
            ),
          ],
        ),
        const SizedBox(height: 10),
        IconButton(
          onPressed: _toggleWorkoutPause,
          icon: Icon(_isWorkoutPaused ? Icons.play_circle_filled : Icons.pause_circle_filled, color: Colors.white, size: 48),
        ),
      ],
    );
  }

  Widget _buildRestTimerUI(Color accent) {
    return Column(
      children: [
        Text("REST", style: GoogleFonts.exo(color: accent, fontSize: 18, letterSpacing: 3, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          _formatDuration(_restSecondsRemaining),
          style: GoogleFonts.exo(color: accent, fontSize: 48, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 120,
          child: TextButton(
            onPressed: () {
              _restTimer?.cancel();
              setState(() {
                _isResting = false;
                _isWorkoutPaused = false;
              });
            },
            child: Text('Skip Rest', style: GoogleFonts.exo(color: Colors.grey)),
          ),
        )
      ],
    );
  }

  Widget _buildStepper({required String label, required int value, required VoidCallback onDecrement, required VoidCallback onIncrement}) {
    final accent = const Color(0xFFF06500);
    final panelColor = const Color(0xFF1E1E1E);

    return Column(
      children: [
        Text(label, style: GoogleFonts.exo(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: panelColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact, icon: Icon(Icons.remove, color: accent, size: 20), onPressed: onDecrement),
              SizedBox(
                width: 30,
                child: Text(
                  value.toString(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.exo(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact, icon: Icon(Icons.add, color: accent, size: 20), onPressed: onIncrement),
            ],
          ),
        ),
      ],
    );
  }
}