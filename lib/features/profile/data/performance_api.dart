import 'package:dio/dio.dart';

import 'package:flutter_tcc/core/network/api_exception.dart';
import 'package:flutter_tcc/core/network/dio_client.dart';

/// Um número do painel, com a variação em relação ao período anterior.
class Metric {
  const Metric({required this.value, required this.delta});

  factory Metric.fromJson(Map<String, dynamic> json) => Metric(
    value: (json['value'] as num).toDouble(),
    delta: (json['delta'] as num).toDouble(),
  );

  const Metric.zero() : value = 0, delta = 0;

  final double value;
  final double delta;

  /// Variação com sinal, como o cartão a escreve: "+5", "-1", "0".
  String get deltaLabel {
    final rounded = delta == delta.roundToDouble()
        ? delta.toStringAsFixed(0)
        : delta.toStringAsFixed(1);
    return delta > 0 ? '+$rounded' : rounded;
  }

  /// O cartão pinta de verde quando o número andou para o lado bom. Para
  /// serviços cancelados o lado bom é cair, e quem sabe disso é a tela.
  bool get improved => delta >= 0;
}

class DailyInteraction {
  const DailyInteraction({required this.weekday, required this.value});

  factory DailyInteraction.fromJson(Map<String, dynamic> json) =>
      DailyInteraction(
        weekday: '${json['weekday']}',
        value: (json['value'] as num).toInt(),
      );

  final String weekday;
  final int value;
}

class Funnel {
  const Funnel({
    required this.profileViews,
    required this.quoteRequests,
    required this.closedServices,
  });

  factory Funnel.fromJson(Map<String, dynamic> json) => Funnel(
    profileViews: (json['profileViews'] as num).toInt(),
    quoteRequests: (json['quoteRequests'] as num).toInt(),
    closedServices: (json['closedServices'] as num).toInt(),
  );

  const Funnel.zero() : profileViews = 0, quoteRequests = 0, closedServices = 0;

  final int profileViews;
  final int quoteRequests;
  final int closedServices;
}

class Performance {
  const Performance({
    required this.averageRating,
    required this.servicesDone,
    required this.servicesCancelled,
    required this.averageResponseMinutes,
    required this.dailyInteractions,
    required this.funnel,
  });

  factory Performance.fromJson(Map<String, dynamic> json) => Performance(
    averageRating: Metric.fromJson(
      (json['averageRating'] as Map).cast<String, dynamic>(),
    ),
    servicesDone: Metric.fromJson(
      (json['servicesDone'] as Map).cast<String, dynamic>(),
    ),
    servicesCancelled: Metric.fromJson(
      (json['servicesCancelled'] as Map).cast<String, dynamic>(),
    ),
    averageResponseMinutes: Metric.fromJson(
      (json['averageResponseMinutes'] as Map).cast<String, dynamic>(),
    ),
    dailyInteractions: ((json['dailyInteractions'] as List?) ?? const [])
        .map(
          (row) => DailyInteraction.fromJson((row as Map).cast<String, dynamic>()),
        )
        .toList(),
    funnel: Funnel.fromJson((json['funnel'] as Map).cast<String, dynamic>()),
  );

  const Performance.empty()
    : averageRating = const Metric.zero(),
      servicesDone = const Metric.zero(),
      servicesCancelled = const Metric.zero(),
      averageResponseMinutes = const Metric.zero(),
      dailyInteractions = const [],
      funnel = const Funnel.zero();

  final Metric averageRating;
  final Metric servicesDone;
  final Metric servicesCancelled;
  final Metric averageResponseMinutes;
  final List<DailyInteraction> dailyInteractions;
  final Funnel funnel;

  /// O maior valor do gráfico, que define a altura das barras. Um dia sozinho
  /// com movimento já ocupa a barra inteira — é o pico do período, não uma
  /// meta.
  int get peakInteractions => dailyInteractions.fold(
    0,
    (peak, day) => day.value > peak ? day.value : peak,
  );
}

/// Os números da aba Desempenho.
class PerformanceApi {
  const PerformanceApi(this._client);

  final DioClient _client;

  /// [period] aceita `today`, `week`, `month` e `semester`.
  Future<Performance> summary(String period) {
    return apiCall(() async {
      final response = await _client.dio.get(
        '/performance/summary',
        queryParameters: {'period': period},
      );
      return Performance.fromJson(
        (response.data as Map).cast<String, dynamic>(),
      );
    });
  }
}
