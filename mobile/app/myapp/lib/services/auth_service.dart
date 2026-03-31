import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/auth_response_model.dart';
import '../models/message_response_model.dart';
import 'storage_service.dart';

// ─── Auth Service ─────────────────────────────────────────────────────────────
// Handles all authentication-related API calls.
// Mirrors the service functions in the React web app.
//
// Endpoints used:
//   POST /users/login
//   POST /users/forgot-password
//   POST /users/reset-password

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  // ── Config ──────────────────────────────────────────────────────────────────

  static const String _baseUrl = 'http://10.0.2.2:5000';
  // static const String _baseUrl = 'http://localhost:5000';    // iOS simulator
  // static const String _baseUrl = 'https://your-domain.com'; // production

  static const String _usersUrl = '$_baseUrl/users';

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  // ── Login ────────────────────────────────────────────────────────────────────
  // POST /users/login
  // Body:    { email, password }
  // Returns: AuthResponseModel (token + user)
  // Throws:  Exception with server message on failure

  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _post(
      '$_usersUrl/login',
      body: {'email': email, 'password': password},
    );

    final authResponse = AuthResponseModel.fromJson(response);

    // Persist token + user to secure storage automatically
    await StorageService.instance.saveAuthData(
      token: authResponse.token,
      user:  authResponse.user,
    );

    return authResponse;
  }

  // ── Forgot Password ───────────────────────────────────────────────────────────
  // POST /users/forgot-password
  // Body:    { email }
  // Returns: MessageResponseModel
  // Throws:  Exception with server message on failure

  Future<MessageResponseModel> forgotPassword({
    required String email,
  }) async {
    final response = await _post(
      '$_usersUrl/forgot-password',
      body: {'email': email},
    );
    return MessageResponseModel.fromJson(response);
  }

  // ── Reset Password ────────────────────────────────────────────────────────────
  // POST /users/reset-password
  // Body:    { email, code, newPassword }
  // Returns: MessageResponseModel
  // Throws:  Exception with server message on failure

  Future<MessageResponseModel> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final response = await _post(
      '$_usersUrl/reset-password',
      body: {
        'email':       email,
        'code':        code,
        'newPassword': newPassword,
      },
    );
    return MessageResponseModel.fromJson(response);
  }

  // ── Logout ────────────────────────────────────────────────────────────────────
  // Clears local storage — no API call needed (stateless JWT).

  Future<void> logout() => StorageService.instance.clearAll();

  // ── Private HTTP helper ───────────────────────────────────────────────────────
  // Sends a POST request, decodes the JSON body, and throws a readable
  // Exception if the status code is not 2xx.

  Future<Map<String, dynamic>> _post(
    String url, {
    required Map<String, String> body,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(data['message'] ?? 'Request failed (${response.statusCode})');
      }

      return data;
    } on Exception {
      rethrow; // Already an Exception — let the screen handle it
    } catch (e) {
      // Network errors (SocketException, etc.)
      throw Exception('Unable to connect to server. Please check your connection.');
    }
  }
}