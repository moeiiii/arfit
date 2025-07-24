import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const EditProfileScreen({super.key, this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final Color accent = const Color(0xFFF06500);

  late TextEditingController _usernameController;
  DateTime? _birthday;
  double _weight = 70.0;
  double _height = 170.0;
  String _weightUnit = 'kg';
  String _heightUnit = 'cm';
  int _duration = 1;
  int _selectedGoalIndex = 0;

  final List<String> goals = ['Lose Weight', 'Gain Muscle', 'Stay Fit'];
  bool _loading = false;

  // 🌟 Image fields
  String? _profileImageUrl;
  Uint8List? _newImageBytes;

  @override
  void initState() {
    super.initState();
    final data = widget.userData;

    _usernameController = TextEditingController(text: data?['username'] ?? '');
    _birthday = (data?['birthday'] as Timestamp?)?.toDate();
    _weight = (data?['weight'] ?? 70.0).toDouble();
    _weightUnit = data?['weightUnit'] ?? 'kg';
    _height = (data?['height'] ?? 170.0).toDouble();
    _heightUnit = data?['heightUnit'] ?? 'cm';
    _duration = (data?['durationMonths'] ?? 1).toInt();
    _selectedGoalIndex = goals.indexOf(data?['goal'] ?? 'Stay Fit');
    if (_selectedGoalIndex == -1) _selectedGoalIndex = 0;

    _profileImageUrl = widget.userData?['profileImageUrl'];
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _newImageBytes = bytes;
      });
    }
  }

  Future<void> _saveChanges() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_birthday == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your birthday')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      String? downloadUrl;
      if (_newImageBytes != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('profile_pics')
            .child('${user.uid}.jpg');
        await ref.putData(_newImageBytes!);
        downloadUrl = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'username': _usernameController.text.trim(),
        'birthday': Timestamp.fromDate(_birthday!),
        'weight': _weight,
        'weightUnit': _weightUnit,
        'height': _height,
        'heightUnit': _heightUnit,
        'goal': goals[_selectedGoalIndex],
        'durationMonths': _duration,
        'profileImageUrl': downloadUrl ?? _profileImageUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
        Navigator.pop(context, true); // Return success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Edit Profile', style: GoogleFonts.exo()),
        backgroundColor: const Color(0xFF0E1216),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF06500)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // 📸 Profile Image Picker UI
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white10,
                      backgroundImage: _newImageBytes != null
                          ? MemoryImage(_newImageBytes!)
                          : (_profileImageUrl != null
                              ? NetworkImage(_profileImageUrl!)
                              : null) as ImageProvider?,
                      child: _newImageBytes == null && _profileImageUrl == null
                          ? Icon(Icons.add_a_photo, color: accent, size: 30)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _textField('Username', _usernameController),
                  const SizedBox(height: 20),
                  _sectionTitle('Birthday'),
                  ListTile(
                    title: Text(
                      _birthday == null
                          ? 'Select your birthday'
                          : "${_birthday!.day}/${_birthday!.month}/${_birthday!.year}",
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: const Icon(Icons.calendar_today, color: Colors.white),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _birthday ?? DateTime(2000),
                        firstDate: DateTime(1920),
                        lastDate: DateTime.now(),
                        builder: (context, child) => Theme(
                          data: ThemeData.dark().copyWith(
                            colorScheme: ColorScheme.dark(primary: accent),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) setState(() => _birthday = picked);
                    },
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle('Weight ($_weightUnit)'),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _weight,
                          min: 1,
                          max: 300,
                          onChanged: (val) => setState(() => _weight = val),
                          activeColor: accent,
                          label: _weight.toStringAsFixed(1),
                        ),
                      ),
                      Text(_weight.toStringAsFixed(1),
                          style: TextStyle(color: accent, fontSize: 16)),
                      const SizedBox(width: 10),
                      _unitToggle(['kg', 'lb'], _weightUnit, (val) {
                        setState(() => _weightUnit = val);
                      }),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle('Height ($_heightUnit)'),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _height,
                          min: 30,
                          max: 300,
                          onChanged: (val) => setState(() => _height = val),
                          activeColor: accent,
                          label: _height.toStringAsFixed(1),
                        ),
                      ),
                      Text(_height.toStringAsFixed(1),
                          style: TextStyle(color: accent, fontSize: 16)),
                      const SizedBox(width: 10),
                      _unitToggle(['cm', 'in'], _heightUnit, (val) {
                        setState(() => _heightUnit = val);
                      }),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle('Goal'),
                  Slider(
                    value: _selectedGoalIndex.toDouble(),
                    min: 0,
                    max: (goals.length - 1).toDouble(),
                    divisions: goals.length - 1,
                    label: goals[_selectedGoalIndex],
                    onChanged: (val) => setState(() => _selectedGoalIndex = val.round()),
                    activeColor: accent,
                  ),
                  Center(
                    child: Text(goals[_selectedGoalIndex],
                        style: GoogleFonts.exo(color: Colors.white)),
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle('Duration (months)'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove_circle, color: accent),
                        onPressed: () {
                          if (_duration > 1) setState(() => _duration--);
                        },
                      ),
                      Text(
                        '$_duration',
                        style: TextStyle(fontSize: 20, color: accent),
                      ),
                      IconButton(
                        icon: Icon(Icons.add_circle, color: accent),
                        onPressed: () => setState(() => _duration++),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Save Changes'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(title, style: GoogleFonts.exo(color: Colors.white70, fontSize: 16)),
    );
  }

  Widget _textField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.exo(color: Colors.white70),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white30),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFF06500)),
        ),
      ),
    );
  }

  Widget _unitToggle(List<String> options, String selected, Function(String) onChanged) {
    return ToggleButtons(
      isSelected: options.map((e) => e == selected).toList(),
      onPressed: (index) => onChanged(options[index]),
      borderColor: Colors.grey,
      selectedBorderColor: accent,
      selectedColor: accent,
      color: Colors.grey,
      fillColor: Colors.transparent,
      children: options.map((e) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(e),
      )).toList(),
    );
  }
}
