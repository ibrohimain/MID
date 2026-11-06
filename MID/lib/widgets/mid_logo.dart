import 'package:flutter/material.dart';

import '../core/theme/mid_colors.dart';

class MidLogo extends StatelessWidget {
  const MidLogo({
    super.key,
    this.height = 40,
    this.showWordmark = true,
    this.light = false,
  });

  final double height;
  final bool showWordmark;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            'assets/brand/mid-icon.jpg',
            height: height,
            width: height,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: height,
              width: height,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: MidColors.teal,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'M',
                style: TextStyle(
                  color: MidColors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: height * 0.45,
                ),
              ),
            ),
          ),
        ),
        if (showWordmark) ...[
          const SizedBox(width: 10),
          Text(
            'MID',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: light ? MidColors.white : MidColors.navy,
                ),
          ),
        ],
      ],
    );
  }
}
