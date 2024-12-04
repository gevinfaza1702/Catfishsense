import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<UserModel?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;
      if (user != null) {
        return UserModel(
            uid: user.uid, email: user.email!); // Pastikan email tidak null
      }
    } catch (e) {
      print("SignIn Error: $e");
      return null;
    }
    return null;
  }

  Future<UserModel?> signUpWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;
      if (user != null) {
        return UserModel(
            uid: user.uid, email: user.email!); // Pastikan email tidak null
      }
    } catch (e) {
      print("SignUp Error: $e");
      return null;
    }
    return null;
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      print("SignOut Error: $e");
      throw e; // Jangan lupa menangani kesalahan
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print("Reset Password Error: $e");
      throw e; // Tangani kesalahan saat reset password
    }
  }

  Future<UserModel?> getUserByUid(String uid) async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user != null && user.uid == uid) {
        return UserModel(
            uid: user.uid, email: user.email!); // Pastikan email tidak null
      }
    } catch (e) {
      print("Get User Error: $e");
      return null;
    }
    return null;
  }

  // Metode ini menangani pembaruan email di Firebase Authentication
  Future<void> updateEmail(String newEmail) async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.updateEmail(newEmail);
        print("Email updated successfully");
      }
    } catch (e) {
      print("Email Update Error: $e");
      throw e;
    }
  }

  // Metode untuk re-autentikasi sebelum mengupdate email
  Future<void> reauthenticate(String email, String password) async {
    try {
      User? user = _firebaseAuth.currentUser;
      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user?.reauthenticateWithCredential(credential);
      print("Re-authentication successful");
    } catch (e) {
      print("Re-authentication Error: $e");
      throw e;
    }
  }
}
