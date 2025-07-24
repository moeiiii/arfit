import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import 'edit_profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Color accent = const Color(0xFFF06500);

  Map<String, dynamic>? userData;
  bool _loading = true;
  String? _error;

  Future<void> _loadUserData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _error = "User not logged in";
          _loading = false;
        });
        return;
      }

      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        setState(() {
          _error = "No user data found";
          _loading = false;
        });
        return;
      }

      setState(() {
        userData = doc.data();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Failed to load data: $e";
        _loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '-';
    final date = timestamp.toDate();
    return "${date.day}/${date.month}/${date.year}";
  }

  String _formatNumber(dynamic number) {
    if (number == null) return '-';
    if (number is int) return number.toString();
    if (number is double) return number.toStringAsFixed(1);
    return number.toString();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.popUntil(context, (route) => route.isFirst);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text('Profile', style: GoogleFonts.exo(color: Colors.white)),
          backgroundColor: const Color(0xFF0E1216),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () async {
                final updated = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EditProfileScreen(userData: userData)),
                );
                if (updated == true) {
                  _loadUserData();
                }
              },
            )
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFF06500)))
            : _error != null
                ? Center(child: Text(_error!, style: GoogleFonts.exo(color: Colors.red)))
                : Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 10),
                        CircleAvatar(
                          radius: 45,
                          backgroundColor: accent,
                          backgroundImage: userData?['profileImageUrl'] != null
                              ? NetworkImage(userData!['profileImageUrl'])
                              : null,
                          child: userData?['profileImageUrl'] == null
                              ? Text(
                                  (userData?['username'] is String && (userData?['username'] as String).isNotEmpty)
                                      ? (userData?['username'] as String)[0].toUpperCase()
                                      : 'U',
                                  style: GoogleFonts.exo(color: Colors.white, fontSize: 30),
                                )
                              : null,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          userData?['username'] ?? 'Unknown',
                          style: GoogleFonts.exo(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 30),
                        _infoTile('Birthday', _formatDate(userData?['birthday'])),
                        _infoTile('Weight', "${_formatNumber(userData?['weight'])} ${userData?['weightUnit'] ?? ''}"),
                        _infoTile('Height', "${_formatNumber(userData?['height'])} ${userData?['heightUnit'] ?? ''}"),
                        _infoTile('Goal', userData?['goal'] ?? '-'),
                        _infoTile('Duration', "${userData?['durationMonths'] ?? '-'} months"),
                        const SizedBox(height: 30),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await FirebaseAuth.instance.signOut();
                            if (!mounted) return;
                            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false); // Adjust this
                          },
                          icon: const Icon(Icons.logout, color: Colors.white),
                          label: Text('Logout', style: GoogleFonts.exo(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _infoTile(String title, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.exo(color: Colors.white70, fontSize: 15),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.exo(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
