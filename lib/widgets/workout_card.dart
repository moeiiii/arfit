import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WorkoutCard extends StatelessWidget {
  final String title;
  final String exercise;
  final String duration;
  final String reps;
  final String sets;
  final String buttonText;
  final VoidCallback onPressed;

  const WorkoutCard({
    super.key,
    required this.title,
    required this.exercise,
    required this.duration,
    required this.reps,
    required this.sets,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final panelColor = const Color(0xFF0E1216);
    final accent = const Color(0xFFF06500);
    final textColor = Colors.white;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.exo(
                  fontSize: 18, fontWeight: FontWeight.bold, color: accent)),
          const SizedBox(height: 10),
          Text('Exercise: $exercise',
              style: GoogleFonts.exo(fontSize: 16, color: textColor)),
          Text('Duration: $duration',
              style: GoogleFonts.exo(fontSize: 16, color: textColor)),
          Text('Reps: $reps', style: GoogleFonts.exo(fontSize: 16, color: textColor)),
          Text('Sets: $sets', style: GoogleFonts.exo(fontSize: 16, color: textColor)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPressed,
              child: Text(buttonText),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
