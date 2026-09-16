import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tcc/core/network/api_exception.dart';
import 'package:flutter_tcc/core/network/dio_client.dart';
import 'package:flutter_tcc/core/services/token_service.dart';
import 'package:flutter_tcc/core/theme/app_theme.dart';
import 'package:flutter_tcc/features/bids/data/datasources/bid_remote_data_source.dart';
import 'package:flutter_tcc/features/bids/data/models/service_request_detail_model.dart';
import 'package:flutter_tcc/features/bids/presentation/pages/match_details_page.dart';
import 'package:flutter_tcc/injection_container.dart';

class FakeBids extends BidRemoteDataSource {
  FakeBids() : super(dioClient: DioClient(tokenService: TokenService()));
  String requestStatus = 'PENDING';
  String matchStatus = 'PENDING';
  bool closeOnAccept = false;
  int accepted = 0;
  int reads = 0;

  @override
  Future<ServiceRequestDetailModel> getServiceRequest(String id) async {
    reads++;
    return ServiceRequestDetailModel.fromJson({
      'id': id,
      'description': 'Reparar o chuveiro da residência',
      'status': requestStatus,
      'createdAt': '2026-09-15T12:00:00Z',
      'client': {'identityVerified': true},
      'professionalMatches': [
        {'id': 'match', 'status': matchStatus},
      ],
    });
  }

  @override
  Future<void> acceptMatch(String serviceMatchId) async {
    accepted++;
    if (closeOnAccept) {
      requestStatus = 'CANCELED';
      throw const ApiException(
        'Esta solicitação não está mais aberta',
        statusCode: 403,
      );
    }
    matchStatus = 'ACCEPTED';
  }
}

void main() {
  late FakeBids remote;
  setUp(() {
    remote = FakeBids();
    sl.registerSingleton<BidRemoteDataSource>(remote);
  });
  tearDown(() async {
    remote.dioClient.dio.close();
    await sl.reset();
  });

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const MatchDetailsPage(serviceRequestId: 'request'),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final status in ['ACCEPTED', 'IN_PROGRESS', 'COMPLETED', 'CANCELED']) {
    for (final matchStatus in ['PENDING', 'ACCEPTED']) {
      testWidgets('$status/$matchStatus não permite resposta', (tester) async {
        remote.requestStatus = status;
        remote.matchStatus = matchStatus;
        await open(tester);
        expect(find.text('Aceitar'), findsNothing);
        expect(find.text('Recusar'), findsNothing);
        expect(find.text('Enviar devolutiva'), findsNothing);
        expect(find.text('Aguardando você'), findsNothing);
        expect(remote.accepted, 0);
      });
    }
  }

  testWidgets('aceitar chamado aberto libera a devolutiva', (tester) async {
    await open(tester);
    await tester.tap(find.text('Aceitar'));
    await tester.pumpAndSettle();
    expect(remote.accepted, 1);
    expect(find.text('Aceitar'), findsNothing);
    expect(find.text('Enviar devolutiva'), findsOneWidget);
  });

  testWidgets('cancelamento com tela aberta atualiza os botões após conflito', (
    tester,
  ) async {
    remote.closeOnAccept = true;
    await open(tester);
    await tester.tap(find.text('Aceitar'));
    await tester.pumpAndSettle();
    expect(remote.reads, 2);
    expect(find.text('Aceitar'), findsNothing);
    expect(find.text('Solicitação cancelada'), findsOneWidget);
  });
}
