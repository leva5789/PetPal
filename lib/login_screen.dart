import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'registration_screen.dart';
import 'homepage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'admin_dashboard_screen.dart'; // <-- ÚJ IMPORT

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, String> _translations = {};
  String _currentLanguage = 'hu';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTranslations(_currentLanguage);
  }

  Future<void> _loadTranslations(String languageCode) async {
    setState(() {
      _isLoading = true;
    });
    try {
      DocumentSnapshot doc =
      await _firestore.collection('translations').doc(languageCode).get();
      if (doc.exists) {
        setState(() {
          _translations = Map<String, String>.from(doc.data() as Map);
          _isLoading = false;
        });
      } else {
        print('Translation document not found for $languageCode');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading translations: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String translate(String key) {
    return _translations[key] ?? key;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn(
        clientId:
        '669877264006-mld2lv5k7te4rjh3a5v74lploogvihk0.apps.googleusercontent.com',
      ).signIn();

      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        UserCredential userCredential =
        await _auth.signInWithCredential(credential);
        final user = userCredential.user;
        if (user == null) return;

        // Firestore user doc létrehozása, ha nem létezik
        final userDocRef = _firestore.collection('users').doc(user.uid);
        final userDoc = await userDocRef.get();

        if (!userDoc.exists) {
          await userDocRef.set({
            'id': user.uid,
            'fullName': user.displayName ?? '',
            'username': user.displayName ?? '',
            'email': user.email ?? '',
            'profilePictureUrl':
            user.photoURL ??
                'https://st3.depositphotos.com/6672868/13701/v/450/depositphotos_137014128-stock-illustration-user-profile-icon.jpg',
            'isAdmin': false,
            'isPremium': false,
          });
        }

        final data = (await userDocRef.get()).data() as Map<String, dynamic>;
        final isAdmin = data['isAdmin'] as bool? ?? false;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => isAdmin
                ? const AdminDashboardScreen()
                : HomePage(currentLanguage: _currentLanguage),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            translate('google_login_error')
                .replaceAll('\${e.toString()}', e.toString()),
          ),
        ),
      );
    }
  }

  void _login() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    try {
      UserCredential userCredential =
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      final user = userCredential.user;
      if (user == null) return;

      // Firestore user doc
      final userDocRef = _firestore.collection('users').doc(user.uid);
      final userDoc = await userDocRef.get();

      if (!userDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(translate('no_user_data_error'))),
        );
        return;
      }

      final data = userDoc.data() as Map<String, dynamic>;
      final isAdmin = data['isAdmin'] as bool? ?? false;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => isAdmin
              ? const AdminDashboardScreen()
              : HomePage(currentLanguage: _currentLanguage),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = translate('user_not_found_error');
          break;
        case 'wrong-password':
          errorMessage = translate('wrong_password_error');
          break;
        case 'invalid-email':
          errorMessage = translate('invalid_email_error');
          break;
        case 'user-disabled':
          errorMessage = translate('user_disabled_error');
          break;
        case 'too-many-requests':
          errorMessage = translate('too_many_requests_error');
          break;
        default:
          errorMessage = translate('general_error')
              .replaceAll('\${e.message}', e.message ?? '');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            translate('unexpected_error')
                .replaceAll('\${e.toString()}', e.toString()),
          ),
        ),
      );
    }
  }

  void _changeLanguage(String languageCode) {
    setState(() {
      _currentLanguage = languageCode;
      _loadTranslations(languageCode);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(translate('login_button')),
        actions: [
          PopupMenuButton<String>(
            onSelected: _changeLanguage,
            itemBuilder: (BuildContext context) =>
            <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'en',
                child: Text('English'),
              ),
              const PopupMenuItem<String>(
                value: 'de',
                child: Text('Deutsch'),
              ),
              const PopupMenuItem<String>(
                value: 'hu',
                child: Text('Magyar'),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration:
              InputDecoration(labelText: translate('email_label')),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _passwordController,
              decoration:
              InputDecoration(labelText: translate('password_label')),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: Text(translate('login_button')),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _loginWithGoogle,
              child: Text(translate('google_login_button')),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RegistrationScreen(
                      translations: _translations,
                      currentLanguage: _currentLanguage,
                    ),
                  ),
                );
              },
              child: Text(translate('register_button')),
            ),
          ],
        ),
      ),
    );
  }
}
