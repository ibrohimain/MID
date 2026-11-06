import 'package:flutter/material.dart';

import 'app_user.dart';
import 'user_role.dart';

enum MidPage {
  dashboard,
  tasks,
  projects,
  finance,
  employees,
  students,
  departments,
  positions,
  announcements,
  profile,
}

extension MidPageX on MidPage {
  String get label => switch (this) {
        MidPage.dashboard => 'Bosh sahifa',
        MidPage.tasks => 'Topshiriqlar',
        MidPage.projects => 'Loyihalar',
        MidPage.finance => 'Moliya',
        MidPage.employees => 'Xodimlar',
        MidPage.students => "O'quvchilar",
        MidPage.departments => "Bo'limlar",
        MidPage.positions => 'Lavozimlar',
        MidPage.announcements => "E'lonlar",
        MidPage.profile => 'Profil',
      };

  IconData get icon => switch (this) {
        MidPage.dashboard => Icons.dashboard_outlined,
        MidPage.tasks => Icons.task_alt_outlined,
        MidPage.projects => Icons.rocket_launch_outlined,
        MidPage.finance => Icons.account_balance_wallet_outlined,
        MidPage.employees => Icons.groups_outlined,
        MidPage.students => Icons.menu_book_outlined,
        MidPage.departments => Icons.apartment_outlined,
        MidPage.positions => Icons.work_outline,
        MidPage.announcements => Icons.campaign_outlined,
        MidPage.profile => Icons.manage_accounts_outlined,
      };
}

abstract final class RolePermissions {
  static List<MidPage> pagesFor(UserRole role) {
    final base = switch (role) {
      UserRole.direktor => const [
          MidPage.dashboard,
          MidPage.tasks,
          MidPage.projects,
          MidPage.finance,
          MidPage.employees,
          MidPage.students,
          MidPage.departments,
          MidPage.positions,
          MidPage.announcements,
        ],
      UserRole.rahbar => const [
          MidPage.dashboard,
          MidPage.tasks,
          MidPage.projects,
          MidPage.finance,
          MidPage.employees,
          MidPage.students,
          MidPage.departments,
          MidPage.announcements,
        ],
      UserRole.xodim => const [
          MidPage.dashboard,
          MidPage.tasks,
          MidPage.projects,
          MidPage.announcements,
        ],
      UserRole.oquvchi => const [
          MidPage.dashboard,
          MidPage.tasks,
          MidPage.students,
          MidPage.announcements,
        ],
      UserRole.shogirt => const [
          MidPage.dashboard,
          MidPage.tasks,
          MidPage.projects,
          MidPage.students,
          MidPage.announcements,
        ],
    };
    return [...base, MidPage.profile];
  }

  static bool canDeleteUser(UserRole actor, AppUser target) {
    if (target.role == UserRole.direktor) return false;
    if (actor == UserRole.direktor) {
      return target.role == UserRole.xodim ||
          target.role == UserRole.oquvchi ||
          target.role == UserRole.shogirt ||
          target.role == UserRole.rahbar;
    }
    if (actor == UserRole.rahbar) {
      return target.role == UserRole.xodim ||
          target.role == UserRole.oquvchi ||
          target.role == UserRole.shogirt;
    }
    return false;
  }
}
