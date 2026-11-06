import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/domain.dart';
import '../models/user_role.dart';
import 'api/api_client.dart';
import 'api/json_mappers.dart';

class MidStore extends ChangeNotifier {
  MidStore({ApiClient? api}) : api = api ?? ApiClient();

  final ApiClient api;

  final List<AppUser> users = [];
  final List<TaskItem> tasks = [];
  final List<ProjectItem> projects = [];
  final List<ProjectUpdate> projectUpdates = [];
  final List<FinanceRecord> finances = [];
  final List<DepartmentItem> departments = [];
  final List<StudyGroup> groups = [];
  final List<AttendanceRecord> attendance = [];
  final List<StudyMaterial> materials = [];
  final List<Announcement> announcements = [];

  int companyCash = 0;
  int reserveCash = 0;
  bool loading = false;
  String? lastError;

  Future<AppUser> login(String login, String password) async {
    final data = await api.post('/auth/login', body: {
      'login': login,
      'password': password,
    }) as Map<String, dynamic>;
    api.setToken(data['access_token'] as String);
    final user = userFromJson(data['user'] as Map<String, dynamic>);
    await refreshAll();
    return userById(user.id) ?? user;
  }

  void logout() {
    api.setToken(null);
    users.clear();
    tasks.clear();
    projects.clear();
    projectUpdates.clear();
    finances.clear();
    departments.clear();
    groups.clear();
    attendance.clear();
    materials.clear();
    announcements.clear();
    companyCash = 0;
    reserveCash = 0;
    notifyListeners();
  }

