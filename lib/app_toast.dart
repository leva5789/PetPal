import 'package:flutter/material.dart';
import 'app_theme.dart';

class AppToast {
  static void success(BuildContext context, String message) {
    _show(context, message, ToastType.success);
  }

  static void error(BuildContext context, String message) {
    _show(context, message, ToastType.error);
  }

  static void warning(BuildContext context, String message) {
    _show(context, message, ToastType.warning);
  }

  static void info(BuildContext context, String message) {
    _show(context, message, ToastType.info);
  }

  static void _show(BuildContext context, String message, ToastType type) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              type.icon,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: type.color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: type == ToastType.error
            ? const Duration(seconds: 4)
            : const Duration(seconds: 3),
      ),
    );
  }

  static String getAuthErrorMessage(dynamic error) {
    String errorCode = '';

    if (error is FirebaseAuthException) {
      errorCode = error.code;
    } else if (error.toString().contains('firebase_auth')) {
      final match = RegExp(r'\[.*\/(.*)\]').firstMatch(error.toString());
      errorCode = match?.group(1) ?? '';
    }

    switch (errorCode.toLowerCase()) {
      case 'invalid-email':
        return 'Please enter a valid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'weak-password':
        return 'Password should be at least 6 characters';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      case 'requires-recent-login':
        return 'Please sign in again to continue';
      default:
        if (error.toString().toLowerCase().contains('password')) {
          return 'Incorrect email or password';
        }
        if (error.toString().toLowerCase().contains('network')) {
          return 'Network error. Please check your connection';
        }
        return 'Something went wrong. Please try again';
    }
  }
}

enum ToastType {
  success(Icons.check_circle_rounded, AppTheme.mint),
  error(Icons.error_rounded, Color(0xFFE53935)),
  warning(Icons.warning_rounded, Color(0xFFFFA726)),
  info(Icons.info_rounded, Color(0xFF42A5F5));

  final IconData icon;
  final Color color;

  const ToastType(this.icon, this.color);
}

class FirebaseAuthException implements Exception {
  final String code;
  final String? message;

  FirebaseAuthException(this.code, [this.message]);
}
