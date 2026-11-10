import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'primary_button.dart';

/// Friendly failure state with an optional retry action.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    this.title = 'Something went wrong',
    this.onRetry,
    this.retryLabel = 'Try again',
  });

  final String message;
  final String title;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: AppColors.submittedTile,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 26,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 14),
              Text(title, textAlign: TextAlign.center, style: AppTextStyles.cardTitle),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(height: 1.5),
              ),
              if (onRetry != null) ...<Widget>[
                const SizedBox(height: 18),
                SizedBox(
                  width: 170,
                  child: PrimaryButton(label: retryLabel, onPressed: onRetry),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
