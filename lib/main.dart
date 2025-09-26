import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:procastimate_app/screens/signin_screen.dart';
import 'package:procastimate_app/screens/signup_screen.dart';
import 'package:procastimate_app/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const MyApp());
  } catch (e, stack) {
    // If Firebase fails, show an error screen instead of crashing silently
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Text(
              'Firebase initialization failed:\n$e',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
    debugPrintStack(label: e.toString(), stackTrace: stack);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Procastimate',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true, // enables Material 3 design
      ),
      home: const HomeScreen(),
      routes: {
        '/signin': (_) => const SignIn(),
        '/signup': (_) => const SignUp(),
      },
    );
  }
}


