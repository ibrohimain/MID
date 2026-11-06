import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/safe_mutate.dart';
import '../../core/theme/mid_colors.dart';
import '../../data/mid_store.dart';
import '../../models/app_user.dart';
import '../../models/domain.dart';
import '../../models/nav_destination.dart';
import '../../models/user_role.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/section_header.dart';

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key, required this.user, required this.store});

  final AppUser user;
  final MidStore store;

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs =
      TabController(length: 4, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canManage = widget.user.role.isLeadership;
    final learners = widget.user.isLearner
        ? widget.store.learners.where((l) => l.id == widget.user.id).toList()
        : widget.store.learners;

    return ColoredBox(
      color: MidColors.sand,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: SectionHeader(
                title: "O'quvchilar va shogirtlar",
                subtitle: "Guruh, yo'qlama, baho, material va reyting",
                action: canManage
                    ? FilledButton.icon(
                        onPressed: () => _addLearner(context),
                        icon: const Icon(Icons.person_add_alt),
                        label: const Text("Qo'shish"),
                      )
                    : null,
              ),
            ),
            TabBar(
              controller: _tabs,
              isScrollable: true,
              labelColor: MidColors.teal,
              tabs: const [
                Tab(text: "Ro'yxat"),
                Tab(text: "Yo'qlama/baho"),
                Tab(text: 'Materiallar'),
                Tab(text: 'Top reyting'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _listTab(learners, canManage),
                  _attendanceTab(canManage),
                  _materialsTab(canManage),
                  _rankingTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _listTab(List<AppUser> learners, bool canManage) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (canManage) ...[
          SurfaceBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Guruhlar va mas’ul ustozlar',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                ...widget.store.groups.map((g) {
                  final teacher = widget.store.userById(g.teacherId);
                  return Text(
                    '${g.name} · ${g.direction} · Ustoz: ${teacher?.fullName ?? '-'}',
                  );
                }),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => _addGroup(context),
                  icon: const Icon(Icons.group_add),
                  label: const Text("Guruh qo'shish"),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        ...learners.map((s) {
          final avg = widget.store.averageGrade(s.id);
          final canDelete = canManage &&
              RolePermissions.canDeleteUser(widget.user.role, s);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SurfaceBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.fullName,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      TagChip(text: s.role.label, color: MidColors.coral),
                      if (canManage)
                        IconButton(
                          tooltip: 'Tahrirlash',
                          onPressed: () => _editLearner(s),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                      if (canDelete)
                        IconButton(
                          tooltip: "O'chirish",
                          onPressed: () => _confirmDeleteLearner(s),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: MidColors.coral,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Yo'nalish: ${s.direction ?? '-'} · "
                    "To'lov: ${moneySum(s.paymentAmount)}",
                  ),
                  Text(
                    "O'qigan: ${s.studiedMonths} oy · "
                    "Qolgan: ${s.remainingMonths} oy · "
                    "Jami: ${s.totalMonths} oy",
                  ),
                  Text(
                    "O'rtacha baho: ${avg.toStringAsFixed(1)} / 10",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (canManage)
                    Text(
                      'Login: ${s.login} · Parol: ${s.password}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: MidColors.navyMuted,
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _attendanceTab(bool canManage) {
    if (!canManage) {
      final mine = widget.store.attendance
          .where((a) => a.studentId == widget.user.id)
          .toList();
      return ListView(
        padding: const EdgeInsets.all(24),
        children: mine
            .map(
              (a) => SurfaceBox(
                child: Text(
                  '${shortDate(a.date)} · '
                  '${a.present ? "Kelgan" : "Yo'q"} · Baho: ${a.grade}',
                ),
              ),
            )
            .toList(),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        FilledButton.icon(
          onPressed: () => _markAttendance(context),
          icon: const Icon(Icons.fact_check_outlined),
          label: const Text("Bugungi yo'qlama / baho"),
        ),
        const SizedBox(height: 12),
        ...widget.store.attendance.reversed.map((a) {
          final student = widget.store.userById(a.studentId);
          final group = widget.store.groups
              .where((g) => g.id == a.groupId)
              .firstOrNull;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SurfaceBox(
              child: Text(
                '${shortDate(a.date)} · ${group?.name ?? ''} · '
                '${student?.fullName ?? ''} · '
                '${a.present ? "Kelgan" : "Yo'q"} · ${a.grade}/10',
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _materialsTab(bool canManage) {
    final mats = widget.user.isLearner
        ? widget.store.materials
            .where((m) => m.groupId == widget.user.groupId)
            .toList()
        : widget.store.materials;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (canManage)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FilledButton.icon(
              onPressed: () => _addMaterial(context),
              icon: const Icon(Icons.upload_file),
              label: const Text('Material yuklash'),
            ),
          ),
        ...mats.map((m) {
          final group =
              widget.store.groups.where((g) => g.id == m.groupId).firstOrNull;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SurfaceBox(
              child: Row(
                children: [
                  TagChip(text: m.type.label, color: MidColors.teal),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.title,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${group?.name ?? ''} · ${m.urlOrNote}',
                          style: const TextStyle(color: MidColors.navyMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _rankingTab() {
    final top = widget.store.topStudents();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        for (var i = 0; i < top.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SurfaceBox(
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: i == 0
                        ? MidColors.coral.withValues(alpha: 0.2)
                        : MidColors.teal.withValues(alpha: 0.15),
                    foregroundColor:
                        i == 0 ? MidColors.coral : MidColors.teal,
                    child: Text('${i + 1}'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      top[i].fullName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    '${widget.store.averageGrade(top[i].id).toStringAsFixed(1)} / 10',
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _editLearner(AppUser existing) async {
    final name = TextEditingController(text: existing.fullName);
    final login = TextEditingController(text: existing.login);
    final password = TextEditingController(text: existing.password);
    final payment =
        TextEditingController(text: '${existing.paymentAmount}');
    final studied =
        TextEditingController(text: '${existing.studiedMonths}');
    final total = TextEditingController(text: '${existing.totalMonths}');
    var role = existing.role;
    String? groupId = existing.groupId;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text("O'quvchini tahrirlash"),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'F.I.Sh'),
                  ),
                  TextField(
                    controller: login,
                    decoration: const InputDecoration(labelText: 'Login'),
                  ),
                  TextField(
                    controller: password,
                    decoration: const InputDecoration(labelText: 'Parol'),
                  ),
                  DropdownButtonFormField<UserRole>(
                    value: role,
                    items: const [
                      DropdownMenuItem(
                        value: UserRole.oquvchi,
                        child: Text("O'quvchi"),
                      ),
                      DropdownMenuItem(
                        value: UserRole.shogirt,
                        child: Text('Shogirt'),
                      ),
                    ],
                    onChanged: (v) => setLocal(() => role = v ?? role),
                    decoration: const InputDecoration(labelText: 'Rol'),
                  ),
                  DropdownButtonFormField<String>(
                    value: groupId,
                    items: widget.store.groups
                        .map(
                          (g) => DropdownMenuItem(
                            value: g.id,
                            child: Text('${g.name} · ${g.direction}'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setLocal(() => groupId = v),
                    decoration: const InputDecoration(labelText: 'Guruh'),
                  ),
                  TextField(
                    controller: payment,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "To'lov"),
                  ),
                  TextField(
                    controller: studied,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: "O'qigan oy"),
                  ),
                  TextField(
                    controller: total,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Jami muddat (oy)'),
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
              child: const Text('Saqlash'),
            ),
          ],
        ),
      ),
    );

    if (ok == true && name.text.trim().isNotEmpty) {
      final group =
          widget.store.groups.where((g) => g.id == groupId).firstOrNull;
      widget.store.updateStaffUser(
        userId: existing.id,
        fullName: name.text.trim(),
        login: login.text.trim(),
        password: password.text.trim(),
        role: role,
        groupId: groupId,
        direction: group?.direction,
        sector: group?.sector,
        paymentAmount: int.tryParse(payment.text) ?? 0,
        studiedMonths: int.tryParse(studied.text) ?? 0,
        totalMonths: int.tryParse(total.text) ?? 0,
      );
    }
  }

  Future<void> _confirmDeleteLearner(AppUser target) async {
    final ok = await confirmDelete(
      context,
      title: "O'quvchini o'chirish",
      message: '${target.fullName} tizimdan o‘chirilsinmi?',
    );
    if (!ok) return;
    await safeMutate(
      context,
      () => widget.store.deleteUser(target.id, actorRole: widget.user.role),
    );
  }

  Future<void> _addLearner(BuildContext context) async {
    final name = TextEditingController();
    final login = TextEditingController();
    final password = TextEditingController(text: '1234');
    final payment = TextEditingController(text: '3000000');
    final studied = TextEditingController(text: '0');
    final total = TextEditingController(text: '9');
    var role = UserRole.oquvchi;
    String? groupId = widget.store.groups.firstOrNull?.id;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text("Yangi o'quvchi / shogirt"),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'F.I.Sh'),
                  ),
                  TextField(
                    controller: login,
                    decoration: const InputDecoration(labelText: 'Login'),
                  ),
                  TextField(
                    controller: password,
                    decoration: const InputDecoration(labelText: 'Parol'),
                  ),
                  DropdownButtonFormField<UserRole>(
                    value: role,
                    items: const [
                      DropdownMenuItem(
                        value: UserRole.oquvchi,
                        child: Text("O'quvchi"),
                      ),
                      DropdownMenuItem(
                        value: UserRole.shogirt,
                        child: Text('Shogirt'),
                      ),
                    ],
                    onChanged: (v) => setLocal(() => role = v ?? role),
                    decoration: const InputDecoration(labelText: 'Rol'),
                  ),
                  DropdownButtonFormField<String>(
                    value: groupId,
                    items: widget.store.groups
                        .map(
                          (g) => DropdownMenuItem(
                            value: g.id,
                            child: Text('${g.name} · ${g.direction}'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setLocal(() => groupId = v),
                    decoration: const InputDecoration(labelText: 'Guruh'),
                  ),
                  TextField(
                    controller: payment,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "To'lov"),
                  ),
                  TextField(
                    controller: studied,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: "O'qigan oy"),
                  ),
                  TextField(
                    controller: total,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Jami muddat (oy)'),
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
              child: const Text("Qo'shish"),
            ),
          ],
        ),
      ),
    );

    if (ok == true && name.text.trim().isNotEmpty) {
      final group =
          widget.store.groups.where((g) => g.id == groupId).firstOrNull;
      widget.store.addUser(
        fullName: name.text.trim(),
        login: login.text.trim(),
        password: password.text.trim(),
        role: role,
        groupId: groupId,
        direction: group?.direction,
        sector: group?.sector,
        paymentAmount: int.tryParse(payment.text) ?? 0,
        studiedMonths: int.tryParse(studied.text) ?? 0,
        totalMonths: int.tryParse(total.text) ?? 0,
      );
    }
  }

  Future<void> _addGroup(BuildContext context) async {
    final name = TextEditingController();
    final direction = TextEditingController();
    AppUser? teacher = widget.store.staffOnly.firstOrNull;
    var sector = Sector.a;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text("Yangi guruh"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Guruh nomi'),
              ),
              TextField(
                controller: direction,
                decoration: const InputDecoration(labelText: "Yo'nalish"),
              ),
              DropdownButtonFormField<AppUser>(
                value: teacher,
                items: widget.store.staffOnly
                    .map((e) =>
                        DropdownMenuItem(value: e, child: Text(e.fullName)))
                    .toList(),
                onChanged: (v) => setLocal(() => teacher = v),
                decoration: const InputDecoration(labelText: 'Mas’ul ustoz'),
              ),
              DropdownButtonFormField<Sector>(
                value: sector,
                items: Sector.values
                    .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                    .toList(),
                onChanged: (v) => setLocal(() => sector = v ?? sector),
                decoration: const InputDecoration(labelText: 'Sektor'),
              ),
            ],
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
      ),
    );
    if (ok == true && teacher != null && name.text.trim().isNotEmpty) {
      widget.store.addGroup(
        name: name.text.trim(),
        direction: direction.text.trim(),
        teacherId: teacher!.id,
        sector: sector,
      );
    }
  }

  Future<void> _markAttendance(BuildContext context) async {
    String? groupId = widget.store.groups.firstOrNull?.id;
    List<AppUser> groupStudents() => widget.store.learners
        .where((l) => l.groupId == groupId)
        .toList();
    final grades = <String, int>{};
    final present = <String, bool>{};

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final list = groupStudents();
          for (final s in list) {
            grades.putIfAbsent(s.id, () => 7);
            present.putIfAbsent(s.id, () => true);
          }
          return AlertDialog(
            title: const Text("Yo'qlama (1-10 baho)"),
            content: SizedBox(
              width: 460,
              height: 360,
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: groupId,
                    items: widget.store.groups
                        .map((g) => DropdownMenuItem(
                              value: g.id,
                              child: Text(g.name),
                            ))
                        .toList(),
                    onChanged: (v) => setLocal(() => groupId = v),
                    decoration: const InputDecoration(labelText: 'Guruh'),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      children: list.map((s) {
                        return ListTile(
                          title: Text(s.fullName),
                          subtitle: Row(
                            children: [
                              Checkbox(
                                value: present[s.id] ?? true,
                                onChanged: (v) => setLocal(
                                  () => present[s.id] = v ?? true,
                                ),
                              ),
                              const Text('Keldi'),
                              const SizedBox(width: 12),
                              DropdownButton<int>(
                                value: grades[s.id],
                                items: [
                                  for (var i = 1; i <= 10; i++)
                                    DropdownMenuItem(
                                      value: i,
                                      child: Text('$i'),
                                    ),
                                ],
                                onChanged: (v) =>
                                    setLocal(() => grades[s.id] = v ?? 7),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
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
                child: const Text('Saqlash'),
              ),
            ],
          );
        },
      ),
    );

    if (ok == true && groupId != null) {
      for (final s in groupStudents()) {
        widget.store.markAttendance(
          groupId: groupId!,
          studentId: s.id,
          present: present[s.id] ?? true,
          grade: grades[s.id] ?? 7,
        );
      }
    }
  }

  Future<void> _addMaterial(BuildContext context) async {
    final title = TextEditingController();
    final note = TextEditingController();
    String? groupId = widget.store.groups.firstOrNull?.id;
    var type = StudyMaterialKind.darslik;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Material'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: groupId,
                items: widget.store.groups
                    .map((g) =>
                        DropdownMenuItem(value: g.id, child: Text(g.name)))
                    .toList(),
                onChanged: (v) => setLocal(() => groupId = v),
                decoration: const InputDecoration(labelText: 'Guruh'),
              ),
              DropdownButtonFormField<StudyMaterialKind>(
                value: type,
                items: StudyMaterialKind.values
                    .map((t) =>
                        DropdownMenuItem(value: t, child: Text(t.label)))
                    .toList(),
                onChanged: (v) => setLocal(() => type = v ?? type),
                decoration: const InputDecoration(labelText: 'Turi'),
              ),
              TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'Sarlavha'),
              ),
              TextField(
                controller: note,
                decoration:
                    const InputDecoration(labelText: 'Havola / izoh'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Bekor'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Yuklash'),
            ),
          ],
        ),
      ),
    );
    if (ok == true && groupId != null && title.text.trim().isNotEmpty) {
      widget.store.addMaterial(
        groupId: groupId!,
        title: title.text.trim(),
        type: type,
        urlOrNote: note.text.trim(),
      );
    }
  }
}
