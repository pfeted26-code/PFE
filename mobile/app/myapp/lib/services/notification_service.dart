import '../models/notification_model.dart';
import 'api_service.dart';

// ─── NotificationService ────────────────────────────────────────────────────────
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  // Get user notifications
Future<List<NotificationModel>> getNotifications() async {
    return ApiService.instance.getList(
      '/notifications',
      NotificationModel.fromJson,
    );
  }

  Future<List<NotificationModel>> getByUser(String userId) async {
    return ApiService.instance.getList(
      '/notifications/user/$userId',
      NotificationModel.fromJson,
    );
  }

  // Mark as read
  Future<void> markAsRead(String id) async {
    await ApiService.instance.put(
      '/notifications/$id/read',
      {},
      (json) => json,
    );
  }

  // Get unread count
  Future<int> getUnreadCount() async {
    final data = await ApiService.instance.get('/notifications/unread-count', (json) => json);
    return data['count'] as int;
  }
}

