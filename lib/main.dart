import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:procastimate_app/services/theme_service.dart';
import 'firebase_options.dart';
import 'package:procastimate_app/screens/home_screen.dart';
import 'package:procastimate_app/screens/signin_screen.dart';
import 'package:procastimate_app/screens/signup_screen.dart';
import 'package:procastimate_app/mainapp/main_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized for: ${DefaultFirebaseOptions.currentPlatform.appId}');
  } catch (e, st) {
    debugPrint('❌ Firebase initialization failed: $e\n$st');
  }

  runApp(const MyApp());
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  ThemeData _buildLightTheme() {
    const fallbackPrimary = Color(0xFFBCA88D);
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: fallbackPrimary,
      scaffoldBackgroundColor: Colors.white,
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: Colors.black,
      scaffoldBackgroundColor: Colors.black87,
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
            '/signin': (_) => const SignInScreen(),
            '/signup': (_) => const SignUpScreen(),
            '/main_screen': (_) => const MainScreen(),
          },
        );
      },
    );
  }
}
