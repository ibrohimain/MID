import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/domain.dart';
import '../models/user_role.dart';

class MidStore extends ChangeNotifier {
  MidStore() {
    _seed();
  }

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
  int _seq = 100;

  String _id(String prefix) {
    _seq++;
    return '$prefix-$_seq';
  }

  String _receipt() {
    _seq++;
    return 'CHK-${DateTime.now().year}-$_seq';
  }

  AppUser? findByLogin(String login, String password) {
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
  AppUser addUser({
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
  }) {
    final user = AppUser(
      id: _id('u'),
      fullName: fullName,
      login: login,
      password: password,
      role: role,
      sector: sector,
      departmentId: departmentId,
      position: position,
      email: email,
      groupId: groupId,
      direction: direction,
      salary: salary,
      paymentAmount: paymentAmount,
      studiedMonths: studiedMonths,
      totalMonths: totalMonths,
    );
    users.add(user);
    notifyListeners();
    return user;
  }

  void updateUser(AppUser user) {
    notifyListeners();
  }

  void updateProfile({
    required String userId,
    String? fullName,
    String? email,
    String? phone,
    String? password,
  }) {
    final user = userById(userId);
    if (user == null) return;
    if (fullName != null && fullName.trim().isNotEmpty) {
      user.fullName = fullName.trim();
    }
    if (email != null) user.email = email.trim();
    if (phone != null) user.phone = phone.trim();
    if (password != null && password.trim().isNotEmpty) {
      user.password = password.trim();
    }
    notifyListeners();
  }

  /// Soft-delete: tizimdan chiqaradi, login ishlamaydi.
  bool deleteUser(String userId, {required UserRole actorRole}) {
    final target = userById(userId);
    if (target == null) return false;
    if (target.role == UserRole.direktor) return false;
    if (actorRole == UserRole.rahbar &&
        (target.role == UserRole.rahbar || target.role == UserRole.direktor)) {
      return false;
    }
    if (actorRole != UserRole.direktor && actorRole != UserRole.rahbar) {
      return false;
    }
    target.active = false;
    notifyListeners();
    return true;
  }

  bool loginTaken(String login, {String? exceptUserId}) {
    final needle = login.trim().toLowerCase();
    return users.any(
      (u) =>
          u.active &&
          u.login.toLowerCase() == needle &&
          u.id != exceptUserId,
    );
  }

  // --- Tasks ---
  TaskItem assignTask({
    required String title,
    required String description,
    required String assigneeId,
    required String createdById,
    required TaskPriority priority,
    String? projectId,
  }) {
    final task = TaskItem(
      id: _id('t'),
      title: title,
      description: description,
      assigneeId: assigneeId,
      createdById: createdById,
      status: TaskStatus.yangi,
      priority: priority,
      projectId: projectId,
    );
    tasks.insert(0, task);
    notifyListeners();
    return task;
  }

  void setTaskStatus(String taskId, TaskStatus status) {
    final t = tasks.firstWhere((e) => e.id == taskId);
    t.status = status;
    notifyListeners();
  }

  void updateTask({
    required String taskId,
    required String title,
    required String description,
    required String assigneeId,
    required TaskPriority priority,
    required TaskStatus status,
    String? projectId,
  }) {
    final t = tasks.firstWhere((e) => e.id == taskId);
    t.title = title;
    t.description = description;
    t.assigneeId = assigneeId;
    t.priority = priority;
    t.status = status;
    t.projectId = projectId;
    notifyListeners();
  }

  void deleteTask(String taskId) {
    tasks.removeWhere((e) => e.id == taskId);
    notifyListeners();
  }

  // --- Projects ---
  ProjectItem addProject({
    required String name,
    required String description,
    required String stage,
    required int requiredBudget,
    required int investment,
    required int expense,
    required Sector sector,
    List<String> assigneeIds = const [],
  }) {
    final p = ProjectItem(
      id: _id('p'),
      name: name,
      description: description,
      stage: stage,
      requiredBudget: requiredBudget,
      investment: investment,
      expense: expense,
      sector: sector,
      assigneeIds: List.of(assigneeIds),
      parts: {},
    );
    projects.insert(0, p);
    notifyListeners();
    return p;
  }

  void updateProject({
    required String projectId,
    required String name,
    required String description,
    required String stage,
    required int requiredBudget,
    required int investment,
    required int expense,
    required Sector sector,
  }) {
    final p = projects.firstWhere((e) => e.id == projectId);
    p.name = name;
    p.description = description;
    p.stage = stage;
    p.requiredBudget = requiredBudget;
    p.investment = investment;
    p.expense = expense;
    p.sector = sector;
    notifyListeners();
  }

  void setProjectStage(String projectId, String stage) {
    final p = projects.firstWhere((e) => e.id == projectId);
    p.stage = stage;
    notifyListeners();
  }

  void deleteProject(String projectId) {
    projects.removeWhere((e) => e.id == projectId);
    projectUpdates.removeWhere((e) => e.projectId == projectId);
    notifyListeners();
  }

  void assignEmployeeToProjectPart({
    required String projectId,
    required String partName,
    required String employeeId,
  }) {
    final p = projects.firstWhere((e) => e.id == projectId);
    p.parts = {...p.parts, partName: employeeId};
    if (!p.assigneeIds.contains(employeeId)) {
      p.assigneeIds = [...p.assigneeIds, employeeId];
    }
    notifyListeners();
  }

  ProjectUpdate addProjectUpdate({
    required String projectId,
    required String authorId,
    required String title,
    required String body,
  }) {
    final u = ProjectUpdate(
      id: _id('pu'),
      projectId: projectId,
      authorId: authorId,
      title: title,
      body: body,
    );
    projectUpdates.insert(0, u);
    notifyListeners();
    return u;
  }

  void deleteProjectUpdate(String updateId) {
    projectUpdates.removeWhere((e) => e.id == updateId);
    notifyListeners();
  }

  List<ProjectUpdate> updatesFor(String projectId) =>
      projectUpdates.where((e) => e.projectId == projectId).toList();

  // --- Announcements ---
  Announcement addAnnouncement({
    required String title,
    required String body,
    required String authorId,
    required AnnouncementAudience audience,
  }) {
    final a = Announcement(
      id: _id('an'),
      title: title,
      body: body,
      authorId: authorId,
      audience: audience,
    );
    announcements.insert(0, a);
    notifyListeners();
    return a;
  }

  void updateAnnouncement({
    required String id,
    required String title,
    required String body,
    required AnnouncementAudience audience,
  }) {
    final a = announcements.firstWhere((e) => e.id == id);
    a.title = title;
    a.body = body;
    a.audience = audience;
    notifyListeners();
  }

  void deleteAnnouncement(String id) {
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
  void _applyFinance(FinanceType type, int amount, {required bool reverse}) {
    final signed = reverse ? -amount : amount;
    switch (type) {
      case FinanceType.kirim:
        companyCash += signed;
      case FinanceType.chiqim:
      case FinanceType.maosh:
      case FinanceType.ajratma:
        companyCash -= signed;
      case FinanceType.zaxira:
        companyCash -= signed;
        reserveCash += signed;
    }
  }

  FinanceRecord addFinance({
    required String title,
    required int amount,
    required FinanceType type,
    String note = '',
    String? relatedUserId,
    String? projectId,
  }) {
    final rec = FinanceRecord(
      id: _id('f'),
      title: title,
      amount: amount,
      type: type,
      receiptNo: _receipt(),
      note: note,
      relatedUserId: relatedUserId,
      projectId: projectId,
    );
    finances.insert(0, rec);
    _applyFinance(type, amount, reverse: false);
    notifyListeners();
    return rec;
  }

  void updateFinance({
    required String id,
    required String title,
    required int amount,
    required FinanceType type,
    String note = '',
  }) {
    final rec = finances.firstWhere((e) => e.id == id);
    _applyFinance(rec.type, rec.amount, reverse: true);
    rec.title = title;
    rec.amount = amount;
    rec.type = type;
    rec.note = note;
    _applyFinance(type, amount, reverse: false);
    notifyListeners();
  }

  void deleteFinance(String id) {
    final idx = finances.indexWhere((e) => e.id == id);
    if (idx < 0) return;
    final rec = finances[idx];
    _applyFinance(rec.type, rec.amount, reverse: true);
    finances.removeAt(idx);
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
  DepartmentItem addDepartment({
    required String name,
    required Sector sector,
    required String headId,
    required List<String> positions,
  }) {
    final d = DepartmentItem(
      id: _id('d'),
      name: name,
      sector: sector,
      headId: headId,
      positions: List.of(positions),
    );
    departments.add(d);
    notifyListeners();
    return d;
  }

  void setDepartmentPositions(String id, List<String> positions) {
    final d = departments.firstWhere((e) => e.id == id);
    d.positions = List.of(positions);
    notifyListeners();
  }

  void updateDepartment({
    required String id,
    required String name,
    required Sector sector,
    required String headId,
    required List<String> positions,
  }) {
    final d = departments.firstWhere((e) => e.id == id);
    d.name = name;
    d.sector = sector;
    d.headId = headId;
    d.positions = List.of(positions);
    notifyListeners();
  }

  void assignDepartmentHead(String departmentId, String headId) {
    final d = departments.firstWhere((e) => e.id == departmentId);
    d.headId = headId;
    notifyListeners();
  }

  void deleteDepartment(String id) {
    departments.removeWhere((e) => e.id == id);
    for (final u in users.where((u) => u.departmentId == id)) {
      u.departmentId = null;
    }
    notifyListeners();
  }

  void updateStaffUser({
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
  }) {
    final u = userById(userId);
    if (u == null) return;
    u.fullName = fullName;
    u.login = login;
    u.password = password;
    if (sector != null) u.sector = sector;
    if (departmentId != null) u.departmentId = departmentId;
    if (position != null) u.position = position;
    if (salary != null) u.salary = salary;
    if (email != null) u.email = email;
    if (phone != null) u.phone = phone;
    if (groupId != null) u.groupId = groupId;
    if (direction != null) u.direction = direction;
    if (paymentAmount != null) u.paymentAmount = paymentAmount;
    if (studiedMonths != null) u.studiedMonths = studiedMonths;
    if (totalMonths != null) u.totalMonths = totalMonths;
    if (role != null && role != UserRole.direktor) u.role = role;
    notifyListeners();
  }

  // --- Education ---
  StudyGroup addGroup({
    required String name,
    required String direction,
    required String teacherId,
    Sector? sector,
  }) {
    final g = StudyGroup(
      id: _id('g'),
      name: name,
      direction: direction,
      teacherId: teacherId,
      sector: sector,
    );
    groups.add(g);
    notifyListeners();
    return g;
  }

  void markAttendance({
    required String groupId,
    required String studentId,
    required bool present,
    required int grade,
    DateTime? date,
  }) {
    attendance.add(
      AttendanceRecord(
        id: _id('a'),
        groupId: groupId,
        studentId: studentId,
        date: date ?? DateTime.now(),
        present: present,
        grade: grade.clamp(1, 10),
      ),
    );
    notifyListeners();
  }

  void addMaterial({
    required String groupId,
    required String title,
    required StudyMaterialKind type,
    String urlOrNote = '',
  }) {
    materials.insert(
      0,
      StudyMaterial(
        id: _id('m'),
        groupId: groupId,
        title: title,
        type: type,
        urlOrNote: urlOrNote,
      ),
    );
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
}
