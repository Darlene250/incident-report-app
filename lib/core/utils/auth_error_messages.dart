import 'package:firebase_auth/firebase_auth.dart';

import '../constants/auth_constants.dart';

/// Turns Firebase auth failures into short, user friendly copy.
String authErrorMessage(Object error) {
  if (error is! FirebaseAuthException) {
    return 'Something went wrong. Please check your connection and try again.';
  }

  return switch (error.code) {
    'invalid-email' => 'That email address is not valid.',
    'user-disabled' => 'This account has been disabled. Please contact an administrator.',
    'user-not-found' || 'wrong-password' || 'invalid-credential' =>
      'Email or password is incorrect.',
    'email-already-in-use' =>
      'An account already exists for that email. Try signing in instead.',
    'weak-password' =>
      'Your password is too weak. Use at least ${AuthConstants.minPasswordLength} characters.',
    'operation-not-allowed' =>
      'Email and password sign-in is not enabled for this project.',
    'too-many-requests' => 'Too many attempts. Please wait a moment and try again.',
    'network-request-failed' =>
      'No internet connection. Check your network and try again.',
    'requires-recent-login' => 'Please sign in again to continue.',
    'missing-email' => 'This account has no email address attached.',
    _ => 'Something went wrong. Please try again.',
  };
}
