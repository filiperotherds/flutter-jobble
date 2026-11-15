import 'package:flutter/foundation.dart';

/// Configuração de ambiente da aplicação.
///
/// Todos os valores vêm de `--dart-define`, resolvidos em tempo de compilação.
/// Use `scripts/run.sh` (que lê o `.env` da raiz) ou as configurações do
/// `.vscode/launch.json` para injetá-los. Sem nenhum define, os defaults abaixo
/// apontam para o backend de produção no Railway.
class AppConfig {
  const AppConfig._();

  /// URL base da API, sem barra no final.
  ///
  /// Emulador Android usa `http://10.0.2.2:3333`, simulador iOS usa
  /// `http://localhost:3333`.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://jobble-api.up.railway.app',
  );

  /// Client ID OAuth do Google, do tipo "Web application".
  ///
  /// Vem de `--dart-define=GOOGLE_CLIENT_ID=...`. Sem ele o botão "Entrar com
  /// o Google" fica escondido: o Google recusa qualquer tentativa de login de
  /// uma origem que não esteja registrada nesse Client ID.
  static const String googleClientId = 'dummy_id_for_ui';

  /// Se dá para oferecer o login com o Google nesta build.
  static bool get isGoogleSignInEnabled => googleClientId.isNotEmpty;

  static const String _uploadsBaseUrl = String.fromEnvironment(
    'UPLOADS_BASE_URL',
  );

  /// URL base dos arquivos enviados. Cai para `$apiBaseUrl/uploads` quando
  /// `UPLOADS_BASE_URL` não é definido.
  static String get uploadsBaseUrl =>
      _uploadsBaseUrl.isEmpty ? '$apiBaseUrl/uploads' : _uploadsBaseUrl;

  /// Monta a URL completa de um arquivo enviado a partir do nome salvo no backend.
  static String uploadUrl(String fileName) => '$uploadsBaseUrl/$fileName';

  static const Duration connectTimeout = Duration(
    seconds: int.fromEnvironment(
      'API_CONNECT_TIMEOUT_SECONDS',
      defaultValue: 10,
    ),
  );

  static const Duration receiveTimeout = Duration(
    seconds: int.fromEnvironment(
      'API_RECEIVE_TIMEOUT_SECONDS',
      defaultValue: 15,
    ),
  );

  /// Liga o `LogInterceptor` do Dio. Desligado em release por padrão.
  static const bool enableHttpLogs = bool.fromEnvironment(
    'ENABLE_HTTP_LOGS',
    defaultValue: kDebugMode,
  );

  /// Modo demonstração: pedidos, conversas, avaliações e números fictícios
  /// respondidos de dentro do app, sem tocar no servidor. Serve para ver as
  /// telas cheias. Liga com `--dart-define=DEMO_DATA=true`; desligado, o app
  /// se comporta como sempre.
  static const bool demoData = bool.fromEnvironment('DEMO_DATA');

  /// Resumo da configuração ativa, para log de inicialização.
  static String describe() =>
      'AppConfig(apiBaseUrl: $apiBaseUrl, uploadsBaseUrl: $uploadsBaseUrl, '
      'connectTimeout: ${connectTimeout.inSeconds}s, '
      'receiveTimeout: ${receiveTimeout.inSeconds}s, '
      'enableHttpLogs: $enableHttpLogs)';
}
