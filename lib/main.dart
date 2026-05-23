import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'login_screen.dart';
import 'app_theme.dart';
import 'firebase_options.dart';
import 'pet_public_profile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => MyAppState();

  static MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<MyAppState>();
}

class MyAppState extends State<MyApp> {
  ThemeMode themeMode = ThemeMode.light;

  void toggleTheme(ThemeMode mode) {
    setState(() {
      themeMode = mode;
    });
  }

  Widget _getInitialScreen() {
    if (kIsWeb) {
      final fragment = Uri.base.fragment;
      if (fragment.isNotEmpty) {
        final uri = Uri.parse(fragment);
        if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'pet') {
          final petId = uri.pathSegments[1];
          return PetPublicProfilePage(petId: petId);
        }
      }
    }
    return LoginScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PetPal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: _getInitialScreen(),
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name ?? '/');

        if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'pet') {
          final petId = uri.pathSegments[1];
          return MaterialPageRoute(
            builder: (context) => PetPublicProfilePage(petId: petId),
          );
        }

        return MaterialPageRoute(
          builder: (context) => LoginScreen(),
        );
      },
    );
  }
}
