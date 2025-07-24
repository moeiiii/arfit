// lib/screens/all_workouts.dart

import 'package:arfit_app/models/workout_model.dart';
import 'package:arfit_app/screens/add_workout.dart';
import 'package:arfit_app/screens/edit_workout.dart';
import 'package:arfit_app/screens/workout.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AllWorkoutsScreen extends StatefulWidget {
  const AllWorkoutsScreen({super.key});

  @override
  State<AllWorkoutsScreen> createState() => _AllWorkoutsScreenState();
}

class _AllWorkoutsScreenState extends State<AllWorkoutsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final panelColor = const Color(0xFF0E1216);
    final accent = const Color(0xFFF06500);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('My Workouts', style: GoogleFonts.exo()),
        backgroundColor: panelColor,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search workouts...',
                hintStyle: const TextStyle(color: Color(0xFFA1A1AA)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFFA1A1AA)),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: user == null
          ? const Center(child: Text("Please log in."))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('workouts')
                  .orderBy('name')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: accent));
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      "No workouts yet. Tap '+' to add one!",
                      style: GoogleFonts.exo(color: Colors.white70, fontSize: 18),
                    ),
                  );
                }

                final workoutDocs = snapshot.data!.docs.where((doc) {
                  final workoutName = doc.data()['name'].toString().toLowerCase();
                  return workoutName.contains(_searchQuery);
                }).toList();

                if (workoutDocs.isEmpty && _searchQuery.isNotEmpty) {
                  return Center(
                    child: Text(
                      "No workouts found for '$_searchQuery'",
                      style: GoogleFonts.exo(color: Colors.white70, fontSize: 18),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: workoutDocs.length,
                  itemBuilder: (context, index) {
                    final doc = workoutDocs[index];
                    final workout = Workout.fromSnapshot(doc);

                    return Dismissible(
                      key: Key(workout.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) async {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .collection('workouts')
                            .doc(workout.id)
                            .delete();
                        ScaffoldMessenger.of(context)
                          ..removeCurrentSnackBar()
                          ..showSnackBar(SnackBar(
                            content: Text('${workout.name} deleted.'),
                            backgroundColor: Colors.red,
                          ));
                      },
                      background: Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        alignment: Alignment.centerRight,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: Card(
                        color: panelColor,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
                          title: Text(workout.name, style: GoogleFonts.exo(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            '${workout.sets} sets x ${workout.reps} reps',
                            style: GoogleFonts.exo(color: const Color(0xFFA1A1AA)),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.edit, color: Colors.grey[400]),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditWorkoutScreen(workout: workout),
                                ),
                              );
                            },
                          ),
                          onTap: () {
                             Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => WorkoutScreen(
                                    docId: workout.id,
                                    workout: workout,
                                  ),
                                ),
                              );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddWorkoutScreen()),
          );
        },
        backgroundColor: accent,
        child: const Icon(Icons.add),
      ),
    );
  }
}