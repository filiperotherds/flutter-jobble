import 'package:flutter_tcc/features/auth/domain/entities/user.dart';
import 'package:flutter_tcc/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_tcc/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:flutter_tcc/features/auth/data/models/login_request.dart';
import 'package:flutter_tcc/features/auth/data/models/signup_request.dart';
import 'package:flutter_tcc/features/auth/data/models/login_response.dart';
import 'package:flutter_tcc/features/auth/data/models/user_model.dart';

import 'package:flutter_tcc/features/auth/data/datasources/auth_local_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<LoginResponse> login(String email, String password) async {
    return await remoteDataSource.login(
      LoginRequest(email: email, password: password),
    );
  }

  @override
  Future<LoginResponse> loginWithGoogle(String idToken) async {
    return await remoteDataSource.loginWithGoogle(idToken);
  }

  @override
  Future<void> signup(String email, String password) async {
    await remoteDataSource.signup(
      SignupRequest(email: email, password: password),
    );
  }

  @override
  Future<void> verifyEmail(String email, String code) async {
    await remoteDataSource.verifyEmail(email, code);
  }

  @override
  Future<void> resendVerificationCode(String email) async {
    return await remoteDataSource.resendVerificationCode(email);
  }

  @override
  Future<void> completeOnboarding(
    String organizationName, {
    String? description,
    String? legalType,
    String? document,
    String? legalName,
  }) async {
    await remoteDataSource.completeOnboarding(
      organizationName,
      description: description,
      legalType: legalType,
      document: document,
      legalName: legalName,
    );
  }

  @override
  Future<User> getMe() async {
    try {
      final userModel = await remoteDataSource.getMe();
      await _cacheQuietly(userModel);
      return userModel;
    } catch (e) {
      // Em caso de falha de conexão ou erro, tenta buscar do cache
      final cachedUser = await _readCacheQuietly();
      if (cachedUser != null) {
        return cachedUser;
      }
      rethrow;
    }
  }

  /// Guarda o usuário para abrir o app sem rede da próxima vez.
  ///
  /// O banco local é sqflite, que não existe na web: lá toda chamada falha. É
  /// conveniência, não parte da sessão — deixar o erro subir derrubava o
  /// login inteiro depois de o servidor já ter respondido que estava tudo
  /// certo.
  Future<void> _cacheQuietly(UserModel user) async {
    try {
      await localDataSource.cacheUser(user);
    } catch (_) {
      // Sem cache local; a resposta do servidor continua valendo.
    }
  }

  /// Último usuário guardado, ou `null` se não houver — nem banco onde ler.
  Future<User?> _readCacheQuietly() async {
    try {
      return await localDataSource.getCachedUser();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> updateOrganizationProfile(String tags, String bio) async {
    await remoteDataSource.updateOrganizationProfile(tags, bio);
  }
}
