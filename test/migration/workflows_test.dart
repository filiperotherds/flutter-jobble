import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tcc/core/theme/app_theme.dart';
import 'package:flutter_tcc/core/state/jobble_quote_state.dart';
import 'package:flutter_tcc/features/home/presentation/pages/provider_agenda_page.dart';
import 'package:flutter_tcc/features/requests/presentation/pages/provider_quote_generator_page.dart';
import 'package:flutter_tcc/features/requests/presentation/pages/provider_job_tracker_page.dart';

void main() {
  setUpAll(() async {
    for (final family in ['SpaceGrotesk', 'Urbanist', 'PlusJakartaSans']) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('assets/fonts/$family-Regular.ttf'))).load();
    }
  });

  Future<void> mount(WidgetTester tester, Widget page) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: page));
    await tester.pumpAndSettle();
  }

  testWidgets('agenda adds the submitted event to the selected day', (
    tester,
  ) async {
    await mount(tester, const ProviderAgendaPage());
    await tester.tap(find.text('20'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Visita técnica');
    await tester.enterText(find.byType(TextField).at(1), '10:00 - 11:00');
    await tester.enterText(find.byType(TextField).at(2), 'Ana');
    await tester.tap(find.text('Salvar Compromisso'));
    await tester.pumpAndSettle();
    expect(find.text('Visita técnica'), findsOneWidget);
    expect(find.text('Cliente: Ana'), findsOneWidget);
  });

  testWidgets('tracker adds an update and changes the progress', (
    tester,
  ) async {
    await mount(tester, const ProviderJobTrackerPage());
    await tester.tap(find.text('Nova Atualização'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).first,
      'Acabamento concluído',
    );
    final slider = tester.widget<Slider>(find.byType(Slider));
    slider.onChanged!(0.90);
    await tester.pump();
    await tester.ensureVisible(find.text('Salvar e Notificar Cliente'));
    await tester.tap(find.text('Salvar e Notificar Cliente'));
    await tester.pumpAndSettle();
    expect(find.text('Acabamento concluído'), findsOneWidget);
    expect(find.text('90%'), findsOneWidget);
  });

  testWidgets('new quote recalculates total and requires a new signature', (
    tester,
  ) async {
    await mount(tester, const ProviderQuoteGeneratorPage());
    await tester.enterText(find.widgetWithText(TextFormField, '1'), '2');
    await tester.pump();
    expect(find.text('R\$ 900.00'), findsWidgets);
    await tester.tap(find.text('Avançar'));
    await tester.pumpAndSettle();
    expect(find.text('Assinar e Enviar'), findsOneWidget);
  });

  test(
    'reissuing a proposal invalidates client acceptance and copies its items',
    () {
      final quote = JobbleQuoteState.instance;
      quote.signByClient(signaturePoints: [const Offset(1, 2)]);
      final items = [
        {'desc': 'Serviço', 'qtd': 2, 'unit': 25.0},
      ];
      quote.sendQuoteByProvider(
        quoteItems: items,
        quoteTotal: 50,
        prazo: '2 dias',
        condicoes: 'À vista',
        gar: '90 dias',
        obs: '',
        signedDate: '19/09/2026',
        signaturePoints: [const Offset(4, 5)],
      );
      items.first['unit'] = 999.0;
      expect(quote.total, 50);
      expect(quote.isProviderSigned, isTrue);
      expect(quote.isClientSigned, isFalse);
      expect(quote.clientSignaturePoints, isEmpty);
      expect(quote.clientSignedDate, isNull);
      quote.reset();
    },
  );
}
