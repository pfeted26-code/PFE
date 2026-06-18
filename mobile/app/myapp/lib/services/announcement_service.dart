import '../models/announcement_model.dart';
import 'api_service.dart';

class AnnouncementService {
  AnnouncementService._();

  static final AnnouncementService instance =
      AnnouncementService._();

  Future<List<AnnouncementModel>> getAllAnnouncements() async {
    final dynamic response = await ApiService.instance.getRaw(
      '/announcement',
    );

    return _parseAnnouncementList(response);
  }

  Future<List<AnnouncementModel>> getMyAnnouncements() async {
    final dynamic response = await ApiService.instance.getRaw(
      '/announcement/my-announcements',
    );

    return _parseAnnouncementList(response);
  }

  Future<AnnouncementModel> getAnnouncementById(
    String id,
  ) {
    return ApiService.instance.get(
      '/announcement/$id',
      AnnouncementModel.fromJson,
    );
  }

  Future<AnnouncementModel> createAnnouncement(
    Map<String, dynamic> data,
  ) {
    return ApiService.instance.post(
      '/announcement',
      data,
      AnnouncementModel.fromJson,
    );
  }

  Future<AnnouncementModel> updateAnnouncement(
    String id,
    Map<String, dynamic> data,
  ) {
    return ApiService.instance.put(
      '/announcement/$id',
      data,
      AnnouncementModel.fromJson,
    );
  }

  Future<void> deleteAnnouncement(String id) async {
    await ApiService.instance.delete('/announcements/$id');
  }

  Future<void> markAsViewed(String id) async {
    await ApiService.instance.post<Map<String, dynamic>>(
      '/announcement/$id/view',
      <String, dynamic>{},
      (Map<String, dynamic> json) => json,
    );
  }

  Future<void> togglePin(String id) async {
    await ApiService.instance.patch<Map<String, dynamic>>(
      '/announcement/$id/toggle-pin',
      <String, dynamic>{},
      (Map<String, dynamic> json) => json,
    );
  }

  List<AnnouncementModel> _parseAnnouncementList(
    dynamic response,
  ) {
    late final List<dynamic> list;

    if (response is List) {
      list = response;
    } else if (response is Map) {
      final dynamic wrapped =
          response['announcements'] ??
          response['annonces'] ??
          response['data'] ??
          response['results'];

      if (wrapped is List) {
        list = wrapped;
      } else {
        throw Exception(
          'Invalid announcements response from server',
        );
      }
    } else {
      throw Exception(
        'Invalid announcements response from server',
      );
    }

    return list
        .whereType<Map>()
        .map(
          (Map item) => AnnouncementModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }
}
