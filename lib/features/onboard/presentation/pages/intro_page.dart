import 'package:flutter_tcc/features/auth/presentation/widgets/google_sign_in_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tcc/core/constants/app_assets.dart';
import 'package:flutter_tcc/core/theme/app_colors.dart';
import 'package:flutter_tcc/core/theme/app_spacing.dart';
import 'package:flutter_tcc/core/theme/app_theme.dart';
import 'package:flutter_tcc/core/theme/app_typography.dart';
import 'package:flutter_tcc/core/widgets/app_buttons.dart';
import 'package:flutter_tcc/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_tcc/features/auth/presentation/pages/signup_page.dart';

/// Cor do papel da ilustração. A tela inteira usa o mesmo fundo para a imagem
/// não ter borda.
const _paper = Color(0xFFF8F9F2);

/// Porta de entrada do app: a ilustração do profissional e do cliente se
/// acertando pelo celular, e as duas saídas — entrar ou criar conta.
///
/// Fica sempre no tema claro: a ilustração é clara, e um fundo escuro em volta
/// dela pareceria um recorte.
class IntroPage extends StatelessWidget {
  const IntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    const ink = AppColorsTheme.light;

    return Theme(
      data: AppTheme.light,
      child: Scaffold(
        backgroundColor: _paper,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenH,
                    AppSpacing.md,
                    AppSpacing.screenH,
                    0,
                  ),
                  child: Image.asset(
                    AppAssets.introIllustration,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenH,
                  AppSpacing.md,
                  AppSpacing.screenH,
                  AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    
                    AppPrimaryButton(
                      label: 'Criar conta',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignupPage()),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppSecondaryButton(
                      label: 'Já tenho conta',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Center(child: GoogleSignInButton()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
