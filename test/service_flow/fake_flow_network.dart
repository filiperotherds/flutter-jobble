import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_tcc/core/network/dio_client.dart';
import 'package:flutter_tcc/core/services/token_service.dart';
import 'package:flutter_tcc/features/bids/data/datasources/bid_remote_data_source.dart';
import 'package:flutter_tcc/features/contracts/data/datasources/contract_remote_data_source.dart';
import 'package:flutter_tcc/features/contracts/domain/contract_repository.dart';
import 'package:flutter_tcc/features/legal/data/datasources/legal_remote_data_source.dart';
import 'package:flutter_tcc/features/notifications/data/datasources/notification_remote_data_source.dart';
import 'package:flutter_tcc/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:flutter_tcc/injection_container.dart';

typedef Reply = FutureOr<dynamic> Function(RequestOptions request);

class FlowTestClient extends DioClient {
  FlowTestClient(Reply reply) : super(tokenService: TokenService()) {
    transport.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) async {
          try {
            handler.resolve(
              Response(
                requestOptions: request,
                statusCode: 200,
                data: await reply(request),
              ),
            );
          } catch (e) {
            handler.reject(
              DioException(
                requestOptions: request,
                type: DioExceptionType.unknown,
                error: e,
              ),
            );
          }
        },
      ),
    );
  }
  final transport = Dio();
  @override
  Dio get dio => transport;
}

Future<void> setupFlowNetwork([Reply? reply]) async {
  if (sl.isRegistered<DioClient>()) {
    await sl.unregister<DioClient>();
  }
  sl.registerSingleton<DioClient>(FlowTestClient(reply ?? emptyFlowReply));
  // O aviso de cadastro pendente aparece dentro das cascas do app e lê a
  // verificação da conta por aqui.
  if (sl.isRegistered<LegalRemoteDataSource>()) {
    await sl.unregister<LegalRemoteDataSource>();
  }
  sl.registerSingleton<LegalRemoteDataSource>(
    LegalRemoteDataSource(dioClient: sl<DioClient>()),
  );
  // O painel e as telas de perfil leem chamados, avisos e projetos por estas
  // fontes; sem registrá-las o `sl` lança antes da primeira renderização.
  if (sl.isRegistered<BidRemoteDataSource>()) {
    await sl.unregister<BidRemoteDataSource>();
  }
  sl.registerSingleton<BidRemoteDataSource>(
    BidRemoteDataSource(dioClient: sl<DioClient>()),
  );
  if (sl.isRegistered<NotificationRemoteDataSource>()) {
    await sl.unregister<NotificationRemoteDataSource>();
  }
  sl.registerSingleton<NotificationRemoteDataSource>(
    NotificationRemoteDataSource(dioClient: sl<DioClient>()),
  );
  if (sl.isRegistered<ProfileRemoteDataSource>()) {
    await sl.unregister<ProfileRemoteDataSource>();
  }
  sl.registerSingleton<ProfileRemoteDataSource>(
    ProfileRemoteDataSourceImpl(dioClient: sl<DioClient>()),
  );
  if (sl.isRegistered<ContractRepository>()) {
    await sl.unregister<ContractRepository>();
  }
  sl.registerSingleton<ContractRepository>(
    ContractRemoteDataSource(dioClient: sl<DioClient>()),
  );
}

Future<void> clearFlowNetwork() async {
  for (final unregister in [
    () async {
      if (sl.isRegistered<ContractRepository>()) {
        await sl.unregister<ContractRepository>();
      }
    },
    () async {
      if (sl.isRegistered<ProfileRemoteDataSource>()) {
        await sl.unregister<ProfileRemoteDataSource>();
      }
    },
    () async {
      if (sl.isRegistered<NotificationRemoteDataSource>()) {
        await sl.unregister<NotificationRemoteDataSource>();
      }
    },
    () async {
      if (sl.isRegistered<BidRemoteDataSource>()) {
        await sl.unregister<BidRemoteDataSource>();
      }
    },
    () async {
      if (sl.isRegistered<LegalRemoteDataSource>()) {
        await sl.unregister<LegalRemoteDataSource>();
      }
    },
    () async {
      if (sl.isRegistered<DioClient>()) {
        await sl.unregister<DioClient>();
      }
    },
  ]) {
    await unregister();
  }
}

dynamic emptyFlowReply(RequestOptions r) {
  // Conta já liberada: o aviso de cadastro pendente fica fora das telas que
  // estes testes conferem.
  if (r.path.endsWith('/users/profile')) {
    return {
      'id': 'user-teste',
      'email': 'teste@jobble.local',
      'verification': {
        'clientReady': true,
        'providerReady': true,
        'profileComplete': true,
        'identityStatus': 'APPROVED',
        'backgroundCheckStatus': 'APPROVED',
        'missing': <String>[],
      },
    };
  }
  if (r.path.endsWith('/notifications/count')) return {'count': 0};
  if (r.path.endsWith('/organizations/legal-profile')) {
    return {
      'id': 'organizacao-teste',
      'tradeName': 'Organização de Teste',
      'legalType': 'INDIVIDUAL',
      'canEdit': true,
      'readiness': {
        'ready': true,
        'profileComplete': true,
        'identityStatus': 'APPROVED',
        'missing': <String>[],
      },
    };
  }
  if (r.path.endsWith('/provider/settings')) {
    return {
      'hours': {
        'allDay': true,
        'days': List.generate(
          7,
          (day) => {'day': day, 'allDay': true, 'windows': []},
        ),
      },
      'timeZone': 'America/Sao_Paulo',
      'services': [],
      'response': {'rate': null, 'answered': 0, 'total': 0, 'pending': 0},
    };
  }
  return [];
}
