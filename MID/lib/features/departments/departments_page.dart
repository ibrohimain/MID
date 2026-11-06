import 'package:flutter/material.dart';

import '../../core/safe_mutate.dart';
import '../../core/theme/mid_colors.dart';
import '../../data/mid_store.dart';
import '../../models/app_user.dart';
import '../../models/domain.dart';
import '../../models/user_role.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/section_header.dart';

class DepartmentsPage extends StatelessWidget {
  const DepartmentsPage({super.key, required this.user, required this.store});

  final AppUser user;
  final MidStore store;

  List<AppUser> get _headCandidates => store.users
      .where((u) =>
          u.active &&
          (u.role == UserRole.rahbar || u.role == UserRole.xodim))
      .toList();

  @override
  Widget build(BuildContext context) {
    final canEdit = user.role.isLeadership;
    final director =
        store.users.where((u) => u.role == UserRole.direktor).firstOrNull;
    final rahbars =
        store.users.where((u) => u.active && u.role == UserRole.rahbar).toList();

    return PageScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: "Bo'limlar va tuzilma",
            subtitle:
                'Yangi bo‘lim, tahrirlash, o‘chirish va ichida rahbar/xodim tayinlash',
            action: canEdit
                ? FilledButton.icon(
                    onPressed: () => _editDepartment(context),
                    icon: const Icon(Icons.add_business),
                    label: const Text("Bo'lim qo'shish"),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          SurfaceBox(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Boshqaruv ierarxiyasi',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                _Node(
                  title: director?.fullName ?? 'Direktor',
                  subtitle: 'Yagona Direktor',
                  accent: MidColors.coral,
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 18),
                  child: Icon(Icons.arrow_downward, size: 18),
                ),
                Row(
                  children: [
                    for (final r in rahbars)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _Node(
                            title: r.fullName,
                            subtitle: '${r.position} · ${r.sector?.label}',
                            accent: MidColors.teal,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          for (final sector in Sector.values) ...[
            Text(
              sector.label,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            ...store.departments.where((d) => d.sector == sector).map((d) {
              final head = store.userById(d.headId);
              return Padding(
                key: ValueKey(d.id),
                padding: const EdgeInsets.only(bottom: 10),
                child: SurfaceBox(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              d.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          TagChip(text: sector.label, color: MidColors.navy),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Bo‘lim rahbari: ${head?.fullName ?? '-'}'
                        '${head != null ? ' (${head.role.label})' : ''}',
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: d.positions
                            .map(
                              (p) => TagChip(text: p, color: MidColors.teal),
                            )
                            .toList(),
                      ),
                      if (canEdit) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            TextButton.icon(
                              onPressed: () =>
                                  _assignHead(context, d),
                              icon: const Icon(Icons.badge_outlined, size: 18),
                              label: const Text('Rahbar/xodim tayinlash'),
                            ),
                            TextButton.icon(
                              onPressed: () =>
                                  _editDepartment(context, existing: d),
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: const Text('Tahrirlash'),
                            ),
                            TextButton.icon(
                              onPressed: () => _deleteDepartment(context, d),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: MidColors.coral,
                                size: 18,
                              ),
                              label: const Text("O'chirish"),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Future<void> _assignHead(BuildContext context, DepartmentItem d) async {
    AppUser? selected = store.userById(d.headId) ?? _headCandidates.firstOrNull;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('${d.name} — rahbar tayinlash'),
          content: DropdownButtonFormField<AppUser>(
            value: selected != null &&
                    _headCandidates.any((c) => c.id == selected!.id)
                ? selected
                : _headCandidates.firstOrNull,
            items: _headCandidates
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(
                      '${e.fullName} · ${e.role.label}'
                      '${e.sector != null ? ' · ${e.sector!.label}' : ''}',
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) => setLocal(() => selected = v),
            decoration: const InputDecoration(
              labelText: 'Rahbar yoki xodim',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Bekor'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Tayinlash'),
            ),
          ],
        ),
      ),
    );
    if (ok == true && selected != null) {
      store.assignDepartmentHead(d.id, selected!.id);
    }
  }

  Future<void> _deleteDepartment(
    BuildContext context,
    DepartmentItem d,
  ) async {
    final ok = await confirmDelete(
      context,
      title: "Bo'limni o'chirish",
      message: '«${d.name}» o‘chirilsinmi?',
    );
    if (!ok) return;
    await safeMutate(context, () => store.deleteDepartment(d.id));
  }

  Future<void> _editDepartment(
    BuildContext context, {
    DepartmentItem? existing,
  }) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final positions = TextEditingController(
      text: existing?.positions.join(', ') ?? 'Mutaxassis, Katta mutaxassis',
    );
    var sector = existing?.sector ?? user.sector ?? Sector.a;
    AppUser? head = existing != null
        ? store.userById(existing.headId)
        : _headCandidates
            .where((u) => u.role == UserRole.rahbar && u.sector == sector)
            .firstOrNull;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(
            existing == null ? "Yangi bo'lim" : "Bo'limni tahrirlash",
          ),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: "Bo'lim nomi"),
                  ),
                  DropdownButtonFormField<Sector>(
                    value: sector,
                    items: Sector.values
                        .map((s) =>
                            DropdownMenuItem(value: s, child: Text(s.label)))
                        .toList(),
                    onChanged: (v) => setLocal(() => sector = v ?? sector),
                    decoration: const InputDecoration(labelText: 'Sektor'),
                  ),
                  DropdownButtonFormField<AppUser>(
                    value: head != null &&
                            _headCandidates.any((c) => c.id == head!.id)
                        ? head
                        : _headCandidates.firstOrNull,
                    items: _headCandidates
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text('${e.fullName} · ${e.role.label}'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setLocal(() => head = v),
                    decoration: const InputDecoration(
                      labelText: 'Bo‘lim rahbari (rahbar/xodim)',
                    ),
                  ),
                  TextField(
                    controller: positions,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Lavozimlar (vergul bilan)',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Bekor'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(existing == null ? "Qo'shish" : 'Saqlash'),
            ),
          ],
        ),
      ),
    );

    if (ok == true && name.text.trim().isNotEmpty && head != null) {
      final pos = positions.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (existing == null) {
        store.addDepartment(
          name: name.text.trim(),
          sector: sector,
          headId: head!.id,
          positions: pos,
        );
      } else {
        store.updateDepartment(
          id: existing.id,
          name: name.text.trim(),
          sector: sector,
          headId: head!.id,
          positions: pos,
        );
      }
    }
  }
}

class _Node extends StatelessWidget {
  const _Node({
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MidColors.mist),
        color: accent.withValues(alpha: 0.08),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          Text(subtitle, style: const TextStyle(color: MidColors.navyMuted)),
        ],
      ),
    );
  }
}
