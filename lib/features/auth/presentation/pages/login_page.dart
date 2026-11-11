import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_tcc/core/theme/app_colors.dart';
import 'package:flutter_tcc/core/theme/app_spacing.dart';
import 'package:flutter_tcc/core/theme/app_theme.dart';
import 'package:flutter_tcc/core/theme/app_typography.dart';
import 'package:flutter_tcc/core/widgets/app_buttons.dart';
import 'package:flutter_tcc/core/widgets/joberto_stage.dart';
import 'package:flutter_tcc/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_tcc/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_tcc/features/auth/presentation/widgets/auth_error_card.dart';
import 'package:flutter_tcc/features/auth/presentation/widgets/auth_motion.dart';
import 'package:flutter_tcc/features/auth/presentation/widgets/login_form.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _emailFocused = false;
  bool _passwordFocused = false;

  /// O login acabou de ser recusado e o Joberto ainda está reagindo.
  bool _failed = false;

  void _onFieldFocus(LoginField field, bool focused) {
    setState(() {
      switch (field) {
        case LoginField.email:
          _emailFocused = focused;
        case LoginField.password:
          _passwordFocused = focused;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Sempre no tema claro: o fundo precisa ser o mesmo do clipe do Joberto.
    return Theme(
      data: AppTheme.light,
      child: Builder(builder: _buildPage),
    );
  }

  /// O Joberto fica fora da área que rola: com o teclado aberto o formulário
  /// sobe, e ele sairia da tela justo quando está reagindo ao que é digitado.
  /// O tamanho é fixo, já contando com o teclado: encolher na hora parecia a
  /// câmera se afastando.
  Widget _buildJoberto(BuildContext context) {
    return Entrance(
      index: 0,
      child: BlocBuilder<AuthBloc, AuthState>(
        buildWhen: (previous, current) =>
            (previous is AuthLoading) != (current is AuthLoading),
        builder: (context, state) => JobertoStage(
          height: 190,
          clip: JobertoClip.forLogin(
            submitting: state is AuthLoading,
            failed: _failed,
            passwordFocused: _passwordFocused,
            emailFocused: _emailFocused,
          ),
          onCompleted: () {
            if (_failed) setState(() => _failed = false);
          },
        ),
      ),
    );
  }

  Widget _buildPage(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: jobertoPaper,
      appBar: AppBar(
        backgroundColor: jobertoPaper,
        leadingWidth: AppSize.iconButton + AppSpacing.md + AppSpacing.xs,
        leading: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.md),
          child: AppCircleIconButton(
            icon: LucideIcons.arrow_left,
            tooltip: 'Voltar',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: const Text('Entrar'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildJoberto(context),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.screenH,
                            AppSpacing.md,
                            AppSpacing.screenH,
                            AppSpacing.xl,
                          ),
                          child: BlocConsumer<AuthBloc, AuthState>(
                            listener: (context, state) {
                              if (state is AuthFailure) {
                                setState(() => _failed = true);
                              }
                            },
                            builder: (context, state) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (state is AuthFailure) ...[
                                    AuthErrorCard(
                                      title: 'Falha ao entrar',
                                      message: state.message,
                                    ),
                                    const SizedBox(height: AppSpacing.xl),
                                  ],
                                  Entrance(
                                    index: 1,
                                    child: Text(
                                      'Acesse sua conta',
                                      style: AppTypography.h1.copyWith(
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Entrance(
                                    index: 2,
                                    child: Text(
                                      'Entre para acompanhar seu trabalho e gerenciar seu negócio',
                                      style: AppTypography.body.copyWith(
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.section),
                                  Expanded(
                                    child: Shake(
                                      trigger: state is AuthFailure
                                          ? state
                                          : null,
                                      child: Entrance(
                                        index: 3,
                                        child: LoginForm(
                                          onFieldFocus: _onFieldFocus,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
