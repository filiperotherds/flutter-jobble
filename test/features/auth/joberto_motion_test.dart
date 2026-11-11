import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_tcc/core/widgets/joberto_celebration.dart';
import 'package:flutter_tcc/core/widgets/joberto_stage.dart';
import 'package:flutter_tcc/features/auth/presentation/widgets/auth_motion.dart';

void main() {
  testWidgets('sem vídeo disponível, o Joberto aparece como imagem parada', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: JobertoStage(clip: JobertoClip.waving)),
      ),
    );
    await tester.pump();

    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as AssetImage).assetName, JobertoClip.waving.still);
  });

  group('reação do Joberto na tela de entrada', () {
    JobertoClip clip({
      bool submitting = false,
      bool failed = false,
      bool passwordFocused = false,
      bool emailFocused = false,
    }) => JobertoClip.forLogin(
      submitting: submitting,
      failed: failed,
      passwordFocused: passwordFocused,
      emailFocused: emailFocused,
    );

    test('acena quando nada está acontecendo', () {
      expect(clip(), JobertoClip.waving);
    });

    test('mede no e-mail e tapa os olhos na senha', () {
      expect(clip(emailFocused: true), JobertoClip.measuring);
      expect(clip(passwordFocused: true), JobertoClip.hiding);
    });

    test('o envio e o erro passam na frente do campo em foco', () {
      expect(clip(failed: true, passwordFocused: true), JobertoClip.puzzled);
      expect(
        clip(submitting: true, failed: true, emailFocused: true),
        JobertoClip.working,
      );
    });

    test('só os clipes que voltam ao aceno repetem', () {
      expect(JobertoClip.waving.loops, isTrue);
      expect(JobertoClip.measuring.loops, isTrue);
      expect(JobertoClip.working.loops, isTrue);
      expect(JobertoClip.hiding.loops, isFalse);
      expect(JobertoClip.puzzled.loops, isFalse);
      expect(JobertoClip.success.loops, isFalse);
    });
  });

  group('comemoração do login', () {
    Widget app(JobertoCelebrationController controller) {
      return MaterialApp(
        builder: (context, child) =>
            JobertoCelebration(controller: controller, child: child!),
        home: const Scaffold(body: Text('app')),
      );
    }

    testWidgets('cobre o app ao disparar e sai sozinha', (tester) async {
      final controller = JobertoCelebrationController();
      await tester.pumpWidget(app(controller));
      expect(find.byKey(JobertoCelebration.layerKey), findsNothing);

      controller.play();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byKey(JobertoCelebration.layerKey), findsOneWidget);
      expect(find.text('Tudo certo!'), findsOneWidget);

      await tester.pump(JobertoCelebration.duration);
      await tester.pump();
      expect(find.byKey(JobertoCelebration.layerKey), findsNothing);
      expect(find.text('app'), findsOneWidget);
    });

    testWidgets('não aparece com movimento reduzido', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );

      final controller = JobertoCelebrationController();
      await tester.pumpWidget(app(controller));
      controller.play();
      await tester.pump();

      expect(find.byKey(JobertoCelebration.layerKey), findsNothing);
    });
  });

  testWidgets('itens entram em sequência e terminam visíveis no lugar', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Entrance(index: 0, child: Text('primeiro')),
              Entrance(index: 3, child: Text('quarto')),
            ],
          ),
        ),
      ),
    );

    double opacityOf(String text) => tester
        .widget<Opacity>(
          find.ancestor(of: find.text(text), matching: find.byType(Opacity)),
        )
        .opacity;

    await tester.pump(const Duration(milliseconds: 200));
    expect(opacityOf('primeiro'), greaterThan(opacityOf('quarto')));

    await tester.pumpAndSettle();
    expect(opacityOf('primeiro'), 1);
    expect(opacityOf('quarto'), 1);
  });

  testWidgets('o formulário treme quando o gatilho muda e volta ao lugar', (
    tester,
  ) async {
    Widget build(Object? trigger) => MaterialApp(
      home: Scaffold(
        body: Shake(trigger: trigger, child: const Text('form')),
      ),
    );

    await tester.pumpWidget(build(null));
    final rest = tester.getTopLeft(find.text('form'));

    await tester.pumpWidget(build('erro'));
    await tester.pump(const Duration(milliseconds: 60));
    expect(tester.getTopLeft(find.text('form')).dx, isNot(rest.dx));

    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('form')), rest);
  });
}
