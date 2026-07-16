import 'package:flutter/material.dart';

/// Standard responsive breakpoints used across the app.
class Breakpoints {
  const Breakpoints._();

  static const double compact = 600; // phones
  static const double medium = 840; // small tablets / large phones landscape
  static const double expanded = 1200; // tablets / desktop / web
}

/// Screen size classes for adaptive layout decisions.
enum ScreenSizeClass { compact, medium, expanded }

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;

  ScreenSizeClass get sizeClass {
    final width = screenWidth;
    if (width >= Breakpoints.expanded) return ScreenSizeClass.expanded;
    if (width >= Breakpoints.compact) return ScreenSizeClass.medium;
    return ScreenSizeClass.compact;
  }

  bool get isCompact => sizeClass == ScreenSizeClass.compact;
  bool get isExpanded => sizeClass == ScreenSizeClass.expanded;
}

/// Constrains content to a comfortable reading/interaction width and centers it
/// on large screens (tablet, foldable, desktop, web) while filling the width on
/// phones. Prevents forms and menus from stretching edge-to-edge on wide
/// viewports.
class AdaptiveContentWidth extends StatelessWidget {
  const AdaptiveContentWidth({
    super.key,
    required this.child,
    this.maxWidth = 520,
    this.padding = EdgeInsets.zero,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
