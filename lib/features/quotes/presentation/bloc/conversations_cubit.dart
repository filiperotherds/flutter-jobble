import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_tcc/core/network/api_exception.dart';
import 'package:flutter_tcc/features/quotes/data/quote_models.dart';
import 'package:flutter_tcc/features/quotes/data/quotes_api.dart';

class ConversationsState extends Equatable {
  const ConversationsState({
    this.items = const [],
    this.loading = true,
    this.error,
  });

  final List<ConversationSummary> items;
  final bool loading;
  final String? error;

  /// O selo da aba: soma do que chegou e ninguém leu.
  int get unreadTotal =>
      items.fold(0, (total, item) => total + item.unreadCount);

  @override
  List<Object?> get props => [items, loading, error];
}

/// A aba de conversas.
///
/// Recarrega sozinha de tempos em tempos porque é assim que a mensagem do
/// outro lado aparece: não há conexão aberta, o app pergunta. O intervalo é
/// curto o bastante para a conversa parecer viva e longo o bastante para não
/// virar uma consulta por segundo.
class ConversationsCubit extends Cubit<ConversationsState> {
  ConversationsCubit({required QuotesApi api})
    : _api = api,
      super(const ConversationsState());

  final QuotesApi _api;
  Timer? _poll;

  static const Duration pollInterval = Duration(seconds: 8);

  Future<void> load({bool silent = false}) async {
    if (!silent) emit(ConversationsState(items: state.items, loading: true));

    try {
      final items = await _api.conversations();
      if (isClosed) return;
      emit(ConversationsState(items: items, loading: false));
    } on ApiException catch (error) {
      if (isClosed) return;
      emit(
        ConversationsState(
          items: state.items,
          loading: false,
          // Falha de rede num recarregamento silencioso não merece ocupar a
          // tela: o que está listado continua valendo.
          error: silent ? null : error.message,
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