  Future<void> refreshAll() async {
    loading = true;
    lastError = null;
    notifyListeners();
    try {
      final data = await api.get('/bootstrap') as Map<String, dynamic>;
      _applyBootstrap(data);
    } catch (e) {
      lastError = e.toString();
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void _applyBootstrap(Map<String, dynamic> data) {
    users
      ..clear()
      ..addAll(
        (data['users'] as List<dynamic>)
            .map((e) => userFromJson(e as Map<String, dynamic>)),
      );
    tasks
      ..clear()
      ..addAll(
        (data['tasks'] as List<dynamic>)
            .map((e) => taskFromJson(e as Map<String, dynamic>)),
      );
    projects
      ..clear()
      ..addAll(
        (data['projects'] as List<dynamic>)
            .map((e) => projectFromJson(e as Map<String, dynamic>)),
      );
    projectUpdates
      ..clear()
      ..addAll(
        (data['project_updates'] as List<dynamic>)
            .map((e) => projectUpdateFromJson(e as Map<String, dynamic>)),
      );
    finances
      ..clear()
      ..addAll(
        (data['finances'] as List<dynamic>)
            .map((e) => financeFromJson(e as Map<String, dynamic>)),
      );
    departments
      ..clear()
      ..addAll(
        (data['departments'] as List<dynamic>)
            .map((e) => departmentFromJson(e as Map<String, dynamic>)),
      );
    groups
      ..clear()
      ..addAll(
        (data['groups'] as List<dynamic>)
            .map((e) => groupFromJson(e as Map<String, dynamic>)),
      );
    attendance
      ..clear()
      ..addAll(
        (data['attendance'] as List<dynamic>)
            .map((e) => attendanceFromJson(e as Map<String, dynamic>)),
      );
    materials
      ..clear()
      ..addAll(
        (data['materials'] as List<dynamic>)
            .map((e) => materialFromJson(e as Map<String, dynamic>)),
      );
    announcements
      ..clear()
      ..addAll(
        (data['announcements'] as List<dynamic>)
            .map((e) => announcementFromJson(e as Map<String, dynamic>)),
      );
    companyCash = (data['company_cash'] as num).toInt();
    reserveCash = (data['reserve_cash'] as num).toInt();
  }

  AppUser? findByLogin(String login, String password) {
    // Local fallback unused when API is connected.
    try {
      return users.firstWhere(
        (u) =>
            u.login.toLowerCase() == login.trim().toLowerCase() &&
            u.password == password &&
            u.active,
      );
    } catch (_) {
      return null;
    }
  }

  AppUser? userById(String id) {
    try {
      return users.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  List<AppUser> get employees => users
      .where((u) =>
          u.active &&
          (u.role == UserRole.xodim ||
              u.role == UserRole.rahbar ||
              u.role == UserRole.direktor))
      .toList();

  List<AppUser> get staffOnly =>
      users.where((u) => u.active && u.role == UserRole.xodim).toList();

  List<AppUser> get learners =>
      users.where((u) => u.active && u.isLearner).toList();

  Set<String> get assigneeIdsWithOpenTasks => tasks
      .where((t) =>
          t.status == TaskStatus.yangi ||
          t.status == TaskStatus.jarayonda ||
          t.status == TaskStatus.javobBerildi)
      .map((t) => t.assigneeId)
      .toSet();

  List<AppUser> get loadedEmployees =>
      staffOnly.where((e) => assigneeIdsWithOpenTasks.contains(e.id)).toList();

  List<AppUser> get unloadedEmployees => staffOnly
      .where((e) => !assigneeIdsWithOpenTasks.contains(e.id))
      .toList();

  List<AppUser> get respondedEmployees {
    final ids = tasks
        .where((t) => t.status == TaskStatus.javobBerildi)
        .map((t) => t.assigneeId)
        .toSet();
    return staffOnly.where((e) => ids.contains(e.id)).toList();
  }

  List<AppUser> get noResponseEmployees {
    final pending = tasks
        .where((t) =>
            t.status == TaskStatus.yangi || t.status == TaskStatus.jarayonda)
        .map((t) => t.assigneeId)
        .toSet();
    final responded = tasks
        .where((t) => t.status == TaskStatus.javobBerildi)
        .map((t) => t.assigneeId)
        .toSet();
    return staffOnly
        .where((e) => pending.contains(e.id) && !responded.contains(e.id))
        .toList();
  }

  List<ProjectItem> get activeProjects =>
      projects.where((p) => p.stage.toLowerCase() != 'yopilgan').toList();

  // --- Users ---
  Future<AppUser> addUser({
    required String fullName,
    required String login,
    required String password,
    required UserRole role,
    Sector? sector,
    String? departmentId,
    String? position,
    String? email,
    String? groupId,
    String? direction,
    int salary = 0,
    int paymentAmount = 0,
    int studiedMonths = 0,
    int totalMonths = 0,
  }) async {
    final data = await api.post('/users', body: {
      'full_name': fullName,
      'login': login,
      'password': password,
      'role': role.name,
      'sector': sectorToApi(sector),
      'department_id': departmentId,
      'position': position,
      'email': email,
      'group_id': groupId,
      'direction': direction,
      'salary': salary,
      'payment_amount': paymentAmount,
      'studied_months': studiedMonths,
      'total_months': totalMonths,
    }) as Map<String, dynamic>;
    final user = userFromJson(data);
    users.add(user);
    notifyListeners();
    return user;
  }

  void updateUser(AppUser user) {
    notifyListeners();
  }

  Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? email,
    String? phone,
    String? password,
  }) async {
    final data = await api.patch('/auth/me', body: {
      if (fullName != null) 'full_name': fullName,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (password != null && password.isNotEmpty) 'password': password,
    }) as Map<String, dynamic>;
    final updated = userFromJson(data);
    final idx = users.indexWhere((u) => u.id == userId);
    if (idx >= 0) {
      // keep password visible for managers if present
      final prev = users[idx];
      users[idx] = AppUser(
        id: updated.id,
        fullName: updated.fullName,
        login: updated.login,
        password: updated.password.isNotEmpty ? updated.password : prev.password,
        role: updated.role,
        sector: updated.sector,
        departmentId: updated.departmentId,
        position: updated.position,
        email: updated.email,
        phone: updated.phone,
        groupId: updated.groupId,
        direction: updated.direction,
        salary: updated.salary,
        paymentAmount: updated.paymentAmount,
        studiedMonths: updated.studiedMonths,
        totalMonths: updated.totalMonths,
        active: updated.active,
      );
    }
    notifyListeners();
  }

  Future<bool> deleteUser(String userId, {required UserRole actorRole}) async {
    await api.delete('/users/$userId');
    final target = userById(userId);
    if (target != null) target.active = false;
    notifyListeners();
    return true;
  }

  Future<bool> loginTaken(String login, {String? exceptUserId}) async {
    final data = await api.get('/users/check-login', query: {
      'login': login,
      if (exceptUserId != null) 'except_user_id': exceptUserId,
    }) as Map<String, dynamic>;
    return data['taken'] as bool? ?? false;
  }

  // --- Tasks ---
  Future<TaskItem> assignTask({
    required String title,
    required String description,
    required String assigneeId,
    required String createdById,
    required TaskPriority priority,
    String? projectId,
  }) async {
    final data = await api.post('/tasks', body: {
      'title': title,
      'description': description,
      'assignee_id': assigneeId,
      'priority': priority.name,
      'project_id': projectId,
    }) as Map<String, dynamic>;
    final task = taskFromJson(data);
    tasks.insert(0, task);
    notifyListeners();
    return task;
  }

  Future<void> setTaskStatus(String taskId, TaskStatus status) async {
    final data = await api.patch('/tasks/$taskId/status', body: {
      'status': status.name,
    }) as Map<String, dynamic>;
    final updated = taskFromJson(data);
    final idx = tasks.indexWhere((e) => e.id == taskId);
    if (idx >= 0) tasks[idx] = updated;
    notifyListeners();
  }

  Future<void> updateTask({
    required String taskId,
    required String title,
    required String description,
    required String assigneeId,
    required TaskPriority priority,
    required TaskStatus status,
    String? projectId,
  }) async {
    final data = await api.patch('/tasks/$taskId', body: {
      'title': title,
      'description': description,
      'assignee_id': assigneeId,
      'priority': priority.name,
      'status': status.name,
      'project_id': projectId,
    }) as Map<String, dynamic>;
    final updated = taskFromJson(data);
    final idx = tasks.indexWhere((e) => e.id == taskId);
    if (idx >= 0) tasks[idx] = updated;
    notifyListeners();
  }

  Future<void> deleteTask(String taskId) async {
    await api.delete('/tasks/$taskId');
    tasks.removeWhere((e) => e.id == taskId);
    notifyListeners();
  }

  // --- Projects ---
  Future<ProjectItem> addProject({
    required String name,
    required String description,
    required String stage,
    required int requiredBudget,
    required int investment,
    required int expense,
    required Sector sector,
    List<String> assigneeIds = const [],
  }) async {
    final data = await api.post('/projects', body: {
      'name': name,
      'description': description,
      'stage': stage,
      'required_budget': requiredBudget,
      'investment': investment,
      'expense': expense,
      'sector': sector.name,
      'assignee_ids': assigneeIds,
    }) as Map<String, dynamic>;
    final p = projectFromJson(data);
    projects.insert(0, p);
    notifyListeners();
    return p;
  }

  Future<void> updateProject({
    required String projectId,
    required String name,
    required String description,
    required String stage,
    required int requiredBudget,
    required int investment,
    required int expense,
    required Sector sector,
  }) async {
    final data = await api.patch('/projects/$projectId', body: {
      'name': name,
      'description': description,
      'stage': stage,
      'required_budget': requiredBudget,
      'investment': investment,
      'expense': expense,
      'sector': sector.name,
    }) as Map<String, dynamic>;
    final updated = projectFromJson(data);
    final idx = projects.indexWhere((e) => e.id == projectId);
    if (idx >= 0) {
      updated.assigneeIds = projects[idx].assigneeIds;
      updated.parts = projects[idx].parts;
      projects[idx] = updated;
    }
    notifyListeners();
  }

  Future<void> setProjectStage(String projectId, String stage) async {
    final data = await api.patch('/projects/$projectId/stage', body: {
      'stage': stage,
    }) as Map<String, dynamic>;
    final updated = projectFromJson(data);
    final idx = projects.indexWhere((e) => e.id == projectId);
    if (idx >= 0) {
      updated.assigneeIds = projects[idx].assigneeIds;
      updated.parts = projects[idx].parts;
      projects[idx] = updated;
    }
    notifyListeners();
  }

  Future<void> deleteProject(String projectId) async {
    await api.delete('/projects/$projectId');
    projects.removeWhere((e) => e.id == projectId);
    projectUpdates.removeWhere((e) => e.projectId == projectId);
    notifyListeners();
  }

  Future<void> assignEmployeeToProjectPart({
    required String projectId,
    required String partName,
    required String employeeId,
  }) async {
    final data = await api.put('/projects/$projectId/parts', body: {
      'part_name': partName,
      'employee_id': employeeId,
    }) as Map<String, dynamic>;
    final updated = projectFromJson(data);
    final idx = projects.indexWhere((e) => e.id == projectId);
    if (idx >= 0) projects[idx] = updated;
    notifyListeners();
  }

  Future<ProjectUpdate> addProjectUpdate({
    required String projectId,
    required String authorId,
    required String title,
    required String body,
  }) async {
    final data = await api.post('/projects/$projectId/updates', body: {
      'title': title,
      'body': body,
    }) as Map<String, dynamic>;
    final u = projectUpdateFromJson(data);
    projectUpdates.insert(0, u);
    notifyListeners();
    return u;
  }

  Future<void> deleteProjectUpdate(String updateId) async {
    projectUpdates.removeWhere((e) => e.id == updateId);
    notifyListeners();
  }

  List<ProjectUpdate> updatesFor(String projectId) =>
      projectUpdates.where((e) => e.projectId == projectId).toList();

  // --- Announcements ---
  Future<Announcement> addAnnouncement({
    required String title,
    required String body,
    required String authorId,
    required AnnouncementAudience audience,
  }) async {
    final data = await api.post('/announcements', body: {
      'title': title,
      'body': body,
      'audience': audience.name,
    }) as Map<String, dynamic>;
    final a = announcementFromJson(data);
    announcements.insert(0, a);
    notifyListeners();
    return a;
  }

  Future<void> updateAnnouncement({
    required String id,
    required String title,
    required String body,
    required AnnouncementAudience audience,
  }) async {
    final data = await api.patch('/announcements/$id', body: {
      'title': title,
      'body': body,
      'audience': audience.name,
    }) as Map<String, dynamic>;
    final updated = announcementFromJson(data);
    final idx = announcements.indexWhere((e) => e.id == id);
    if (idx >= 0) announcements[idx] = updated;
    notifyListeners();
  }

  Future<void> deleteAnnouncement(String id) async {
    await api.delete('/announcements/$id');
    announcements.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  List<Announcement> announcementsFor(AppUser user) {
    if (user.role.isLeadership) return List.of(announcements);
    return announcements.where((a) {
      return switch (a.audience) {
        AnnouncementAudience.barcha => true,
        AnnouncementAudience.xodimlar => user.role == UserRole.xodim,
        AnnouncementAudience.shogirtlar => user.role == UserRole.shogirt,
        AnnouncementAudience.oquvchilar => user.role == UserRole.oquvchi,
      };
    }).toList();
  }

  // --- Finance ---
  Future<FinanceRecord> addFinance({
    required String title,
    required int amount,
    required FinanceType type,
    String note = '',
    String? relatedUserId,
    String? projectId,
  }) async {
    final data = await api.post('/finance/records', body: {
      'title': title,
      'amount': amount,
      'type': type.name,
      'note': note,
      'related_user_id': relatedUserId,
      'project_id': projectId,
    }) as Map<String, dynamic>;
    final rec = financeFromJson(data);
    finances.insert(0, rec);
    final summary = await api.get('/finance/summary') as Map<String, dynamic>;
    companyCash = (summary['company_cash'] as num).toInt();
    reserveCash = (summary['reserve_cash'] as num).toInt();
    notifyListeners();
    return rec;
  }

  Future<void> updateFinance({
    required String id,
    required String title,
    required int amount,
    required FinanceType type,
    String note = '',
  }) async {
    final data = await api.patch('/finance/records/$id', body: {
      'title': title,
      'amount': amount,
      'type': type.name,
      'note': note,
    }) as Map<String, dynamic>;
    final updated = financeFromJson(data);
    final idx = finances.indexWhere((e) => e.id == id);
    if (idx >= 0) finances[idx] = updated;
    final summary = await api.get('/finance/summary') as Map<String, dynamic>;
    companyCash = (summary['company_cash'] as num).toInt();
    reserveCash = (summary['reserve_cash'] as num).toInt();
    notifyListeners();
  }

  Future<void> deleteFinance(String id) async {
    await api.delete('/finance/records/$id');
    finances.removeWhere((e) => e.id == id);
    final summary = await api.get('/finance/summary') as Map<String, dynamic>;
    companyCash = (summary['company_cash'] as num).toInt();
    reserveCash = (summary['reserve_cash'] as num).toInt();
    notifyListeners();
  }

  /// Kampaniya pulini qo'lda belgilash (cheksiz ochilish balansi).
  void setCompanyCash(int amount) {
    companyCash = amount < 0 ? 0 : amount;
    notifyListeners();
  }

  void setReserveCash(int amount) {
    reserveCash = amount < 0 ? 0 : amount;
    notifyListeners();
  }

  void resetFinanceBalances() {
    companyCash = 0;
    reserveCash = 0;
    finances.clear();
    notifyListeners();
  }

  int get totalKirim => finances
      .where((f) => f.type == FinanceType.kirim)
      .fold(0, (s, f) => s + f.amount);

  int get totalChiqim => finances
      .where((f) =>
          f.type == FinanceType.chiqim ||
          f.type == FinanceType.maosh ||
          f.type == FinanceType.ajratma)
      .fold(0, (s, f) => s + f.amount);

  int get totalMaosh => finances
      .where((f) => f.type == FinanceType.maosh)
      .fold(0, (s, f) => s + f.amount);

  // --- Departments ---
  Future<DepartmentItem> addDepartment({
    required String name,
    required Sector sector,
    required String headId,
    required List<String> positions,
  }) async {
    final data = await api.post('/departments', body: {
      'name': name,
      'sector': sector.name,
      'head_id': headId,
      'positions': positions,
    }) as Map<String, dynamic>;
    final d = departmentFromJson(data);
    departments.add(d);
    notifyListeners();
    return d;
  }

  Future<void> setDepartmentPositions(String id, List<String> positions) async {
    await updateDepartment(
      id: id,
      name: departments.firstWhere((e) => e.id == id).name,
      sector: departments.firstWhere((e) => e.id == id).sector,
      headId: departments.firstWhere((e) => e.id == id).headId,
      positions: positions,
    );
  }

  Future<void> updateDepartment({
    required String id,
    required String name,
    required Sector sector,
    required String headId,
    required List<String> positions,
  }) async {
    final data = await api.patch('/departments/$id', body: {
      'name': name,
      'sector': sector.name,
      'head_id': headId,
      'positions': positions,
    }) as Map<String, dynamic>;
    final updated = departmentFromJson(data);
    final idx = departments.indexWhere((e) => e.id == id);
    if (idx >= 0) departments[idx] = updated;
    notifyListeners();
  }

  Future<void> assignDepartmentHead(String departmentId, String headId) async {
    final data = await api.patch('/departments/$departmentId/head', body: {
      'head_id': headId,
    }) as Map<String, dynamic>;
    final updated = departmentFromJson(data);
    final idx = departments.indexWhere((e) => e.id == departmentId);
    if (idx >= 0) departments[idx] = updated;
    notifyListeners();
  }

  Future<void> deleteDepartment(String id) async {
    await api.delete('/departments/$id');
    departments.removeWhere((e) => e.id == id);
    for (final u in users.where((u) => u.departmentId == id)) {
      u.departmentId = null;
    }
    notifyListeners();
  }

  Future<void> updateStaffUser({
    required String userId,
    required String fullName,
    required String login,
    required String password,
    Sector? sector,
    String? departmentId,
    String? position,
    int? salary,
    String? email,
    String? phone,
    String? groupId,
    String? direction,
    int? paymentAmount,
    int? studiedMonths,
    int? totalMonths,
    UserRole? role,
  }) async {
    final data = await api.patch('/users/$userId', body: {
      'full_name': fullName,
      'login': login,
      if (password.trim().isNotEmpty) 'password': password,
      if (sector != null) 'sector': sector.name,
      if (departmentId != null) 'department_id': departmentId,
      if (position != null) 'position': position,
      if (salary != null) 'salary': salary,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (groupId != null) 'group_id': groupId,
      if (direction != null) 'direction': direction,
      if (paymentAmount != null) 'payment_amount': paymentAmount,
      if (studiedMonths != null) 'studied_months': studiedMonths,
      if (totalMonths != null) 'total_months': totalMonths,
      if (role != null && role != UserRole.direktor) 'role': role.name,
    }) as Map<String, dynamic>;
    final updated = userFromJson(data);
    final idx = users.indexWhere((u) => u.id == userId);
    if (idx >= 0) users[idx] = updated;
    notifyListeners();
  }

  // --- Education ---
  Future<StudyGroup> addGroup({
    required String name,
    required String direction,
    required String teacherId,
    Sector? sector,
  }) async {
    final data = await api.post('/groups', body: {
      'name': name,
      'direction': direction,
      'teacher_id': teacherId,
      'sector': sectorToApi(sector),
    }) as Map<String, dynamic>;
    final g = groupFromJson(data);
    groups.add(g);
    notifyListeners();
    return g;
  }

  Future<void> markAttendance({
    required String groupId,
    required String studentId,
    required bool present,
    required int grade,
    DateTime? date,
  }) async {
    final list = await api.post('/attendance/bulk', body: {
      'group_id': groupId,
      if (date != null) 'date': date.toIso8601String(),
      'records': [
        {
          'student_id': studentId,
          'present': present,
          'grade': grade.clamp(1, 10),
        }
      ],
    }) as List<dynamic>;
    for (final item in list) {
      attendance.add(attendanceFromJson(item as Map<String, dynamic>));
    }
    notifyListeners();
  }

  Future<void> addMaterial({
    required String groupId,
    required String title,
    required StudyMaterialKind type,
    String urlOrNote = '',
  }) async {
    final data = await api.post('/materials', body: {
      'group_id': groupId,
      'title': title,
      'type': type.name,
      'url_or_note': urlOrNote,
    }) as Map<String, dynamic>;
    materials.insert(0, materialFromJson(data));
    notifyListeners();
  }

  double averageGrade(String studentId) {
    final list = attendance.where((a) => a.studentId == studentId).toList();
    if (list.isEmpty) return 0;
    return list.map((a) => a.grade).reduce((a, b) => a + b) / list.length;
  }

  List<AppUser> topStudents({int limit = 5}) {
    final ranked = [...learners]
      ..sort((a, b) => averageGrade(b.id).compareTo(averageGrade(a.id)));
    return ranked.take(limit).toList();
  }
<<<<<<< HEAD

  void _seed() {
    final director = AppUser(
      id: 'u-dir',
      fullName: 'Aziza Karimova',
      login: 'direktor',
      password: '1234',
      role: UserRole.direktor,
      position: 'Direktor',
      email: 'direktor@mid.uz',
      salary: 25000000,
    );
    final rahbarA = AppUser(
      id: 'u-ra',
      fullName: 'Bekzod Tursunov',
      login: 'rahbar_a',
      password: 'a12345',
      role: UserRole.rahbar,
      sector: Sector.a,
      position: 'A sektor rahbari',
      email: 'rahbar.a@mid.uz',
      phone: '+998 90 111 22 33',
      salary: 18000000,
    );
    final rahbarB = AppUser(
      id: 'u-rb',
      fullName: 'Nilufar Saidova',
      login: 'rahbar_b',
      password: 'b12345',
      role: UserRole.rahbar,
      sector: Sector.b,
      position: 'B sektor rahbari',
      email: 'rahbar.b@mid.uz',
      phone: '+998 90 444 55 66',
      salary: 18000000,
    );
    users.addAll([director, rahbarA, rahbarB]);

    final deptA1 = DepartmentItem(
      id: 'd-a1',
      name: 'Loyihalar',
      sector: Sector.a,
      headId: rahbarA.id,
      positions: ['Loyiha menejeri', 'Product owner', 'Analitik'],
    );
    final deptA2 = DepartmentItem(
      id: 'd-a2',
      name: "O'quv",
      sector: Sector.a,
      headId: rahbarA.id,
      positions: ['Mentor', "O'qituvchi", 'Kurator'],
    );
    final deptB1 = DepartmentItem(
      id: 'd-b1',
      name: 'Moliya',
      sector: Sector.b,
      headId: rahbarB.id,
      positions: ['Moliyaviy analitik', 'Buxgalter', 'Investitsiya menejeri'],
    );
    final deptB2 = DepartmentItem(
      id: 'd-b2',
      name: 'HR',
      sector: Sector.b,
      headId: rahbarB.id,
      positions: ['HR mutaxassisi', 'Rekruter'],
    );
    departments.addAll([deptA1, deptA2, deptB1, deptB2]);

    final jasur = AppUser(
      id: 'u-x1',
      fullName: 'Jasur Aliyev',
      login: 'jasur',
      password: '1234',
      role: UserRole.xodim,
      sector: Sector.a,
      departmentId: deptA1.id,
      position: 'Loyiha menejeri',
      salary: 9000000,
    );
    final dilshod = AppUser(
      id: 'u-x2',
      fullName: 'Dilshod Normatov',
      login: 'dilshod',
      password: '1234',
      role: UserRole.xodim,
      sector: Sector.a,
      departmentId: deptA2.id,
      position: 'Mentor',
      salary: 8000000,
    );
    final malika = AppUser(
      id: 'u-x3',
      fullName: 'Malika Ergasheva',
      login: 'malika',
      password: '1234',
      role: UserRole.xodim,
      sector: Sector.b,
      departmentId: deptB1.id,
      position: 'Moliyaviy analitik',
      salary: 8500000,
    );
    final odil = AppUser(
      id: 'u-x4',
      fullName: 'Odil Hasanov',
      login: 'odil',
      password: '1234',
      role: UserRole.xodim,
      sector: Sector.b,
      departmentId: deptB2.id,
      position: 'HR mutaxassisi',
      salary: 7000000,
    );
    users.addAll([jasur, dilshod, malika, odil]);

    final gFlutter = StudyGroup(
      id: 'g-1',
      name: 'Flutter-01',
      direction: 'Flutter',
      teacherId: dilshod.id,
      sector: Sector.a,
    );
    final gUx = StudyGroup(
      id: 'g-2',
      name: 'UIUX-02',
      direction: 'UI/UX',
      teacherId: dilshod.id,
      sector: Sector.a,
    );
    groups.addAll([gFlutter, gUx]);

    final madina = AppUser(
      id: 'u-o1',
      fullName: 'Madina Yusupova',
      login: 'madina',
      password: '1234',
      role: UserRole.oquvchi,
      sector: Sector.a,
      groupId: gFlutter.id,
      direction: 'Flutter',
      paymentAmount: 3500000,
      studiedMonths: 4,
      totalMonths: 9,
    );
    final sardor = AppUser(
      id: 'u-s1',
      fullName: 'Sardor Rahimov',
      login: 'sardor',
      password: '1234',
      role: UserRole.shogirt,
      sector: Sector.a,
      groupId: gFlutter.id,
      direction: 'Flutter',
      paymentAmount: 0,
      studiedMonths: 2,
      totalMonths: 6,
    );
    final dilnoza = AppUser(
      id: 'u-o2',
      fullName: 'Dilnoza Ergasheva',
      login: 'dilnoza',
      password: '1234',
      role: UserRole.oquvchi,
      sector: Sector.a,
      groupId: gUx.id,
      direction: 'UI/UX',
      paymentAmount: 3000000,
      studiedMonths: 3,
      totalMonths: 8,
    );
    users.addAll([madina, sardor, dilnoza]);

    projects.addAll([
      ProjectItem(
        id: 'p-1',
        name: 'EduLink',
        description: "Ta'lim platformasi MVP va mentor marketplace.",
        stage: 'MVP',
        requiredBudget: 150000000,
        investment: 120000000,
        expense: 48000000,
        sector: Sector.a,
        assigneeIds: [jasur.id, sardor.id],
        parts: {
          'Frontend': jasur.id,
          'Amaliyot': sardor.id,
        },
      ),
      ProjectItem(
        id: 'p-2',
        name: 'PayNest',
        description: "To'lov va investitsiya kuzatuv tizimi.",
        stage: 'Growth',
        requiredBudget: 250000000,
        investment: 210000000,
        expense: 96000000,
        sector: Sector.b,
        assigneeIds: [malika.id],
        parts: {'Moliya moduli': malika.id},
      ),
      ProjectItem(
        id: 'p-3',
        name: 'AgroSense',
        description: 'Agro sensor monitoring startup.',
        stage: "Boshlanish",
        requiredBudget: 100000000,
        investment: 85000000,
        expense: 12000000,
        sector: Sector.a,
        assigneeIds: [],
        parts: {},
      ),
    ]);

    tasks.addAll([
      TaskItem(
        id: 't-1',
        title: 'Pitch deck yangilash',
        description: 'EduLink investorlar uchun deck.',
        assigneeId: jasur.id,
        createdById: rahbarA.id,
        status: TaskStatus.jarayonda,
        priority: TaskPriority.yuqori,
        projectId: 'p-1',
      ),
      TaskItem(
        id: 't-2',
        title: 'Haftalik moliya hisoboti',
        description: 'Kirim-chiqim va zaxira.',
        assigneeId: malika.id,
        createdById: rahbarB.id,
        status: TaskStatus.javobBerildi,
        priority: TaskPriority.yuqori,
        projectId: 'p-2',
      ),
      TaskItem(
        id: 't-3',
        title: 'Yangi mentor sessiyasi',
        description: 'Flutter-01 guruhiga sessiyа.',
        assigneeId: dilshod.id,
        createdById: rahbarA.id,
        status: TaskStatus.yangi,
        priority: TaskPriority.orta,
      ),
    ]);

      // Moliya 0 dan boshlanadi — foydalanuvchi o'zi kiritadi.
    companyCash = 0;
    reserveCash = 0;
    finances.clear();

    attendance.addAll([
      AttendanceRecord(
        id: 'a-1',
        groupId: gFlutter.id,
        studentId: madina.id,
        date: DateTime.now().subtract(const Duration(days: 1)),
        present: true,
        grade: 9,
      ),
      AttendanceRecord(
        id: 'a-2',
        groupId: gFlutter.id,
        studentId: sardor.id,
        date: DateTime.now().subtract(const Duration(days: 1)),
        present: true,
        grade: 8,
      ),
      AttendanceRecord(
        id: 'a-3',
        groupId: gUx.id,
        studentId: dilnoza.id,
        date: DateTime.now().subtract(const Duration(days: 1)),
        present: true,
        grade: 10,
      ),
    ]);

    materials.addAll([
      StudyMaterial(
        id: 'm-1',
        groupId: gFlutter.id,
        title: 'Widget tree asoslari',
        type: StudyMaterialKind.darslik,
        urlOrNote: 'pdf/flutter-widgets.pdf',
      ),
      StudyMaterial(
        id: 'm-2',
        groupId: gFlutter.id,
        title: 'Uy vazifa #4',
        type: StudyMaterialKind.uyVazifa,
        urlOrNote: 'ListView + model',
      ),
      StudyMaterial(
        id: 'm-3',
        groupId: gUx.id,
        title: 'Figma prototip video',
        type: StudyMaterialKind.video,
        urlOrNote: 'https://mid.uz/video/figma-01',
      ),
    ]);

    projectUpdates.add(
      ProjectUpdate(
        id: 'pu-1',
        projectId: 'p-1',
        authorId: director.id,
        title: 'MVP demo tayyor',
        body: 'EduLink asosiy oqimlar sinovdan o‘tdi. Keyingi qadam — investor demo.',
      ),
    );

    announcements.addAll([
      Announcement(
        id: 'an-1',
        title: 'Haftalik yig‘ilish',
        body: 'Juma soat 16:00 da barcha xodimlar uchun yig‘ilish.',
        authorId: director.id,
        audience: AnnouncementAudience.xodimlar,
      ),
      Announcement(
        id: 'an-2',
        title: 'Amaliyot yangiligi',
        body: 'Shogirtlar uchun yangi mentor sessiyasi dushanba kuni.',
        authorId: rahbarA.id,
        audience: AnnouncementAudience.shogirtlar,
      ),
      Announcement(
        id: 'an-3',
        title: 'Umumiy e’lon',
        body: 'MID tizimida yangi funksiyalar yoqildi — profil va e’lonlar.',
        authorId: director.id,
        audience: AnnouncementAudience.barcha,
      ),
    ]);
  }
=======
>>>>>>> 7f965f570d9776b230abf7dd2a5c675f10174ea8
}
