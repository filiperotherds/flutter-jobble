import 'package:flutter_tcc/core/network/dio_client.dart';
import 'package:flutter_tcc/core/network/api_exception.dart';
import 'package:flutter_tcc/features/notifications/data/models/notification_model.dart';

class NotificationRemoteDataSource {
  final DioClient dioClient;

  NotificationRemoteDataSource({required this.dioClient});

  Future<List<NotificationModel>> fetchUnread() => _fetch(unreadOnly: true);

  Future<List<NotificationModel>> fetchAll() => _fetch();

  Future<List<NotificationModel>> _fetch({bool unreadOnly = false}) =>
      apiCall(() async {
        final response = await dioClient.dio.get(
          '/notifications',
          queryParameters: unreadOnly ? {'unread': 'true'} : null,
        );
        return (response.data as List)
            .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
            .toList();
      });

  Future<int> fetchUnreadCount() async {
    final response = await dioClient.dio.get('/notifications/count');
    return response.data['count'] as int;
  }

  Future<void> markAsRead(String id) async {
    await dioClient.dio.patch('/notifications/$id/read');
  }

  Future<void> markMultipleAsRead(List<String> ids) async {
    await dioClient.dio.patch('/notifications/read', data: {'ids': ids});
  }
}
