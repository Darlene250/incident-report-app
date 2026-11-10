import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/names.dart';

/// Gradient circle showing the user's initials.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.name, this.size = 48});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        shape: BoxShape.circle,
      ),
      child: Text(
        initialsOf(name),
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.34,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
