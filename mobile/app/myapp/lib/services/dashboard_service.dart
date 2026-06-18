import '../models/student_dashboard_model.dart';
import 'api_service.dart';

class DashboardService {
  DashboardService._();

  static final DashboardService instance =
      DashboardService._();

  // The React page calls getDashboardStats('student'), but the
  // JavaScript dashboardService file was not supplied.
  //
  // Keep the endpoint used by your backend first in this list.
  // The other values are compatibility fallbacks.
  static const List<String> _studentEndpoints =
      <String>[
    '/dashboard/stats/student',
    '/dashboard/student',
    '/dashboard/stats?role=student',
  ];

  Future<StudentDashboardModel>
      getStudentDashboard() async {
    Object? lastError;

    for (final String endpoint
        in _studentEndpoints) {
      try {
        final dynamic response =
            await ApiService.instance.getRaw(
          endpoint,
        );

        if (response is Map) {
          return StudentDashboardModel.fromJson(
            Map<String, dynamic>.from(response),
          );
        }

        throw Exception(
          'Invalid dashboard response from $endpoint',
        );
      } catch (error) {
        lastError = error;
      }
    }

    throw Exception(
      'Unable to load student dashboard. '
      '${lastError ?? ''}',
    );
  }
}
