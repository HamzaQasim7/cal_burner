import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  // Get current user
  UserModel? get currentUser {
    final user = _auth.currentUser;
    if (user != null) {
      return UserModel(
        id: user.uid,
        email: user.email!,
        name: user.displayName ?? '',
        photoUrl: user.photoURL,
        createdAt: DateTime.now(),
      );
    }
    return null;
  }

  // Store user data in Firestore
  Future<void> _storeUserData(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).set({
        'id': user.id,
        'email': user.email,
        'name': user.name,
        'photoUrl': user.photoUrl,
        'createdAt': user.createdAt.toIso8601String(),
        'isEmailVerified': user.isEmailVerified,
        'age': user.age,
        'height': user.height,
        'weight': user.weight,
        'bodyFatPercentage': user.bodyFatPercentage,
        'gender': user.gender,
        'location': user.location,
        'impScore': user.impScore,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get user data from Firestore (made public)
  Future<UserModel?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Update user data in Firestore
  Future<void> updateUserData(UserModel user) async {
    try {
      // Calculate new IMP Score
      final updatedUser = user.updateImpScore();

      await _firestore
          .collection('users')
          .doc(user.id)
          .update(updatedUser.toJson());
    } catch (e) {
      rethrow;
    }
  }

  // Email & Password Sign In
  Future<UserModel?> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Reload user to get latest verification status
        await userCredential.user!.reload();

        // Check if email is verified
        if (!userCredential.user!.emailVerified) {
          // Send verification email again if not verified
          await userCredential.user!.sendEmailVerification();
          throw FirebaseAuthException(
            code: 'email-not-verified',
            message: 'Please verify your email first',
          );
        }

        final userData = await getUserData(userCredential.user!.uid);
        if (userData != null) {
          return userData;
        }

        return UserModel(
          id: userCredential.user!.uid,
          email: userCredential.user!.email!,
          name: userCredential.user!.displayName ?? '',
          photoUrl: userCredential.user!.photoURL,
          createdAt: DateTime.now(),
          isEmailVerified: userCredential.user!.emailVerified,
          age: 0,
          height: 0.0,
          weight: 0.0,
          bodyFatPercentage: 0.0,
          gender: '',
          location: '',
          impScore: 0.0,
        );
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Google Sign In
  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        // Check if user data exists in Firestore
        final userData = await getUserData(userCredential.user!.uid);

        if (userData != null) {
          return userData;
        }

        // If no Firestore data exists, create and store new user with default values
        final user = UserModel(
          id: userCredential.user!.uid,
          email: userCredential.user!.email!,
          name: userCredential.user!.displayName ?? '',
          photoUrl: userCredential.user!.photoURL,
          createdAt: DateTime.now(),
          isEmailVerified: userCredential.user!.emailVerified,
          // Initialize profile data with default values
          age: 0,
          height: 0.0,
          weight: 0.0,
          bodyFatPercentage: 0.0,
          gender: '',
          location: '',
          impScore: 0.0,
        );

        // Store user data in Firestore
        await _storeUserData(user);

        return user;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Sign Up with Email & Password
  Future<UserModel?> signUpWithEmail(
    String email,
    String password,
    String name,
  ) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update user profile with name
      await userCredential.user?.updateDisplayName(name);

      // Send verification email
      await userCredential.user?.sendEmailVerification();

      if (userCredential.user != null) {
        // Create user model
        final user = UserModel(
          id: userCredential.user!.uid,
          email: userCredential.user!.email!,
          name: name,
          photoUrl: userCredential.user!.photoURL,
          createdAt: DateTime.now(),
          isEmailVerified: userCredential.user!.emailVerified,
        );

        // Store user data in Firestore
        await _storeUserData(user);

        return user;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
    } catch (e) {
      rethrow;
    }
  }

  // Forgot Password
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  // Optional: Verify Password Reset Code
  Future<bool> verifyPasswordResetCode(String code) async {
    try {
      await _auth.verifyPasswordResetCode(code);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  // Optional: Confirm Password Reset
  Future<void> confirmPasswordReset(String code, String newPassword) async {
    try {
      await _auth.confirmPasswordReset(code: code, newPassword: newPassword);
    } catch (e) {
      rethrow;
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      rethrow;
    }
  }

  // Check if email is verified
  bool get isEmailVerified {
    final user = _auth.currentUser;
    return user?.emailVerified ?? false;
  }

  // Reload user to get latest verification status
  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      rethrow;
    }
  }

  // Delete Account
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Delete user data from Firestore
        await _firestore.collection('users').doc(user.uid).delete();
        // Delete user account
        await user.delete();
      }
    } catch (e) {
      rethrow;
    }
  }

  // Add this method to check email verification status
  Future<bool> checkEmailVerification() async {
    try {
      await _auth.currentUser?.reload();
      return _auth.currentUser?.emailVerified ?? false;
    } catch (e) {
      rethrow;
    }
  }

  // Change Password
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No user is currently signed in',
        );
      }

      // Get credentials for reauthentication
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      // Reauthenticate user before changing password
      await user.reauthenticateWithCredential(credential);

      // Change password
      await user.updatePassword(newPassword);
    } catch (e) {
      rethrow;
    }
  }

  // Change Email
  Future<void> changeEmail(String currentPassword, String newEmail) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No user is currently signed in',
        );
      }

      // Get credentials for reauthentication
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      // Reauthenticate user before changing email
      await user.reauthenticateWithCredential(credential);

      // Change email
      await user.verifyBeforeUpdateEmail(newEmail);

      // Send verification email to the new address
      await user.sendEmailVerification();

      // Update UserModel
      UserModel(
        id: user.uid,
        email: newEmail,
        name: user.displayName ?? '',
        photoUrl: user.photoURL,
        createdAt: DateTime.now(),
        isEmailVerified: false,
      );

      // Update email in Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'email': newEmail,
        'isEmailVerified': false,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Verify Current Password
  Future<bool> verifyCurrentPassword(String currentPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No user is currently signed in',
        );
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      return true;
    } catch (e) {
      return false;
    }
  }
}
