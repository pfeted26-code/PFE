import '../models/presence_model.dart';
import 'api_service.dart';

class PresenceService {
  PresenceService._();

  static final PresenceService instance =
      PresenceService._();

  Future<PresenceModel> markPresence({
    required String seanceId,
    required String studentId,
    required bool present,
  }) {
    return ApiService.instance.post(
      '/presence/create',
      <String, dynamic>{
        'seance': seanceId,
        'etudiant': studentId,
        'presente': present,
        'statut': present ? 'présent' : 'absent',
      },
      PresenceModel.fromJson,
    );
  }

  Future<List<PresenceModel>> getStudentPresences(
    String studentId,
  ) async {
    final String id = studentId.trim();

    if (id.isEmpty) {
      throw Exception('Student ID is missing');
    }

    final dynamic response =
        await ApiService.instance.getRaw(
      '/presence/getByEtudiant/$id',
    );

    return _parsePresenceList(response);
  }

  Future<List<PresenceModel>> getSeancePresences(
    String seanceId,
  ) async {
    final String id = seanceId.trim();

    if (id.isEmpty) {
      throw Exception('Session ID is missing');
    }

    final dynamic response =
        await ApiService.instance.getRaw(
      '/presence/getBySeance/$id',
    );

    return _parsePresenceList(response);
  }

  Future<PresenceModel> getPresenceById(
    String presenceId,
  ) {
    return ApiService.instance.get(
      '/presence/getById/$presenceId',
      PresenceModel.fromJson,
    );
  }

  Future<dynamic> getStudentAttendanceRate(
    String studentId,
  ) {
    return ApiService.instance.getRaw(
      '/presence/taux/etudiant/$studentId',
    );
  }

  Future<dynamic> getStudentAttendanceRateForSeance({
    required String studentId,
    required String seanceId,
  }) {
    return ApiService.instance.getRaw(
      '/presence/taux/etudiant/$studentId/'
      'seance/$seanceId',
    );
  }

  List<PresenceModel> _parsePresenceList(
    dynamic response,
  ) {
    late final List<dynamic> list;

    if (response is List) {
      list = response;
    } else if (response is Map) {
      final dynamic wrapped =
          response['presences'] ??
          response['data'] ??
          response['results'];

      if (wrapped is List) {
        list = wrapped;
      } else {
        throw Exception(
          'Invalid attendance response from server',
        );
      }
    } else {
      throw Exception(
        'Invalid attendance response from server',
      );
    }

    return list
        .whereType<Map>()
        .map(
          (Map item) => PresenceModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }
}
