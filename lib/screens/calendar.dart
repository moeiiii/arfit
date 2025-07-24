// lib/screens/calendar.dart

import 'dart:collection';
import 'package:arfit_app/models/workout_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final ValueNotifier<List<Workout>> _selectedEvents;
  // A map to hold all workouts, grouped by date.
  LinkedHashMap<DateTime, List<Workout>> _events = LinkedHashMap();

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
    _fetchCompletedWorkouts();
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  // Fetches all completed workouts and groups them by date
  void _fetchCompletedWorkouts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('workouts')
        .where('lastCompleted', isNotEqualTo: null)
        .get();

    final Map<DateTime, List<Workout>> eventsMap = {};
    for (var doc in snapshot.docs) {
      final workout = Workout.fromSnapshot(doc);
      if (workout.lastCompleted != null) {
        final date = workout.lastCompleted!.toDate();
        // Normalize the date to ignore the time part
        final day = DateTime.utc(date.year, date.month, date.day);
        if (eventsMap[day] == null) {
          eventsMap[day] = [];
        }
        eventsMap[day]!.add(workout);
      }
    }

    setState(() {
      _events = LinkedHashMap(
        equals: isSameDay,
        hashCode: (key) => key.day * 1000000 + key.month * 10000 + key.year,
      )..addAll(eventsMap);
      // Refresh events for the currently selected day
      _selectedEvents.value = _getEventsForDay(_selectedDay!);
    });
  }

  List<Workout> _getEventsForDay(DateTime day) {
    // Retrieve events from our map for the given day
    return _events[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      _selectedEvents.value = _getEventsForDay(selectedDay);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFFF06500);
    final panelColor = const Color(0xFF0E1216);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Workout Calendar', style: GoogleFonts.exo()),
        backgroundColor: panelColor,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          TableCalendar<Workout>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: _onDaySelected,
            eventLoader: _getEventsForDay,
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              defaultTextStyle: const TextStyle(color: Colors.white),
              weekendTextStyle: const TextStyle(color: Colors.white),
              todayDecoration: BoxDecoration(
                color: accent.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextStyle: GoogleFonts.exo(color: Colors.white, fontSize: 18.0),
              leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.white),
              rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.white),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: GoogleFonts.exo(color: Colors.white70),
              weekendStyle: GoogleFonts.exo(color: Colors.white70),
            ),
          ),
          const SizedBox(height: 8.0),
          const Divider(color: Colors.grey),
          Expanded(
            child: ValueListenableBuilder<List<Workout>>(
              valueListenable: _selectedEvents,
              builder: (context, value, _) {
                if (value.isEmpty) {
                  return Center(
                    child: Text(
                      "No workouts completed on this day.",
                      style: GoogleFonts.exo(color: Colors.white70, fontSize: 16),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: value.length,
                  itemBuilder: (context, index) {
                    final workout = value[index];
                    return Card(
                      color: panelColor,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(workout.name, style: GoogleFonts.exo(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          '${workout.sets} sets x ${workout.reps} reps @ ${workout.weight} ${workout.weightUnit}',
                          style: GoogleFonts.exo(color: Colors.grey[400]),
                        ),
                        trailing: Text(
                          DateFormat('h:mm a').format(workout.lastCompleted!.toDate()),
                          style: GoogleFonts.exo(color: accent),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}