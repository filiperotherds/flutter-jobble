import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import 'package:flutter_tcc/core/network/api_exception.dart';
import 'package:flutter_tcc/core/network/dio_client.dart';
import 'package:flutter_tcc/injection_container.dart';

/// Um serviço do catálogo do profissional.
class CatalogService {
  const CatalogService({
    required this.id,
    required this.title,
    required this.requiresVisit,
    this.description,
    this.priceCents,
    this.unit,
  });

  factory CatalogService.fromJson(Map<String, dynamic> json) => CatalogService(
    id: '${json['id']}',
    title: '${json['title']}',
    requiresVisit: json['requiresVisit'] == true,
    description: json['description'] as String?,
    priceCents: (json['priceCents'] as num?)?.toInt(),
    unit: json['unit'] as String?,
  );

  final String id;
  final String title;
  final String? description;

  /// Nulo quando o valor só sai depois da visita.
  final int? priceCents;

  final String? unit;
  final bool requiresVisit;

  /// O preço como o card o escreve. Sem valor, "A combinar" — e a linha de
  /// baixo explica por quê.
  String get priceLabel {
    if (priceCents == null) return 'A combinar';
    return NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    ).format(priceCents! / 100);
  }

  /// A linha pequena embaixo do preço.
  String get unitLabel {
    if (unit != null && unit!.isNotEmpty) return unit!;
    return requiresVisit ? 'após a visita' : 'sob orçamento';
  }
}

/// O catálogo de serviços.
///
/// A leitura é pública: quem está escolhendo profissional precisa ver o que
/// ele faz e por quanto antes de ter conta. Criar e editar exigem a sessão do
/// dono.
class ServicesApi {
  ServicesApi({DioClient? client}) : _dio = (client ?? sl<DioClient>()).dio;

  final Dio _dio;

  Future<List<CatalogService>> forProvider(String providerId) =>
      _list('/providers/$providerId/services');

  Future<List<CatalogService>> mine() => _list('/services/mine');

  Future<List<CatalogService>> _list(String path) {
    return apiCall(() async {
      final response = await _dio.get(path);
      return (response.data as List)
          .map(
            (row) =>
                CatalogService.fromJson((row as Map).cast<String, dynamic>()),
          )
          .toList();
    });
  }

  Future<CatalogService> create({
    required String title,
    String? description,
    int? priceCents,
    String? unit,
    bool requiresVisit = false,
  }) {
    return apiCall(() async {
      final response = await _dio.post(
        '/services',
        data: {
          'title': title,
          if (description != null && description.isNotEmpty)
            'description': description,
          if (!requiresVisit && priceCents != null) 'priceCents': priceCents,
          if (unit != null && unit.isNotEmpty) 'unit': unit,
          'requiresVisit': requiresVisit,
        },
      );
      return CatalogService.fromJson(
        (response.data as Map).cast<String, dynamic>(),
      );
    });
  }

  Future<CatalogService> update(
    String id, {
    String? title,
    String? description,
    int? priceCents,
    String? unit,
    bool? requiresVisit,
  }) {
    return apiCall(() async {
      final response = await _dio.patch(
        '/services/$id',
        data: {
          if (title != null) 'title': title,
          if (description != null) 'description': description,
          if (priceCents != null) 'priceCents': priceCents,
          if (unit != null) 'unit': unit,
          if (requiresVisit != null) 'requiresVisit': requiresVisit,
        },
      );
      return CatalogService.fromJson(
        (response.data as Map).cast<String, dynamic>(),
      );
    });
  }

  Future<void> remove(String id) {
    return apiCall(() async {
      await _dio.delete('/services/$id');
    });
  }
}
