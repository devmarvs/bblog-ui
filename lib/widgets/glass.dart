import 'dart:ui';

import 'package:flutter/material.dart';

class GlassBackground extends StatelessWidget {
  const GlassBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    final gradient = LinearGradient(
      colors: [
        colorScheme.primary.withValues(alpha: isLight ? 0.35 : 0.22),
        colorScheme.secondary.withValues(alpha: isLight ? 0.28 : 0.18),
        colorScheme.tertiary.withValues(alpha: isLight ? 0.25 : 0.16),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return DecoratedBox(
      decoration: BoxDecoration(gradient: gradient),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: _GlassGlow(
              color: colorScheme.primary.withValues(alpha: isLight ? 0.55 : 0.3),
              size: 260,
            ),
          ),
          Positioned(
            bottom: -140,
            left: -90,
            child: _GlassGlow(
              color:
                  colorScheme.secondary.withValues(alpha: isLight ? 0.5 : 0.26),
              size: 320,
            ),
          ),
          Positioned(
            top: 200,
            left: -120,
            child: _GlassGlow(
              color:
                  colorScheme.tertiary.withValues(alpha: isLight ? 0.4 : 0.22),
              size: 240,
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.blur = 18,
    this.opacity = 0.65,
    this.showShadow = true,
  });

  final Widget child;
  final EdgeInsets padding;
  final BorderRadius borderRadius;
  final double blur;
  final double opacity;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;
    final baseOpacity = opacity.clamp(0.0, 1.0).toDouble();
    final highlightOpacity = (baseOpacity * 0.6).clamp(0.0, 1.0).toDouble();
    final borderOpacity = isLight ? 0.22 : 0.18;

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.surface.withValues(alpha: baseOpacity),
                colorScheme.surface.withValues(alpha: highlightOpacity),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: borderRadius,
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: borderOpacity),
            ),
            boxShadow: showShadow
                ? [
                    BoxShadow(
                      color:
                          theme.shadowColor.withValues(alpha: isLight ? 0.16 : 0.3),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ]
                : null,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassGlow extends StatelessWidget {
  const _GlassGlow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}
