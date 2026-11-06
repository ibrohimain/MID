import 'package:flutter/foundation.dart';

import '../../data/mid_store.dart';
import '../../models/app_user.dart';

class AuthController extends ChangeNotifier {
  AuthController(this.store);

  final MidStore store;
  AppUser? _user;
  String? error;

  AppUser? get user => _user;
  bool get isAuthenticated => _user != null;

  bool signIn(String login, String password) {
    final found = store.findByLogin(login, password);
    if (found == null) {
      error = "Login yoki parol noto'g'ri";
      notifyListeners();
      return false;
    }
    error = null;
    _user = found;
    notifyListeners();
    return true;
  }

  void signOut() {
    _user = null;
    error = null;
    notifyListeners();
  }

  void refreshUser() {
    if (_user == null) return;
    final fresh = store.userById(_user!.id);
    if (fresh == null || !fresh.active) {
      signOut();
      return;
    }
    _user = fresh;
    notifyListeners();
  }
}
