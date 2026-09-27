import 'dart:async';

import 'package:google_sign_in/google_sign_in.dart';

import 'package:flutter_tcc/core/config/app_config.dart';

/// Ponte com o Google Sign-In.
///
/// O plugin entrega um `idToken` assinado pelo Google; quem decide se a pessoa
/// entra é o backend, em `POST /auth/google`, que confere essa assinatura. O
/// app nunca cria sessão por conta própria a partir do que o Google devolve.
class GoogleAuthService {
  GoogleAuthService._();

  static final GoogleAuthService instance = GoogleAuthService._();

  Future<void>? _initialization;

  /// `idToken` de cada login concluído. Na web o Google usa o botão dele e
  /// avisa por aqui — não há um `Future` para aguardar.
  Stream<String> get idTokens => GoogleSignIn.instance.authenticationEvents
      .where((event) => event is GoogleSignInAuthenticationEventSignIn)
      .cast<GoogleSignInAuthenticationEventSignIn>()
      .map((event) => event.user.authentication.idToken)
      .where((token) => token != null)
      .cast<String>();

  /// Prepara o plugin uma vez só; chamadas seguintes reaproveitam a primeira.
  Future<void> initialize() {
    return _initialization ??= GoogleSignIn.instance.initialize(
      clientId: AppConfig.googleClientId,
    );
  }

  /// Fora da web o app abre o fluxo; na web quem faz isso é o botão do Google.
  bool get canStartFlow => GoogleSignIn.instance.supportsAuthenticate();

  /// Abre o seletor de contas. Só use quando [canStartFlow] for verdadeiro.
  Future<String?> authenticate() async {
    await initialize();
    final account = await GoogleSignIn.instance.authenticate();
    return account.authentication.idToken;
  }
}
