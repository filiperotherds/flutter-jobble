import 'package:dio/dio.dart';
import 'package:flutter_tcc/core/network/api_exception.dart';
import 'package:flutter_tcc/core/network/dio_client.dart';
import 'package:flutter_tcc/injection_container.dart';

/// Disponibilidade do prestador: aberto ou fechado para novos pedidos.
///
/// É o mesmo estado que o app do cliente lê para marcar o card do profissional
/// como "Aberto" ou "Fechado" — por isso ele mora no servidor, e não só na
/// tela do painel.
class ProviderAvailabilityApi {
  ProviderAvailabilityApi({DioClient? client})
    : _dio = (client ?? sl<DioClient>()).dio;

  final Dio _dio;

  /// Estado atual da conta logada.
  Future<bool> get() {
    return apiCall(() async {
      final response = await _dio.get('/providers/me/availability');
      return (response.data as Map)['acceptingOrders'] as bool;
    });
  }

  /// Abre ou fecha o prestador. Devolve o estado que o servidor gravou.
  Future<bool> set({required bool acceptingOrders}) {
    return apiCall(() async {
      final response = await _dio.patch(
        '/providers/me/availability',
        data: {'acceptingOrders': acceptingOrders},
      );
      return (response.data as Map)['acceptingOrders'] as bool;
    });
  }
}
