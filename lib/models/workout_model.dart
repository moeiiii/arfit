// lib/models/workout_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Workout {
  final String id;
  final String name;
  final String workoutType;
  final int sets;
  final int reps;
  final int weight;
  final String weightUnit;
  final bool isBodyweight;
  final int restTime; // ✅ NEW: Rest time in seconds
  final Timestamp? lastOpened;
  final bool isFavourite;
  final Timestamp? lastCompleted;
  final int durationInSeconds;

  Workout({
    required this.id,
    required this.name,
    this.workoutType = 'Strength',
    required this.sets,
    required this.reps,
    this.weight = 0,
    this.weightUnit = 'lbs',
    this.isBodyweight = false,
    this.restTime = 60, // ✅ Default value
    this.lastOpened,
    this.isFavourite = false,
    this.lastCompleted,
    this.durationInSeconds = 0,
  });

  factory Workout.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    return Workout(
      id: snapshot.id,
      name: data['name'] ?? '',
      workoutType: data['workoutType'] ?? 'Strength',
      sets: data['sets'] ?? 0,
      reps: data['reps'] ?? 0,
      weight: data['weight'] ?? 0,
      weightUnit: data['weightUnit'] ?? 'lbs',
      isBodyweight: data['isBodyweight'] ?? false,
      restTime: data['restTime'] ?? 60, // ✅ NEW
      lastOpened: data['lastOpened'] as Timestamp?,
      isFavourite: data['isFavourite'] ?? false,
      lastCompleted: data['lastCompleted'] as Timestamp?,
      durationInSeconds: data['durationInSeconds'] ?? 0,
    );
  }
}