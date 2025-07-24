// lib/screens/add_workout.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddWorkoutScreen extends StatefulWidget {
  const AddWorkoutScreen({super.key});

  @override
  State<AddWorkoutScreen> createState() => _AddWorkoutScreenState();
}

class _AddWorkoutScreenState extends State<AddWorkoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _setsController = TextEditingController();
  final _repsController = TextEditingController();
  final _weightController = TextEditingController();
  final _restTimeController = TextEditingController(text: '60'); // ✅ NEW
  bool _isLoading = false;

  String _workoutType = 'Strength';
  final List<String> _workoutTypes = ['Strength', 'Cardio', 'HIIT', 'Mobility', 'Calisthenics'];
  String _weightUnit = 'lbs';
  bool _isBodyweight = false;

  @override
  void dispose() {
    _nameController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _restTimeController.dispose(); // ✅ NEW
    super.dispose();
  }

  Future<void> _saveWorkout() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      final newWorkoutData = {
        'name': _nameController.text,
        'workoutType': _workoutType,
        'sets': int.tryParse(_setsController.text) ?? 0,
        'reps': int.tryParse(_repsController.text) ?? 0,
        'isBodyweight': _isBodyweight,
        'weight': _isBodyweight ? 0 : (int.tryParse(_weightController.text) ?? 0),
        'weightUnit': _isBodyweight ? '' : _weightUnit,
        'restTime': int.tryParse(_restTimeController.text) ?? 60, // ✅ NEW
        'createdAt': Timestamp.now(),
        'lastOpened': Timestamp.now(),
        'isFavourite': false,
        'lastCompleted': null,
        'durationInSeconds': 0,
      };

      await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('workouts').add(newWorkoutData);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save workout: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (UI Code remains largely the same, but with the new Rest Time field added)
    // Here is the full build method for clarity:
    final accent = const Color(0xFFF06500);
    final panelColor = const Color(0xFF0E1216);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Create New Workout', style: GoogleFonts.exo()),
        backgroundColor: panelColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTextFormField(controller: _nameController, labelText: 'Exercise Name'),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _workoutType,
                  items: _workoutTypes.map((String type) {
                    return DropdownMenuItem<String>(value: type, child: Text(type, style: GoogleFonts.exo()));
                  }).toList(),
                  onChanged: (newValue) => setState(() => _workoutType = newValue!),
                  decoration: _inputDecoration('Workout Type'),
                  dropdownColor: panelColor,
                  style: GoogleFonts.exo(color: Colors.white),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _buildTextFormField(controller: _setsController, labelText: 'Sets', keyboardType: TextInputType.number)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextFormField(controller: _repsController, labelText: 'Reps', keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 20),
                // ✅ NEW: Rest Time field
                _buildTextFormField(controller: _restTimeController, labelText: 'Rest Time (seconds)', keyboardType: TextInputType.number),
                const SizedBox(height: 10),
                CheckboxListTile(
                  title: Text('Bodyweight Exercise', style: GoogleFonts.exo(color: Colors.white)),
                  value: _isBodyweight,
                  onChanged: (value) => setState(() {
                    _isBodyweight = value ?? false;
                    if (_isBodyweight) _weightController.clear();
                  }),
                  activeColor: accent,
                  checkColor: Colors.black,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 10),
                if (!_isBodyweight)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildTextFormField(controller: _weightController, labelText: 'Weight', keyboardType: TextInputType.number, isEnabled: !_isBodyweight),
                      ),
                      const SizedBox(width: 10),
                      ToggleButtons(
                        isSelected: [_weightUnit == 'lbs', _weightUnit == 'kg'],
                        onPressed: (index) => setState(() => _weightUnit = index == 0 ? 'lbs' : 'kg'),
                        borderRadius: BorderRadius.circular(12),
                        selectedColor: Colors.black,
                        color: Colors.white,
                        fillColor: accent,
                        selectedBorderColor: accent,
                        borderColor: Colors.grey[700],
                        children: const [Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('lbs')), Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('kg'))],
                      ),
                    ],
                  ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveWorkout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('Save Workout', style: GoogleFonts.exo(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFFA1A1AA)),
      filled: true,
      fillColor: const Color(0xFF0E1216),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }

  Widget _buildTextFormField({required TextEditingController controller, required String labelText, TextInputType keyboardType = TextInputType.text, bool isEnabled = true}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: isEnabled,
      style: TextStyle(color: isEnabled ? Colors.white : Colors.grey[600]),
      decoration: _inputDecoration(labelText),
      validator: (value) {
        if (!isEnabled) return null;
        if (value == null || value.isEmpty) return 'Cannot be empty';
        if (keyboardType == TextInputType.number && int.tryParse(value) == null) return 'Invalid number';
        return null;
      },
    );
  }
}