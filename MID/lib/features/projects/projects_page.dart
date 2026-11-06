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

class ProjectsPage extends StatelessWidget {
  const ProjectsPage({super.key, required this.user, required this.store});

  final AppUser user;
  final MidStore store;

  @override
  Widget build(BuildContext context) {
    final canManage = user.role.canAssignTasks;
    final list = user.role == UserRole.xodim || user.role == UserRole.shogirt
        ? store.projects
            .where((p) => p.assigneeIds.contains(user.id))
            .toList()
        : store.projects;

    return PageScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: 'Loyihalar va startuplar',
            subtitle: 'Tahrirlash, bosqich, yangiliklar va moliyaviy ma’lumot',
            action: canManage
                ? FilledButton.icon(
                    onPressed: () => _editProject(context),
                    icon: const Icon(Icons.add),
                    label: const Text("Loyiha qo'shish"),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          ...list.map((p) {
            final updates = store.updatesFor(p.id);
            return Padding(
              key: ValueKey(p.id),
              padding: const EdgeInsets.only(bottom: 12),
              child: SurfaceBox(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            p.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        TagChip(text: p.stage, color: MidColors.teal),
                        const SizedBox(width: 6),
                        TagChip(text: p.sector.label, color: MidColors.navy),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(p.description),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 20,
                      runSpacing: 10,
                      children: [
                        _Money('Talab', p.requiredBudget),
                        _Money('Invest', p.investment),
                        _Money('Xarajat', p.expense),
                        _Money('Balans', p.balance),
                        _Money('Yetishmayotgan', p.remainingNeed),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Loyiha qismlari',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    if (p.memberPositions.isNotEmpty) ...[
                      Text(
                        'Jamoa lavozimlari',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      ...p.memberPositions.entries.map((e) {
                        final emp = store.userById(e.key);
                        return Text(
                          '${emp?.fullName ?? e.key}: ${e.value}',
                        );
                      }),
                      const SizedBox(height: 14),
                    ],
                    if (p.parts.isEmpty)
                      const Text(
                        "Hali qismga xodim biriktirilmagan",
                        style: TextStyle(color: MidColors.navyMuted),
                      )
                    else
                      ...p.parts.entries.map((e) {
                        final emp = store.userById(e.value);
                        final role = p.memberPositions[e.value];
                        final rolePart =
                            role != null && role.isNotEmpty ? ' · $role' : '';
                        return Text(
                          '${e.key}: ${emp?.fullName ?? e.value}$rolePart',
                        );
                      }),
                    const SizedBox(height: 14),
                    Text(
                      'Loyiha yangiliklari',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    if (updates.isEmpty)
                      const Text(
                        'Hali yangilik yo‘q',
                        style: TextStyle(color: MidColors.navyMuted),
                      )
                    else
                      ...updates.take(5).map((u) {
                        final author = store.userById(u.authorId);
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: MidColors.sand,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                u.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(u.body),
                              Text(
                                '${author?.fullName ?? ''} · ${shortDate(u.createdAt)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: MidColors.navyMuted,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    if (canManage) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _setStage(context, p),
                            icon: const Icon(Icons.flag_outlined),
                            label: const Text('Bosqich'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _addUpdate(context, p.id),
                            icon: const Icon(Icons.newspaper_outlined),
                            label: const Text('Yangilik'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _assignPart(context, p.id),
                            icon: const Icon(Icons.person_add_alt),
                            label: const Text('Xodim'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _editProject(context, existing: p),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Tahrirlash'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _deleteProject(context, p),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: MidColors.coral,
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
        ],
      ),
    );
  }

  Future<void> _setStage(BuildContext context, ProjectItem p) async {
    var stage = ProjectStages.values.contains(p.stage)
        ? p.stage
        : ProjectStages.values.first;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Jarayon bosqichi'),
          content: DropdownButtonFormField<String>(
            value: stage,
            items: ProjectStages.values
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setLocal(() => stage = v ?? stage),
            decoration: const InputDecoration(labelText: 'Bosqich'),
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
    if (ok == true) {
      await safeMutate(context, () => store.setProjectStage(p.id, stage));
    }
  }

  Future<void> _addUpdate(BuildContext context, String projectId) async {
    final title = TextEditingController();
    final body = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Loyiha yangiligi'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'Sarlavha'),
              ),
              TextField(
                controller: body,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Matn'),
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
            child: const Text('Yozish'),
          ),
        ],
      ),
    );
    if (ok == true && title.text.trim().isNotEmpty) {
      await safeMutate(
        context,
        () => store.addProjectUpdate(
          projectId: projectId,
          authorId: user.id,
          title: title.text.trim(),
          body: body.text.trim(),
        ),
      );
    }
  }

  Future<void> _deleteProject(BuildContext context, ProjectItem p) async {
    final ok = await confirmDelete(
      context,
      title: "Loyihani o'chirish",
      message: '«${p.name}» o‘chirilsinmi?',
    );
    if (!ok) return;
    await safeMutate(context, () => store.deleteProject(p.id));
  }

  Future<void> _editProject(
    BuildContext context, {
    ProjectItem? existing,
  }) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final desc = TextEditingController(text: existing?.description ?? '');
    var stage = existing?.stage ?? 'Boshlanish';
    if (!ProjectStages.values.contains(stage)) {
      stage = ProjectStages.values.first;
    }
    final required = TextEditingController(
      text: '${existing?.requiredBudget ?? 100000000}',
    );
    final invest =
        TextEditingController(text: '${existing?.investment ?? 0}');
    final expense =
        TextEditingController(text: '${existing?.expense ?? 0}');
    var sector = existing?.sector ??
        (user.sector == Sector.b ? ProjectSector.b : ProjectSector.a);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(existing == null ? 'Yangi loyiha' : 'Loyihani tahrirlash'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Nomi'),
                  ),
                  TextField(
                    controller: desc,
                    maxLines: 3,
                    decoration:
                        const InputDecoration(labelText: "To'liq tavsif"),
                  ),
                  DropdownButtonFormField<String>(
                    value: stage,
                    items: ProjectStages.values
                        .map((s) =>
                            DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setLocal(() => stage = v ?? stage),
                    decoration: const InputDecoration(labelText: 'Bosqich'),
                  ),
                  TextField(
                    controller: required,
                    decoration: const InputDecoration(
                      labelText: 'Talab qilinadigan pul',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: invest,
                    decoration:
                        const InputDecoration(labelText: 'Investitsiya'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: expense,
                    decoration: const InputDecoration(labelText: 'Xarajat'),
                    keyboardType: TextInputType.number,
                  ),
                  DropdownButtonFormField<ProjectSector>(
                    value: sector,
                    items: ProjectSector.values
                        .map((s) =>
                            DropdownMenuItem(value: s, child: Text(s.label)))
                        .toList(),
                    onChanged: (v) => setLocal(() => sector = v ?? sector),
                    decoration: const InputDecoration(
                      labelText: 'Jamoa (A / B / ikkala)',
                      helperText:
                          'Ikkala tanlansa — har ikki rahbarga ish yuklanadi',
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

    if (ok == true && name.text.trim().isNotEmpty) {
      await safeMutate(context, () async {
        if (existing == null) {
          await store.addProject(
            name: name.text.trim(),
            description: desc.text.trim(),
            stage: stage,
            requiredBudget: int.tryParse(required.text) ?? 0,
            investment: int.tryParse(invest.text) ?? 0,
            expense: int.tryParse(expense.text) ?? 0,
            sector: sector,
          );
        } else {
          await store.updateProject(
            projectId: existing.id,
            name: name.text.trim(),
            description: desc.text.trim(),
            stage: stage,
            requiredBudget: int.tryParse(required.text) ?? 0,
            investment: int.tryParse(invest.text) ?? 0,
            expense: int.tryParse(expense.text) ?? 0,
            sector: sector,
          );
        }
      });
    }
  }

  Future<void> _assignPart(BuildContext context, String projectId) async {
    final part = TextEditingController();
    final titles = store.jobTitleNames;
    AppUser? emp = store.staffOnly.firstOrNull;
    String? position = titles.isNotEmpty
        ? (emp?.position != null && titles.contains(emp!.position)
            ? emp!.position
            : titles.first)
        : emp?.position;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Qismga xodim'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: part,
                  decoration: const InputDecoration(
                    labelText: "Loyiha qismi",
                  ),
                ),
                DropdownButtonFormField<AppUser>(
                  value: emp,
                  items: store.staffOnly
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(
                            '${e.fullName}${e.position != null ? ' · ${e.position}' : ''}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setLocal(() {
                    emp = v;
                    final pos = v?.position;
                    if (pos != null && titles.contains(pos)) {
                      position = pos;
                    }
                  }),
                  decoration: const InputDecoration(labelText: 'Xodim'),
                ),
                if (titles.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: position != null && titles.contains(position)
                        ? position
                        : titles.first,
                    items: titles
                        .map(
                          (p) => DropdownMenuItem(value: p, child: Text(p)),
                        )
                        .toList(),
                    onChanged: (v) => setLocal(() => position = v),
                    decoration: const InputDecoration(
                      labelText: 'Loyihadagi lavozim',
                      helperText:
                          'Asosiy lavozimidan farq qilishi mumkin',
                    ),
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
              child: const Text('Biriktirish'),
            ),
          ],
        ),
      ),
    );
    if (ok == true && emp != null && part.text.trim().isNotEmpty) {
      await safeMutate(
        context,
        () => store.assignEmployeeToProjectPart(
          projectId: projectId,
          partName: part.text.trim(),
          employeeId: emp!.id,
          position: position,
        ),
      );
    }
  }
}

class _Money extends StatelessWidget {
  const _Money(this.label, this.value);

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: MidColors.navyMuted)),
        Text(
          moneySum(value),
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
