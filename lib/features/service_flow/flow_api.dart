import 'dart:typed_data';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter_tcc/core/network/api_exception.dart';
import 'package:flutter_tcc/core/network/dio_client.dart';
import 'package:flutter_tcc/injection_container.dart';

typedef Json = Map<String, dynamic>;
Json object(dynamic value) => Map<String, dynamic>.from(value as Map);
List<Json> objects(dynamic value) =>
    (value as List? ?? []).map(object).toList();
String actionKey() {
  final r = Random.secure();
  final bytes = List.generate(16, (_) => r.nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final s = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${s.substring(0, 8)}-${s.substring(8, 12)}-${s.substring(12, 16)}-${s.substring(16, 20)}-${s.substring(20)}';
}

class FlowApi {
  FlowApi({Dio? dio}) : _dio = dio ?? sl<DioClient>().dio;
  final Dio _dio;
  Future<dynamic> get(String path) =>
      apiCall(() async => (await _dio.get('/flow/$path')).data);
  Future<dynamic> post(String path, Json body) => apiCall(
    () async => (await _dio.post(
      '/flow/$path',
      data: body,
      options: Options(receiveTimeout: const Duration(seconds: 90)),
    )).data,
  );
  Future<dynamic> patch(String path, Json body) =>
      apiCall(() async => (await _dio.patch('/flow/$path', data: body)).data);
  Future<dynamic> upload(String path, Uint8List bytes, String key) => apiCall(
    () async => (await _dio.post(
      '/flow/$path',
      data: FormData.fromMap({
        'clientKey': key,
        'file': MultipartFile.fromBytes(bytes, filename: 'imagem.jpg'),
      }),
      options: Options(receiveTimeout: const Duration(seconds: 60)),
    )).data,
  );
}
