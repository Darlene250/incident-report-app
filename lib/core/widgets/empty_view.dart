import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import '../theme/app_theme.dart';

/// Shared empty/zero-data placeholder.
///
/// [boxed] draws a tinted card for use inside scrolling lists; otherwise it is a
/// centred column that fills the available space.
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.boxed = true,
  });

  final String title;
  final String message;
  final IconData icon;
  final bool boxed;

  @override
  Widget build(BuildContext context) {
    if (!boxed) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _iconBadge(size: 48, background: AppColors.filterChip, iconSize: 24),
              const SizedBox(height: 14),
              Text(title, textAlign: TextAlign.center, style: AppTextStyles.cardTitle),
              const SizedBox(height: 4),
              Text(message, textAlign: TextAlign.center, style: AppTextStyles.caption),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      decoration: BoxDecoration(
        color: AppColors.shell,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      ),
      child: Column(
        children: <Widget>[
          _iconBadge(size: 44, background: Colors.white, iconSize: 22),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: AppTextStyles.cardTitle),
          const SizedBox(height: 4),
          Text(message, textAlign: TextAlign.center, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _iconBadge({
    required double size,
    required Color background,
    required double iconSize,
  }) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(icon, size: iconSize, color: AppColors.textHint),
    );
  }
}
