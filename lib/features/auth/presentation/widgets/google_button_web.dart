import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

/// Na web o login precisa passar pelo botão renderizado pelo Google: o plugin
/// não expõe um método para abrir o fluxo por conta própria.
Widget? renderGoogleButton() => web.renderButton(
  configuration: web.GSIButtonConfiguration(
    theme: web.GSIButtonTheme.outline,
    size: web.GSIButtonSize.large,
    text: web.GSIButtonText.signinWith,
    shape: web.GSIButtonShape.rectangular,
    logoAlignment: web.GSIButtonLogoAlignment.left,
  ),
);
