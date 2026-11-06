import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/safe_mutate.dart';
import '../../core/theme/mid_colors.dart';
import '../../data/mid_store.dart';
import '../../models/app_user.dart';
import '../../models/domain.dart';
import '../../models/user_role.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/section_header.dart';
import '../../widgets/stat_tile.dart';

class FinancePage extends StatelessWidget {
  const FinancePage({super.key, required this.user, required this.store});

  final AppUser user;
  final MidStore store;

  @override
  Widget build(BuildContext context) {
    final canEdit = user.role.canManageFinance;

    return PageScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: 'Moliya',
            subtitle:
                'Kampaniya pulini qo‘lda belgilang, keyin cheklar bilan yuriting',
            action: canEdit
                ? Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _setCompanyCash(context),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Pul belgilash'),
                      ),
                      FilledButton.icon(
                        onPressed: () => _addReceipt(context),
                        icon: const Icon(Icons.receipt_long),
                        label: const Text('Chek yozish'),
                      ),
                    ],
                  )
                : null,
          ),
          const SizedBox(height: 16),
          if (canEdit)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SurfaceBox(
                child: Row(
                  children: [
                    const Icon(Icons.account_balance, color: MidColors.teal),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Kampaniya puli (qo‘lda)',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            moneySum(store.companyCash),
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: () => _setCompanyCash(context),
                      child: const Text('O‘zgartirish'),
                    ),
                  ],
                ),
              ),
            ),
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth > 900
                  ? 3
                  : c.maxWidth > 600
                      ? 2
                      : 1;
              return GridView.count(
                crossAxisCount: cols,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  StatTile(
                    label: 'Kampaniya puli',
                    value: moneySum(store.companyCash),
                    icon: Icons.account_balance,
                  ),
                  StatTile(
                    label: 'Zaxira',
                    value: moneySum(store.reserveCash),
                    icon: Icons.savings_outlined,
                    accent: MidColors.success,
                  ),
                  StatTile(
                    label: 'Jami kirim',
                    value: moneySum(store.totalKirim),
                    icon: Icons.south_west,
                    accent: MidColors.teal,
                  ),
                  StatTile(
                    label: 'Jami chiqim',
                    value: moneySum(store.totalChiqim),
                    icon: Icons.north_east,
                    accent: MidColors.coral,
                  ),
                  StatTile(
                    label: 'Maoshlar',
                    value: moneySum(store.totalMaosh),
                    icon: Icons.payments_outlined,
                    accent: MidColors.warning,
                  ),
                  StatTile(
                    label: 'Cheklar soni',
                    value: '${store.finances.length}',
                    icon: Icons.receipt_outlined,
                    accent: MidColors.navyMuted,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          const SectionHeader(
            title: 'Statistik tahlil',
            subtitle: 'Turlar bo‘yicha ulush',
          ),
          const SizedBox(height: 12),
          SurfaceBox(
            child: Column(
              children: FinanceType.values.map((type) {
                final sum = store.finances
                    .where((f) => f.type == type)
                    .fold<int>(0, (s, f) => s + f.amount);
                final max = store.finances.fold<int>(
                  1,
                  (s, f) => f.amount > s ? f.amount : s,
                );
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(type.label)),
                          Text(moneySum(sum)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: (sum / max).clamp(0, 1),
                          minHeight: 8,
                          backgroundColor: MidColors.mist,
                          color: MidColors.teal,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Cheklar'),
          const SizedBox(height: 12),
          ...store.finances.map((f) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SurfaceBox(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: MidColors.sand,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: MidColors.mist),
                      ),
                      child: const Icon(Icons.receipt_long, color: MidColors.teal),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${f.receiptNo} · ${shortDate(f.createdAt)}'
                            '${f.note.isEmpty ? '' : ' · ${f.note}'}',
                            style: const TextStyle(color: MidColors.navyMuted),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          moneySum(f.amount),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        TagChip(text: f.type.label, color: MidColors.teal),
                        if (canEdit)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Tahrirlash',
                                onPressed: () => _editReceipt(context, f),
                                icon: const Icon(Icons.edit_outlined, size: 18),
                              ),
                              IconButton(
                                tooltip: "O'chirish",
                                onPressed: () => _deleteReceipt(context, f),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: MidColors.coral,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _setCompanyCash(BuildContext context) async {
    final ctrl = TextEditingController(text: '${store.companyCash}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kampaniya pulini belgilash'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bu yerga mavjud balansni o‘zingiz yozing. Keyin cheklar shu summadan hisoblanadi.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Summa (so‘m)',
                  hintText: '0',
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ctrl.text = '0',
                child: const Text('0 qilish'),
              ),
            ],
          ),
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
    if (ok == true) {
      await safeMutate(
        context,
        () => store.setCompanyCash(int.tryParse(ctrl.text.trim()) ?? 0),
      );
    }
  }

  Future<void> _deleteReceipt(BuildContext context, FinanceRecord f) async {
    final ok = await confirmDelete(
      context,
      title: "Chekni o'chirish",
      message: '«${f.title}» o‘chirilsinmi? Summa balansdan qaytariladi.',
    );
    if (!ok) return;
    await safeMutate(context, () => store.deleteFinance(f.id));
  }

  Future<void> _editReceipt(
    BuildContext context, [
    FinanceRecord? existing,
  ]) async {
    final title = TextEditingController(text: existing?.title ?? '');
    final amount =
        TextEditingController(text: existing != null ? '${existing.amount}' : '');
    final note = TextEditingController(text: existing?.note ?? '');
    var type = existing?.type ?? FinanceType.chiqim;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(existing == null ? 'Yangi chek' : 'Chekni tahrirlash'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Nomi'),
                ),
                TextField(
                  controller: amount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Summa'),
                ),
                DropdownButtonFormField<FinanceType>(
                  value: type,
                  items: FinanceType.values
                      .map((t) =>
                          DropdownMenuItem(value: t, child: Text(t.label)))
                      .toList(),
                  onChanged: (v) => setLocal(() => type = v ?? type),
                  decoration: const InputDecoration(labelText: 'Turi'),
                ),
                TextField(
                  controller: note,
                  decoration: const InputDecoration(labelText: 'Izoh'),
                ),
              ],
            ),
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
      ),
    );

    if (ok == true && title.text.trim().isNotEmpty) {
      await safeMutate(context, () async {
        if (existing == null) {
          await store.addFinance(
            title: title.text.trim(),
            amount: int.tryParse(amount.text) ?? 0,
            type: type,
            note: note.text.trim(),
          );
        } else {
          await store.updateFinance(
            id: existing.id,
            title: title.text.trim(),
            amount: int.tryParse(amount.text) ?? 0,
            type: type,
            note: note.text.trim(),
          );
        }
      });
    }
  }

  Future<void> _addReceipt(BuildContext context) => _editReceipt(context);
}
