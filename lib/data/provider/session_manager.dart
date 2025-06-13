import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager extends ChangeNotifier {
  static const String _hasSeenOnboardingKey = 'has_seen_onboarding';
  static const String _isFirstLaunchKey = 'is_first_launch';

  final SharedPreferences _prefs;
  final FirebaseAuth _auth;

  SessionManager({required SharedPreferences prefs, FirebaseAuth? auth})
    : _prefs = prefs,
      _auth = auth ?? FirebaseAuth.instance {
    // Listen to auth state changes
    _auth.authStateChanges().listen((user) {
      notifyListeners();
    });
  }

  bool get isAuthenticated {
    final user = _auth.currentUser;
    return user != null && user.emailVerified;
  }

  bool get hasSeenOnboarding => _prefs.getBool(_hasSeenOnboardingKey) ?? false;
  bool get isFirstLaunch => _prefs.getBool(_isFirstLaunchKey) ?? true;

  Future<void> setHasSeenOnboarding(bool value) async {
    await _prefs.setBool(_hasSeenOnboardingKey, value);
    notifyListeners();
  }

  Future<void> setFirstLaunch(bool value) async {
    await _prefs.setBool(_isFirstLaunchKey, value);
    notifyListeners();
  }

  Future<void> clearSession() async {
    await _auth.signOut();
    // Don't clear onboarding flag
    notifyListeners();
  }

  // Add method to handle authentication success
  Future<void> onAuthenticationSuccess() async {
    notifyListeners();
  }

  // Add method to handle sign out
  Future<void> signOut() async {
    await clearSession();
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
      await clearSession();
    } catch (e) {
      rethrow;
    }
  }

  // Add method to check authentication status
  Future<bool> checkAuthenticationStatus() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload();
      return user.emailVerified;
    }
    return false;
  }
}
