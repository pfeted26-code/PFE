// ─── Forgot Password Response Model ──────────────────────────────────────────
// Represents the response body returned by POST /users/forgot-password
// and POST /users/reset-password.

class MessageResponseModel {
  final String message;

  const MessageResponseModel({required this.message});

  factory MessageResponseModel.fromJson(Map<String, dynamic> json) {
    return MessageResponseModel(
      message: (json['message'] ?? '') as String,
    );
  }

  @override
  String toString() => 'MessageResponseModel(message: $message)';
}