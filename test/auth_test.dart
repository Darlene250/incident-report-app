import 'package:campus_incident_app/core/constants/auth_constants.dart';
import 'package:campus_incident_app/core/utils/auth_error_messages.dart';
import 'package:campus_incident_app/core/utils/auth_validators.dart';
import 'package:campus_incident_app/providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

void main() {
  group('ALU email rules', () {
    test('accepts both allowed domains, case insensitive', () {
      expect(AuthConstants.isAluEmail('elijah@alustudent.com'), isTrue);
      expect(AuthConstants.isAluEmail('Elijah@ALUStudent.com'), isTrue);
      expect(AuthConstants.isAluEmail('elijah.laddie@alueducation.com'), isTrue);
      expect(AuthConstants.isAluEmail('  elijah@alustudent.com  '), isTrue);
    });

    test('rejects other domains and malformed addresses', () {
      expect(AuthConstants.isAluEmail('someone@gmail.com'), isFalse);
      expect(AuthConstants.isAluEmail('someone@alustudent.com.evil.com'), isFalse);
      expect(AuthConstants.isAluEmail('someone@notalustudent.com'), isFalse);
      expect(AuthConstants.isAluEmail('not-an-email'), isFalse);
      expect(AuthConstants.isAluEmail('@alustudent.com'), isFalse);
      expect(AuthConstants.isAluEmail('someone@'), isFalse);
    });

    test('lists the allowed domains for messages', () {
      expect(
        AuthConstants.allowedDomainsLabel,
        '@alustudent.com, @alueducation.com or @aluedu.com',
      );
    });

    test('aluedu.com is the staff domain; the others are not', () {
      expect(AuthConstants.isAluEmail('mary@aluedu.com'), isTrue);
      expect(AuthConstants.isStaffEmail('Mary@ALUEDU.com'), isTrue);
      expect(AuthConstants.isStaffEmail('elijah@alustudent.com'), isFalse);
      expect(AuthConstants.isStaffEmail('mary@alueducation.com'), isFalse);
      expect(AuthConstants.isStaffEmail('mary@aluedu.com.evil.com'), isFalse);
      expect(AuthConstants.isStaffEmail('not-an-email'), isFalse);
    });
  });

  group('validators', () {
    test('full name is required and not too short', () {
      expect(validateFullName(null), 'Enter your full name');
      expect(validateFullName('   '), 'Enter your full name');
      expect(validateFullName('El'), 'Your name looks too short');
      expect(validateFullName('Elijah Laddie'), isNull);
    });

    test('email must be ALU', () {
      expect(validateAluEmail(''), 'Enter your ALU email');
      expect(validateAluEmail('elijah'), 'Enter a valid email address');
      expect(validateAluEmail('elijah@gmail.com'),
          contains('Only ALU emails are allowed'));
      expect(validateAluEmail('elijah@gmail.com'), contains('@alustudent.com'));
      expect(validateAluEmail('elijah@alustudent.com'), isNull);
    });

    test('password length follows AuthConstants', () {
      expect(validatePassword(''), 'Enter your password');
      expect(validatePassword('12345'), 'Use at least 6 characters');
      expect(validatePassword('123456'), isNull);
    });

    test('confirm password must match', () {
      expect(validateConfirmPassword('', '123456'), 'Re-enter your password');
      expect(validateConfirmPassword('123457', '123456'), 'Passwords do not match');
      expect(validateConfirmPassword('123456', '123456'), isNull);
    });
  });

  group('auth error messages', () {
    test('maps the common Firebase codes to friendly copy', () {
      expect(
        authErrorMessage(FirebaseAuthException(code: 'wrong-password')),
        'Email or password is incorrect.',
      );
      expect(
        authErrorMessage(FirebaseAuthException(code: 'user-not-found')),
        'Email or password is incorrect.',
      );
      expect(
        authErrorMessage(FirebaseAuthException(code: 'invalid-credential')),
        'Email or password is incorrect.',
      );
      expect(
        authErrorMessage(FirebaseAuthException(code: 'email-already-in-use')),
        contains('already exists'),
      );
      expect(
        authErrorMessage(FirebaseAuthException(code: 'weak-password')),
        contains('at least 6 characters'),
      );
      expect(
        authErrorMessage(FirebaseAuthException(code: 'too-many-requests')),
        contains('Too many attempts'),
      );
      expect(
        authErrorMessage(FirebaseAuthException(code: 'network-request-failed')),
        contains('No internet connection'),
      );
      expect(
        authErrorMessage(FirebaseAuthException(code: 'operation-not-allowed')),
        contains('not enabled'),
      );
      expect(
        authErrorMessage(FirebaseAuthException(code: 'user-disabled')),
        contains('disabled'),
      );
    });

    test('provider refuses non-ALU emails before calling Firebase', () async {
      final FakeAuthService service = FakeAuthService();
      final AuthProvider provider = AuthProvider(authService: service);
      addTearDown(provider.dispose);

      expect(await provider.signIn(email: 'someone@gmail.com', password: 'secret1'), isFalse);
      expect(provider.errorMessage, contains('Only ALU emails'));

      expect(
        await provider.register(fullName: 'Some One', email: 'x@yahoo.com', password: 'secret1'),
        isFalse,
      );
      expect(await provider.sendPasswordReset('x@yahoo.com'), isFalse);
      expect(provider.errorMessage, contains('ALU email'));
    });

    test('falls back for unknown codes and non-Firebase errors', () {
      expect(
        authErrorMessage(FirebaseAuthException(code: 'brand-new-code')),
        'Something went wrong. Please try again.',
      );
      expect(
        authErrorMessage(const FormatException('boom')),
        contains('Something went wrong'),
      );
    });
  });
}
