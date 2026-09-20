import '../service_flow/fake_flow_network.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tcc/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_tcc/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tcc/core/theme/app_theme.dart';
import 'package:flutter_tcc/features/home/presentation/pages/provider_shell_page.dart';

class TestAuthBloc extends Cubit<AuthState> implements AuthBloc {
  TestAuthBloc() : super(AuthInitial());
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(setupFlowNetwork);
  tearDown(clearFlowNetwork);
  testWidgets(
    'ProviderShellPage renders completely without errors or infinite width assertions',
    (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final auth = TestAuthBloc();
      addTearDown(auth.close);
      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: auth,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const ProviderShellPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Seu dia de trabalho'), findsOneWidget);
      expect(find.text('Horários de atendimento'), findsOneWidget);
      expect(find.text('Catálogo de serviços'), findsOneWidget);
      expect(find.text('Taxa de resposta · últimos 3 meses'), findsOneWidget);
      await tester.tap(find.text('Chats').last);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('As solicitações recebidas aparecerão aqui'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
}
