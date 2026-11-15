import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'package:flutter_tcc/core/config/app_config.dart';
import 'package:flutter_tcc/core/network/api_exception.dart';
import 'package:flutter_tcc/core/network/dio_client.dart';
import 'package:flutter_tcc/features/quotes/data/quote_models.dart';

/// As chamadas do fluxo de orçamento.
///
/// Uma classe só para pedido, conversa, proposta e contrato porque, do ponto
/// de vista do app, é uma conversa só que muda de forma: o pedido vira chat,
/// o chat recebe a proposta, a proposta assinada vira contrato.
class QuotesApi {
  const QuotesApi(this._client);

  final DioClient _client;

  Dio get _dio => _client.dio;

  /// Monta a URL completa de uma foto a partir do caminho que o servidor deu.
  static String photoUrl(String path) {
    // Fotos que já vêm no app (modo demonstração) não passam pelo servidor.
    if (path.startsWith('http') || path.startsWith('assets/')) return path;
    final base = AppConfig.apiBaseUrl.endsWith('/')
        ? AppConfig.apiBaseUrl.substring(0, AppConfig.apiBaseUrl.length - 1)
        : AppConfig.apiBaseUrl;
    return '$base$path';
  }

  // ---------------------------------------------------------------- pedidos

  Future<QuoteRequest> createRequest({
    required String providerId,
    required String title,
    required String description,
  }) {
    return apiCall(() async {
      final response = await _dio.post(
        '/quote-requests',
        data: {
          'providerId': providerId,
          'title': title,
          'description': description,
        },
      );
      return QuoteRequest.fromJson(
        (response.data as Map).cast<String, dynamic>(),
      );
    });
  }

  /// Anexa uma foto. Uma chamada por foto: uma que falhe não leva as outras.
  Future<QuoteRequest> attachPhoto({
    required String requestId,
    required Uint8List bytes,
    required String filename,
  }) {
    return apiCall(() async {
      final form = FormData.fromMap({
        'photo': MultipartFile.fromBytes(bytes, filename: filename),
      });
      final response = await _dio.post(
        '/quote-requests/$requestId/photos',
        data: form,
      );
      return QuoteRequest.fromJson(
        (response.data as Map).cast<String, dynamic>(),
      );
    });
  }

  Future<List<QuoteRequest>> myRequests() => _requests('/quote-requests/mine');

  Future<List<QuoteRequest>> receivedRequests() =>
      _requests('/quote-requests/received');

  Future<QuoteRequest> request(String id) {
    return apiCall(() async {
      final response = await _dio.get('/quote-requests/$id');
      return QuoteRequest.fromJson(
        (response.data as Map).cast<String, dynamic>(),
      );
    });
  }

  Future<QuoteRequest> declineRequest(String id) {
    return apiCall(() async {
      final response = await _dio.post('/quote-requests/$id/decline');
      return QuoteRequest.fromJson(
        (response.data as Map).cast<String, dynamic>(),
      );
    });
  }

  Future<List<QuoteRequest>> _requests(String path) {
    return apiCall(() async {
      final response = await _dio.get(path);
      return (response.data as List)
          .map((row) => QuoteRequest.fromJson((row as Map).cast<String, dynamic>()))
          .toList();
    });
  }

  // --------------------------------------------------------------- conversas

  Future<List<ConversationSummary>> conversations() {
    return apiCall(() async {
      final response = await _dio.get('/conversations');
      return (response.data as List)
          .map((row) =>
              ConversationSummary.fromJson((row as Map).cast<String, dynamic>()))
          .toList();
    });
  }

  /// Só a contagem, para o selo da aba: a lista inteira é peso demais para
  /// uma pergunta que o app repete de poucos em poucos segundos.
  Future<int> unreadCount() {
    return apiCall(() async {
      final response = await _dio.get('/conversations/unread-count');
      final data = (response.data as Map).cast<String, dynamic>();
      return (data['unreadCount'] as num?)?.toInt() ?? 0;
    });
  }

  Future<List<ChatMessage>> messages(String conversationId) {
    return apiCall(() async {
      final response = await _dio.get('/conversations/$conversationId/messages');
      return (response.data as List)
          .map((row) => ChatMessage.fromJson((row as Map).cast<String, dynamic>()))
          .toList();
    });
  }

  Future<ChatMessage> sendMessage(String conversationId, String body) {
    return apiCall(() async {
      final response = await _dio.post(
        '/conversations/$conversationId/messages',
        data: {'body': body},
      );
      return ChatMessage.fromJson(
        (response.data as Map).cast<String, dynamic>(),
      );
    });
  }

  Future<void> markRead(String conversationId) {
    return apiCall(() async {
      await _dio.post('/conversations/$conversationId/read');
    });
  }

  // --------------------------------------------------------------- propostas

  Future<Proposal> createProposal({
    required String requestId,
    required String title,
    required int amountCents,
    required int deadlineDays,
    required int warrantyDays,
    String? notes,
    DateTime? startsOn,
    DateTime? endsOn,
  }) {
    return apiCall(() async {
      final response = await _dio.post(
        '/quote-requests/$requestId/proposals',
        data: {
          'title': title,
          'amountCents': amountCents,
          'deadlineDays': deadlineDays,
          'warrantyDays': warrantyDays,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
          if (startsOn != null) 'startsOn': startsOn.toIso8601String(),
          if (endsOn != null) 'endsOn': endsOn.toIso8601String(),
        },
      );
      return Proposal.fromJson((response.data as Map).cast<String, dynamic>());
    });
  }

  /// Assina. Quem assina sai do token; o servidor decide se cabe agora.
  Future<Proposal> signProposal(String id) {
    return apiCall(() async {
      final response = await _dio.post('/proposals/$id/sign');
      return Proposal.fromJson((response.data as Map).cast<String, dynamic>());
    });
  }

  Future<Proposal> declineProposal(String id) {
    return apiCall(() async {
      final response = await _dio.post('/proposals/$id/decline');
      return Proposal.fromJson((response.data as Map).cast<String, dynamic>());
    });
  }

  // --------------------------------------------------------------- contratos

  /// O profissional dá o serviço por concluído.
  Future<ServiceContract> completeContract(String id) {
    return apiCall(() async {
      final response = await _dio.post('/contracts/$id/complete');
      return ServiceContract.fromJson(
        (response.data as Map).cast<String, dynamic>(),
      );
    });
  }

  /// Cancela o contrato. Os dois lados podem; o motivo vai para a conversa.
  Future<ServiceContract> cancelContract(String id, {String? reason}) {
    return apiCall(() async {
      final response = await _dio.post(
        '/contracts/$id/cancel',
        data: {if (reason != null && reason.isNotEmpty) 'reason': reason},
      );
      return ServiceContract.fromJson(
        (response.data as Map).cast<String, dynamic>(),
      );
    });
  }

  /// A avaliação do cliente, depois do serviço concluído.
  Future<void> reviewContract({
    required String contractId,
    required int rating,
    required String comment,
  }) {
    return apiCall(() async {
      await _dio.post(
        '/contracts/$contractId/review',
        data: {'rating': rating, 'comment': comment},
      );
    });
  }

  Future<List<ServiceContract>> contracts() {
    return apiCall(() async {
      final response = await _dio.get('/contracts');
      return (response.data as List)
          .map((row) =>
              ServiceContract.fromJson((row as Map).cast<String, dynamic>()))
          .toList();
    });
  }
}
