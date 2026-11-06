import 'package:flutter/material.dart';

import '../data/mid_store.dart';

/// Store o'zgarganda faqat shu sahifa qayta chiziladi (butun app emas).
class ListenablePage extends StatelessWidget {
  const ListenablePage({
    super.key,
    required this.store,
    required this.builder,
  });

  final MidStore store;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) => builder(context),
    );
  }
}
