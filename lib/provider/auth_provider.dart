import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    try {
      _user = await _authService.signInWithEmailAndPassword(email, password);
      _errorMessage = null;

      if (_user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('uid', _user!.uid);
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
    notifyListeners();
    return _user != null;
  }

  Future<bool> signUp(String email, String password) async {
    _setLoading(true);
    try {
      _user = await _authService.signUpWithEmailAndPassword(email, password);
      _errorMessage = null;

      if (_user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('uid', _user!.uid);
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
    notifyListeners();
    return _user != null;
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      _user = null;
      _errorMessage = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isLoggedIn');
      await prefs.remove('uid');
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
    notifyListeners();
  }

  Future<void> resetPassword(String email) async {
    _setLoading(true);
    try {
      await _authService.resetPassword(email);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
    notifyListeners();
  }

  Future<bool> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    bool? isLoggedIn = prefs.getBool('isLoggedIn');
    if (isLoggedIn == true) {
      String? uid = prefs.getString('uid');
      if (uid != null) {
        _user = await _authService.getUserByUid(uid);
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  // Metode untuk memperbarui email di Firebase Authentication
  Future<void> updateEmail(String newEmail, String password) async {
    _setLoading(true);
    try {
      await _authService.reauthenticate(
          user!.email, password); // Re-autentikasi
      await _authService.updateEmail(newEmail); // Update email
      _user = _user?.copyWith(email: newEmail); // Update objek user lokal
      _errorMessage = null;

      // Simpan email baru di SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('email', newEmail);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
    notifyListeners();
  }

  // Pembaruan profil pengguna di Firestore
  Future<void> updateFirestoreUserProfile(
      String uid, String name, String phone) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    try {
      await userRef.update({
        'namaLengkap': name,
        'nomorHandphone': phone,
      });
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  // Metode updateUser untuk memperbarui nama dan nomor telepon lokal
  void updateUser({String? name, String? phoneNumber}) {
    if (_user != null) {
      _user = _user!.copyWith(
        name: name,
        phoneNumber: phoneNumber,
      );
      notifyListeners();
    }
  }

  // Tambahan: Auto Login saat aplikasi dibuka kembali jika user sudah login
  Future<void> autoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    bool? isLoggedIn = prefs.getBool('isLoggedIn');
    String? uid = prefs.getString('uid');

    if (isLoggedIn != null && isLoggedIn && uid != null) {
      _user = await _authService.getUserByUid(uid);
      notifyListeners();
    }
  }
}
