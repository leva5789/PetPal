import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petpal/success_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'app_theme.dart';
import 'app_toast.dart';
import 'widgets/premium_widgets.dart';

class RegistrationScreen extends StatefulWidget {
  final Map<String, String> translations;
  final String currentLanguage;

  const RegistrationScreen({
    super.key,
    required this.translations,
    required this.currentLanguage,
  });

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String translate(String key) {
    return widget.translations[key] ?? key;
  }

  void _register() async {
    final fullName = _fullNameController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final phoneNumber = _phoneController.text.trim();

    if (password != confirmPassword) {
      AppToast.warning(context, 'Passwords do not match');
      return;
    }

    if (fullName.isEmpty ||
        username.isEmpty ||
        email.isEmpty ||
        phoneNumber.isEmpty) {
      AppToast.warning(context, 'Please fill in all fields');
      return;
    }

    if (password.length < 6) {
      AppToast.warning(context, 'Password must be at least 6 characters');
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String userId = userCredential.user!.uid;

      await _firestore.collection('users').doc(userId).set({
        'id': userId,
        'fullName': fullName,
        'username': username,
        'email': email,
        'phoneNumber': phoneNumber,
        'profilePictureUrl':
            'https://st3.depositphotos.com/6672868/13701/v/450/depositphotos_137014128-stock-illustration-user-profile-icon.jpg',
        'isAdmin': false,
        'isPremium': false,
        'householdId': userId,
      });

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        FadePageRoute(page: SuccessScreen()),
      );
    } catch (e) {
      if (mounted) {
        AppToast.error(context, AppToast.getAuthErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.mint.withOpacity(isDark ? 0.1 : 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.blueAccent.withOpacity(isDark ? 0.1 : 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkCard : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                            color: isDark ? Colors.white : AppTheme.darkText,
                          ),
                        ),
                      ),
                    ).animate().fadeIn().slideX(begin: -0.2, end: 0),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.mint.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_add_rounded,
                        size: 48,
                        color: AppTheme.mint,
                      ),
                    )
                        .animate()
                        .scale(duration: 500.ms, curve: Curves.easeOutBack),
                    const SizedBox(height: 24),
                    Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.darkText,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 100.ms)
                        .slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 8),
                    Text(
                      'Join PetPal today!',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.white70 : Colors.grey[600],
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 200.ms)
                        .slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 48),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          PremiumTextField(
                            controller: _fullNameController,
                            label: translate('full_name_label'),
                            prefixIcon: Icons.person_outline_rounded,
                          ),
                          const SizedBox(height: 16),
                          PremiumTextField(
                            controller: _usernameController,
                            label: translate('username_label'),
                            prefixIcon: Icons.alternate_email_rounded,
                          ),
                          const SizedBox(height: 16),
                          PremiumTextField(
                            controller: _emailController,
                            label: translate('email_label'),
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          PremiumTextField(
                            controller: _passwordController,
                            label: translate('password_label'),
                            prefixIcon: Icons.lock_outline_rounded,
                            isPassword: true,
                          ),
                          const SizedBox(height: 16),
                          PremiumTextField(
                            controller: _confirmPasswordController,
                            label: translate('confirm_password_label'),
                            prefixIcon: Icons.lock_reset_rounded,
                            isPassword: true,
                          ),
                          const SizedBox(height: 16),
                          PremiumTextField(
                            controller: _phoneController,
                            label: 'Phone Number',
                            prefixIcon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 32),
                          Container(
                            height: 56,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: AppTheme.mintGradient,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.mint.withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          translate('register_button'),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.arrow_forward_rounded,
                                            color: Colors.white),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 300.ms)
                        .slideY(begin: 0.1, end: 0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
