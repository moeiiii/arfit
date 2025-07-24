// lib/screens/calories.dart

import 'dart:async';
import 'package:arfit_app/models/food_log_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class CaloriesScreen extends StatefulWidget {
  const CaloriesScreen({super.key});

  @override
  State<CaloriesScreen> createState() => _CaloriesScreenState();
}

class _CaloriesScreenState extends State<CaloriesScreen> {
  DateTime _selectedDate = DateTime.now();
  
  int _dailyCalorieGoal = 2500;
  int _dailyProteinGoal = 180;
  int _dailyCarbsGoal = 300;
  int _dailyFatsGoal = 70;

  @override
  void initState() {
    super.initState();
    _fetchUserGoals();
  }

  Future<void> _fetchUserGoals() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists && mounted) {
      setState(() {
        _dailyCalorieGoal = doc.data()?['dailyCalorieGoal'] ?? 2500;
        _dailyProteinGoal = doc.data()?['dailyProteinGoal'] ?? 180;
        _dailyCarbsGoal = doc.data()?['dailyCarbsGoal'] ?? 300;
        _dailyFatsGoal = doc.data()?['dailyFatsGoal'] ?? 70;
      });
    }
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
  }

  void _showAddFoodDialog() {
    final formKey = GlobalKey<FormState>();
    final foodNameController = TextEditingController();
    final caloriesController = TextEditingController();
    final proteinController = TextEditingController();
    final carbsController = TextEditingController();
    final fatsController = TextEditingController();
    String mealType = 'Breakfast';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: Text('Log Food', style: GoogleFonts.exo(color: Colors.white)),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(controller: foodNameController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Food Name', labelStyle: TextStyle(color: Colors.grey)), validator: (v) => v!.isEmpty ? 'Required' : null),
                      TextFormField(controller: caloriesController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Calories (kcal)', labelStyle: TextStyle(color: Colors.grey)), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Required' : null),
                      TextFormField(controller: proteinController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Protein (g)', labelStyle: TextStyle(color: Colors.grey)), keyboardType: TextInputType.number),
                      TextFormField(controller: carbsController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Carbs (g)', labelStyle: TextStyle(color: Colors.grey)), keyboardType: TextInputType.number),
                      TextFormField(controller: fatsController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Fats (g)', labelStyle: TextStyle(color: Colors.grey)), keyboardType: TextInputType.number),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: mealType,
                        items: ['Breakfast', 'Lunch', 'Dinner', 'Snack'].map((String v) => DropdownMenuItem<String>(value: v, child: Text(v))).toList(),
                        onChanged: (v) => setDialogState(() => mealType = v!),
                        dropdownColor: const Color(0xFF1E1E1E),
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelStyle: TextStyle(color: Colors.grey)),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.exo(color: Colors.grey))),
                TextButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) return;
                      await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('food_logs').add({
                        'foodName': foodNameController.text,
                        'calories': int.tryParse(caloriesController.text) ?? 0,
                        'protein': int.tryParse(proteinController.text) ?? 0,
                        'carbs': int.tryParse(carbsController.text) ?? 0,
                        'fats': int.tryParse(fatsController.text) ?? 0,
                        'mealType': mealType,
                        'timestamp': Timestamp.fromDate(_selectedDate),
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: Text('Log', style: GoogleFonts.exo(color: const Color(0xFFF06500))),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ✅ UPDATED: Dialog now edits all goals
  void _showEditGoalDialog() {
    final calorieController = TextEditingController(text: _dailyCalorieGoal.toString());
    final proteinController = TextEditingController(text: _dailyProteinGoal.toString());
    final carbsController = TextEditingController(text: _dailyCarbsGoal.toString());
    final fatsController = TextEditingController(text: _dailyFatsGoal.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text('Set Daily Goals', style: GoogleFonts.exo(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: calorieController, style: const TextStyle(color: Colors.white), keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Calorie Goal (kcal)', labelStyle: TextStyle(color: Colors.grey))),
              const SizedBox(height: 16),
              TextField(controller: proteinController, style: const TextStyle(color: Colors.white), keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Protein Goal (g)', labelStyle: TextStyle(color: Colors.grey))),
              const SizedBox(height: 16),
              TextField(controller: carbsController, style: const TextStyle(color: Colors.white), keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Carbs Goal (g)', labelStyle: TextStyle(color: Colors.grey))),
              const SizedBox(height: 16),
              TextField(controller: fatsController, style: const TextStyle(color: Colors.white), keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Fats Goal (g)', labelStyle: TextStyle(color: Colors.grey))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.exo(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;
              
              await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                'dailyCalorieGoal': int.tryParse(calorieController.text) ?? _dailyCalorieGoal,
                'dailyProteinGoal': int.tryParse(proteinController.text) ?? _dailyProteinGoal,
                'dailyCarbsGoal': int.tryParse(carbsController.text) ?? _dailyCarbsGoal,
                'dailyFatsGoal': int.tryParse(fatsController.text) ?? _dailyFatsGoal,
              }, SetOptions(merge: true));
              
              Navigator.pop(context);
              _fetchUserGoals();
            },
            child: Text('Save', style: GoogleFonts.exo(color: const Color(0xFFF06500))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final panelColor = const Color(0xFF0E1216);
    final accent = const Color(0xFFF06500);
    final user = FirebaseAuth.instance.currentUser;

    final startOfDay = Timestamp.fromDate(DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day));
    final endOfDay = Timestamp.fromDate(DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Calorie Tracker', style: GoogleFonts.exo()),
        backgroundColor: panelColor,
      ),
      body: user == null
          ? const Center(child: Text("Please log in."))
          : Column(
              children: [
                Container(
                  color: panelColor,
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => _changeDate(-1)),
                      Text(DateFormat('MMMM d, yyyy').format(_selectedDate), style: GoogleFonts.exo(color: Colors.white, fontSize: 18)),
                      IconButton(icon: const Icon(Icons.arrow_forward_ios, color: Colors.white), onPressed: () => _changeDate(1)),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance.collection('users').doc(user.uid).collection('food_logs').where('timestamp', isGreaterThanOrEqualTo: startOfDay).where('timestamp', isLessThanOrEqualTo: endOfDay).snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator(color: accent));
                      }
                      final foodLogs = snapshot.data?.docs.map((doc) => FoodLog.fromSnapshot(doc)).toList() ?? [];
                      
                      final totalCalories = foodLogs.fold(0, (sum, item) => sum + item.calories);
                      final totalProtein = foodLogs.fold(0, (sum, item) => sum + item.protein);
                      final totalCarbs = foodLogs.fold(0, (sum, item) => sum + item.carbs);
                      final totalFats = foodLogs.fold(0, (sum, item) => sum + item.fats);
                      
                      final groupedLogs = <String, List<FoodLog>>{};
                      for (var log in foodLogs) {
                        (groupedLogs[log.mealType] ??= []).add(log);
                      }
                      final mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'].where((type) => groupedLogs.containsKey(type)).toList();

                      return ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildSummaryCard(totalCalories, totalProtein, totalCarbs, totalFats, accent, panelColor),
                          const SizedBox(height: 24),
                          ...mealTypes.map((mealType) {
                            return _buildMealSection(mealType, groupedLogs[mealType]!, panelColor);
                          }),
                           if (foodLogs.isEmpty) _buildEmptyState(),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFoodDialog,
        backgroundColor: accent,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 64.0),
      child: Center(
        child: Text(
          "No food logged for this day.\nTap '+' to add an entry.",
          textAlign: TextAlign.center,
          style: GoogleFonts.exo(color: Colors.white70, fontSize: 18),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(int totalCals, int totalP, int totalC, int totalF, Color accent, Color panelColor) {
    final calProgress = _dailyCalorieGoal > 0 ? totalCals / _dailyCalorieGoal : 0.0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: panelColor, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              CircularPercentIndicator(
                radius: 60.0,
                lineWidth: 12.0,
                percent: calProgress.clamp(0.0, 1.0),
                center: Text("$totalCals\n kcal", textAlign: TextAlign.center, style: GoogleFonts.exo(color: Colors.white, fontWeight: FontWeight.bold)),
                progressColor: accent,
                backgroundColor: Colors.grey.shade800,
                circularStrokeCap: CircularStrokeCap.round,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Consumed", style: GoogleFonts.exo(color: Colors.white70)),
                  Text("$totalCals kcal", style: GoogleFonts.exo(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text("Daily Goal", style: GoogleFonts.exo(color: Colors.white70)),
                  InkWell(
                    onTap: _showEditGoalDialog,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Text("$_dailyCalorieGoal kcal", style: GoogleFonts.exo(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Icon(Icons.edit, color: Colors.grey[600], size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(color: Colors.grey, height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNutrientStat("Protein", totalP, _dailyProteinGoal),
              _buildNutrientStat("Carbs", totalC, _dailyCarbsGoal),
              _buildNutrientStat("Fats", totalF, _dailyFatsGoal),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientStat(String name, int consumed, int goal) {
    return InkWell(
      onTap: _showEditGoalDialog,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(name, style: GoogleFonts.exo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text("$consumed / ${goal}g", style: GoogleFonts.exo(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _buildMealSection(String mealType, List<FoodLog> logs, Color panelColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(mealType, style: GoogleFonts.exo(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...logs.map((log) {
          return Card(
            color: panelColor,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(log.foodName, style: GoogleFonts.exo(color: Colors.white)),
              subtitle: Text('P: ${log.protein}g, C: ${log.carbs}g, F: ${log.fats}g', style: GoogleFonts.exo(color: Colors.grey[400])),
              trailing: Text("${log.calories} kcal", style: GoogleFonts.exo(color: const Color(0xFFF06500), fontWeight: FontWeight.bold)),
            ),
          );
        }),
        const SizedBox(height: 24),
      ],
    );
  }
}