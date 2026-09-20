import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import 'package:flutter_tcc/core/network/api_exception.dart';
import 'package:flutter_tcc/core/widgets/app_empty_state.dart';
import 'package:flutter_tcc/core/widgets/app_loader.dart';
import 'package:flutter_tcc/features/home/presentation/pages/main_shell_page.dart';
import 'package:flutter_tcc/features/legal/data/datasources/legal_remote_data_source.dart';
import 'package:flutter_tcc/features/legal/data/models/account_verification.dart';
import 'package:flutter_tcc/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:flutter_tcc/injection_container.dart';

/// Entrada depois do login.
///
/// Entrar não depende de cadastro completo — a porta é e-mail e senha. O que
/// depende é receber chamado: a Jobble confere quem atende antes disso, como
/// as plataformas de transporte fazem com motoristas. Enquanto faltar algo,
/// esta tela abre o app com o onboarding guiado por cima.
class AccountGatePage extends StatefulWidget {
  const AccountGatePage({super.key});

  @override
  State<AccountGatePage> createState() => _AccountGatePageState();
}

class _AccountGatePageState extends State<AccountGatePage> {
  final _dataSource = sl<LegalRemoteDataSource>();

  AccountVerification? _verification;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _check();
  }

  /// O onboarding aparece uma vez por sessão do app; depois dele o aviso do
  /// painel é o que continua cobrando.
  static bool _onboardingShown = false;

  Future<void> _maybeOnboard(AccountVerification verification) async {
    if (_onboardingShown || verification.canWork || !mounted) return;
    _onboardingShown = true;
    await OnboardingPage.show(context, onFinished: _check);
  }

  Future<void> _check() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final verification = await _dataSource.getAccountVerification();
      if (!mounted) return;
      setState(() {
        _verification = verification;
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _maybeOnboard(verification),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final verification = _verification;

    if (verification == null) {
      return Scaffold(
        body: _loading
            ? const AppLoaderCentered(label: 'Conferindo seu cadastro…')
            : AppEmptyState(
                icon: LucideIcons.triangle_alert,
                title: 'Não foi possível conferir seu cadastro',
                description: _error,
                actionLabel: 'Tentar de novo',
                onAction: _check,
              ),
      );
    }

    return const MainShellPage();
  }
}
