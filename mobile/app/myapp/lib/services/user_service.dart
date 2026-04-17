import '../models/user_model.dart';
import 'api_service.dart';

// ─── UserService ───────────────────────────────────────────────────────────────
class UserService {
  UserService._();
  static final UserService instance = UserService._();

  // Get all users (admin)
  Future<List<UserModel>> getAllUsers() async {
    return ApiService.instance.getList(
      '/users',
      UserModel.fromJson,
    );
  }

  // Get user by ID
  Future<UserModel> getUserById(String id) async {
    return ApiService.instance.get(
      '/users/$id',
      UserModel.fromJson,
    );
  }

  // Get current profile (like web getUserAuth)
  Future<UserModel> getProfile() async {
    return ApiService.instance.get(
      '/users/me',
      UserModel.fromJson,
    );
  }

  // Update profile
  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    return ApiService.instance.put(
      '/users/profile',
      data,
      UserModel.fromJson,
    );
  }

  // Get users by classe (students)
  Future<List<UserModel>> getClasseStudents(String classeId) async {
    return ApiService.instance.getList(
      '/users/classe/$classeId',
      UserModel.fromJson,
    );
  }

  // Search users
  Future<List<UserModel>> searchUsers(String query) async {
    return ApiService.instance.getList(
      '/users/search?q=$query',
      UserModel.fromJson,
    );
  }
}

