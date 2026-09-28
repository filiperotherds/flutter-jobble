import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:flutter_tcc/core/theme/app_theme.dart';
import 'package:flutter_tcc/core/widgets/app_loader.dart';
import 'package:flutter_tcc/features/legal/presentation/pages/account_gate_page.dart';
import 'package:flutter_tcc/features/onboard/presentation/pages/intro_page.dart';
import 'package:flutter_tcc/injection_container.dart' as di;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tcc/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_tcc/features/auth/presentation/bloc/auth_event.dart';
import 'package:flutter_tcc/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_tcc/features/settings/presentation/bloc/config_bloc.dart';
import 'package:flutter_tcc/core/theme/theme_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Contratos mostram datas por extenso em português; sem os símbolos
  // carregados, `DateFormat` com locale pt_BR lança em tempo de execução.
  await initializeDateFormatting('pt_BR');

  await di.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// Necessário para esvaziar a pilha quando a sessão muda: trocar o `home` não
  /// remove as rotas empilhadas sobre ele, e o prestador continuaria vendo a
  /// conversa aberta por cima da tela de entrada.
  static final navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<AuthBloc>()..add(UserRequested())),
        BlocProvider(create: (_) => di.sl<ThemeCubit>()),
        BlocProvider(create: (_) => di.sl<ConfigBloc>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            title: 'Jobble Prestador',
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            home: const _SessionGate(),
          );
        },
      ),
    );
  }
}

/// Decide entre a abertura e o app autenticado.
///
/// Fica acima do `Navigator` em vez de virar uma rota: assim um 401 em qualquer
/// tela derruba a sessão e a árvore inteira volta para a abertura, sem depender
/// de quem estava empilhado.
class _SessionGate extends StatelessWidget {
  const _SessionGate();

  /// Só estes três estados dizem algo sobre a sessão. Os outros (`AuthLoading`,
  /// `AuthOnboardingSuccess`, `AuthFailure`…) são passos de formulário e não
  /// podem derrubar quem já entrou.
  static bool _decides(AuthState state) =>
      state is AuthSuccess || state is AuthInitial || state is AuthRestoring;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          current is AuthFailure ||
          (_decides(current) &&
              (current is AuthSuccess) != (previous is AuthSuccess)),
      listener: (context, state) {
        if (state is AuthFailure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
          return;
        }
        MyApp.navigatorKey.currentState?.popUntil((route) => route.isFirst);
      },
      buildWhen: (_, current) => _decides(current),
      builder: (context, state) {
        if (state is AuthRestoring) {
          return const Scaffold(body: AppLoaderCentered());
        }
        // Entrar não depende de cadastro completo: quem tem conta vê o app. A
        // porta confere o que falta e abre o onboarding guiado por cima.
        if (state is AuthSuccess) return const AccountGatePage();
        return const IntroPage();
      },
    );
  }
}
