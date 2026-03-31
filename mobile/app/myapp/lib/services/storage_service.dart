import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user_model.dart';

// ─── Storage Service ──────────────────────────────────────────────────────────
// Single source of truth for all secure local storage operations.
// Uses flutter_secure_storage (Keychain on iOS, EncryptedSharedPrefs on Android).
//
// Usage:
//   final storage = StorageService();
//   await storage.saveAuthData(token: '...', user: userModel);
//   final token = await storage.getToken();
//   await storage.clearAll(); // on logout

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ── Keys ────────────────────────────────────────────────────────────────────

  static const _keyToken    = 'auth_token';
  static const _keyUser     = 'auth_user';
  static const _keyRole     = 'user_role';

  // ── Write ───────────────────────────────────────────────────────────────────

  /// Saves the token and full user object after a successful login.
  Future<void> saveAuthData({
    required String    token,
    required UserModel user,
  }) async {
    await Future.wait([
      _storage.write(key: _keyToken, value: token),
      _storage.write(key: _keyUser,  value: jsonEncode(user.toJson())),
      _storage.write(key: _keyRole,  value: user.role),
    ]);
  }

  // ── Read ────────────────────────────────────────────────────────────────────

  /// Returns the stored JWT token, or null if not logged in.
  Future<String?> getToken() => _storage.read(key: _keyToken);

  /// Returns the stored role string ('admin' | 'enseignant' | 'etudiant'),
  /// or null if not logged in.
  Future<String?> getRole() => _storage.read(key: _keyRole);

  /// Returns the full stored UserModel, or null if not logged in.
  Future<UserModel?> getUser() async {
    final raw = await _storage.read(key: _keyUser);
    if (raw == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Returns true if a token exists in storage (user is logged in).
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ── Delete ──────────────────────────────────────────────────────────────────

  /// Clears all auth data — call this on logout.
  Future<void> clearAll() => _storage.deleteAll();
}