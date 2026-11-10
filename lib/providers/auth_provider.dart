import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/auth_constants.dart';
import '../core/utils/auth_error_messages.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

/// Holds the session state that screens and [AuthGate] render from.
class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? authService}) : _authService = authService ?? AuthService() {
    _authSubscription = _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  final AuthService _authService;
  StreamSubscription<User?>? _authSubscription;

  AppUser? _currentUser;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isSignedIn = false;
  bool _isEmailVerified = false;
  String? _email;
  String? _errorMessage;
  bool _isDisposed = false;
  bool _isRegistering = false;

  /// Profile document of the signed-in, verified user.
  AppUser? get currentUser => _currentUser;

  /// True while the session is being restored or the profile is loading.
  bool get isLoading => _isLoading;

  /// True while a form action (sign in, register, resend) is running.
  bool get isSubmitting => _isSubmitting;

  bool get isSignedIn => _isSignedIn;
  bool get isEmailVerified => _isEmailVerified;
  bool get isStaff => _currentUser?.role == UserRole.staff;

  /// Email of the signed-in account, shown on the verification screen.
  String? get email => _email;
  String? get errorMessage => _errorMessage;

  /// Staff-domain accounts (`@aluedu.com`) are let in without verifying their
  /// email; everyone else must click the verification link first.
  static bool _canEnterApp(User user) =>
      user.emailVerified || AuthConstants.isStaffEmail(user.email ?? '');

  Future<void> _onAuthStateChanged(User? user) async {
    _email = user?.email;
    _isSignedIn = user != null;
    _isEmailVerified = user != null && _canEnterApp(user);
    _errorMessage = null;

    if (user == null) {
      _currentUser = null;
      _isLoading = false;
      _notify();
      return;
    }
    if (!_isEmailVerified) {
      _currentUser = null;
      _isLoading = false;
      _notify();
      return;
    }
    if (_isRegistering) {
      // Firebase signs the new account in before its profile document is
      // written, so register() loads the profile once that write is done.
      _isLoading = true;
      _notify();
      return;
    }

    // Covers reopening the app after verifying in another window: the
    // cached token may still say "unverified".
    try {
      await _authService.refreshTokenIfStale(user);
    } catch (_) {
      // Offline: carry on; the profile load reports any real problem.
    }
    await _loadProfile(user.uid);
  }

  Future<void> _loadProfile(String uid) async {
    _isLoading = true;
    _notify();
    try {
      final AppUser? profile = await _authService.fetchUserProfile(uid);
      _currentUser = profile;
      if (profile == null) {
        _errorMessage = 'We could not find your profile. Please contact an administrator.';
      }
    } catch (error) {
      _currentUser = null;
      _errorMessage = authErrorMessage(error);
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    if (_isSubmitting) return false;
    if (_rejectNonAluEmail(email)) return false;
    _isSubmitting = true;
    _errorMessage = null;
    _notify();
    try {
      await _authService.signIn(email: email, password: password);
      return true;
    } catch (error) {
      _errorMessage = authErrorMessage(error);
      return false;
    } finally {
      _isSubmitting = false;
      _notify();
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    if (_isSubmitting) return false;
    if (_rejectNonAluEmail(email)) return false;
    _isSubmitting = true;
    _isRegistering = true;
    _errorMessage = null;
    _notify();
    try {
      await _authService.register(
        fullName: fullName,
        email: email,
        password: password,
      );
      _isRegistering = false;

      // Staff accounts go straight into the app now that the profile exists.
      // Students land on the verification screen instead.
      final User? user = _authService.currentUser;
      if (user != null && _canEnterApp(user)) await _loadProfile(user.uid);
      return true;
    } catch (error) {
      _errorMessage = authErrorMessage(error);
      // Do not leave the gate spinning if the account was created but a later
      // step failed; it will show the profile error with a Retry button.
      _isLoading = false;
      return false;
    } finally {
      _isRegistering = false;
      _isSubmitting = false;
      _notify();
    }
  }

  Future<bool> resendVerificationEmail() async {
    if (_isSubmitting) return false;
    _isSubmitting = true;
    _errorMessage = null;
    _notify();
    try {
      await _authService.sendVerificationEmail();
      return true;
    } catch (error) {
      _errorMessage = authErrorMessage(error);
      return false;
    } finally {
      _isSubmitting = false;
      _notify();
    }
  }

  /// "Forgot password?" on the login screen. Only ALU addresses are accepted,
  /// matching the rest of the app.
  Future<bool> sendPasswordReset(String email) async {
    if (_isSubmitting) return false;
    if (!AuthConstants.isAluEmail(email)) {
      _errorMessage =
          'Enter your ALU email (${AuthConstants.allowedDomainsLabel}) to reset your password.';
      _notify();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    _notify();
    try {
      await _authService.sendPasswordReset(email);
      return true;
    } catch (error) {
      _errorMessage = authErrorMessage(error);
      return false;
    } finally {
      _isSubmitting = false;
      _notify();
    }
  }

  /// Used by the "I have verified" button. Returns false while the account is
  /// still unverified.
  Future<bool> refreshEmailVerification() async {
    if (_isSubmitting) return false;
    _isSubmitting = true;
    _errorMessage = null;
    _notify();
    try {
      final bool verified = await _authService.reloadEmailVerification();
      _isEmailVerified = verified;

      final User? user = _authService.currentUser;
      if (verified && user != null) {
        await _loadProfile(user.uid);
        return true;
      }
      return false;
    } catch (error) {
      _errorMessage = authErrorMessage(error);
      return false;
    } finally {
      _isSubmitting = false;
      _notify();
    }
  }

  /// Re-fetches the profile document, e.g. after an administrator sets the role.
  Future<void> reloadProfile() async {
    final User? user = _authService.currentUser;
    if (user == null) return;

    await _loadProfile(user.uid);
  }

  Future<void> signOut() async {
    _errorMessage = null;
    try {
      await _authService.signOut();
    } catch (error) {
      _errorMessage = authErrorMessage(error);
      _notify();
    }
  }

  /// Second line of defence behind the form validators (the security rules are
  /// the third). Returns true and sets an error when [email] is not ALU.
  bool _rejectNonAluEmail(String email) {
    if (AuthConstants.isAluEmail(email)) return false;

    _errorMessage = 'Only ALU emails are allowed (${AuthConstants.allowedDomainsLabel}).';
    _notify();
    return true;
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    _notify();
  }

  void _notify() {
    if (_isDisposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _authSubscription?.cancel();
    super.dispose();
  }
}
