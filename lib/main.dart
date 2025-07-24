import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
// Theme and services
import 'theme/app_theme.dart';
import 'widgets/auth_service.dart';
// Screens
import 'screens/splash.dart';
import 'screens/login.dart';
import 'screens/create_account.dart';
import 'screens/create_account_step2.dart';
import 'screens/dashboard.dart';
import 'screens/home.dart';
import 'screens/profile.dart';
import 'screens/all_workouts.dart';
import 'screens/add_workout.dart';
import 'screens/calendar.dart';
import 'screens/metrics.dart';
import 'screens/body_weight.dart';
import 'screens/calories.dart';
import 'screens/workout.dart';
import 'screens/tutorial.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ArFitApp());
}

class ArFitApp extends StatelessWidget {
  const ArFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(create: (_) => AuthService()),
        StreamProvider<User?>(
          create: (_) => FirebaseAuth.instance.authStateChanges(),
          initialData: null,
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ArFIT',
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/create-account': (context) => const CreateAccountScreen(),
          '/create-account-step2': (context) => const CreateAccountStepTwoScreen(),
          '/home': (context) => const DashboardScreen(), // Main screen after login
          '/profile': (context) => const ProfileScreen(),
          '/all-workouts': (context) => const AllWorkoutsScreen(),
          '/add-workout': (context) => const AddWorkoutScreen(),
          '/calendar': (context) => const CalendarScreen(),
          '/metrics': (context) => const MetricsScreen(),
          '/body-weight': (context) => const BodyWeightScreen(),
          '/calories': (context) => const CaloriesScreen(),
        },
        // Handles any undefined routes gracefully.
        onUnknownRoute: (settings) => MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: const Center(child: Text('404 - Page not found')),
          ),
        ),
      ),
    );
  }
}