import 'package:flutter/material.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/theme/mid_colors.dart';
import '../../data/mid_store.dart';
import '../../models/nav_destination.dart';
import '../../models/user_role.dart';
import '../../widgets/listenable_page.dart';
import '../../widgets/mid_logo.dart';
import '../announcements/announcements_page.dart';
import '../dashboard/dashboard_page.dart';
import '../departments/departments_page.dart';
import '../employees/employees_page.dart';
import '../finance/finance_page.dart';
import '../positions/positions_page.dart';
import '../profile/profile_page.dart';
import '../projects/projects_page.dart';
import '../students/students_page.dart';
import '../tasks/tasks_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.auth, required this.store});

  final AuthController auth;
  final MidStore store;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  MidPage _page = MidPage.dashboard;

  @override
  Widget build(BuildContext context) {
    final user = widget.auth.user!;
    final pages = RolePermissions.pagesFor(user.role);
    final currentPage = pages.contains(_page) ? _page : pages.first;
    final selectedIndex = pages.indexOf(currentPage);
    final wide = MediaQuery.sizeOf(context).width >= 980;
    final store = widget.store;

    // Store o'zgarganda faqat content qayta chiziladi — scroll siljimaydi.
    final content = ListenablePage(
      store: store,
      builder: (context) => switch (currentPage) {
        MidPage.dashboard => DashboardPage(user: user, store: store),
        MidPage.tasks => TasksPage(user: user, store: store),
        MidPage.projects => ProjectsPage(user: user, store: store),
        MidPage.finance => FinancePage(user: user, store: store),
        MidPage.employees => EmployeesPage(user: user, store: store),
        MidPage.students => StudentsPage(user: user, store: store),
        MidPage.departments => DepartmentsPage(user: user, store: store),
        MidPage.positions => PositionsPage(user: user, store: store),
        MidPage.announcements =>
            AnnouncementsPage(user: user, store: store),
        MidPage.profile => ProfilePage(
            user: user,
            store: store,
            auth: widget.auth,
          ),
      },
    );

    final roleLine = user.role == UserRole.rahbar
        ? '${user.fullName} · ${user.role.label} (${user.sector?.label ?? ''})'
        : '${user.fullName} · ${user.role.label}';

    if (!wide) {
      return Scaffold(
        appBar: AppBar(
          title: const MidLogo(height: 32),
          actions: [
            IconButton(
              tooltip: 'Chiqish',
              onPressed: widget.auth.signOut,
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        drawer: Drawer(
          child: SafeArea(
            child: _SideMenu(
              pages: pages,
              selectedIndex: selectedIndex,
              onSelect: (i) {
                setState(() => _page = pages[i]);
                Navigator.pop(context);
              },
              userLabel: roleLine,
              onSignOut: widget.auth.signOut,
            ),
          ),
        ),
        body: content,
      );
    }

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 260,
            color: MidColors.navy,
            child: _SideMenu(
              dark: true,
              pages: pages,
              selectedIndex: selectedIndex,
              onSelect: (i) => setState(() => _page = pages[i]),
              userLabel: roleLine,
              onSignOut: widget.auth.signOut,
            ),
          ),
          Expanded(child: content),
        ],
      ),
    );
  }
}

class _SideMenu extends StatelessWidget {
  const _SideMenu({
    required this.pages,
    required this.selectedIndex,
    required this.onSelect,
    required this.userLabel,
    required this.onSignOut,
    this.dark = false,
  });

  final List<MidPage> pages;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final String userLabel;
  final VoidCallback onSignOut;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final fg = dark ? MidColors.white : MidColors.navy;
    final muted = dark ? const Color(0xFF9BB0C3) : MidColors.navyMuted;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MidLogo(height: 40, light: dark),
          if (dark)
            Padding(
              padding: const EdgeInsets.only(left: 50, top: 2),
              child: Text(
                'Boshqaruv paneli',
                style: TextStyle(color: muted, fontSize: 12),
              ),
            ),
          const SizedBox(height: 28),
          Expanded(
            child: ListView.builder(
              itemCount: pages.length,
              itemBuilder: (context, index) {
                final page = pages[index];
                final selected = index == selectedIndex;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: InkWell(
                    onTap: () => onSelect(index),
                    borderRadius: BorderRadius.circular(12),
                    child: Ink(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? (dark
                                ? MidColors.teal
                                : MidColors.teal.withValues(alpha: 0.12))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            page.icon,
                            size: 20,
                            color: selected
                                ? (dark ? MidColors.white : MidColors.teal)
                                : muted,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            page.label,
                            style: TextStyle(
                              color: selected ? fg : muted,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: dark ? MidColors.navyMuted : MidColors.sand,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userLabel,
                  style: TextStyle(
                    color: fg,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                TextButton.icon(
                  onPressed: onSignOut,
                  icon: Icon(Icons.logout, size: 16, color: muted),
                  label: Text('Chiqish', style: TextStyle(color: muted)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
