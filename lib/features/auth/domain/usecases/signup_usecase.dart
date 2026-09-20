import 'package:flutter_tcc/features/auth/domain/repositories/auth_repository.dart';

class SignupUseCase {
  final AuthRepository repository;

  SignupUseCase({required this.repository});

  Future<void> execute(String email, String password) async {
    await repository.signup(email, password);
  }
}
