import 'user_role.dart';

class AppUser {
  AppUser({
    required this.id,
    required this.fullName,
    required this.login,
    required this.password,
    required this.role,
    this.sector,
    this.departmentId,
    this.position,
    this.email,
    this.phone,
    this.groupId,
    this.direction,
    this.salary = 0,
    this.paymentAmount = 0,
    this.studiedMonths = 0,
    this.totalMonths = 0,
    this.active = true,
  });

  final String id;
  String fullName;
  String login;
  String password;
  UserRole role;
  Sector? sector;
  String? departmentId;
  String? position;
  String? email;
  String? phone;
  String? groupId;
  String? direction;
  int salary;
  int paymentAmount;
  int studiedMonths;
  int totalMonths;
  bool active;

  bool get isStaff =>
      role == UserRole.xodim ||
      role == UserRole.rahbar ||
      role == UserRole.direktor;

  bool get isLearner =>
      role == UserRole.oquvchi || role == UserRole.shogirt;

  int get remainingMonths =>
      (totalMonths - studiedMonths).clamp(0, totalMonths);
}
