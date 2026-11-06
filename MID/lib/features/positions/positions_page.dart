import 'package:flutter/material.dart';

import '../../core/safe_mutate.dart';
import '../../core/theme/mid_colors.dart';
import '../../data/mid_store.dart';
import '../../models/app_user.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/section_header.dart';

class PositionsPage extends StatelessWidget {
  const PositionsPage({super.key, required this.user, required this.store});

  final AppUser user;
  final MidStore store;

  @override
  Widget build(BuildContext context) {
    final titles = store.jobTitles;

    return PageScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: 'Lavozimlar',
            subtitle:
                'Faqat Direktor kiritadi. Xodimlarga va loyiha a\'zolariga shu lavozimlar beriladi.',
            action: FilledButton.icon(
              onPressed: () => _add(context),
              icon: const Icon(Icons.add),
              label: const Text("Lavozim qo'shish"),
            ),
          ),
          const SizedBox(height: 16),
          if (titles.isEmpty)
            const SurfaceBox(
              child: Text(
                "Hali lavozim yo'q. Yuqoridan qo'shing.",
                style: TextStyle(color: MidColors.navyMuted),
              ),
            )
          else
            ...titles.map(
              (t) => Padding(
                key: ValueKey(t.id),
                padding: const EdgeInsets.only(bottom: 8),
                child: SurfaceBox(
                  child: Row(
                    children: [
                      const Icon(Icons.work_outline, color: MidColors.teal),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          t.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Tahrirlash',
                        onPressed: () => _edit(context, t.id, t.name),
                        icon: const Icon(Icons.edit_outlined, size: 20),
                      ),
                      IconButton(
                        tooltip: "O'chirish",
                        onPressed: () => _delete(context, t.id, t.name),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: MidColors.coral,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _add(BuildContext context) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yangi lavozim'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Lavozim nomi'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Bekor'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Qo'shish"),
          ),
        ],
      ),
    );
    if (ok == true && ctrl.text.trim().isNotEmpty) {
      await safeMutate(context, () => store.addJobTitle(ctrl.text.trim()));
    }
  }

  Future<void> _edit(BuildContext context, String id, String current) async {
    final ctrl = TextEditingController(text: current);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lavozimni tahrirlash'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Lavozim nomi'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Bekor'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Saqlash'),
          ),
        ],
      ),
    );
    if (ok == true && ctrl.text.trim().isNotEmpty) {
      await safeMutate(
        context,
        () => store.updateJobTitle(id, name: ctrl.text.trim()),
      );
    }
  }

  Future<void> _delete(BuildContext context, String id, String name) async {
    final ok = await confirmDelete(
      context,
      title: "Lavozimni o'chirish",
      message: '«$name» o‘chirilsinmi?',
    );
    if (!ok) return;
    await safeMutate(context, () => store.deleteJobTitle(id));
  }
}
