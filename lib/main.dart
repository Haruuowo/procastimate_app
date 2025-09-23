import 'package:flutter/material.dart';
import 'package:procastimate_app/screens/signin_screen.dart';
import 'package:procastimate_app/screens/signup_screen.dart';
import 'package:procastimate_app/screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
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
      ),
      home: const HomeScreen(),
      routes: {
        '/signin': (_) => const SignIn(),
        '/signup': (_) => const SignUp(),
      },
    );
  }
}

