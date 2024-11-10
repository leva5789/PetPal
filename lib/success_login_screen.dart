import 'package:flutter/material.dart';

class SuccessLoginScreen extends StatelessWidget {
  final String fullName;

  SuccessLoginScreen({required this.fullName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sikeres bejelentkezés'),
      ),
      body: Center(
        child: Text(
          'Üdvözöllek, $fullName!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
