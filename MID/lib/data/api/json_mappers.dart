import '../../models/app_user.dart';
import '../../models/domain.dart';
import '../../models/user_role.dart';

UserRole parseRole(String value) => UserRole.values.byName(value);

Sector? parseSector(String? value) {
  if (value == null || value.isEmpty) return null;
  return Sector.values.byName(value);
}

String? sectorToApi(Sector? s) => s?.name;

AppUser userFromJson(Map<String, dynamic> j) {
  return AppUser(
    id: j['id'] as String,
    fullName: j['full_name'] as String,
    login: j['login'] as String,
    password: (j['password'] as String?) ?? '',
    role: parseRole(j['role'] as String),
    sector: parseSector(j['sector'] as String?),
    departmentId: j['department_id'] as String?,
    position: j['position'] as String?,
    email: j['email'] as String?,
    phone: j['phone'] as String?,
    groupId: j['group_id'] as String?,
    direction: j['direction'] as String?,
    salary: (j['salary'] as num?)?.toInt() ?? 0,
    paymentAmount: (j['payment_amount'] as num?)?.toInt() ?? 0,
    studiedMonths: (j['studied_months'] as num?)?.toInt() ?? 0,
    totalMonths: (j['total_months'] as num?)?.toInt() ?? 0,
    active: j['active'] as bool? ?? true,
  );
}

TaskStatus parseTaskStatus(String v) => TaskStatus.values.byName(v);

TaskPriority parseTaskPriority(String v) => TaskPriority.values.byName(v);

TaskItem taskFromJson(Map<String, dynamic> j) {
  return TaskItem(
    id: j['id'] as String,
    title: j['title'] as String,
    description: (j['description'] as String?) ?? '',
    assigneeId: j['assignee_id'] as String,
    createdById: j['created_by_id'] as String,
    status: parseTaskStatus(j['status'] as String),
    priority: parseTaskPriority(j['priority'] as String),
    projectId: j['project_id'] as String?,
    createdAt: DateTime.parse(j['created_at'] as String),
  );
}

ProjectItem projectFromJson(Map<String, dynamic> j) {
  final partsRaw = j['parts'];
  final parts = <String, String>{};
  if (partsRaw is Map) {
    partsRaw.forEach((k, v) => parts['$k'] = '$v');
  }
  final assignees = (j['assignee_ids'] as List<dynamic>? ?? [])
      .map((e) => e as String)
      .toList();
  return ProjectItem(
    id: j['id'] as String,
    name: j['name'] as String,
    description: (j['description'] as String?) ?? '',
    stage: j['stage'] as String,
    requiredBudget: (j['required_budget'] as num).toInt(),
    investment: (j['investment'] as num).toInt(),
    expense: (j['expense'] as num).toInt(),
    sector: parseSector(j['sector'] as String)!,
    assigneeIds: assignees,
    parts: parts,
  );
}

ProjectUpdate projectUpdateFromJson(Map<String, dynamic> j) {
  return ProjectUpdate(
    id: j['id'] as String,
    projectId: j['project_id'] as String,
    authorId: j['author_id'] as String,
    title: j['title'] as String,
    body: (j['body'] as String?) ?? '',
    createdAt: DateTime.parse(j['created_at'] as String),
  );
}

AnnouncementAudience parseAudience(String v) =>
    AnnouncementAudience.values.byName(v);

Announcement announcementFromJson(Map<String, dynamic> j) {
  return Announcement(
    id: j['id'] as String,
    title: j['title'] as String,
    body: (j['body'] as String?) ?? '',
    authorId: j['author_id'] as String,
    audience: parseAudience(j['audience'] as String),
    createdAt: DateTime.parse(j['created_at'] as String),
  );
}

FinanceType parseFinanceType(String v) => FinanceType.values.byName(v);

FinanceRecord financeFromJson(Map<String, dynamic> j) {
  return FinanceRecord(
    id: j['id'] as String,
    title: j['title'] as String,
    amount: (j['amount'] as num).toInt(),
    type: parseFinanceType(j['type'] as String),
    receiptNo: j['receipt_no'] as String,
    note: (j['note'] as String?) ?? '',
    relatedUserId: j['related_user_id'] as String?,
    projectId: j['project_id'] as String?,
    createdAt: DateTime.parse(j['created_at'] as String),
  );
}

DepartmentItem departmentFromJson(Map<String, dynamic> j) {
  final positions = (j['positions'] as List<dynamic>? ?? [])
      .map((e) => e as String)
      .toList();
  return DepartmentItem(
    id: j['id'] as String,
    name: j['name'] as String,
    sector: parseSector(j['sector'] as String)!,
    headId: j['head_id'] as String,
    positions: positions,
  );
}

StudyGroup groupFromJson(Map<String, dynamic> j) {
  return StudyGroup(
    id: j['id'] as String,
    name: j['name'] as String,
    direction: j['direction'] as String,
    teacherId: j['teacher_id'] as String,
    sector: parseSector(j['sector'] as String?),
  );
}

AttendanceRecord attendanceFromJson(Map<String, dynamic> j) {
  return AttendanceRecord(
    id: j['id'] as String,
    groupId: j['group_id'] as String,
    studentId: j['student_id'] as String,
    date: DateTime.parse(j['date'] as String),
    present: j['present'] as bool? ?? true,
    grade: (j['grade'] as num?)?.toInt() ?? 5,
  );
}

StudyMaterialKind parseMaterialKind(String v) =>
    StudyMaterialKind.values.byName(v);

StudyMaterial materialFromJson(Map<String, dynamic> j) {
  return StudyMaterial(
    id: j['id'] as String,
    groupId: j['group_id'] as String,
    title: j['title'] as String,
    type: parseMaterialKind(j['type'] as String),
    urlOrNote: (j['url_or_note'] as String?) ?? '',
  );
}
