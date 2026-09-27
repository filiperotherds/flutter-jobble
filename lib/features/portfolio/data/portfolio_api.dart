import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'package:flutter_tcc/core/network/api_exception.dart';
import 'package:flutter_tcc/core/network/dio_client.dart';
import 'package:flutter_tcc/features/portfolio/data/portfolio_models.dart';
import 'package:flutter_tcc/injection_container.dart';

/// O portfólio do profissional.
///
/// Criar o trabalho e enviar os arquivos são chamadas separadas de propósito:
/// um envio que falha no meio não derruba o trabalho inteiro, e a tela pode
/// mostrar o progresso arquivo a arquivo.
class PortfolioApi {
  PortfolioApi({DioClient? client}) : _dio = (client ?? sl<DioClient>()).dio;

  final Dio _dio;

  /// O portfólio de quem está logado.
  Future<List<PortfolioItem>> mine() => _list('/portfolio/mine');

  /// O portfólio de um profissional, como o cliente o vê. Rota pública.
  Future<List<PortfolioItem>> forProvider(String providerId) =>
      _list('/providers/$providerId/portfolio');

  Future<List<PortfolioItem>> _list(String path) {
    return apiCall(() async {
      final response = await _dio.get(path);
      return (response.data as List)
          .map(
            (row) => PortfolioItem.fromJson((row as Map).cast<String, dynamic>()),
          )
          .toList();
    });
  }

  Future<PortfolioItem> create({
    required PortfolioKind kind,
    required String title,
    String? description,
  }) {
    return apiCall(() async {
      final response = await _dio.post(
        '/portfolio',
        data: {
          'kind': kind.code,
          'title': title,
          if (description != null && description.isNotEmpty)
            'description': description,
        },
      );
      return PortfolioItem.fromJson(
        (response.data as Map).cast<String, dynamic>(),
      );
    });
  }

  /// Envia um arquivo. [role] só vale no antes-e-depois: BEFORE ou AFTER.
  Future<PortfolioItem> addMedia({
    required String itemId,
    required Uint8List bytes,
    required String filename,
    String? role,
  }) {
    return apiCall(() async {
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      });

      final response = await _dio.post(
        '/portfolio/$itemId/media',
        data: form,
        queryParameters: {if (role != null) 'role': role},
      );
      return PortfolioItem.fromJson(
        (response.data as Map).cast<String, dynamic>(),
      );
    });
  }

  Future<void> remove(String itemId) {
    return apiCall(() async {
      await _dio.delete('/portfolio/$itemId');
    });
  }

  Future<PortfolioItem> removeMedia(String itemId, String mediaId) {
    return apiCall(() async {
      final response = await _dio.delete('/portfolio/$itemId/media/$mediaId');
      return PortfolioItem.fromJson(
        (response.data as Map).cast<String, dynamic>(),
      );
    });
  }

  /// Reordena a grade. O app manda os identificadores na ordem desejada.
  Future<List<PortfolioItem>> reorder(List<String> ids) {
    return apiCall(() async {
      final response = await _dio.patch(
        '/portfolio/order',
        data: {'ids': ids},
      );
      return (response.data as List)
          .map(
            (row) => PortfolioItem.fromJson((row as Map).cast<String, dynamic>()),
          )
          .toList();
    });
  }
}
