import 'package:flutter/material.dart';

import '../../core/safe_mutate.dart';
import '../../core/theme/mid_colors.dart';
import '../../data/mid_store.dart';
import '../../models/app_user.dart';
import '../../models/domain.dart';
import '../../models/user_role.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/section_header.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key, required this.user, required this.store});

  final AppUser user;
  final MidStore store;

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final canManage = widget.user.role.canAssignTasks;
    final visibleTasks = widget.user.role.isLeadership
        ? store.tasks
        : store.tasks.where((t) => t.assigneeId == widget.user.id).toList();

    final catalog = store.staffOnly.where((e) {
      final q = _query.toLowerCase();
      return q.isEmpty ||
          e.fullName.toLowerCase().contains(q) ||
          (e.position ?? '').toLowerCase().contains(q) ||
          (e.sector?.label.toLowerCase().contains(q) ?? false);
    }).toList();

    return PageScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: 'Topshiriqlar',
            subtitle: canManage
                ? 'Yuklash, tahrirlash va o‘chirish'
                : 'Sizga biriktirilgan vazifalar',
            action: canManage
                ? FilledButton.icon(
                    onPressed: () => _openEditor(context),
                    icon: const Icon(Icons.add_task),
                    label: const Text('Ish yuklash'),
                  )
                : null,
          ),
          if (canManage) ...[
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Xodim qidirish...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 12),
            SurfaceBox(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Xodimlar katalogi',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  ...catalog.map((e) {
                    final loaded =
                        store.assigneeIdsWithOpenTasks.contains(e.id);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(e.fullName),
                      subtitle: Text(
                        '${e.position ?? ''} · ${e.sector?.label ?? ''} · '
                        '${loaded ? 'Ish yuklangan' : 'Bo‘sh'}',
                      ),
                      trailing: TextButton(
                        onPressed: () => _openEditor(context, preselect: e),
                        child: const Text('Ish berish'),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          ...visibleTasks.map((task) {
            final assignee = store.userById(task.assigneeId);
            return Padding(
              key: ValueKey(task.id),
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
                            task.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        TagChip(
                          text: task.priority.label,
                          color: MidColors.coral,
                        ),
                        const SizedBox(width: 6),
                        TagChip(
                          text: task.status.label,
                          color: MidColors.teal,
                        ),
                        if (canManage) ...[
                          IconButton(
                            tooltip: 'Tahrirlash',
                            onPressed: () =>
                                _openEditor(context, existing: task),
                            icon: const Icon(Icons.edit_outlined, size: 20),
                          ),
                          IconButton(
                            tooltip: "O'chirish",
                            onPressed: () => _deleteTask(task),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: MidColors.coral,
                              size: 20,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(task.description),
                    const SizedBox(height: 6),
                    Text(
                      'Mas’ul: ${assignee?.fullName ?? task.assigneeId}',
                      style: const TextStyle(color: MidColors.navyMuted),
                    ),
                    if (!widget.user.role.isLeadership &&
                        task.assigneeId == widget.user.id) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: () => store.setTaskStatus(
                              task.id,
                              TaskStatus.javobBerildi,
                            ),
                            child: const Text('Javob berish'),
                          ),
                          OutlinedButton(
                            onPressed: () => store.setTaskStatus(
                              task.id,
                              TaskStatus.bajarildi,
                            ),
                            child: const Text('Bajarildi'),
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

  Future<void> _deleteTask(TaskItem task) async {
    final ok = await confirmDelete(
      context,
      title: "Topshiriqni o'chirish",
      message: '«${task.title}» o‘chirilsinmi?',
    );
    if (!ok || !mounted) return;
    await safeMutate(context, () => widget.store.deleteTask(task.id));
  }

  Future<void> _openEditor(
    BuildContext context, {
    AppUser? preselect,
    TaskItem? existing,
  }) async {
    final title = TextEditingController(text: existing?.title ?? '');
    final desc = TextEditingController(text: existing?.description ?? '');
    AppUser? selected = existing != null
        ? widget.store.userById(existing.assigneeId)
        : (preselect ?? widget.store.staffOnly.firstOrNull);
    var priority = existing?.priority ?? TaskPriority.orta;
    var status = existing?.status ?? TaskStatus.yangi;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: Text(existing == null
                  ? 'Xodimga ish yuklash'
                  : 'Topshiriqni tahrirlash'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<AppUser>(
                        value: selected,
                        items: widget.store.staffOnly
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text('${e.fullName} · ${e.position}'),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setLocal(() => selected = v),
                        decoration: const InputDecoration(labelText: 'Xodim'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: title,
                        decoration:
                            const InputDecoration(labelText: 'Sarlavha'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: desc,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Tavsif'),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<TaskPriority>(
                        value: priority,
                        items: TaskPriority.values
                            .map(
                              (p) => DropdownMenuItem(
                                value: p,
                                child: Text(p.label),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setLocal(() => priority = v ?? priority),
                        decoration:
                            const InputDecoration(labelText: 'Muhimlik'),
                      ),
                      if (existing != null) ...[
                        const SizedBox(height: 10),
                        DropdownButtonFormField<TaskStatus>(
                          value: status,
                          items: TaskStatus.values
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s.label),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setLocal(() => status = v ?? status),
                          decoration:
                              const InputDecoration(labelText: 'Holat'),
                        ),
                      ],
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
                  child: Text(existing == null ? 'Yuklash' : 'Saqlash'),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok == true && selected != null && title.text.trim().isNotEmpty) {
      if (existing == null) {
        widget.store.assignTask(
          title: title.text.trim(),
          description: desc.text.trim(),
          assigneeId: selected!.id,
          createdById: widget.user.id,
          priority: priority,
        );
      } else {
        widget.store.updateTask(
          taskId: existing.id,
          title: title.text.trim(),
          description: desc.text.trim(),
          assigneeId: selected!.id,
          priority: priority,
          status: status,
          projectId: existing.projectId,
        );
      }
    }
  }
}
