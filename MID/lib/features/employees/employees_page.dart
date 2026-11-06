import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/safe_mutate.dart';
import '../../core/theme/mid_colors.dart';
import '../../data/mid_store.dart';
import '../../models/app_user.dart';
import '../../models/nav_destination.dart';
import '../../models/user_role.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/section_header.dart';

class EmployeesPage extends StatefulWidget {
  const EmployeesPage({super.key, required this.user, required this.store});

  final AppUser user;
  final MidStore store;

  @override
  State<EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends State<EmployeesPage> {
  String query = '';
  Sector? sectorFilter;
  String? deptFilter;
  String? positionFilter;

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final canManage = widget.user.role.canManageStaff;
    final positions = store.departments.expand((d) => d.positions).toSet().toList()
      ..sort();

    final list = store.employees.where((e) {
      if (e.role == UserRole.direktor) return true;
      final q = query.toLowerCase();
      final matchQ = q.isEmpty ||
          e.fullName.toLowerCase().contains(q) ||
          e.login.toLowerCase().contains(q) ||
          (e.position ?? '').toLowerCase().contains(q);
      final matchS = sectorFilter == null || e.sector == sectorFilter;
      final matchD = deptFilter == null || e.departmentId == deptFilter;
      final matchP = positionFilter == null || e.position == positionFilter;
      return matchQ && matchS && matchD && matchP;
    }).toList();

    return PageScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: 'Xodimlar',
            subtitle:
                "Filterlar, katalog, qo'shish va o'chirish (Direktor + 2 Rahbar)",
            action: canManage
                ? FilledButton.icon(
                    onPressed: () => _addEmployee(context),
                    icon: const Icon(Icons.person_add_alt),
                    label: const Text("Yangi xodim"),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              hintText: 'Qidirish...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => query = v),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              DropdownButton<Sector?>(
                value: sectorFilter,
                hint: const Text('Sektor'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Barcha sektor')),
                  ...Sector.values.map(
                    (s) => DropdownMenuItem(value: s, child: Text(s.label)),
                  ),
                ],
                onChanged: (v) => setState(() => sectorFilter = v),
              ),
              DropdownButton<String?>(
                value: deptFilter,
                hint: const Text("Bo'lim"),
                items: [
                  const DropdownMenuItem(value: null, child: Text("Barcha bo'lim")),
                  ...store.departments.map(
                    (d) => DropdownMenuItem(value: d.id, child: Text(d.name)),
                  ),
                ],
                onChanged: (v) => setState(() => deptFilter = v),
              ),
              DropdownButton<String?>(
                value: positionFilter,
                hint: const Text('Lavozim'),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Barcha lavozim'),
                  ),
                  ...positions.map(
                    (p) => DropdownMenuItem(value: p, child: Text(p)),
                  ),
                ],
                onChanged: (v) => setState(() => positionFilter = v),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...list.map((e) {
            final dept = store.departments
                .where((d) => d.id == e.departmentId)
                .firstOrNull;
            final canDelete = canManage &&
                e.id != widget.user.id &&
                RolePermissions.canDeleteUser(widget.user.role, e);
            return Padding(
              key: ValueKey(e.id),
              padding: const EdgeInsets.only(bottom: 10),
              child: SurfaceBox(
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: MidColors.teal.withValues(alpha: 0.15),
                      foregroundColor: MidColors.teal,
                      child: Text(e.fullName.substring(0, 1)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.fullName,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${e.role.label}'
                            '${e.sector != null ? ' · ${e.sector!.label}' : ''}'
                            '${dept != null ? ' · ${dept.name}' : ''}'
                            '${e.position != null ? ' · ${e.position}' : ''}',
                            style: const TextStyle(color: MidColors.navyMuted),
                          ),
                          if (canManage)
                            Text(
                              'Login: ${e.login} · Parol: ${e.password} · Maosh: ${moneySum(e.salary)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                    if (canManage &&
                        e.role != UserRole.direktor &&
                        (e.role != UserRole.rahbar ||
                            widget.user.role == UserRole.direktor))
                      IconButton(
                        tooltip: 'Tahrirlash',
                        onPressed: () => _editEmployee(context, e),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    if (canDelete)
                      IconButton(
                        tooltip: "O'chirish",
                        onPressed: () => _confirmDelete(context, e),
                        icon: const Icon(Icons.delete_outline, color: MidColors.coral),
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

  Future<void> _editEmployee(BuildContext context, AppUser existing) async {
    final name = TextEditingController(text: existing.fullName);
    final login = TextEditingController(text: existing.login);
    final password = TextEditingController(text: existing.password);
    final salary = TextEditingController(text: '${existing.salary}');
    String? position = existing.position;
    String? deptId = existing.departmentId;
    var sector = existing.sector ?? Sector.a;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final dept = widget.store.departments
              .where((d) => d.id == deptId)
              .firstOrNull;
          final positions = dept?.positions ?? <String>[];
          return AlertDialog(
            title: const Text('Xodimni tahrirlash'),
            content: SizedBox(
              width: 440,
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
                    DropdownButtonFormField<Sector>(
                      value: sector,
                      items: Sector.values
                          .map((s) =>
                              DropdownMenuItem(value: s, child: Text(s.label)))
                          .toList(),
                      onChanged: (v) => setLocal(() => sector = v ?? sector),
                      decoration: const InputDecoration(labelText: 'Sektor'),
                    ),
                    DropdownButtonFormField<String>(
                      value: deptId,
                      items: widget.store.departments
                          .map(
                            (d) => DropdownMenuItem(
                              value: d.id,
                              child: Text('${d.name} (${d.sector.short})'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setLocal(() {
                        deptId = v;
                        position = null;
                      }),
                      decoration: const InputDecoration(labelText: "Bo'lim"),
                    ),
                    DropdownButtonFormField<String>(
                      value: position != null && positions.contains(position)
                          ? position
                          : null,
                      items: positions
                          .map((p) =>
                              DropdownMenuItem(value: p, child: Text(p)))
                          .toList(),
                      onChanged: (v) => setLocal(() => position = v),
                      decoration: const InputDecoration(labelText: 'Lavozim'),
                    ),
                    TextField(
                      controller: salary,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Maosh'),
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
          );
        },
      ),
    );

    if (ok == true && name.text.trim().isNotEmpty) {
      if (widget.store.loginTaken(login.text, exceptUserId: existing.id)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bu login band')),
          );
        }
        return;
      }
      widget.store.updateStaffUser(
        userId: existing.id,
        fullName: name.text.trim(),
        login: login.text.trim(),
        password: password.text.trim(),
        sector: sector,
        departmentId: deptId,
        position: position,
        salary: int.tryParse(salary.text) ?? 0,
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, AppUser target) async {
    final ok = await confirmDelete(
      context,
      title: "Xodimni o'chirish",
      message:
          '${target.fullName} tizimdan o‘chirilsinmi?\nLogin ishlamay qoladi.',
    );
    if (!ok) return;
    await safeMutate(
      context,
      () => widget.store.deleteUser(target.id, actorRole: widget.user.role),
    );
  }

  Future<void> _addEmployee(BuildContext context) async {
    final name = TextEditingController();
    final login = TextEditingController();
    final password = TextEditingController(text: '1234');
    final salary = TextEditingController(text: '7000000');
    String? position;
    String? deptId = widget.store.departments.firstOrNull?.id;
    var sector = Sector.a;
    var role = UserRole.xodim;
    final isDirector = widget.user.role == UserRole.direktor;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final dept = widget.store.departments
              .where((d) => d.id == deptId)
              .firstOrNull;
          final positions = dept?.positions ?? <String>[];
          return AlertDialog(
            title: const Text("Yangi xodim + login/parol"),
            content: SizedBox(
              width: 440,
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
                      items: [
                        const DropdownMenuItem(
                          value: UserRole.xodim,
                          child: Text('Xodim'),
                        ),
                        if (isDirector)
                          const DropdownMenuItem(
                            value: UserRole.rahbar,
                            child: Text('Rahbar'),
                          ),
                      ],
                      onChanged: (v) => setLocal(() => role = v ?? role),
                      decoration: const InputDecoration(labelText: 'Rol'),
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
                    DropdownButtonFormField<String>(
                      value: deptId,
                      items: widget.store.departments
                          .map(
                            (d) => DropdownMenuItem(
                              value: d.id,
                              child: Text('${d.name} (${d.sector.short})'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setLocal(() {
                        deptId = v;
                        position = null;
                      }),
                      decoration: const InputDecoration(labelText: "Bo'lim"),
                    ),
                    DropdownButtonFormField<String>(
                      value: position,
                      items: positions
                          .map((p) =>
                              DropdownMenuItem(value: p, child: Text(p)))
                          .toList(),
                      onChanged: (v) => setLocal(() => position = v),
                      decoration: const InputDecoration(labelText: 'Lavozim'),
                    ),
                    TextField(
                      controller: salary,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Maosh'),
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
          );
        },
      ),
    );

    if (ok == true &&
        name.text.trim().isNotEmpty &&
        login.text.trim().isNotEmpty) {
      if (widget.store.loginTaken(login.text)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bu login band')),
          );
        }
        return;
      }
      widget.store.addUser(
        fullName: name.text.trim(),
        login: login.text.trim(),
        password: password.text.trim(),
        role: role,
        sector: sector,
        departmentId: deptId,
        position: position,
        salary: int.tryParse(salary.text) ?? 0,
      );
    }
  }
}
