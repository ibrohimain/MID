import 'dart:async';

import 'package:flutter/material.dart';

import '../data/api/api_client.dart';

/// Dialog yopilgach focus scrollni pastga otkazmasligi uchun:
/// avval unfocus, keyin keyingi frame'da mutatsiya.
Future<void> safeMutate(
  BuildContext context,
  FutureOr<void> Function() mutate,
) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await Future<void>.delayed(Duration.zero);
  if (!context.mounted) return;
  try {
    await mutate();
  } on ApiException catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.message)),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Xatolik: $e')),
    );
  }
}

Future<bool> confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Bekor'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFE85D4C),
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text("O'chirish"),
        ),
      ],
    ),
  );
  return ok == true;
}
