// lib/models/food_log_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class FoodLog {
  final String id;
  final String foodName;
  final int calories;
  final String mealType;
  final Timestamp timestamp;
  
  // ✅ NEW: Nutrient Fields
  final int protein;
  final int carbs;
  final int fats;

  FoodLog({
    required this.id,
    required this.foodName,
    required this.calories,
    required this.mealType,
    required this.timestamp,
    this.protein = 0,
    this.carbs = 0,
    this.fats = 0,
  });

  factory FoodLog.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    return FoodLog(
      id: snapshot.id,
      foodName: data['foodName'] ?? 'Unknown Food',
      calories: data['calories'] ?? 0,
      mealType: data['mealType'] ?? 'Snack',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      protein: data['protein'] ?? 0,
      carbs: data['carbs'] ?? 0,
      fats: data['fats'] ?? 0,
    );
  }
}