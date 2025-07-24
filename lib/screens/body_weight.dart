import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BodyWeightScreen extends StatefulWidget {
  const BodyWeightScreen({super.key});

  @override
  State<BodyWeightScreen> createState() => _BodyWeightScreenState();
}

class _BodyWeightScreenState extends State<BodyWeightScreen> {
  final Color accent = const Color(0xFFF06500);
  final Color background = Colors.black;
  final Color panel = const Color(0xFF0E1216);
  final textColor = Colors.white;
  

  final user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  List<double> weightData = [];
  List<DateTime> dateData = [];

  double? goalWeight;
  DateTime goalDate = DateTime.now().add(const Duration(days: 90));
  final TextEditingController weightController = TextEditingController();
  final TextEditingController goalWeightController = TextEditingController();

  static const int maxVisiblePoints = 7;
  int currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }
Future<void> _loadData() async {
  if (user == null) return;

  final goalDoc = await firestore.collection('weights').doc(user!.uid).get();
  if (goalDoc.exists) {
    final data = goalDoc.data()!;
    final rawGoalDate = data['goalDate'];

    setState(() {
      goalWeight = (data['goalWeight'] as num?)?.toDouble();

      if (rawGoalDate is Timestamp) {
        goalDate = rawGoalDate.toDate();
      } else if (rawGoalDate is String) {
        goalDate = DateTime.tryParse(rawGoalDate) ?? goalDate;
      }
    });
  }

  final entries = await firestore
      .collection('weights')
      .doc(user!.uid)
      .collection('entries')
      .orderBy('date')
      .get();

  final weights = <double>[];
  final dates = <DateTime>[];

  for (var entry in entries.docs) {
    weights.add((entry['weight'] as num).toDouble());
    dates.add((entry['date'] as Timestamp).toDate());
  }

  setState(() {
    weightData = weights;
    dateData = dates;
    currentPage = ((weightData.length - 1) / maxVisiblePoints).floor().clamp(0, double.infinity).toInt();

  });
}

