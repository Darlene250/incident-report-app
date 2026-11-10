import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_sizes.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

export 'app_colors.dart';
export 'app_text_styles.dart';

/// Global theme for the Campus Incident Reporting app.
abstract final class AppTheme {
  /// Very soft card shadow: blur 16, 6% opacity.
  static const List<BoxShadow> cardShadow = <BoxShadow>[
    BoxShadow(
      color: Color(0x0F1B1B2F),
      blurRadius: AppSizes.cardShadowBlur,
      offset: Offset(0, 4),
    ),
  ];

  static ThemeData get light {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.gradientEnd,
      surface: AppColors.card,
      onSurface: AppColors.textPrimary,
      outline: AppColors.border,
      error: AppColors.error,
    );

    final ThemeData base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.page,
      splashFactory: InkSparkle.splashFactory,
    );

    // google_fonts applies the family to Flutter's own TextTheme; its
    // `*TextTheme()` helpers return a different TextTheme type.
    final TextStyle jakarta = GoogleFonts.plusJakartaSans();

    return base.copyWith(
      textTheme: base.textTheme
          .apply(fontFamily: jakarta.fontFamily, fontFamilyFallback: jakarta.fontFamilyFallback)
          .apply(
            bodyColor: AppColors.textPrimary,
            displayColor: AppColors.textPrimary,
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.page,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 22),
        titleTextStyle: AppTextStyles.sectionTitle,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        hintStyle: AppTextStyles.hint,
        errorStyle: AppTextStyles.errorText,
        errorMaxLines: 3,
        prefixIconColor: AppColors.textHint,
        suffixIconColor: AppColors.textHint,
        prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        suffixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        border: _inputBorder(AppColors.border),
        enabledBorder: _inputBorder(AppColors.border),
        focusedBorder: _inputBorder(AppColors.primary, width: 1.6),
        errorBorder: _inputBorder(AppColors.error),
        focusedErrorBorder: _inputBorder(AppColors.error, width: 1.6),
        disabledBorder: _inputBorder(AppColors.border),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(64, AppSizes.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.filterChip,
        selectedColor: AppColors.primary,
        secondarySelectedColor: AppColors.primary,
        disabledColor: AppColors.border,
        labelStyle: AppTextStyles.chip.copyWith(color: AppColors.textPrimary),
        secondaryLabelStyle: AppTextStyles.chip.copyWith(color: Colors.white),
        padding: AppSizes.chipPadding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.chipRadius),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.page,
        indicatorColor: AppColors.primary.withValues(alpha: 0.16),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.chipRadius),
        ),
        labelTextStyle: WidgetStatePropertyAll<TextStyle>(
          AppTextStyles.chip,
        ),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>(
          (Set<WidgetState> states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textSecondary,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.border,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: AppTextStyles.body.copyWith(color: Colors.white),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: Color(0x332FA05A),
        selectionHandleColor: AppColors.primary,
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.inputRadius),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
