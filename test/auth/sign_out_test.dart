import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tcc/core/services/token_service.dart';
import 'package:flutter_tcc/core/theme/app_theme.dart';
import 'package:flutter_tcc/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_tcc/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_tcc/features/auth/presentation/widgets/sign_out_row.dart';
import 'package:flutter_tcc/features/onboard/presentation/pages/intro_page.dart';
import 'package:flutter_tcc/features/auth/domain/usecases/login_usecase.dart';
import 'package:flutter_tcc/features/auth/domain/usecases/signup_usecase.dart';
import 'package:flutter_tcc/features/auth/domain/usecases/verify_email_usecase.dart';
import 'package:flutter_tcc/features/auth/domain/usecases/complete_onboarding_usecase.dart';
import 'package:flutter_tcc/features/auth/domain/usecases/resend_verification_code_usecase.dart';
import 'package:flutter_tcc/features/auth/domain/usecases/get_me_usecase.dart';
import 'package:flutter_tcc/features/auth/domain/usecases/update_organization_profile_usecase.dart';

class _Repository implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Tokens extends TokenService {
  String? token = 'session';
  bool fail = false;

  @override
  Future<void> deleteToken() async {
    if (fail) throw Exception('storage unavailable');
    token = null;
  }
}

void main() {
  for (final failsFirst in [false, true]) {
    testWidgets('logout clears session and routes, retry: $failsFirst', (
      tester,
    ) async {
      final repository = _Repository();
      final tokens = _Tokens()..fail = failsFirst;
      final bloc = AuthBloc(
        loginUseCase: LoginUseCase(repository: repository),
        signupUseCase: SignupUseCase(repository: repository),
        verifyEmailUseCase: VerifyEmailUseCase(repository: repository),
        completeOnboardingUseCase: CompleteOnboardingUseCase(
          repository: repository,
        ),
        resendVerificationCodeUseCase: ResendVerificationCodeUseCase(
          repository: repository,
        ),
        getMeUseCase: GetMeUseCase(repository: repository),
        updateOrganizationProfileUseCase: UpdateOrganizationProfileUseCase(
          repository: repository,
        ),
        tokenService: tokens,
      );
      addTearDown(bloc.close);
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        BlocProvider.value(
          value: bloc,
          child: MaterialApp(
            navigatorKey: navigator,
            theme: AppTheme.light,
            home: const Scaffold(body: Text('Private route')),
          ),
        ),
      );
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: SignOutRow()),
        ),
      );
      await tester.pumpAndSettle();
      if (failsFirst) {
        for (var attempt = 0; attempt < 2; attempt++) {
          await tester.tap(find.text('Sair do app'));
          await tester.pumpAndSettle();
          expect(tokens.token, 'session');
          expect(find.byType(IntroPage), findsNothing);
          expect(find.text('Sair do app'), findsOneWidget);
        }
        tokens.fail = false;
      }
      await tester.tap(find.text('Sair do app'));
      await tester.pumpAndSettle();
      expect(tokens.token, isNull);
      expect(find.byType(IntroPage), findsOneWidget);
      expect(navigator.currentState!.canPop(), isFalse);
      expect(find.text('Private route'), findsNothing);
    });
  }
}
