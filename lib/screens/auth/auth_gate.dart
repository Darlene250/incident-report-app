import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_view.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../home/main_shell.dart';
import 'login_screen.dart';
import 'verify_email_screen.dart';

/// Routes on the auth state: signed out -> login, unverified -> verify,
/// verified -> the app shell.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();

    if (auth.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.page,
        body: SafeArea(child: LoadingView(message: 'Checking your session…')),
      );
    }

    if (!auth.isSignedIn) return const LoginScreen();
    if (!auth.isEmailVerified) return const VerifyEmailScreen();

    final AppUser? user = auth.currentUser;
    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.page,
        body: SafeArea(
          child: Column(
            children: <Widget>[
              Expanded(
                child: ErrorView(
                  message: auth.errorMessage ?? 'We could not load your profile.',
                  onRetry: () => context.read<AuthProvider>().reloadProfile(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextButton(
                  onPressed: () => context.read<AuthProvider>().signOut(),
                  style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
                  child: const Text('Sign out'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const MainShell();
  }
}
