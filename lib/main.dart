import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'login_screen.dart';
import 'app_theme.dart';
import 'firebase_options.dart'; // <-- EZ NAGYON FONTOS

void main() async {
  WidgetsFlutterBinding.ensureInitialized();


  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PetPal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: LoginScreen(),
    );
  }
}
