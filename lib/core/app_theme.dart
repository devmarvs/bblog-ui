import 'package:flutter/material.dart';

ThemeData buildTheme(Brightness brightness) {
  final isLight = brightness == Brightness.light;
  final colorScheme = ColorScheme.fromSeed(
    seedColor: isLight ? const Color(0xFF8EC5FF) : const Color(0xFF5A8BBF),
    brightness: brightness,
  ).copyWith(
    primary: isLight ? const Color(0xFF8EC5FF) : const Color(0xFF5A8BBF),
    onPrimary: Colors.white,
    primaryContainer:
        isLight ? const Color(0xFFE0F1FF) : const Color(0xFF224A73),
    onPrimaryContainer:
        isLight ? const Color(0xFF0B2F4A) : const Color(0xFFBBD7FF),
    secondary: isLight ? const Color(0xFFFFB3D9) : const Color(0xFFE88ABF),
    onSecondary:
        isLight ? const Color(0xFF3E1D2C) : const Color(0xFF2F0F21),
    secondaryContainer:
        isLight ? const Color(0xFFFFD9EB) : const Color(0xFF512341),
    onSecondaryContainer:
        isLight ? const Color(0xFF2A0F1F) : const Color(0xFFFCD8E9),
    tertiary: isLight ? const Color(0xFFC3FBD8) : const Color(0xFF8CD4B2),
    onTertiary:
        isLight ? const Color(0xFF103527) : const Color(0xFF0B261B),
    tertiaryContainer:
        isLight ? const Color(0xFFE4FFEF) : const Color(0xFF1F4F38),
    onTertiaryContainer:
        isLight ? const Color(0xFF002114) : const Color(0xFFCFF7DE),
    surface: isLight ? const Color(0xFFFFFFFF) : const Color(0xFF1B1F29),
    onSurface:
        isLight ? const Color(0xFF1F1A2D) : const Color(0xFFE6E2EF),
    onSurfaceVariant:
        isLight ? const Color(0xFF4C4757) : const Color(0xFFC9C4D3),
    outline:
        isLight ? const Color(0xFF8C8798) : const Color(0xFF9690A1),
    inverseSurface:
        isLight ? const Color(0xFF2E2A3C) : const Color(0xFFECE6F5),
    onInverseSurface:
        isLight ? const Color(0xFFF3EFFC) : const Color(0xFF1B1826),
    inversePrimary:
        isLight ? const Color(0xFF2F6AA5) : const Color(0xFFD0E4FF),
  );
  final surfaceContainerBase =
      isLight ? const Color(0xFFE6E2F2) : const Color(0xFF424655);

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    fontFamily: 'Roboto',
  );

  return base.copyWith(
    appBarTheme: base.appBarTheme.copyWith(
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
      centerTitle: true,
      elevation: 0,
      titleTextStyle: base.textTheme.titleMedium?.copyWith(
        color: colorScheme.onPrimaryContainer,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    ),
    navigationBarTheme: base.navigationBarTheme.copyWith(
      backgroundColor: colorScheme.surface,
      indicatorColor: colorScheme.primaryContainer.withValues(alpha: 0.6),
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? colorScheme.primary
              : colorScheme.onSurfaceVariant,
        ),
      ),
    ),
    cardTheme: base.cardTheme.copyWith(
      color: colorScheme.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
    ),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      filled: true,
      fillColor: isLight
          ? surfaceContainerBase.withValues(alpha: 0.4)
          : surfaceContainerBase.withValues(alpha: 0.2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide:
            BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide:
            BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
      ),
      labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      hintStyle: TextStyle(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
      ),
      contentPadding: const EdgeInsets.symmetric(
        vertical: 14,
        horizontal: 18,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,
        side: BorderSide(color: colorScheme.primary),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.secondary,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: colorScheme.secondaryContainer,
      selectedColor: colorScheme.primaryContainer,
      labelStyle: TextStyle(color: colorScheme.onSecondaryContainer),
      secondaryLabelStyle: TextStyle(color: colorScheme.onPrimaryContainer),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
    snackBarTheme: base.snackBarTheme.copyWith(
      backgroundColor: colorScheme.secondary,
      contentTextStyle: TextStyle(
        color: colorScheme.onSecondary,
        fontWeight: FontWeight.w600,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}
