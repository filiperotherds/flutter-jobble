import 'dart:async';
import 'package:flutter_tcc/core/config/app_config.dart';
import 'package:flutter_tcc/core/services/google_auth_service.dart';
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
class _SessionGate extends StatefulWidget {
  const _SessionGate();

  @override
  State<_SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<_SessionGate> {
  StreamSubscription<String>? _googleSignIn;

  @override
  void initState() {
    super.initState();
    if (!AppConfig.isGoogleSignInEnabled) return;
    // Uma única assinatura atende ao botão da abertura e ao formulário de login.
    _googleSignIn = GoogleAuthService.instance.idTokens.listen((idToken) {
      if (!mounted) return;
      context.read<AuthBloc>().add(GoogleSignInSubmitted(idToken: idToken));
    });
  }

  @override
  void dispose() {
    _googleSignIn?.cancel();
    super.dispose();
  }

  /// Só estes três estados dizem algo sobre a sessão. Os outros (`AuthLoading`,
  /// `AuthOnboardingSuccess`, `AuthFailure`…) são passos de formulário e não
  /// podem derrubar quem já entrou.
  static bool _decides(AuthState state) =>
      state is AuthSuccess || state is AuthInitial || state is AuthRestoring;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          _decides(current) &&
          (current is AuthSuccess) != (previous is AuthSuccess),
      listener: (_, _) {
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
