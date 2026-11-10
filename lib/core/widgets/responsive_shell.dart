import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import '../theme/app_theme.dart';

/// Keeps the app at phone width on wide screens (web/desktop) and paints the
/// neutral backdrop around it.
class ResponsiveShell extends StatelessWidget {
  const ResponsiveShell({
    super.key,
    required this.child,
    this.background = AppColors.shell,
    this.contentBackground = AppColors.page,
  });

  final Widget child;

  /// Colour shown around the app column on wide screens.
  final Color background;

  /// Colour of the app column itself.
  final Color contentBackground;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = math.min(constraints.maxWidth, AppSizes.maxContentWidth);
        final double? height = constraints.hasBoundedHeight ? constraints.maxHeight : null;

        return ColoredBox(
          color: background,
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: width,
              height: height,
              child: ColoredBox(color: contentBackground, child: child),
            ),
          ),
        );
      },
    );
  }
}
