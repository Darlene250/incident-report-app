import '../constants/auth_constants.dart';

final RegExp _emailShape = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Validator for the full name field.
String? validateFullName(String? value) {
  final String name = (value ?? '').trim();
  if (name.isEmpty) return 'Enter your full name';
  if (name.length < 3) return 'Your name looks too short';

  return null;
}

/// Validator for the email field: valid shape and an ALU domain only.
String? validateAluEmail(String? value) {
  final String email = (value ?? '').trim();
  if (email.isEmpty) return 'Enter your ALU email';
  if (!_emailShape.hasMatch(email)) return 'Enter a valid email address';
  if (!AuthConstants.isAluEmail(email)) {
    return 'Only ALU emails are allowed (${AuthConstants.allowedDomainsLabel})';
  }

  return null;
}

/// Validator for the password field.
String? validatePassword(String? value) {
  final String password = value ?? '';
  if (password.isEmpty) return 'Enter your password';
  if (password.length < AuthConstants.minPasswordLength) {
    return 'Use at least ${AuthConstants.minPasswordLength} characters';
  }

  return null;
}

/// Validator for the confirm password field.
String? validateConfirmPassword(String? value, String password) {
  final String confirmation = value ?? '';
  if (confirmation.isEmpty) return 'Re-enter your password';
  if (confirmation != password) return 'Passwords do not match';

  return null;
}
