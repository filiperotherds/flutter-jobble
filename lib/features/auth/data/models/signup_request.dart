/// Cadastro: e-mail e senha.
///
/// Nome, CPF, nascimento e telefone saíram daqui — são o onboarding, depois
/// de entrar, e é o que libera receber chamados.
class SignupRequest {
  final String email;
  final String password;

  SignupRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() {
    return {'email': email, 'password': password};
  }
}
