import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_tcc/core/network/api_exception.dart';
import 'package:flutter_tcc/features/quotes/data/quote_models.dart';
import 'package:flutter_tcc/features/quotes/data/quotes_api.dart';

class ServiceContractsState extends Equatable {
  const ServiceContractsState({
    this.items = const [],
    this.loading = true,
    this.error,
  });

  final List<ServiceContract> items;
  final bool loading;
  final String? error;

  List<ServiceContract> get inProgress =>
      items.where((item) => item.inProgress).toList();

  @override
  List<Object?> get props => [items, loading, error];
}

/// Contratos abertos, dos dois lados do produto.
///
/// Não há como criar um daqui: contrato nasce da segunda assinatura, no
/// servidor. Esta lista só lê o resultado.
class ServiceContractsCubit extends Cubit<ServiceContractsState> {
  ServiceContractsCubit({required QuotesApi api})
    : _api = api,
      super(const ServiceContractsState());

  final QuotesApi _api;
  Timer? _poll;

  static const Duration pollInterval = Duration(seconds: 15);

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      emit(ServiceContractsState(items: state.items, loading: true));
    }

    try {
      final items = await _api.contracts();
      if (isClosed) return;
      emit(ServiceContractsState(items: items, loading: false));
    } on ApiException catch (error) {
      if (isClosed) return;
      emit(
        ServiceContractsState(
          items: state.items,
          loading: false,
          error: silent ? null : error.message,
        ),
      );
    }
  }

  /// Relê de tempos em tempos. Um contrato nasce do outro lado do produto —
  /// da assinatura que falta —, então a aba precisa perceber sozinha que ele
  /// apareceu, sem a pessoa sair e voltar.
  void startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(pollInterval, (_) => load(silent: true));
  }

  void stopPolling() {
    _poll?.cancel();
    _poll = null;
  }

  @override
  Future<void> close() {
    _poll?.cancel();
    return super.close();
  }
}
