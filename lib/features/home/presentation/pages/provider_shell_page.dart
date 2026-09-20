import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_tcc/core/widgets/app_tab_bar.dart';
import 'package:flutter_tcc/features/service_flow/provider_flow_home.dart';
import 'package:flutter_tcc/features/service_flow/chat_sections_page.dart';
import 'package:flutter_tcc/features/home/presentation/pages/provider_agenda_page.dart';
import 'package:flutter_tcc/features/profile/presentation/pages/provider_profile_tab.dart';

class ProviderShellPage extends StatefulWidget {
  const ProviderShellPage({super.key});
  @override
  State<ProviderShellPage> createState() => _ProviderShellPageState();
}

class _ProviderShellPageState extends State<ProviderShellPage> {
  int _index = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(
      index: _index,
      children: const [
        ProviderFlowHome(),
        ProviderAgendaPage(),
        ChatSectionsPage(provider: true),
        ProviderProfileTab(),
      ],
    ),
    bottomNavigationBar: AppTabBar(
      currentIndex: _index,
      onSelected: (i) => setState(() => _index = i),
      items: const [
        AppTabItem(icon: LucideIcons.layout_grid, label: 'Painel'),
        AppTabItem(icon: LucideIcons.calendar, label: 'Agenda'),
        AppTabItem(icon: LucideIcons.message_circle, label: 'Chats'),
        AppTabItem(icon: LucideIcons.user, label: 'Perfil'),
      ],
    ),
  );
}
