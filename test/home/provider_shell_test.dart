import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tcc/core/theme/app_theme.dart';
import 'package:flutter_tcc/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_tcc/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_tcc/features/home/presentation/pages/provider_shell_page.dart';

import '../service_flow/fake_flow_network.dart';

class TestAuthBloc extends Cubit<AuthState> implements AuthBloc {
  TestAuthBloc() : super(AuthInitial());
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> _match({
  required String id,
  required String status,
  Map<String, dynamic>? contract,
}) {
  return {
    'id': id,
    'status': status,
    'distanceKm': 3.2,
    'createdAt': DateTime.now().toUtc().toIso8601String(),
    'clientRevealed': false,
    'location': 'Pinheiros, São Paulo - SP',
    'request': {
      'id': 'request-$id',
      'title': 'Pintura da sala',
      'description': 'Pintura de uma parede',
      'status': 'PENDING',
      'isEmergency': false,
    },
    'contract': ?contract,
  };
}

void main() {
  tearDown(clearFlowNetwork);

  testWidgets('painel mostra os chamados que a API devolve', (tester) async {
    await setupFlowNetwork((RequestOptions request) {
      if (request.path.endsWith('/matches')) {
        return [
          _match(id: 'match-pendente', status: 'PENDING'),
          _match(
            id: 'match-em-andamento',
            status: 'HIRED',
            contract: {
              'id': 'contrato-1',
              'code': 'JOB-1',
              'status': 'SIGNED',
              'priceCents': 79000,
            },
          ),
        ];
      }
      if (request.path.endsWith('/notifications/count')) return {'count': 3};
      return emptyFlowReply(request);
    });

    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final auth = TestAuthBloc();
    addTearDown(auth.close);
    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: auth,
        child: MaterialApp(theme: AppTheme.light, home: const ProviderShellPage()),
      ),
    );
    await tester.pumpAndSettle();

    // Um chamado por etapa, cada um na sua seção, e o sino com a contagem real.
    expect(find.text('Aguardando sua resposta (1)'), findsOneWidget);
    expect(find.text('Trabalhos em andamento (1)'), findsOneWidget);
    expect(find.text('Pintura da sala'), findsNWidgets(2));
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Recusar'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('sem chamados, o painel explica o vazio', (tester) async {
    await setupFlowNetwork();

    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final auth = TestAuthBloc();
    addTearDown(auth.close);
    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: auth,
        child: MaterialApp(theme: AppTheme.light, home: const ProviderShellPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nenhum chamado por enquanto'), findsOneWidget);
    expect(find.text('Atalhos da sua conta'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}
