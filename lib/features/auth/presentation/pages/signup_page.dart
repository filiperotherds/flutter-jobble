import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_tcc/core/theme/app_colors.dart';
import 'package:flutter_tcc/core/theme/app_spacing.dart';
import 'package:flutter_tcc/core/theme/app_typography.dart';
import 'package:flutter_tcc/core/widgets/app_buttons.dart';
import 'package:flutter_tcc/core/widgets/app_text_field.dart';
import 'package:flutter_tcc/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_tcc/features/auth/presentation/bloc/auth_event.dart';
import 'package:flutter_tcc/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_tcc/features/auth/presentation/widgets/auth_error_card.dart';
import 'package:flutter_tcc/features/legal/presentation/pages/account_gate_page.dart';

/// Cadastro do profissional em uma etapa: e-mail e senha.
///
/// O que a Jobble precisa saber para liberar chamados — dados pessoais,
/// empresa, documento e certidão de antecedentes — é o onboarding guiado,
/// depois de entrar. Aqui a porta é só a porta.
class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    context.read<AuthBloc>().add(
      SignupSubmitted(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        // Conta criada: entra na sequência, sem pedir a senha de novo.
        if (state is AuthSignupStep1Success) {
          context.read<AuthBloc>().add(
            LoginSubmitted(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
        } else if (state is AuthSuccess) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AccountGatePage()),
            (route) => false,
          );
        }
      },
      builder: (context, state) {
        final isLoading =
            state is AuthLoading || state is AuthSignupStep1Success;

        return Scaffold(
          appBar: AppBar(
            titleSpacing: AppSpacing.screenH,
            centerTitle: false,
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                AppCircleIconButton(
                  icon: LucideIcons.arrow_left,
                  tooltip: 'Voltar',
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  'Criar conta',
                  style: AppTypography.title.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.xl,
                AppSpacing.screenH,
                AppSpacing.xxl,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Comece a receber chamados',
                      style: AppTypography.h1.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Crie a conta com e-mail e senha. Em seguida a gente '
                      'monta seu perfil profissional junto com você.',
                      style: AppTypography.body.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppTextField(
                      controller: _emailController,
                      label: 'E-mail',
                      hint: 'exemplo@email.com',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      validator: (value) {
                        final email = (value ?? '').trim();
                        if (email.isEmpty) return 'Informe seu e-mail';
                        if (!email.contains('@')) return 'E-mail inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _passwordController,
                      label: 'Senha',
                      obscureText: true,
                      helper: 'Pelo menos 8 caracteres',
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                      validator: (value) => (value ?? '').length < 8
                          ? 'A senha precisa de 8 caracteres'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirme a senha',
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      validator: (value) => value != _passwordController.text
                          ? 'As senhas não são iguais'
                          : null,
                    ),
                    if (state is AuthFailure) ...[
                      const SizedBox(height: AppSpacing.md),
                      AuthErrorCard(
                        title: 'Não foi possível criar a conta',
                        message: state.message,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          LucideIcons.shield_check,
                          size: 18,
                          color: colors.textHint,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Para receber chamados pedimos seus dados, um '
                            'documento com foto e a certidão de antecedentes. '
                            'É o que dá segurança a quem contrata.',
                            style: AppTypography.caption.copyWith(
                              color: colors.textHint,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppPrimaryButton(
                      label: 'Criar conta',
                      isLoading: isLoading,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
