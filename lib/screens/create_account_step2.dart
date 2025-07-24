import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateAccountStepTwoScreen extends StatefulWidget {
  const CreateAccountStepTwoScreen({super.key});

  @override
  State<CreateAccountStepTwoScreen> createState() => _CreateAccountStepTwoScreenState();
}

class _CreateAccountStepTwoScreenState extends State<CreateAccountStepTwoScreen> {
  DateTime? _birthday;
  double _weight = 70.0;
  double _height = 170.0;
  String _weightUnit = 'kg';
  String _heightUnit = 'cm';
  int _selectedGoalIndex = 0;
  int _duration = 1;
  bool _loading = false;

  File? _profileImage;
  String? _profileImageUrl;

  final List<String> goals = ['Lose Weight', 'Gain Muscle', 'Stay Fit'];
  final Color accent = const Color(0xFFF06500);

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _profileImage = File(picked.path);
      });
    }
  }

  Future<void> _uploadAndSaveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showError('User not logged in.');
      return;
    }

    setState(() => _loading = true);

    String? imageUrl;

    try {
      if (_profileImage != null) {
        final ref = FirebaseStorage.instance.ref().child('users/${user.uid}/profile.jpg');
        await ref.putFile(_profileImage!);
        imageUrl = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'birthday': Timestamp.fromDate(_birthday!),
        'weight': _weight,
        'weightUnit': _weightUnit,
        'height': _height,
        'heightUnit': _heightUnit,
        'goal': goals[_selectedGoalIndex],
        'durationMonths': _duration,
        if (imageUrl != null) 'profileImageUrl': imageUrl,
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pop(context); // go back to previous screen (e.g. navigation root)
      }
    } catch (e) {
      _showError('Error saving profile: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Finish Setup', style: GoogleFonts.exo(color: Colors.white)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[800],
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : (_profileImageUrl != null
                              ? NetworkImage(_profileImageUrl!)
                              : null) as ImageProvider?,
                      child: _profileImage == null && _profileImageUrl == null
                          ? const Icon(Icons.camera_alt, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildBirthdayPicker(),
                  _buildSlider("Weight", _weight, _weightUnit, (v) => _weight = v, ['kg', 'lb']),
                  _buildSlider("Height", _height, _heightUnit, (v) => _height = v, ['cm', 'in']),
                  _buildGoalPicker(),
                  _buildDurationPicker(),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      if (_birthday == null) {
                        _showError('Please select your birthday.');
                        return;
                      }
                      _uploadAndSaveProfile();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Save and Continue'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildBirthdayPicker() {
    return ListTile(
      title: Text(
        _birthday == null
            ? 'Select your birthday'
            : '${_birthday!.day}/${_birthday!.month}/${_birthday!.year}',
        style: const TextStyle(color: Colors.white),
      ),
      trailing: const Icon(Icons.calendar_today, color: Colors.white),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime(2000),
          firstDate: DateTime(1920),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: ThemeData.dark().copyWith(
                colorScheme: ColorScheme.dark(primary: accent),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) setState(() => _birthday = picked);
      },
    );
  }

  Widget _buildSlider(String label, double value, String unit, Function(double) onChanged,
      List<String> unitOptions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('$label ($unit)', style: GoogleFonts.exo(color: Colors.white)),
            const Spacer(),
            ToggleButtons(
              isSelected: unitOptions.map((e) => unit == e).toList(),
              onPressed: (i) {
                setState(() {
                  if (label == 'Weight') _weightUnit = unitOptions[i];
                  if (label == 'Height') _heightUnit = unitOptions[i];
                });
              },
              borderColor: Colors.grey,
              selectedBorderColor: accent,
              selectedColor: accent,
              color: Colors.grey,
              fillColor: Colors.transparent,
              children: unitOptions.map((e) => Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(e))).toList(),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.remove, color: accent),
              onPressed: () => setState(() => onChanged((value - 0.1).clamp(0.0, 999.0))),
            ),
            Expanded(
              child: Center(
                child: Text(value.toStringAsFixed(1), style: TextStyle(color: accent, fontSize: 24)),
              ),
            ),
            IconButton(
              icon: Icon(Icons.add, color: accent),
              onPressed: () => setState(() => onChanged((value + 0.1).clamp(0.0, 999.0))),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildGoalPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Goal', style: GoogleFonts.exo(color: Colors.white)),
        Slider(
          value: _selectedGoalIndex.toDouble(),
          min: 0,
          max: (goals.length - 1).toDouble(),
          divisions: goals.length - 1,
          onChanged: (val) => setState(() => _selectedGoalIndex = val.round()),
          activeColor: accent,
          label: goals[_selectedGoalIndex],
        ),
        Center(
          child: Text(goals[_selectedGoalIndex], style: const TextStyle(color: Colors.white)),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDurationPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Duration (months)', style: GoogleFonts.exo(color: Colors.white)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.remove_circle, color: accent),
              onPressed: () => setState(() {
                if (_duration > 1) _duration--;
              }),
            ),
            Text('$_duration', style: TextStyle(fontSize: 20, color: accent)),
            IconButton(
              icon: Icon(Icons.add_circle, color: accent),
              onPressed: () => setState(() => _duration++),
            ),
          ],
        ),
      ],
    );
  }
}
