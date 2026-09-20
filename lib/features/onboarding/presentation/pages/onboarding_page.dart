import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import 'package:flutter_tcc/core/network/api_exception.dart';
import 'package:flutter_tcc/core/services/onboarding_reminders.dart';
import 'package:flutter_tcc/core/theme/app_colors.dart';
import 'package:flutter_tcc/core/theme/app_spacing.dart';
import 'package:flutter_tcc/core/theme/app_typography.dart';
import 'package:flutter_tcc/core/widgets/app_buttons.dart';
import 'package:flutter_tcc/core/widgets/app_card.dart';
import 'package:flutter_tcc/core/widgets/app_loader.dart';
import 'package:flutter_tcc/features/auth/presentation/pages/complete_profile_page.dart';
import 'package:flutter_tcc/features/legal/data/datasources/legal_remote_data_source.dart';
import 'package:flutter_tcc/features/legal/data/models/account_verification.dart';
import 'package:flutter_tcc/features/legal/data/models/legal_models.dart';
import 'package:flutter_tcc/features/legal/presentation/pages/verification_center_page.dart';
import 'package:flutter_tcc/injection_container.dart';

/// Onboarding guiado do profissional, logo depois de entrar.
///
/// O cadastro pede dois campos. O que libera receber chamados — perfil
/// profissional, dados pessoais, documento e certidão de antecedentes — está
/// aqui, explicado e em ordem. A tela não tranca o app: mostra o que falta e
/// leva direto para a próxima etapa.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, this.onFinished});

  final VoidCallback? onFinished;

  static Future<void> show(BuildContext context, {VoidCallback? onFinished}) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => OnboardingPage(onFinished: onFinished),
      ),
    );
  }

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _legal = sl<LegalRemoteDataSource>();

  AccountVerification? _verification;
  bool _hasOrganization = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final verification = await _legal.getAccountVerification();
      if (!mounted) return;
      setState(() {
        _verification = verification;
        // Sem organização o servidor não tem o que avaliar do lado
        // profissional: `providerReady` vem nulo.
        _hasOrganization = verification.providerReady != null;
        _loading = false;
      });
    } on ApiException {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _openStep(Widget page) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => page));
    await _load();
    await sl<OnboardingReminders>().sync();
  }

  Future<void> _later() async {
    final navigator = Navigator.of(context);
    // A permissão é pedida no momento em que a pessoa adia: é quando o aviso
    // faz sentido para ela.
    await sl<OnboardingReminders>().requestPermission();
    await sl<OnboardingReminders>().sync();
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final verification = _verification;
    final missing = verification?.missing ?? const <String>[];
    final identityDone =
        verification?.identityStatus == IdentityStatus.approved;
    final backgroundDone =
        verification?.backgroundCheckStatus == IdentityStatus.approved;
    final done = verification?.canWork == true;
    // Dados pessoais e organização compartilham a lista `missing`; sem
    // organização a etapa dela é o primeiro passo, e as outras vêm depois.
    final personalDone = _hasOrganization && missing.isEmpty;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Complete seu cadastro'),
        actions: [
          TextButton(onPressed: _later, child: const Text('Agora não')),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: _loading && verification == null
          ? const AppLoaderCentered(label: 'Conferindo seu cadastro…')
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenH,
                  AppSpacing.lg,
                  AppSpacing.screenH,
                  AppSpacing.xxl,
                ),
                children: [
                  Text(
                    done
                        ? 'Sua conta está liberada'
                        : 'Bem-vindo. Falta pouco para receber chamados.',
                    style: AppTypography.h1.copyWith(color: colors.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    done
                        ? 'Você já aparece nas buscas e recebe solicitações da '
                              'sua região.'
                        : 'Como nas plataformas de transporte, a Jobble '
                              'confere quem atende antes de mandar o primeiro '
                              'chamado: seus dados, um documento com foto e a '
                              'certidão de antecedentes. Você pode olhar o app '
                              'agora — chamados só chegam depois disso.',
                    style: AppTypography.body.copyWith(color: colors.textBody),
                  ),
                  const SizedBox(height: AppSpacing.section),
                  _Step(
                    index: 1,
                    title: 'Perfil profissional',
                    description: _hasOrganization
                        ? 'Criado'
                        : 'Nome do negócio e como você atende',
                    icon: LucideIcons.briefcase,
                    done: _hasOrganization,
                    onTap: _hasOrganization
                        ? null
                        : () => _openStep(const CompleteProfilePage()),
                  ),
                  const SizedBox(height: AppSpacing.gap),
                  _Step(
                    index: 2,
                    title: 'Dados pessoais e da organização',
                    description: !_hasOrganization
                        ? 'Depois de criar o perfil'
                        : missing.isEmpty
                        ? 'Completos'
                        : 'Falta: ${missing.join(', ')}',
                    icon: LucideIcons.user,
                    done: personalDone,
                    onTap: _hasOrganization ? _openCenter : null,
                  ),
                  const SizedBox(height: AppSpacing.gap),
                  _Step(
                    index: 3,
                    title: 'Documento com foto',
                    description:
                        verification?.identityStatus.label ??
                        'Frente do documento e uma selfie',
                    icon: LucideIcons.scan_face,
                    done: identityDone,
                    onTap: _hasOrganization ? _openCenter : null,
                  ),
                  const SizedBox(height: AppSpacing.gap),
                  _Step(
                    index: 4,
                    title: 'Certidão de antecedentes',
                    description:
                        verification?.backgroundCheckStatus?.certificateLabel ??
                        'Emitida pela Polícia Federal ou Civil',
                    icon: LucideIcons.shield_check,
                    done: backgroundDone,
                    onTap: _hasOrganization ? _openCenter : null,
                  ),
                  const SizedBox(height: AppSpacing.section),
                  if (done)
                    AppPrimaryButton(
                      label: 'Começar a atender',
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onFinished?.call();
                      },
                    )
                  else ...[
                    AppPrimaryButton(
                      label: _hasOrganization
                          ? 'Continuar meu cadastro'
                          : 'Criar meu perfil profissional',
                      onPressed: _hasOrganization
                          ? _openCenter
                          : () => _openStep(const CompleteProfilePage()),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppSecondaryButton(
                      label: 'Agora não, me lembre depois',
                      onPressed: _later,
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  void _openCenter() => _openStep(VerificationCenterPage(onChanged: _load));
}

class _Step extends StatelessWidget {
  const _Step({
    required this.index,
    required this.title,
    required this.description,
    required this.icon,
    required this.done,
    this.onTap,
  });

  final int index;
  final String title;
  final String description;
  final IconData icon;
  final bool done;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: done
                  ? colors.success.withValues(alpha: 0.12)
                  : colors.surfaceLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              done ? LucideIcons.check : icon,
              size: 18,
              color: done ? colors.success : colors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$index. $title',
                  style: AppTypography.title.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppTypography.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null && !done)
            Icon(LucideIcons.chevron_right, size: 18, color: colors.textHint),
        ],
      ),
    );
  }
}
