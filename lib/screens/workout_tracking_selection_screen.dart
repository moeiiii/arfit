// workout_tracking_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pose_detector_view.dart'; // Import your PoseDetectorView

class WorkoutTrackingSelectionScreen extends StatelessWidget {
  const WorkoutTrackingSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final panelColor = const Color(0xFF0E1216);
    final accent = const Color(0xFFF06500);

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        title: Text('Select Exercise to Track', style: GoogleFonts.exo()),
        backgroundColor: panelColor,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Choose an exercise to track:',
                style: GoogleFonts.exo(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              _buildTrackingButton(context, 'Push-Ups', WorkoutType.pushups, accent),
              const SizedBox(height: 15),
              _buildTrackingButton(context, 'Bicep Curls', WorkoutType.bicepCurls, accent),
              const SizedBox(height: 15),
              _buildTrackingButton(context, 'Shoulder Press', WorkoutType.shoulderPress, accent),
              const SizedBox(height: 15),
              _buildTrackingButton(context, 'Squats', WorkoutType.squats, accent),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // Go back to the previous workout detail screen
                },
                icon: const Icon(Icons.arrow_back),
                label: Text('Back to Workout Details', style: GoogleFonts.exo()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrackingButton(BuildContext context, String title, WorkoutType type, Color accentColor) {
    return SizedBox(
      width: double.infinity, // Make buttons fill width
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PoseDetectorView(workoutType: type),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.exo(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        child: Text(title),
      ),
    );
  }
}