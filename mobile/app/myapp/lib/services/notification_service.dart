import '../models/notification_model.dart';
import 'api_service.dart';

// ─── NotificationService ────────────────────────────────────────────────────────
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  // Get user notifications
Future<List<NotificationModel>> getNotifications() async {
    print('🔍 NotificationService.getNotifications called');
    return ApiService.instance.getList(
      '/notification',
      NotificationModel.fromJson,
    );
  }

Future<List<NotificationModel>> getByUser(String userId) async {
    return ApiService.instance.getList(
      '/notification/user/$userId',
      NotificationModel.fromJson,
    );
  }

  // Mark as read
  Future<void> markAsRead(String id) async {
    await ApiService.instance.put(
      '/notification/$id/read',

      {},
      (json) => json,
    );
  }

  Future<void> deleteAll(String userId) async {
    await ApiService.instance.delete('/notification/user/$userId/delete-all');
  }

  Future<void> delete(String id) async {
    await ApiService.instance.delete('/notification/$id');
  }

  // Get unread count
  Future<int> getUnreadCount() async {
    final data = await ApiService.instance.get('/notifications/unread-count', (json) => json);
    return data['count'] as int;
  }
}

