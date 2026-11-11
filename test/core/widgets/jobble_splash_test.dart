import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_tcc/core/widgets/jobble_splash.dart';

Widget _app({VoidCallback? onTap}) {
  return MaterialApp(
    builder: (context, child) => JobbleSplash(child: child!),
    home: Scaffold(
      body: Center(
        child: TextButton(onPressed: onTap, child: const Text('app')),
      ),
    ),
  );
}

void main() {
  testWidgets('a abertura cobre o app e some quando a animação termina', (
    tester,
  ) async {
    await tester.pumpWidget(_app());

    expect(find.byKey(JobbleSplash.layerKey), findsOneWidget);
    // O app monta por baixo desde o primeiro frame: a abertura não atrasa a
    // restauração da sessão.
    expect(find.text('app'), findsOneWidget);

    await tester.pump(JobbleSplash.duration ~/ 2);
    expect(find.byKey(JobbleSplash.layerKey), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byKey(JobbleSplash.layerKey), findsNothing);
    expect(find.text('app'), findsOneWidget);
  });

  testWidgets('toques não atravessam a abertura', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_app(onTap: () => taps++));

    await tester.tap(find.text('app'), warnIfMissed: false);
    expect(taps, 0);

    await tester.pumpAndSettle();
    await tester.tap(find.text('app'));
    expect(taps, 1);
  });

  testWidgets('com movimento reduzido o app aparece direto', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await tester.pumpWidget(_app());

    expect(find.byKey(JobbleSplash.layerKey), findsNothing);
    expect(find.text('app'), findsOneWidget);
  });
}
