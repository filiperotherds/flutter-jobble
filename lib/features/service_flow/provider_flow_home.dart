import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_tcc/features/home/presentation/pages/service_center_page.dart';
import 'package:flutter_tcc/features/onboarding/presentation/widgets/onboarding_banner.dart';
import 'flow_api.dart';
import 'chat_sections_page.dart';
import 'provider_setup_page.dart';

class ProviderFlowHome extends StatefulWidget {
  const ProviderFlowHome({super.key});
  @override
  State<ProviderFlowHome> createState() => _ProviderFlowHomeState();
}

class _ProviderFlowHomeState extends State<ProviderFlowHome> {
  Json? _settings;
  String? _error;

  /// O erro é falta de perfil/verificação, não falha de rede.
  bool get _blocked {
    final message = _error?.toLowerCase() ?? '';
    return message.contains('permiss') || message.contains('organiza');
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s = object(await FlowApi().get('provider/settings'));
      if (mounted) {
        setState(() {
          _settings = s;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _open(Widget page) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => page),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final s = _settings, r = s == null ? null : object(s['response']);
    return Scaffold(
      appBar: AppBar(title: const Text('Seu trabalho na Jobble')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Seu dia de trabalho',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('Gerencie suas solicitações, horários e serviços.'),
            const SizedBox(height: 20),
            const OnboardingBanner(),
            // Conta sem perfil profissional ainda: o servidor recusa estas
            // configurações, e quem explica o que fazer é o aviso acima.
            if (_error != null && !_blocked)
              TextButton(
                onPressed: _load,
                child: Text('$_error\nTentar novamente'),
              ),
            if (s == null && _error == null)
              const Center(child: CircularProgressIndicator()),
            if (s != null && s['hours'] == null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Complete seu perfil: horários de atendimento',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'Defina os dias e horários em que você está disponível para atender.',
                      ),
                      FilledButton(
                        onPressed: () => _open(const ProviderAttendancePage()),
                        child: const Text('Configurar horários'),
                      ),
                    ],
                  ),
                ),
              ),
            _tile(
              LucideIcons.message_circle,
              'Chats',
              'Responda às solicitações e envie orçamentos',
              const ChatSectionsPage(provider: true),
            ),
            _tile(
              LucideIcons.clock,
              'Horários de atendimento',
              'Dias da semana, janelas de horário e atendimento 24h',
              const ProviderAttendancePage(),
            ),
            _tile(
              LucideIcons.briefcase,
              'Catálogo de serviços',
              'Defina seus serviços e a oferta de urgência',
              const ProviderCatalogPage(),
            ),
            _tile(
              LucideIcons.file_text,
              'Serviços e contratos',
              'Acompanhe os contratos, assinaturas e serviços',
              const ServiceCenterPage(),
            ),
            if (r != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Taxa de resposta · últimos 3 meses',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        r['rate'] == null
                            ? 'Sem solicitações com prazo apurado'
                            : '${((r['rate'] as num) * 100).toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      Text(
                        '${r['answered']} respostas no prazo · ${r['total']} solicitações apuradas\n${r['pending']} aguardando resposta dentro do prazo',
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Uma mensagem ou orçamento em até 24h conta como resposta. Em pedidos urgentes, o prazo é de 3h. Avisos automáticos não contam.',
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _tile(IconData icon, String title, String subtitle, Widget page) =>
      Card(
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Icon(icon),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(LucideIcons.chevron_right),
          onTap: () => _open(page),
        ),
      );
}
