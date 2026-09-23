import 'package:dio/dio.dart';

import 'package:flutter_tcc/core/network/api_exception.dart';
import 'package:flutter_tcc/core/network/dio_client.dart';
import 'package:flutter_tcc/features/reviews/data/review_models.dart';

/// As avaliações, do lado de quem as recebe.
class ReviewsApi {
  const ReviewsApi(this._client);

  final DioClient _client;

  Dio get _dio => _client.dio;

  Future<ReviewsPage> received() {
    return apiCall(() async {
      final response = await _dio.get('/reviews/received');
      return ReviewsPage.fromJson(
        (response.data as Map).cast<String, dynamic>(),
      );
    });
  }

  /// Avaliações que o profissional ainda não abriu. É o número do sino.
  Future<int> unreadCount() {
    return apiCall(() async {
      final response = await _dio.get('/reviews/unread-count');
      final data = (response.data as Map).cast<String, dynamic>();
      return (data['unreadCount'] as num?)?.toInt() ?? 0;
    });
  }

  Future<void> markRead() {
    return apiCall(() async {
      await _dio.post('/reviews/read');
    });
  }

  Future<Review> reply(String reviewId, String reply) {
    return apiCall(() async {
      final response = await _dio.post(
        '/reviews/$reviewId/reply',
        data: {'reply': reply},
      );
      return Review.fromJson((response.data as Map).cast<String, dynamic>());
    });
  }
}
