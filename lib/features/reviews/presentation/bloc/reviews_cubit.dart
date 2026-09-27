import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_tcc/core/network/api_exception.dart';
import 'package:flutter_tcc/features/reviews/data/review_models.dart';
import 'package:flutter_tcc/features/reviews/data/reviews_api.dart';

class ReviewsState extends Equatable {
  const ReviewsState({
    this.page = const ReviewsPage.empty(),
    this.loading = true,
    this.replying,
    this.error,
  });

  final ReviewsPage page;
  final bool loading;

  /// Identificador da avaliação sendo respondida agora, para o botão daquele
  /// card — e só dele — mostrar que está trabalhando.
  final String? replying;

  final String? error;

  int get unreadCount => page.items.where((item) => item.unread).length;

  ReviewsState copyWith({
    ReviewsPage? page,
    bool? loading,
    String? replying,
    bool clearReplying = false,
    String? error,
    bool clearError = false,
  }) {
    return ReviewsState(
      page: page ?? this.page,
      loading: loading ?? this.loading,
      replying: clearReplying ? null : (replying ?? this.replying),
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [page, loading, replying, error];
}

/// As avaliações recebidas pelo profissional.
///
/// Recarrega de tempos em tempos porque avaliação chega do outro lado do
/// produto, sem aviso: é o mesmo motivo do polling das conversas.
class ReviewsCubit extends Cubit<ReviewsState> {
  ReviewsCubit({required ReviewsApi api})
    : _api = api,
      super(const ReviewsState());

  final ReviewsApi _api;
  Timer? _poll;

  static const Duration pollInterval = Duration(seconds: 30);

  Future<void> load({bool silent = false}) async {
    if (!silent) emit(state.copyWith(loading: true, clearError: true));

    try {
      final page = await _api.received();
      if (isClosed) return;
      emit(state.copyWith(page: page, loading: false));
    } on ApiException catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          loading: false,
          error: silent ? null : error.message,
        ),
      );
    }
  }

  /// Marca as avaliações como vistas. Chamado ao abrir a lista: quem está
  /// olhando a tela já viu, e é isso que apaga o ponto no sino.
  Future<void> markRead() async {
    try {
      await _api.markRead();
      await load(silent: true);
    } on ApiException {
      // O ponto continua aceso; a próxima abertura tenta de novo.
    }
  }

  Future<bool> reply(String reviewId, String text) async {
    emit(state.copyWith(replying: reviewId, clearError: true));

    try {
      await _api.reply(reviewId, text);
      if (isClosed) return true;
      emit(state.copyWith(clearReplying: true));
      await load(silent: true);
      return true;
    } on ApiException catch (error) {
      if (isClosed) return false;
      emit(state.copyWith(clearReplying: true, error: error.message));
      return false;
    }
  }

  void clearError() => emit(state.copyWith(clearError: true));

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
