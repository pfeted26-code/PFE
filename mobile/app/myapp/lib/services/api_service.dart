import 'dart:convert';

import 'package:http/http.dart' as http;

import 'storage_service.dart';

class ApiService {
  ApiService._();

  // Add this method inside your existing ApiService class.
// It is required because the backend toggle-pin route uses PATCH.

Future<T> patch<T>(
  String path,
  Map<String, dynamic> body,
  T Function(Map<String, dynamic>) fromJson,
) async {
  final Map<String, String> headers = await _getAuthHeaders();

  final http.Response response = await http.patch(
    Uri.parse('$_baseUrl$path'),
    headers: headers,
    body: jsonEncode(body),
  );

  _checkResponse(response);

  if (response.body.trim().isEmpty) {
    return fromJson(<String, dynamic>{});
  }

  final dynamic data = jsonDecode(response.body);

  if (data is! Map) {
    throw Exception('Invalid object response from $path');
  }

  return fromJson(Map<String, dynamic>.from(data));
}


  static final ApiService instance = ApiService._();

  // Physical Android phone:
  // Replace this value if your computer IPv4 changes.
  static const String _baseUrl = 'http://192.168.1.211:5000';

  Future<T> get<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final dynamic data = await getRaw(path);

    if (data is! Map) {
      throw Exception('Invalid object response from $path');
    }

    return fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  Future<dynamic> getRaw(String path) async {
    final Map<String, String> headers =
        await _getAuthHeaders();

    final http.Response response = await http.get(
      Uri.parse('$_baseUrl$path'),
      headers: headers,
    );

    _checkResponse(response);
    return _decodeResponse(response);
  }

  Future<List<T>> getList<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final dynamic data = await getRaw(endpoint);

    late final List<dynamic> list;

    if (data is List) {
      list = data;
    } else if (
        data is Map<String, dynamic> &&
        data['demandes'] is List
    ) {
      list = List<dynamic>.from(data['demandes']);
    } else if (
        data is Map<String, dynamic> &&
        data['data'] is List
    ) {
      list = List<dynamic>.from(data['data']);
    } else if (
        data is Map<String, dynamic> &&
        data['requests'] is List
    ) {
      list = List<dynamic>.from(data['requests']);
    } else {
      throw Exception(
        'Invalid list response from $endpoint',
      );
    }

    return list
        .whereType<Map>()
        .map(
          (Map item) => fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  Future<T> post<T>(
    String path,
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final Map<String, String> headers =
        await _getAuthHeaders();

    final http.Response response = await http.post(
      Uri.parse('$_baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    );

    _checkResponse(response);

    final dynamic data = _decodeResponse(response);

    if (data is! Map) {
      throw Exception('Invalid object response from $path');
    }

    return fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  Future<T> put<T>(
    String path,
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final Map<String, String> headers =
        await _getAuthHeaders();

    final http.Response response = await http.put(
      Uri.parse('$_baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    );

    _checkResponse(response);

    final dynamic data = _decodeResponse(response);

    if (data is! Map) {
      throw Exception('Invalid object response from $path');
    }

    return fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  Future<Map<String, dynamic>> delete(
    String path,
  ) async {
    final Map<String, String> headers =
        await _getAuthHeaders();

    final http.Response response = await http.delete(
      Uri.parse('$_baseUrl$path'),
      headers: headers,
    );

    _checkResponse(response);

    if (response.body.trim().isEmpty) {
      return <String, dynamic>{};
    }

    final dynamic data = _decodeResponse(response);

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return <String, dynamic>{};
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final Map<String, String> headers =
        <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final String? token =
        await StorageService.instance.getToken();

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  dynamic _decodeResponse(
    http.Response response,
  ) {
    if (response.body.trim().isEmpty) {
      return <String, dynamic>{};
    }

    try {
      return jsonDecode(response.body);
    } on FormatException {
      throw Exception('Invalid response format');
    }
  }

  void _checkResponse(
    http.Response response,
  ) {
    if (
      response.statusCode >= 200 &&
      response.statusCode < 300
    ) {
      return;
    }

    String message =
        'Server error: ${response.statusCode}';

    try {
      final dynamic data =
          jsonDecode(response.body);

      if (data is Map) {
        message = (
          data['message'] ??
          data['error'] ??
          message
        ).toString();
      }
    } catch (_) {
      if (response.body.trim().isNotEmpty) {
        message = response.body.trim();
      }
    }

    throw Exception(message);
  }
}
