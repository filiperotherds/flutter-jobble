import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import 'package:flutter_tcc/core/theme/app_spacing.dart';
import 'package:flutter_tcc/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_tcc/features/auth/presentation/bloc/auth_event.dart';
import 'package:flutter_tcc/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_tcc/features/onboard/presentation/pages/intro_page.dart';

/// "Sair da conta" do perfil do profissional.
///
/// Mesma rotina do [SignOutRow]: o bloco apaga o token e só então a tela troca
/// para a entrada. Sair não pode depender de a navegação acontecer antes, ou a
/// sessão ficaria de pé por trás.
class SignOutButton extends StatefulWidget {
  const SignOutButton({super.key});

  @override
  State<SignOutButton> createState() => _SignOutButtonState();
}

class _SignOutButtonState extends State<SignOutButton> {
  bool _pending = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (_, state) =>
          _pending && (state is AuthLoggedOut || state is AuthLogoutFailure),
      listener: (context, state) {
        setState(() => _pending = false);
        if (state is AuthLoggedOut) {
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const IntroPage()),
            (_) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Não foi possível sair. Tente novamente.'),
            ),
          );
        }
      },
      child: ElevatedButton.icon(
        onPressed: _pending
            ? null
            : () {
                setState(() => _pending = true);
                context.read<AuthBloc>().add(LogoutRequested());
              },
        icon: const Icon(LucideIcons.log_out, color: Colors.red),
        label: Text(
          _pending ? 'Saindo…' : 'Sair da conta',
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[50],
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
