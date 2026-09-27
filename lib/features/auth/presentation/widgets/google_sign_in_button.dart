import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:flutter_tcc/core/config/app_config.dart';
import 'package:flutter_tcc/core/constants/app_assets.dart';
import 'package:flutter_tcc/core/services/google_auth_service.dart';
import 'package:flutter_tcc/core/theme/app_colors.dart';
import 'package:flutter_tcc/core/theme/app_spacing.dart';
import 'package:flutter_tcc/core/theme/app_typography.dart';

import 'google_button_native.dart'
    if (dart.library.js_interop) 'google_button_web.dart';

/// "Entrar com o Google".
///
/// Some quando a build não tem `GOOGLE_CLIENT_ID`: um botão que o Google vai
/// recusar é pior do que botão nenhum. Na web mostra o botão oficial, exigido
/// pelo fluxo de lá; nas demais plataformas, um botão do próprio app.
class GoogleSignInButton extends StatefulWidget {
  const GoogleSignInButton({super.key, this.onError});

  /// Chamado quando o Google recusa ou a pessoa desiste.
  final ValueChanged<String>? onError;

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  final _google = GoogleAuthService.instance;
  bool _ready = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (AppConfig.isGoogleSignInEnabled) _prepare();
  }

  Future<void> _prepare() async {
    try {
      await _google.initialize();
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      // Sem o SDK carregado não há login com o Google; o e-mail e senha
      // continuam de pé, então a tela não precisa acusar nada.
    }
  }

  Future<void> _startNativeFlow() async {
    setState(() => _busy = true);
    try {
      await _google.authenticate();
    } catch (error) {
      widget.onError?.call('Não consegui entrar com o Google.');
      debugPrint('Google Sign-In: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.isGoogleSignInEnabled || !_ready) {
      return const SizedBox.shrink();
    }

    final officialButton = renderGoogleButton();
    if (officialButton != null) {
      return SizedBox(height: 44, child: officialButton);
    }

    final colors = context.colors;
    return OutlinedButton.icon(
      onPressed: _busy ? null : _startNativeFlow,
      icon: SvgPicture.asset(AppAssets.googleIcon, width: 20, height: 20),
      label: Text(
        _busy ? 'Entrando…' : 'Entrar com o Google',
        style: AppTypography.body.copyWith(
          fontWeight: FontWeight.bold,
          color: colors.textPrimary,
        ),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        side: BorderSide(color: colors.borderLight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
      ),
    );
  }
}
