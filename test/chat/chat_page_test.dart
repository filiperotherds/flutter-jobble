import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tcc/core/theme/app_theme.dart';
import 'package:flutter_tcc/features/contracts/presentation/pages/chat_page.dart';
import '../service_flow/fake_flow_network.dart';

void main() {
  setUp(setupFlowNetwork);
  tearDown(clearFlowNetwork);
  testWidgets(
    'legacy shortcut opens persisted inbox without invented conversations',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const ChatPage(
            providerName: 'Gabriel',
            providerImage: 'assets/images/logo_pintor.jpg',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Chats'), findsOneWidget);
      expect(find.text('Gabriel'), findsNothing);
      expect(find.text('Proposta Formal de Orçamento'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
