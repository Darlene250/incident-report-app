import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/constants/auth_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/auth_validators.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../providers/auth_provider.dart';
import 'widgets/auth_error_banner.dart';
import 'widgets/auth_header.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final AuthProvider auth = context.read<AuthProvider>();
    final bool registered = await auth.register(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!registered || !mounted) return;

    // AuthGate now shows the verification screen.
    Navigator.of(context).popUntil((Route<void> route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();
    final String? error = auth.errorMessage;

    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.screenPadding,
            vertical: 12,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const AuthHeader(
                  title: 'Campus Incident Reporting',
                  subtitle: 'Create your account with your ALU email.',
                ),
                const SizedBox(height: 28),
                AppTextField(
                  label: 'Full name',
                  hintText: 'e.g. Elijah Laddie',
                  controller: _nameController,
                  prefixIcon: Icons.person_outline_rounded,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const <String>[AutofillHints.name],
                  validator: validateFullName,
                ),
                const SizedBox(height: 16),
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
                  hintText: 'At least ${AuthConstants.minPasswordLength} characters',
                  controller: _passwordController,
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  validator: validatePassword,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Confirm password',
                  hintText: 'Re-enter your password',
                  controller: _confirmController,
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  validator: (String? value) =>
                      validateConfirmPassword(value, _passwordController.text),
                  onFieldSubmitted: (_) => _submit(),
                ),
                if (error != null) ...<Widget>[
                  const SizedBox(height: 16),
                  AuthErrorBanner(message: error),
                ],
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Create account',
                  isLoading: auth.isSubmitting,
                  onPressed: _submit,
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Text('Already have an account?', style: AppTextStyles.caption),
                    TextButton(
                      onPressed: auth.isSubmitting ? null : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text('Sign in', style: AppTextStyles.link),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
