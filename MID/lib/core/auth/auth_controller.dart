import 'package:flutter/foundation.dart';

import '../../data/api/api_client.dart';
import '../../data/mid_store.dart';
import '../../models/app_user.dart';

class AuthController extends ChangeNotifier {
  AuthController(this.store);

  final MidStore store;
  AppUser? _user;
  String? error;
  bool busy = false;

  AppUser? get user => _user;
  bool get isAuthenticated => _user != null;

  Future<bool> signIn(String login, String password) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      final found = await store.login(login, password);
      found.password = password;
      _user = found;
      busy = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      busy = false;
      notifyListeners();
      return false;
    } catch (_) {
      error = "Serverga ulanib bo'lmadi. Backend ishlayotganini tekshiring.";
      busy = false;
      notifyListeners();
      return false;
    }
  }

  void signOut() {
    _user = null;
    error = null;
    store.logout();
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
