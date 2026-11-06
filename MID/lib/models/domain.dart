import 'user_role.dart';

enum TaskStatus { yangi, jarayonda, javobBerildi, bajarildi, rad }

enum TaskPriority { past, orta, yuqori }

extension TaskStatusX on TaskStatus {
  String get label => switch (this) {
        TaskStatus.yangi => 'Yangi',
        TaskStatus.jarayonda => 'Jarayonda',
        TaskStatus.javobBerildi => 'Javob berildi',
        TaskStatus.bajarildi => 'Bajarildi',
        TaskStatus.rad => 'Rad etildi',
      };
}

extension TaskPriorityX on TaskPriority {
  String get label => switch (this) {
        TaskPriority.past => 'Past',
        TaskPriority.orta => "O'rta",
        TaskPriority.yuqori => 'Yuqori',
      };
}

class TaskItem {
  TaskItem({
    required this.id,
    required this.title,
    required this.description,
    required this.assigneeId,
    required this.createdById,
    required this.status,
    required this.priority,
    this.projectId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  String title;
  String description;
  String assigneeId;
  String createdById;
  TaskStatus status;
  TaskPriority priority;
  String? projectId;
  DateTime createdAt;
}

abstract final class ProjectStages {
  static const values = <String>[
    'Goya',
    'Boshlanish',
    'MVP',
    'Test',
    'Growth',
    'Scale',
    'Yopilgan',
  ];
}

class ProjectUpdate {
  ProjectUpdate({
    required this.id,
    required this.projectId,
    required this.authorId,
    required this.title,
    required this.body,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String projectId;
  final String authorId;
  String title;
  String body;
  DateTime createdAt;
}

class ProjectItem {
  ProjectItem({
    required this.id,
    required this.name,
    required this.description,
    required this.stage,
    required this.requiredBudget,
    required this.investment,
    required this.expense,
    required this.sector,
    this.assigneeIds = const [],
    this.parts = const {},
  });

  final String id;
  String name;
  String description;
  String stage;
  int requiredBudget;
  int investment;
  int expense;
  Sector sector;
  List<String> assigneeIds;
  Map<String, String> parts; // partName -> employeeId

  int get balance => investment - expense;
  int get remainingNeed =>
      (requiredBudget - investment).clamp(0, requiredBudget);
}

enum AnnouncementAudience { barcha, xodimlar, shogirtlar, oquvchilar }

extension AnnouncementAudienceX on AnnouncementAudience {
  String get label => switch (this) {
        AnnouncementAudience.barcha => 'Barcha foydalanuvchilar',
        AnnouncementAudience.xodimlar => 'Xodimlar',
        AnnouncementAudience.shogirtlar => 'Shogirtlar',
        AnnouncementAudience.oquvchilar => "O'quvchilar",
      };
}

class Announcement {
  Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.authorId,
    required this.audience,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  String title;
  String body;
  String authorId;
  AnnouncementAudience audience;
  DateTime createdAt;
}

enum FinanceType { kirim, chiqim, maosh, zaxira, ajratma }

extension FinanceTypeX on FinanceType {
  String get label => switch (this) {
        FinanceType.kirim => 'Kirim',
        FinanceType.chiqim => 'Chiqim',
        FinanceType.maosh => 'Maosh',
        FinanceType.zaxira => 'Zaxira',
        FinanceType.ajratma => 'Ajratma',
      };
}

class FinanceRecord {
  FinanceRecord({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.receiptNo,
    this.note = '',
    this.relatedUserId,
    this.projectId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  String title;
  int amount;
  FinanceType type;
  String receiptNo;
  String note;
  String? relatedUserId;
  String? projectId;
  DateTime createdAt;
}

class DepartmentItem {
  DepartmentItem({
    required this.id,
    required this.name,
    required this.sector,
    required this.headId,
    required this.positions,
  });

  final String id;
  String name;
  Sector sector;
  String headId;
  List<String> positions;
}

class StudyGroup {
  StudyGroup({
    required this.id,
    required this.name,
    required this.direction,
    required this.teacherId,
    this.sector,
  });

  final String id;
  String name;
  String direction;
  String teacherId;
  Sector? sector;
}

class AttendanceRecord {
  AttendanceRecord({
    required this.id,
    required this.groupId,
    required this.studentId,
    required this.date,
    required this.present,
    required this.grade,
  });

  final String id;
  String groupId;
  String studentId;
  DateTime date;
  bool present;
  int grade; // 1..10
}

enum StudyMaterialKind { uyVazifa, sorov, video, pdf, darslik }

extension StudyMaterialKindX on StudyMaterialKind {
  String get label => switch (this) {
        StudyMaterialKind.uyVazifa => 'Uy vazifa',
        StudyMaterialKind.sorov => "So'rov",
        StudyMaterialKind.video => 'Video',
        StudyMaterialKind.pdf => 'PDF',
        StudyMaterialKind.darslik => 'Darslik',
      };
}

class StudyMaterial {
  StudyMaterial({
    required this.id,
    required this.groupId,
    required this.title,
    required this.type,
    this.urlOrNote = '',
  });

  final String id;
  String groupId;
  String title;
  StudyMaterialKind type;
  String urlOrNote;
}
