import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petpal/success_screen.dart';

class RegistrationScreen extends StatefulWidget {
  final Map<String, String> translations;
  final String currentLanguage;

  RegistrationScreen({required this.translations, required this.currentLanguage});

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String translate(String key) {
    return widget.translations[key] ?? key;
  }

  void _register() async {
    final fullName = _fullNameController.text;
    final username = _usernameController.text;
    final email = _emailController.text;
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(translate("passwords_do_not_match"))),
      );
      return;
    }

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String userId = userCredential.user!.uid;

      // Automatikus dokumentumazonosító létrehozása a .add() metódussal, alapértelmezett profilképpel
      await _firestore.collection('users').add({
        'id': userId,
        'fullName': fullName,
        'username': username,
        'email': email,
        'profilePictureUrl': 'https://st3.depositphotos.com/6672868/13701/v/450/depositphotos_137014128-stock-illustration-user-profile-icon.jpg', // Alapértelmezett kép URL
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SuccessScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'email-already-in-use') {
        errorMessage = translate("email_already_in_use");
      } else if (e.code == 'weak-password') {
        errorMessage = translate("weak_password");
      } else if (e.code == 'invalid-email') {
        errorMessage = translate("invalid_email");
      } else {
        errorMessage = translate("registration_error").replaceAll('\${e.toString()}', e.toString());
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(translate("registration_error").replaceAll('\${e.toString()}', e.toString()))),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(translate('register_button')),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _fullNameController,
              decoration: InputDecoration(labelText: translate('full_name_label')),
            ),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: translate('username_label')),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: translate('email_label')),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: translate('password_label')),
              obscureText: true,
            ),
            TextField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(labelText: translate('confirm_password_label')),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _register,
              child: Text(translate('register_button')),
            ),
          ],
        ),
      ),
    );
  }
}