import 'user_model.dart';

// ─── Auth Response Model ──────────────────────────────────────────────────────
// Represents the full response body returned by POST /users/login.

class AuthResponseModel {
  final String    token;
  final UserModel user;

  const AuthResponseModel({
    required this.token,
    required this.user,
  });

  // ── Deserialization ─────────────────────────────────────────────────────────

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      token: (json['token'] ?? '') as String,
      user:  UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  // ── Serialization ───────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'token': token,
    'user':  user.toJson(),
  };

  @override
  String toString() => 'AuthResponseModel(token: ${token.substring(0, 10)}..., user: $user)';
}