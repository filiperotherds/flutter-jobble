import 'package:dio/dio.dart';

import 'package:flutter_tcc/core/demo/demo_backend.dart';

/// Desvia para o [DemoBackend] as chamadas que ele sabe responder.
///
/// O resto — entrar na conta, o perfil — segue para a rede como sempre.
class DemoInterceptor extends Interceptor {
  DemoInterceptor({DemoBackend? backend})
    : _backend = backend ?? DemoBackend.instance;

  final DemoBackend _backend;

  /// Um instante de espera, para as telas mostrarem o carregamento como
  /// fariam com o servidor.
  static const latency = Duration(milliseconds: 220);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final Object? data;
    try {
      data = _backend.handle(
        options.method.toUpperCase(),
        options.path,
        options.data,
        options.queryParameters,
      );
    } on DemoError catch (error) {
      await Future<void>.delayed(latency);
      return handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response<dynamic>(
            requestOptions: options,
            statusCode: error.status,
            data: {'message': error.message},
          ),
        ),
      );
    }

    if (identical(data, DemoBackend.pass)) return handler.next(options);

    await Future<void>.delayed(latency);
    handler.resolve(
      Response<dynamic>(requestOptions: options, statusCode: 200, data: data),
    );
  }
}
