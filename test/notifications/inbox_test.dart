import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tcc/core/network/dio_client.dart';
import 'package:flutter_tcc/core/services/token_service.dart';
import 'package:flutter_tcc/core/theme/app_theme.dart';
import 'package:flutter_tcc/features/bids/data/datasources/bid_remote_data_source.dart';
import 'package:flutter_tcc/features/bids/presentation/pages/match_details_page.dart';
import 'package:flutter_tcc/features/home/presentation/pages/inbox_page.dart';
import 'package:flutter_tcc/injection_container.dart';

class _Tokens extends TokenService {
  String? token = 'test-session';

  @override
  Future<String?> getToken() async => token;

  @override
  Future<void> deleteToken() async => token = null;
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.respond);
  final Object? Function(RequestOptions) respond;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode(respond(options)),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _notification({String? requestId = 'request-1'}) => {
  'id': 'notification-1',
  'organizationId': 'organization-1',
  // Older contract/proposal notifications may lack contractId.
  'type': 'CONTRACT_CHANGES_REQUESTED',
  'title': 'Atualização da solicitação',
  'personName': 'Cliente',
  'serviceRequestId': requestId,
  'contractId': null,
  'isUnread': true,
  'createdAt': DateTime.now().toUtc().toIso8601String(),
};

void main() {
  tearDown(() => sl.reset());

  for (final failure in [
    DioExceptionType.receiveTimeout,
    DioExceptionType.connectionTimeout,
    DioExceptionType.connectionError,
  ]) {
    test('session survives $failure and authenticates the retry', () async {
      final tokens = _Tokens();
      final client = DioClient(tokenService: tokens);
      var fail = true;
      client.dio.httpClientAdapter = _Adapter((options) {
        if (fail) {
          throw DioException(requestOptions: options, type: failure);
        }
        expect(options.headers['Authorization'], 'Bearer test-session');
        return [];
      });
      await expectLater(
        client.dio.get('/notifications'),
        throwsA(isA<DioException>()),
      );
      expect(tokens.token, 'test-session');
      fail = false;
      expect((await client.dio.get('/notifications')).statusCode, 200);
      client.dio.close();
    });
  }

  testWidgets(
    'retry loads notifications and opens the linked request details',
    (tester) async {
      var fail = true;
      var markedRead = false;
      final client = DioClient(tokenService: _Tokens());
      client.dio.httpClientAdapter = _Adapter((options) {
        if (options.path == '/notifications') {
          if (fail) {
            throw DioException(
              requestOptions: options,
              type: DioExceptionType.receiveTimeout,
            );
          }
          return [_notification()];
        }
        if (options.path == '/notifications/notification-1/read') {
          markedRead = true;
          return {};
        }
        if (options.path == '/service-requests/request-1') {
          return {
            'id': 'request-1',
            'title': 'Soldar virabrequim',
            'description': 'Reparar fissura no virabrequim desmontado.',
            'status': 'CANCELED',
            'createdAt': '2026-09-15T12:00:00Z',
            'clientRevealed': false,
            'client': {'name': null, 'email': null, 'identityVerified': true},
            'address': {'revealed': false, 'city': 'São Paulo', 'state': 'SP'},
            'professionalMatches': [
              {'id': 'match-1', 'status': 'PENDING'},
            ],
          };
        }
        throw StateError('Unexpected route: ${options.path}');
      });
      sl.registerSingleton<DioClient>(client);
      sl.registerSingleton<BidRemoteDataSource>(
        BidRemoteDataSource(dioClient: client),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: InboxPage()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Nenhuma notificação'), findsNothing);
      expect(find.text('Não foi possível carregar'), findsOneWidget);

      fail = false;
      await tester.tap(find.text('Tentar de novo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Atualização da solicitação'));
      await tester.pumpAndSettle();

      expect(find.byType(MatchDetailsPage), findsOneWidget);
      expect(find.text('Solicitação cancelada'), findsOneWidget);
      expect(find.text('Aguardando você'), findsNothing);
      expect(
        find.text('Reparar fissura no virabrequim desmontado.'),
        findsOneWidget,
      );
      expect(find.text('Aceitar'), findsNothing);
      expect(markedRead, isTrue);
      await tester.pumpWidget(const SizedBox());
      client.dio.close();
    },
  );

  testWidgets(
    'notification without a destination explains why it cannot open',
    (tester) async {
      var markedRead = false;
      final client = DioClient(tokenService: _Tokens());
      client.dio.httpClientAdapter = _Adapter((options) {
        if (options.path.endsWith('/read')) markedRead = true;
        return [_notification(requestId: null)];
      });
      sl.registerSingleton<DioClient>(client);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: InboxPage()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Atualização da solicitação'));
      await tester.pump();
      expect(
        find.text('Esta notificação não tem um serviço vinculado.'),
        findsOneWidget,
      );
      expect(markedRead, isFalse);
      await tester.pumpWidget(const SizedBox());
      client.dio.close();
    },
  );
}
