import '../service_flow/fake_flow_network.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tcc/core/theme/app_theme.dart';
import 'package:flutter_tcc/features/auth/presentation/bloc/auth_bloc.dart';
import '../home/provider_shell_test.dart' show TestAuthBloc;
import 'package:flutter_tcc/features/profile/presentation/pages/provider_services_catalog_page.dart';
import 'package:flutter_tcc/features/profile/presentation/pages/provider_profile_tab.dart';
import 'package:flutter_tcc/features/profile/presentation/pages/provider_portfolio_page.dart';
import 'package:flutter_tcc/features/profile/presentation/pages/provider_registration_page.dart';
import 'package:flutter_tcc/features/profile/presentation/pages/provider_help_center_page.dart';
import 'package:flutter_tcc/features/profile/presentation/pages/provider_edit_profile_page.dart';
import 'package:flutter_tcc/features/profile/presentation/pages/provider_signup_wizard_page.dart';
import 'package:flutter_tcc/features/profile/presentation/pages/provider_performance_page.dart';
import 'package:flutter_tcc/features/profile/presentation/pages/provider_settings_page.dart';
import 'package:flutter_tcc/features/home/presentation/pages/provider_agenda_page.dart';
import 'package:flutter_tcc/features/home/presentation/pages/provider_messages_page.dart';
import 'package:flutter_tcc/features/home/presentation/pages/provider_shell_page.dart';
import 'package:flutter_tcc/features/requests/presentation/pages/provider_job_tracker_page.dart';
import 'package:flutter_tcc/features/requests/presentation/pages/provider_quote_generator_page.dart';
import 'package:flutter_tcc/features/requests/presentation/pages/provider_request_detail_page.dart';
import 'package:flutter_tcc/features/notifications/presentation/pages/provider_notifications_page.dart';

void main() {
  setUp(setupFlowNetwork);
  tearDown(clearFlowNetwork);
  setUpAll(() async {
    for (final family in ['SpaceGrotesk', 'Urbanist', 'PlusJakartaSans']) {
      final loader = FontLoader(family)
        ..addFont(rootBundle.load('assets/fonts/$family-Regular.ttf'));
      await loader.load();
    }
  });
  final screens = <String, Widget Function()>{
    'ProviderQuotePreviewPage': () => const ProviderQuotePreviewPage(
      items: [
        {'desc': 'Pintura', 'qtd': 1, 'unit': 150.0},
      ],
      total: 150,
      isReadOnly: true,
    ),
    'ProviderServicesCatalogPage': () => const ProviderServicesCatalogPage(),
    'ProviderProfileTab': () => const ProviderProfileTab(),
    'ProviderPortfolioPage': () => const ProviderPortfolioPage(),
    'ProviderRegistrationPage': () => const ProviderRegistrationPage(),
    'ProviderHelpCenterPage': () => const ProviderHelpCenterPage(),
    'ProviderEditProfilePage': () => const ProviderEditProfilePage(),
    'ProviderSignupWizardPage': () => const ProviderSignupWizardPage(),
    'ProviderPerformancePage': () => const ProviderPerformancePage(),
    'ProviderSettingsPage': () => const ProviderSettingsPage(),
    'ProviderAgendaPage': () => const ProviderAgendaPage(),
    'ProviderMessagesPage': () => const ProviderMessagesPage(),
    'ProviderShellPage': () => const ProviderShellPage(),
    'ProviderJobTrackerPage': () => const ProviderJobTrackerPage(),
    'ProviderQuoteGeneratorPage': () => const ProviderQuoteGeneratorPage(),
    'ProviderRequestDetailPage': () => const ProviderRequestDetailPage(),
    'ProviderNotificationsPage': () => const ProviderNotificationsPage(),
  };
  for (final entry in screens.entries) {
    testWidgets('${entry.key} fits a 390px phone', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auth = TestAuthBloc();
      addTearDown(auth.close);
      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: auth,
          child: MaterialApp(theme: AppTheme.light, home: entry.value()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
    });
  }
}
