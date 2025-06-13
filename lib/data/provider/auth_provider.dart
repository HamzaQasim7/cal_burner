import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../repository/auth_repository.dart';

class AuthenticationProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  AuthenticationProvider({AuthRepository? authRepository})
    : _authRepository = authRepository ?? AuthRepository();

  // Getters
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _authRepository.isAuthenticated;
  bool get isEmailVerified => _authRepository.isEmailVerified;
  User? get firebaseUser => FirebaseAuth.instance.currentUser;

  // Initialize provider
  Future<void> initialize() async {
    _setLoading(true);
    try {
      _user = _authRepository.currentUser;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Email & Password Sign In
  Future<bool> signInWithEmail(String email, String password) async {
    _setLoading(true);
    try {
      _user = await _authRepository.signInWithEmail(email, password);
      if (_user == null) {
        _error = "Failed to sign in";
        notifyListeners();
        return false;
      }
      
      // Check email verification
      if (!_user!.isEmailVerified) {
        await _authRepository.sendEmailVerification();
        _error = "Please verify your email first";
        notifyListeners();
        return false;
      }
      
      _error = null;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Google Sign In
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    try {
      _user = await _authRepository.signInWithGoogle();
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign Up with Email & Password
  Future<bool> signUpWithEmail(
    String email,
    String password,
    String name,
  ) async {
    _setLoading(true);
    try {
      _user = await _authRepository.signUpWithEmail(email, password, name);
      _error = null;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign Out
  Future<bool> signOut() async {
    _setLoading(true);
    try {
      await _authRepository.signOut();
      _user = null;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Forgot Password
  Future<bool> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    try {
      await _authRepository.sendPasswordResetEmail(email);
      _error = null;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Verify Password Reset Code
  Future<bool> verifyPasswordResetCode(String code) async {
    _setLoading(true);
    try {
      final result = await _authRepository.verifyPasswordResetCode(code);
      _error = null;
      notifyListeners();
      return result;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Confirm Password Reset
  Future<bool> confirmPasswordReset(String code, String newPassword) async {
    _setLoading(true);
    try {
      await _authRepository.confirmPasswordReset(code, newPassword);
      _error = null;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Send Email Verification
  Future<bool> sendEmailVerification() async {
    _setLoading(true);
    try {
      await _authRepository.sendEmailVerification();
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Reload User
  Future<bool> reloadUser() async {
    _setLoading(true);
    try {
      await _authRepository.reloadUser();
      _user = _authRepository.currentUser;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete Account
  Future<bool> deleteAccount() async {
    _setLoading(true);
    try {
      await _authRepository.deleteAccount();
      _user = null;
      _error = null;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update User Data
  Future<bool> updateUserData(UserModel updatedUser) async {
    _setLoading(true);
    try {
      await _authRepository.updateUserData(updatedUser);
      _user = updatedUser; // Update the local user state
      _error = null;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Add method to check email verification
  Future<bool> checkEmailVerification() async {
    try {
      return await _authRepository.checkEmailVerification();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Helper method to set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
