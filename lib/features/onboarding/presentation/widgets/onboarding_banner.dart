import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import 'package:flutter_tcc/core/network/api_exception.dart';
import 'package:flutter_tcc/core/theme/app_colors.dart';
import 'package:flutter_tcc/core/theme/app_spacing.dart';
import 'package:flutter_tcc/core/theme/app_typography.dart';
import 'package:flutter_tcc/core/widgets/app_card.dart';
import 'package:flutter_tcc/features/legal/data/datasources/legal_remote_data_source.dart';
import 'package:flutter_tcc/features/legal/data/models/account_verification.dart';
import 'package:flutter_tcc/features/legal/data/models/legal_models.dart';
import 'package:flutter_tcc/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:flutter_tcc/injection_container.dart';

/// Aviso fixo de cadastro pendente no painel do profissional.
///
/// O onboarding guiado aparece uma vez por sessão; este cartão é o que fica
/// enquanto a conta não recebe chamados. Some sozinho quando ela é liberada.
class OnboardingBanner extends StatefulWidget {
  const OnboardingBanner({super.key});

  @override
  State<OnboardingBanner> createState() => _OnboardingBannerState();
}

class _OnboardingBannerState extends State<OnboardingBanner> {
  AccountVerification? _verification;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final verification = await sl<LegalRemoteDataSource>()
          .getAccountVerification();
      if (mounted) setState(() => _verification = verification);
    } on ApiException {
      // Sem resposta, o painel segue sem o aviso.
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final verification = _verification;
    if (verification == null || verification.canWork) {
      return const SizedBox.shrink();
    }

    final missing = verification.readiness.missing;
    final analysing =
        missing.isEmpty &&
        verification.identityStatus == IdentityStatus.pending;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: AppCard(
        onTap: analysing
            ? null
            : () => OnboardingPage.show(context, onFinished: _load),
        color: colors.primary.withValues(alpha: 0.08),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              analysing ? LucideIcons.clock : LucideIcons.shield_check,
              size: 20,
              color: colors.primary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    analysing
                        ? 'Cadastro em análise'
                        : 'Complete seu cadastro para receber chamados',
                    style: AppTypography.title.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    analysing
                        ? 'Costuma levar até 1 dia útil. Avisamos assim que '
                              'sua conta for liberada.'
                        : 'Falta: ${missing.take(3).join(', ')}.',
                    style: AppTypography.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (!analysing) ...[
              const SizedBox(width: AppSpacing.sm),
              Icon(LucideIcons.chevron_right, size: 18, color: colors.primary),
            ],
          ],
        ),
      ),
    );
  }
}
