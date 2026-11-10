import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/auth_validators.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../providers/auth_provider.dart';
import 'register_screen.dart';
import 'widgets/auth_error_banner.dart';
import 'widgets/auth_header.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // AuthGate reacts to the new session: the app if verified, otherwise the
    // verification screen.
    await context.read<AuthProvider>().signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  Future<void> _resetPassword() async {
    FocusScope.of(context).unfocus();
    final AuthProvider auth = context.read<AuthProvider>();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final String email = _emailController.text.trim();

    final bool sent = await auth.sendPasswordReset(email);
    if (!sent || !mounted) return;

    messenger.showSnackBar(
      SnackBar(content: Text('Password reset link sent to $email.')),
    );
  }

  void _openRegister() {
    context.read<AuthProvider>().clearError();
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (BuildContext context) => const RegisterScreen()),
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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const AuthHeader(
                    title: 'Campus Incident Reporting',
                    subtitle: 'Sign in to report and track campus incidents.',
                  ),
                  const SizedBox(height: 32),
                  AppTextField(
                    label: 'ALU email',
                    hintText: 'you@alustudent.com',
                    controller: _emailController,
                    prefixIcon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const <String>[AutofillHints.email],
                    validator: validateAluEmail,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Password',
                    hintText: 'Your password',
                    controller: _passwordController,
                    prefixIcon: Icons.lock_outline_rounded,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    autofillHints: const <String>[AutofillHints.password],
                    validator: validatePassword,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: auth.isSubmitting ? null : _resetPassword,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text('Forgot password?', style: AppTextStyles.link),
                    ),
                  ),
                  if (error != null) ...<Widget>[
                    const SizedBox(height: 16),
                    AuthErrorBanner(message: error),
                  ],
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Sign in',
                    isLoading: auth.isSubmitting,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      Text('New here?', style: AppTextStyles.caption),
                      TextButton(
                        onPressed: auth.isSubmitting ? null : _openRegister,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text('Create an account', style: AppTextStyles.link),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
