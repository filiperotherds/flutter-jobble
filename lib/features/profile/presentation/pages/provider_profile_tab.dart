import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tcc/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_tcc/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_tcc/features/auth/presentation/bloc/auth_event.dart';
import 'package:flutter_tcc/core/widgets/profile_avatar.dart';
import 'package:flutter_tcc/features/profile/presentation/pages/provider_edit_profile_page.dart';
import 'package:flutter_tcc/features/profile/presentation/pages/provider_portfolio_page.dart';
import 'package:flutter_tcc/features/profile/presentation/pages/provider_services_catalog_page.dart';
import 'package:flutter_tcc/features/profile/presentation/pages/provider_performance_page.dart';
import 'package:flutter_tcc/features/profile/presentation/pages/provider_settings_page.dart';
import 'package:flutter_tcc/features/home/presentation/pages/provider_agenda_page.dart';

class ProviderProfileTab extends StatelessWidget {
  const ProviderProfileTab({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    final user = state is AuthSuccess ? state.user : null;
    final name = user?.organization?.name ?? user?.name ?? 'Meu perfil';
    void open(Widget page) {
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Meu perfil')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        children: [
          Center(
            child: ProfileAvatar(
              imageUrl: user?.organization?.avatarUrl ?? user?.avatarUrl,
              fallbackName: name,
              size: 80,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Editar perfil'),
            onTap: () => open(const ProviderEditProfilePage()),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Meu portfólio'),
            onTap: () => open(const ProviderPortfolioPage()),
          ),
          ListTile(
            leading: const Icon(Icons.list_alt_outlined),
            title: const Text('Catálogo de serviços'),
            onTap: () => open(const ProviderServicesCatalogPage()),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month_outlined),
            title: const Text('Agenda de serviços'),
            onTap: () => open(const ProviderAgendaPage()),
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Meu desempenho'),
            onTap: () => open(const ProviderPerformancePage()),
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Preferências e segurança'),
            onTap: () => open(const ProviderSettingsPage()),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => context.read<AuthBloc>().add(LogoutRequested()),
            child: const Text('Sair da conta'),
          ),
        ],
      ),
    );
  }
}
