import 'package:flutter_tcc/features/auth/data/models/login_response.dart';
import 'package:flutter_tcc/features/auth/domain/repositories/auth_repository.dart';

class GoogleLoginUseCase {
  final AuthRepository repository;

  GoogleLoginUseCase({required this.repository});

  Future<LoginResponse> execute(String idToken) async {
    return await repository.loginWithGoogle(idToken);
  }
}
