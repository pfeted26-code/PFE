**Mobile Notifications - Like Web**

**Status**: In Progress

**Backend**: GET /notifications/user/:userId ✓ (auth OK)

**Steps**:
- [ ] 1. notification_service.dart: Add getByUser(String userId)
- [ ] 2. Layout.dart: import NotificationService, _fetchNotifications → getByUser(_user!.id)
- [ ] 3. Map NotificationModel → _Notif (id, message: titre+message, date, unread: !lu)
- [ ] 4. `flutter pub get && flutter run` test

**Model**: titre/message/type/user/lu/createdAt → _Notif mock

