import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_tcc/core/demo/demo_backend.dart';
import 'package:flutter_tcc/features/portfolio/data/portfolio_models.dart';
import 'package:flutter_tcc/features/profile/data/performance_api.dart';
import 'package:flutter_tcc/features/quotes/data/quote_models.dart';
import 'package:flutter_tcc/features/reviews/data/review_models.dart';
import 'package:flutter_tcc/features/services/data/services_api.dart';

/// O servidor de demonstração só vale se as telas conseguirem ler o que ele
/// responde: cada teste passa a resposta pelo mesmo modelo que a tela usa.
void main() {
  final backend = DemoBackend.instance;

  Object? call(String method, String path, {Object? body, String? period}) =>
      backend.handle(method, path, body, {'period': ?period});

  List<Map<String, dynamic>> rows(Object? data) => (data as List)
      .map((row) => (row as Map).cast<String, dynamic>())
      .toList();

  test('rotas que não são da demonstração seguem para a rede', () {
    expect(call('GET', '/users/profile'), same(DemoBackend.pass));
    expect(call('POST', '/auth/signin'), same(DemoBackend.pass));
  });

  test('pedidos cobrem as etapas do painel', () {
    final requests = rows(
      call('GET', '/quote-requests/received'),
    ).map(QuoteRequest.fromJson).toList();

    expect(requests.where((r) => r.isPending), isNotEmpty);
    final negotiating = requests.where((r) => r.status == 'ANSWERED');
    expect(negotiating.any((r) => r.latestProposal == null), isTrue);
    expect(
      negotiating.any((r) => r.latestProposal?.awaitsClient ?? false),
      isTrue,
    );
    expect(
      negotiating.any((r) => r.latestProposal?.awaitsProvider ?? false),
      isTrue,
    );
  });

  test('conversas trazem a última mensagem e as não lidas', () {
    final conversations = rows(
      call('GET', '/conversations'),
    ).map(ConversationSummary.fromJson).toList();

    expect(conversations, isNotEmpty);
    expect(conversations.every((c) => c.lastMessageBody != null), isTrue);

    final unread =
        (call('GET', '/conversations/unread-count') as Map)['unreadCount'];
    expect(unread, conversations.fold<int>(0, (sum, c) => sum + c.unreadCount));
    expect(unread, greaterThan(0));

    final messages = rows(
      call('GET', '/conversations/${conversations.first.id}/messages'),
    ).map(ChatMessage.fromJson).toList();
    expect(messages, isNotEmpty);
  });

  test('mandar mensagem e marcar como lida mudam a conversa', () {
    const id = 'demo-conv-7k2f';
    final before = rows(call('GET', '/conversations/$id/messages')).length;

    final sent = ChatMessage.fromJson(
      (call('POST', '/conversations/$id/messages', body: {'body': 'Olá!'})
              as Map)
          .cast<String, dynamic>(),
    );
    expect(sent.mine, isTrue);
    expect(
      rows(call('GET', '/conversations/$id/messages')),
      hasLength(before + 1),
    );

    call('POST', '/conversations/$id/read');
    final conversation = rows(
      call('GET', '/conversations'),
    ).map(ConversationSummary.fromJson).firstWhere((c) => c.id == id);
    expect(conversation.unreadCount, 0);
  });

  test('assinar depois do cliente abre o contrato', () {
    final request = rows(call('GET', '/quote-requests/received'))
        .map(QuoteRequest.fromJson)
        .firstWhere((r) => r.latestProposal?.awaitsProvider ?? false);
    final running = rows(
      call('GET', '/contracts'),
    ).map(ServiceContract.fromJson).where((c) => c.inProgress).length;

    final signed = Proposal.fromJson(
      (call('POST', '/proposals/${request.latestProposal!.id}/sign') as Map)
          .cast<String, dynamic>(),
    );
    expect(signed.isSigned, isTrue);

    final contracts = rows(
      call('GET', '/contracts'),
    ).map(ServiceContract.fromJson).where((c) => c.inProgress);
    expect(contracts, hasLength(running + 1));

    final after = QuoteRequest.fromJson(
      (call('GET', '/quote-requests/${request.id}') as Map)
          .cast<String, dynamic>(),
    );
    expect(after.status, isNot('ANSWERED'));
  });

  test('desempenho, avaliações e catálogo passam pelos modelos das telas', () {
    for (final period in ['today', 'week', 'month', 'semester']) {
      final performance = Performance.fromJson(
        (call('GET', '/performance/summary', period: period) as Map)
            .cast<String, dynamic>(),
      );
      expect(performance.dailyInteractions, hasLength(7));
      expect(performance.funnel.profileViews, greaterThan(0));
    }

    final reviews = ReviewsPage.fromJson(
      (call('GET', '/reviews/received') as Map).cast<String, dynamic>(),
    );
    expect(reviews.items, isNotEmpty);
    expect(
      reviews.summary.distribution.values.fold<int>(0, (a, b) => a + b),
      reviews.summary.total,
    );

    final services = rows(
      call('GET', '/services/mine'),
    ).map(CatalogService.fromJson).toList();
    expect(services, isNotEmpty);
  });

  test('portfólio usa as fotos que já vêm no app', () {
    final works = rows(
      call('GET', '/portfolio/mine'),
    ).map(PortfolioItem.fromJson).toList();

    expect(works, isNotEmpty);
    for (final work in works) {
      expect(work.media, isNotEmpty);
      expect(
        work.media.every((media) => media.fullUrl.startsWith('assets/')),
        isTrue,
      );
    }
  });

  test('ação que a demonstração não imita é recusada, não vai à rede', () {
    expect(
      () => call('POST', '/portfolio'),
      throwsA(isA<DemoError>().having((e) => e.status, 'status', 501)),
    );
  });

  test('item que não existe é avisado como não encontrado', () {
    expect(
      () => call('GET', '/quote-requests/nao-existe'),
      throwsA(isA<DemoError>()),
    );
  });
}
