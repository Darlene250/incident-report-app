import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Logo badge, app title and subtitle shared by the login and register screens.
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          height: 64,
          width: 64,
          decoration: BoxDecoration(
            gradient: AppColors.heroGradient,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 30),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.greeting,
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.caption.copyWith(height: 1.5),
        ),
      ],
    );
  }
}
