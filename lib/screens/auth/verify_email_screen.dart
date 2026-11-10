import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/primary_button.dart';
import '../../providers/auth_provider.dart';
import 'widgets/auth_error_banner.dart';

/// Shown while the signed-in account still has an unverified email address.
class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  Future<void> _checkVerified(BuildContext context) async {
    final AuthProvider auth = context.read<AuthProvider>();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    final bool verified = await auth.refreshEmailVerification();
    // When verified, AuthGate swaps this screen for the app automatically.
    if (verified) return;

    messenger.showSnackBar(
      const SnackBar(
        content: Text('Not verified yet. Open the link in your inbox, then try again.'),
      ),
    );
  }

  Future<void> _resendEmail(BuildContext context) async {
    final AuthProvider auth = context.read<AuthProvider>();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    final bool sent = await auth.resendVerificationEmail();
    if (!sent) return;

    messenger.showSnackBar(
      SnackBar(content: Text('Verification email sent to ${auth.email ?? 'your inbox'}.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();
    final String? error = auth.errorMessage;

    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.screenPadding,
              vertical: 28,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: Container(
                    height: 64,
                    width: 64,
                    decoration: BoxDecoration(
                      color: AppColors.myReportsTile,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.mark_email_unread_outlined,
                      size: 28,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Verify your email',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.greeting,
                ),
                const SizedBox(height: 10),
                Text(
                  'We sent a verification link to ${auth.email ?? 'your ALU email'}. '
                  'Open it, then come back and tap "I have verified".',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(height: 1.5),
                ),
                if (error != null) ...<Widget>[
                  const SizedBox(height: 18),
                  AuthErrorBanner(message: error),
                ],
                const SizedBox(height: 28),
                PrimaryButton(
                  label: 'I have verified',
                  isLoading: auth.isSubmitting,
                  onPressed: () => _checkVerified(context),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: AppSizes.buttonHeight,
                  child: OutlinedButton(
                    onPressed: auth.isSubmitting ? null : () => _resendEmail(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
                      ),
                      textStyle: AppTextStyles.button.copyWith(color: AppColors.primary),
                    ),
                    child: const Text('Resend email'),
                  ),
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: auth.isSubmitting ? null : () => context.read<AuthProvider>().signOut(),
                  style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
                  child: const Text('Use a different account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
