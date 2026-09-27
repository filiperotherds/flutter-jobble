import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_tcc/core/network/api_exception.dart';
import 'package:flutter_tcc/features/quotes/data/quote_models.dart';
import 'package:flutter_tcc/features/quotes/data/quotes_api.dart';

class ChatState extends Equatable {
  const ChatState({
    this.messages = const [],
    this.loading = true,
    this.sending = false,
    this.signing = false,
    this.error,
    this.justSigned = false,
  });

  final List<ChatMessage> messages;
  final bool loading;
  final bool sending;
  final bool signing;
  final String? error;

  /// Marca o instante em que uma assinatura fechou o contrato, para a tela
  /// avisar uma vez e seguir.
  final bool justSigned;

  /// A última proposta que ainda vale. As substituídas continuam no histórico
  /// da conversa, mas não são mais assináveis.
  Proposal? get liveProposal {
    for (final message in messages.reversed) {
      final proposal = message.proposal;
      if (proposal != null && !proposal.isSuperseded) return proposal;
    }
    return null;
  }

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? loading,
    bool? sending,
    bool? signing,
    String? error,
    bool clearError = false,
    bool? justSigned,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      loading: loading ?? this.loading,
      sending: sending ?? this.sending,
      signing: signing ?? this.signing,
      error: clearError ? null : (error ?? this.error),
      justSigned: justSigned ?? this.justSigned,
    );
  }

  @override
  List<Object?> get props => [
    messages,
    loading,
    sending,
    signing,
    error,
    justSigned,
  ];
}

/// Uma conversa aberta.
///
/// Enquanto a tela está à frente, pergunta ao servidor por mensagens novas.
/// Marca como lidas a cada carga: se a pessoa está com a conversa aberta, ela
/// leu — e é isso que apaga o selo do outro lado.
class ChatCubit extends Cubit<ChatState> {
  ChatCubit({required QuotesApi api, required this.conversationId})
    : _api = api,
      super(const ChatState());

  final QuotesApi _api;
  final String conversationId;
  Timer? _poll;

  static const Duration pollInterval = Duration(seconds: 5);

  Future<void> load({bool silent = false}) async {
    if (!silent) emit(state.copyWith(loading: true, clearError: true));

    try {
      final messages = await _api.messages(conversationId);
      if (isClosed) return;
      emit(state.copyWith(messages: messages, loading: false));

      // Ler é consequência de estar aqui, não um botão separado.
      await _api.markRead(conversationId);
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

  Future<void> send(String body) async {
    final text = body.trim();
    if (text.isEmpty || state.sending) return;

    emit(state.copyWith(sending: true, clearError: true));
    try {
      await _api.sendMessage(conversationId, text);
      if (isClosed) return;
      emit(state.copyWith(sending: false));
      await load(silent: true);
    } on ApiException catch (error) {
      if (isClosed) return;
      emit(state.copyWith(sending: false, error: error.message));
    }
  }

  /// Assina a proposta. O servidor recusa se não for a vez de quem pediu, e a
  /// mensagem de recusa vai direto para a tela.
  Future<Proposal?> sign(String proposalId) async {
    if (state.signing) return null;
    emit(state.copyWith(signing: true, clearError: true));

    try {
      final proposal = await _api.signProposal(proposalId);
      if (isClosed) return proposal;
      emit(state.copyWith(signing: false, justSigned: proposal.isSigned));
      await load(silent: true);
      return proposal;
    } on ApiException catch (error) {
      if (isClosed) return null;
      emit(state.copyWith(signing: false, error: error.message));
      // Estado defasado é causa comum de recusa: recarregar mostra o motivo.
      await load(silent: true);
      return null;
    }
  }

  Future<void> decline(String proposalId) async {
    emit(state.copyWith(signing: true, clearError: true));
    try {
      await _api.declineProposal(proposalId);
      if (isClosed) return;
      emit(state.copyWith(signing: false));
      await load(silent: true);
    } on ApiException catch (error) {
      if (isClosed) return;
      emit(state.copyWith(signing: false, error: error.message));
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
