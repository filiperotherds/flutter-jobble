import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tcc/core/theme/app_theme.dart';
import 'package:flutter_tcc/features/service_flow/chat_sections_page.dart';
import 'package:flutter_tcc/features/service_flow/conversation_page.dart';
import 'fake_flow_network.dart';

Map<String, dynamic> detail({bool closed = false}) => {
  'id': 'match-1',
  'name': 'Manoel Pintor',
  'closed': closed,
  'contract': null,
  'request': {
    'id': 'request-1',
    'title': 'Pintura residencial',
    'number': 6346,
    'description': 'Pintar a sala de 20 metros quadrados.',
    'urgent': false,
  },
  'messages': [
    {
      'id': 'm1',
      'kind': 'SYSTEM',
      'text': closed
          ? 'Solicitação encerrada'
          : 'Mantenha a negociação na Jobble.',
      'mine': false,
      'createdAt': '2026-09-19T12:00:00Z',
    },
  ],
  'quotes': [],
};
void main() {
  tearDown(clearFlowNetwork);
  Future<void> mount(WidgetTester tester, Widget page) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: page));
    await tester.pumpAndSettle();
  }

  testWidgets('requests show separate headers with their own conversations', (
    tester,
  ) async {
    await setupFlowNetwork(
      (_) => [
        {
          'id': 'a',
          'number': 6346,
          'title': 'Pintura residencial',
          'urgent': false,
          'chats': [
            {
              'id': '1',
              'name': 'Manoel Pintor',
              'lastMessage': 'Recebido',
              'closed': false,
            },
          ],
        },
        {
          'id': 'b',
          'number': 6347,
          'title': 'Instalação de chuveiro',
          'urgent': true,
          'chats': [
            {
              'id': '2',
              'name': 'Ana Eletricista',
              'lastMessage': 'Recebido',
              'closed': false,
            },
          ],
        },
      ],
    );
    await mount(tester, const ChatSectionsPage());
    expect(find.text('Pintura residencial — #6346'), findsOneWidget);
    expect(
      find.textContaining('Instalação de chuveiro — #6347'),
      findsOneWidget,
    );
    expect(find.text('Manoel Pintor'), findsOneWidget);
    expect(find.text('Ana Eletricista'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  for (final provider in [false, true]) {
    testWidgets(
      'closed history has no composer, attachments or quotes (provider=$provider)',
      (tester) async {
        await setupFlowNetwork((_) => detail(closed: true));
        await mount(
          tester,
          ConversationPage(matchId: 'match-1', provider: provider),
        );
        expect(find.text('Solicitação encerrada'), findsWidgets);
        expect(find.byType(TextField), findsNothing);
        expect(find.byTooltip('Enviar imagem'), findsNothing);
        expect(find.text('Enviar orçamento'), findsNothing);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets(
    'message is sent to its own conversation and visible after reload',
    (tester) async {
      final data = detail();
      final calls = <String>[];
      await setupFlowNetwork((r) {
        calls.add('${r.method} ${r.path}');
        if (r.method == 'POST') {
          expect(r.data['text'], 'Olá, pode incluir o teto?');
          expect(r.data['clientKey'], isNotEmpty);
          (data['messages'] as List).add({
            'id': 'm2',
            'kind': 'TEXT',
            'text': r.data['text'],
            'mine': true,
            'createdAt': '2026-09-19T12:01:00Z',
          });
          return {};
        }
        return data;
      });
      await mount(tester, const ConversationPage(matchId: 'match-1'));
      await tester.enterText(
        find.byType(TextField),
        'Olá, pode incluir o teto?',
      );
      await tester.tap(find.byTooltip('Enviar mensagem'));
      await tester.pumpAndSettle();
      expect(calls, contains('POST /flow/client/chats/match-1/messages'));
      expect(find.text('Olá, pode incluir o teto?'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
