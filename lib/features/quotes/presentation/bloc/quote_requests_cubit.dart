import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_tcc/core/network/api_exception.dart';
import 'package:flutter_tcc/features/quotes/data/quote_models.dart';
import 'package:flutter_tcc/features/quotes/data/quotes_api.dart';

class QuoteRequestsState extends Equatable {
  const QuoteRequestsState({
    this.items = const [],
    this.loading = true,
    this.error,
  });

  final List<QuoteRequest> items;
  final bool loading;
  final String? error;

  /// Os que ainda não receberam resposta nenhuma — a fila de verdade.
  List<QuoteRequest> get waiting =>
      items.where((item) => item.isPending).toList();

  /// Em negociação: já houve conversa ou proposta, mas não há contrato.
  List<QuoteRequest> get inProgress =>
      items.where((item) => item.status == 'ANSWERED').toList();

  @override
  List<Object?> get props => [items, loading, error];
}

/// Os pedidos de orçamento que chegaram para o profissional.
///
/// É o que enche os cards de "Aguardando orçamento" no painel. Recarrega
/// sozinho enquanto o painel está aberto: pedido novo é a razão de o
/// profissional abrir o app.
class QuoteRequestsCubit extends Cubit<QuoteRequestsState> {
  QuoteRequestsCubit({required QuotesApi api})
    : _api = api,
      super(const QuoteRequestsState());

  final QuotesApi _api;
  Timer? _poll;

  static const Duration pollInterval = Duration(seconds: 10);

  Future<void> load({bool silent = false}) async {
    if (!silent) emit(QuoteRequestsState(items: state.items, loading: true));

    try {
      final items = await _api.receivedRequests();
      if (isClosed) return;
      emit(QuoteRequestsState(items: items, loading: false));
    } on ApiException catch (error) {
      if (isClosed) return;
      emit(
        QuoteRequestsState(
          items: state.items,
          loading: false,
          error: silent ? null : error.message,
        ),
      );
    }
  }

  Future<void> decline(String id) async {
    try {
      await _api.declineRequest(id);
      await load(silent: true);
    } on ApiException catch (error) {
      if (isClosed) return;
      emit(
        QuoteRequestsState(
          items: state.items,
          loading: false,
          error: error.message,
        ),
      );
    }
  }

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
