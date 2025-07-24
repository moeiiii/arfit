import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Workout Tracker',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          },
          child: const Text("Continue"),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Workout")),
      body: ListView(
        children: [
          ListTile(
            title: const Text("Squat"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CameraScreen(workout: 'Squat'),
                ),
              );
            },
          ),
          ListTile(
            title: const Text("Push-up"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CameraScreen(workout: 'Push-up'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class CameraScreen extends StatelessWidget {
  final String workout;

  const CameraScreen({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(workout)),
      body: Stack(
        children: [
          Container(color: Colors.black), // Placeholder for camera feed
          const FeedbackOverlay(message: 'Keep your back straight!'),
        ],
      ),
    );
  }
}

class FeedbackOverlay extends StatelessWidget {
  final String message;

  const FeedbackOverlay({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 30,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class WorkoutResultScreen extends StatelessWidget {
  final double score;

  const WorkoutResultScreen({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Workout Summary")),
      body: Center(
        child: Text(
          "Score: ${score.toStringAsFixed(1)}%",
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