void _addWeight() async {
  final input = double.tryParse(weightController.text);
  if (input != null && user != null) {
    final timestamp = DateTime.now();

    setState(() {
      weightData.add(input);
      dateData.add(timestamp);
      weightController.clear();
      if (weightData.length % maxVisiblePoints == 1 && weightData.length > maxVisiblePoints) {
        currentPage++;
      }
    });

    await firestore
        .collection('weights')
        .doc(user!.uid)
        .collection('entries')
        .add({'weight': input, 'date': timestamp});

    // Check if goal is reached
    if (goalWeight != null) {
      final start = weightData.first;
      final current = input;
      final totalChange = goalWeight! - start;
      final currentChange = current - start;

      // Detect if goal direction matched
      final goalReached = (totalChange >= 0 && current >= goalWeight!) ||
          (totalChange < 0 && current <= goalWeight!);

      if (goalReached) {
        _showGoalAchievedDialog();
      }
    }
  }
}
void _showGoalAchievedDialog() {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        backgroundColor: panel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events, size: 64, color: Colors.amber),
              const SizedBox(height: 16),
              Text(
                "Congratulations!",
                style: GoogleFonts.exo(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                "You've hit your goal of ${goalWeight!.toStringAsFixed(1)}kg!",
                style: GoogleFonts.exo(color: Colors.grey, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  minimumSize: const Size.fromHeight(40),
                ),
                icon: const Icon(Icons.flag, color: Colors.white),
                label: Text("Set New Goal", style: GoogleFonts.exo(color: Colors.white)),
                onPressed: () {
                  Navigator.pop(context);
                  _editGoalWeight();
                },
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Keep Current Goal", style: GoogleFonts.exo(color: Colors.grey)),
              )
            ],
          ),
        ),
      );
    },
  );
}


  void _editGoalDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: goalDate.isBefore(now) ? now : goalDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 730)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(primary: accent, surface: panel),
          ),
          child: child!,
        );
      },
    );
    if (selected != null && user != null) {
      setState(() => goalDate = selected);
      await firestore
          .collection('weights')
          .doc(user!.uid)
          .set({'goalDate': goalDate}, SetOptions(merge: true));
    }
  }

  void _editGoalWeight() {
    showDialog(
      context: context,
      builder: (context) {
        goalWeightController.text = goalWeight?.toStringAsFixed(1) ?? '';
        return AlertDialog(
          backgroundColor: panel,
          title: Text("Set Goal Weight", style: GoogleFonts.exo(color: Colors.white)),
          content: TextField(
            controller: goalWeightController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: "e.g. 70",
              hintStyle: TextStyle(color: Colors.grey),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final newGoal = double.tryParse(goalWeightController.text);
                if (newGoal != null && user != null) {
                  setState(() => goalWeight = newGoal);
                  await firestore
                      .collection('weights')
                      .doc(user!.uid)
                      .set({'goalWeight': goalWeight}, SetOptions(merge: true));
                  Navigator.pop(context);
                }
              },
              child: Text("Save", style: GoogleFonts.exo(color: accent)),
            )
          ],
        );
      },
    );
  }

  void _resetJourney() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: panel,
        title: Text("Reset Journey", style: GoogleFonts.exo(color: Colors.white)),
        content: Text("Are you sure you want to reset all progress?",
            style: GoogleFonts.exo(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel", style: GoogleFonts.exo(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Reset", style: GoogleFonts.exo(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true && user != null) {
      setState(() {
        weightData.clear();
        dateData.clear();
        goalWeight = null;
        goalDate = DateTime.now().add(const Duration(days: 90));
        currentPage = 0;
      });

      final entries = await firestore
          .collection('weights')
          .doc(user!.uid)
          .collection('entries')
          .get();

      for (var doc in entries.docs) {
        await doc.reference.delete();
      }

      await firestore.collection('weights').doc(user!.uid).delete();
    }
  }

  List<FlSpot> getWeightSpots() {
    int startIndex = currentPage * maxVisiblePoints;
    int endIndex = (startIndex + maxVisiblePoints).clamp(0, weightData.length);
    return List.generate(
      endIndex - startIndex,
      (i) => FlSpot(i.toDouble(), weightData[startIndex + i]),
    );
  }

  List<String> getDateLabels() {
    int startIndex = currentPage * maxVisiblePoints;
    int endIndex = (startIndex + maxVisiblePoints).clamp(0, dateData.length);
    return dateData
        .sublist(startIndex, endIndex)
        .map((d) => DateFormat.Md().format(d))
        .toList();
  }

  double getProgressPercent() {
    if (weightData.length < 2 || goalWeight == null) return 0.0;
    final start = weightData.first;
    final current = weightData.last;
    final totalChange = goalWeight! - start;
    final currentChange = current - start;
    if (totalChange == 0) return 1.0;
    return (currentChange / totalChange).clamp(0.0, 1.0).abs();
  }

  @override
  Widget build(BuildContext context) {
    final weightSpots = getWeightSpots();
    final dateLabels = getDateLabels();
    final daysLeft = goalDate.difference(DateTime.now()).inDays;
    final percent = getProgressPercent();

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: panel,
        title: Text("Body Weight", style: GoogleFonts.exo(color: textColor)),
        leading: const BackButton(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.restart_alt, color: Colors.orange), onPressed: _resetJourney),
          IconButton(icon: const Icon(Icons.flag, color: Colors.orange), onPressed: _editGoalWeight),
          IconButton(icon: const Icon(Icons.calendar_today, color: Colors.orange), onPressed: _editGoalDate),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: CircularPercentIndicator(
              radius: 80.0,
              lineWidth: 12.0,
              animation: true,
              percent: percent,
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("${(percent * 100).toInt()}%",
                      style: GoogleFonts.exo(fontSize: 20, color: accent, fontWeight: FontWeight.bold)),
                  Text("towards goal", style: GoogleFonts.exo(color: Colors.grey, fontSize: 12)),
                ],
              ),
              circularStrokeCap: CircularStrokeCap.round,
              progressColor: accent,
              backgroundColor: panel,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              daysLeft > 0 ? "$daysLeft days left to hit goal" : "Goal date passed",
              style: GoogleFonts.exo(color: Colors.redAccent, fontSize: 14),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                backgroundColor: background,
                lineBarsData: [
                  LineChartBarData(
                    spots: weightSpots,
                    isCurved: true,
                    color: accent,
                    belowBarData: BarAreaData(show: true, color: accent.withOpacity(0.15)),
                    dotData: FlDotData(show: true),
                    barWidth: 3,
                  )
                ],
                minX: 0,
                maxX: (weightSpots.length - 1).toDouble(),
                minY: weightSpots.isEmpty ? 0 : weightSpots.map((e) => e.y).reduce((a, b) => a < b ? a : b) - 5,
                maxY: weightSpots.isEmpty ? 100 : weightSpots.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 5,
                gridData: FlGridData(show: true, horizontalInterval: 10),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, _) {
                        int index = value.toInt();
                        if (index >= dateLabels.length) return const SizedBox.shrink();
                        return Text(
                          dateLabels[index],
                          style: GoogleFonts.exo(color: Colors.grey, fontSize: 10),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 10,
                      getTitlesWidget: (val, _) => Text(
                        '${val.toInt()}',
                        style: GoogleFonts.exo(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                extraLinesData: goalWeight != null
                    ? ExtraLinesData(horizontalLines: [
                        HorizontalLine(
                          y: goalWeight!,
                          color: Colors.redAccent,
                          strokeWidth: 2,
                          dashArray: [6, 3],
                          label: HorizontalLineLabel(
                            show: true,
                            labelResolver: (_) => 'Goal: ${goalWeight!.toInt()}kg',
                            style: GoogleFonts.exo(color: Colors.white),
                          ),
                        )
                      ])
                    : ExtraLinesData(),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: currentPage > 0 ? () => setState(() => currentPage--) : null,
                child: const Text("← Prev", style: TextStyle(color: Colors.white)),
              ),
              TextButton(
                onPressed: (currentPage + 1) * maxVisiblePoints < weightData.length
                    ? () => setState(() => currentPage++)
                    : null,
                child: const Text("Next →", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard("Current", weightData.isEmpty ? "--" : "${weightData.last.toStringAsFixed(1)}kg"),
              _buildStatCard("Start", weightData.isEmpty ? "--" : "${weightData.first.toStringAsFixed(1)}kg"),
              _buildStatCard("Goal", goalWeight != null ? "${goalWeight!.toStringAsFixed(1)}kg" : "--"),
            ],
          ),
          const SizedBox(height: 24),
          if (weightData.length >= 2) ..._buildWeeklyChanges(),
          const SizedBox(height: 24),
          Text("Log your current weight", style: GoogleFonts.exo(color: Colors.white, fontSize: 16)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: weightController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Enter weight (kg)",
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: panel,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: accent, shape: const CircleBorder()),
                onPressed: _addWeight,
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(title, style: GoogleFonts.exo(color: Colors.grey)),
          const SizedBox(height: 6),
          Text(value,
              style: GoogleFonts.exo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }

  List<Widget> _buildWeeklyChanges() {
    final List<Widget> widgets = [];
    final formatter = DateFormat.Md();

    final trimmedWeights = weightData;
    final trimmedDates = dateData;
    final int limit = (trimmedWeights.length - 1).clamp(0, 6);

    for (int i = trimmedWeights.length - limit; i < trimmedWeights.length; i++) {
      final change = (trimmedWeights[i] - trimmedWeights[i - 1]);
      final changeStr = change > 0 ? "+${change.toStringAsFixed(1)}kg" : "${change.toStringAsFixed(1)}kg";
      final date = formatter.format(trimmedDates[i]);

      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(date, style: GoogleFonts.exo(color: Colors.grey)),
              Text(
                changeStr,
                style: GoogleFonts.exo(
                  color: change > 0 ? Colors.redAccent : Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return [
      Text("Weekly Progress", style: GoogleFonts.exo(color: Colors.white, fontSize: 16)),
      const SizedBox(height: 8),
      ...widgets,
    ];
  }
}
