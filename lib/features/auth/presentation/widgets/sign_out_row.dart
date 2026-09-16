import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import 'package:flutter_tcc/core/widgets/app_list_row.dart';
import 'package:flutter_tcc/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_tcc/features/auth/presentation/bloc/auth_event.dart';
import 'package:flutter_tcc/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_tcc/features/onboard/presentation/pages/intro_page.dart';

class SignOutRow extends StatefulWidget {
  const SignOutRow({super.key});

  @override
  State<SignOutRow> createState() => _SignOutRowState();
}

class _SignOutRowState extends State<SignOutRow> {
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
      child: AppListRow(
        title: _pending ? 'Saindo…' : 'Sair do app',
        icon: LucideIcons.log_out,
        destructive: true,
        onTap: _pending
            ? null
            : () {
                setState(() => _pending = true);
                context.read<AuthBloc>().add(LogoutRequested());
              },
      ),
    );
  }
}
