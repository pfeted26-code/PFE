import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/auth_response_model.dart';
import 'storage_service.dart';

// ─── ApiService ─────────────────────────────────────────────────────────────────
// Centralized HTTP client for all API calls.
// Features: Auth token auto-injection, JSON serialization, error handling,
//           type-safe responses via fromJson factories.
//
// Usage:
//   ApiService.getList<ClasseModel>('/classe/getAllClasses', ClasseModel.fromJson)
//   ApiService.post<ClasseModel>('/classe/createClasse', data, ClasseModel.fromJson)

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  // ── Config ────────────────────────────────────────────────────────────────────
  static const String _baseUrl = 'http://192.168.1.109:5000'; // Android emulator
  // static const String _baseUrl = 'http://localhost:5000'; // iOS
  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json',
  };

  // ── Generic GET ───────────────────────────────────────────────────────────────
  Future<T> get<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final headers = await _getAuthHeaders();
    final response = await http.get(Uri.parse('$_baseUrl$path'), headers: headers);

    _checkResponse(response);
    return fromJson(jsonDecode(response.body));
  }

  // ── Generic GET List ──────────────────────────────────────────────────────────
  Future<List<T>> getList<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final headers = await _getAuthHeaders();
    final response = await http.get(Uri.parse('$_baseUrl$path'), headers: headers);

    _checkResponse(response);
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((item) => fromJson(item)).toList();
  }

  // ── Generic POST ──────────────────────────────────────────────────────────────
  Future<T> post<T>(
    String path,
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final headers = await _getAuthHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    );

    _checkResponse(response);
    return fromJson(jsonDecode(response.body));
  }

  // ── Generic PUT ───────────────────────────────────────────────────────────────
  Future<T> put<T>(
    String path,
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final headers = await _getAuthHeaders();
    final response = await http.put(
      Uri.parse('$_baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    );

    _checkResponse(response);
    return fromJson(jsonDecode(response.body));
  }

  // ── Generic DELETE ────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> delete(String path) async {
    final headers = await _getAuthHeaders();
    final response = await http.delete(Uri.parse('$_baseUrl$path'), headers: headers);
    _checkResponse(response);
    return jsonDecode(response.body);
  }

  // ── Private helpers ────────────────────────────────────────────────────────────
  Future<Map<String, String>> _getAuthHeaders() async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = await StorageService.instance.getToken();
    if (token?.isNotEmpty ?? false) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  void _checkResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(data['message'] ?? 'Server error: ${response.statusCode}');
      }
    } on FormatException {
      throw Exception('Invalid response format');
    }
  }
}


