import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:procastimate_app/screens/signin_screen.dart';
import 'package:procastimate_app/screens/signup_screen.dart';
import 'package:procastimate_app/screens/home_screen.dart';
import 'package:procastimate_app/services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e, st) {
      debugPrint('Firebase.initializeApp failed: $e\n$st');
      // continue without crashing
    }
  } else {
    debugPrint('Web detected - skipping Firebase.initializeApp');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  ThemeData _buildLightTheme() {
    const fallbackPrimary = Color(0xFFBCA88D); // same tone used before
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: fallbackPrimary,
      scaffoldBackgroundColor: Colors.white,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: Colors.black87),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    const fallbackPrimary = Color(0xFFBCA88D);
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: Colors.black,
      scaffoldBackgroundColor: Colors.black87,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(backgroundColor: fallbackPrimary),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: fallbackPrimary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.instance.notifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Procastimate',
          theme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
          themeMode: themeMode,
          initialRoute: '/',
          routes: {
            '/': (_) => const HomeScreen(),
            '/signin': (_) => const SignIn(),
            '/signup': (_) => const SignUp(),
          },
        );
      },
    );
  }
}


