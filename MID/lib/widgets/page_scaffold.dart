import 'package:flutter/material.dart';

import '../core/theme/mid_colors.dart';

/// Sahifa kontenti — yuqoridan joylashadi, o'chirishda scroll siljimaydi.
class PageScaffold extends StatelessWidget {
  const PageScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: MidColors.sand,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return ScrollConfiguration(
              behavior: const _StableScrollBehavior(),
              child: CustomScrollView(
                primary: false,
                physics: const ClampingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                    sliver: SliverToBoxAdapter(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: constraints.maxWidth,
                        ),
                        child: child,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Focus/dialogdan keyin ensureVisible orqali pastga otishni kamaytiradi.
class _StableScrollBehavior extends MaterialScrollBehavior {
  const _StableScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}

class SurfaceBox extends StatelessWidget {
  const SurfaceBox({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MidColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MidColors.mist),
      ),
      child: child,
    );
  }
}

class TagChip extends StatelessWidget {
  const TagChip({super.key, required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
