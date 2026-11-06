import 'package:flutter/material.dart';

enum UserRole {
  direktor,
  rahbar,
  xodim,
  oquvchi,
  shogirt,
}

enum Sector { a, b }

extension SectorX on Sector {
  String get label => this == Sector.a ? 'A sektor' : 'B sektor';
  String get short => this == Sector.a ? 'A' : 'B';
}

extension UserRoleX on UserRole {
  String get label => switch (this) {
        UserRole.direktor => 'Direktor',
        UserRole.rahbar => 'Rahbar',
        UserRole.xodim => 'Xodim',
        UserRole.oquvchi => "O'quvchi",
        UserRole.shogirt => 'Shogirt',
      };

  IconData get icon => switch (this) {
        UserRole.direktor => Icons.workspace_premium_outlined,
        UserRole.rahbar => Icons.admin_panel_settings_outlined,
        UserRole.xodim => Icons.badge_outlined,
        UserRole.oquvchi => Icons.school_outlined,
        UserRole.shogirt => Icons.handshake_outlined,
      };

  bool get canManageStaff =>
      this == UserRole.direktor || this == UserRole.rahbar;

  bool get canManageFinance =>
      this == UserRole.direktor || this == UserRole.rahbar;

  bool get canAssignTasks =>
      this == UserRole.direktor || this == UserRole.rahbar;

  bool get isLeadership =>
      this == UserRole.direktor || this == UserRole.rahbar;
}
