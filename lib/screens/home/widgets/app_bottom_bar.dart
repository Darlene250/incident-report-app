import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/app_theme.dart';

/// Bottom navigation with Home, Reports, a raised centre "+" and Profile.
class AppBottomBar extends StatelessWidget {
  const AppBottomBar({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.onAddPressed,
  });

  /// 0 = Home, 1 = Reports, 2 = Profile.
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onAddPressed;

  /// How far the round button rises above the bar.
  static const double _lift = 16;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: AppSizes.bottomBarHeight + _lift,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: <Widget>[
            Container(
              height: AppSizes.bottomBarHeight,
              decoration: const BoxDecoration(
                color: AppColors.card,
                border: Border(top: BorderSide(color: AppColors.border)),
                boxShadow: <BoxShadow>[
                  BoxShadow(color: Color(0x0F1B1B2F), blurRadius: 16, offset: Offset(0, -4)),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: AppSizes.bottomBarHeight,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: _BarItem(
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home_rounded,
                      label: 'Home',
                      isActive: currentIndex == 0,
                      onTap: () => onDestinationSelected(0),
                    ),
                  ),
                  Expanded(
                    child: _BarItem(
                      icon: Icons.description_outlined,
                      activeIcon: Icons.description_rounded,
                      label: 'Reports',
                      isActive: currentIndex == 1,
                      onTap: () => onDestinationSelected(1),
                    ),
                  ),
                  // Keeps the four slots equal; the round button floats here.
                  const Expanded(child: SizedBox.shrink()),
                  Expanded(
                    child: _BarItem(
                      icon: Icons.person_outline_rounded,
                      activeIcon: Icons.person_rounded,
                      label: 'Profile',
                      isActive: currentIndex == 2,
                      onTap: () => onDestinationSelected(2),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              child: _AddButton(size: AppSizes.addButtonSize, onPressed: onAddPressed),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  const _BarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = isActive ? AppColors.primary : AppColors.textHint;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(isActive ? activeIcon : icon, size: 23, color: color),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.tileLabel.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.size, required this.onPressed});

  final double size;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      shape: const CircleBorder(),
      elevation: 6,
      shadowColor: AppColors.primary.withValues(alpha: 0.4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          height: size,
          width: size,
          child: const Icon(Icons.add_rounded, size: 28, color: Colors.white),
        ),
      ),
    );
  }
}
