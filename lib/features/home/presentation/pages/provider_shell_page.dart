import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import 'package:flutter_tcc/core/network/api_exception.dart';
import 'package:flutter_tcc/core/theme/app_colors.dart';
import 'package:flutter_tcc/core/theme/app_spacing.dart';
import 'package:flutter_tcc/core/theme/app_typography.dart';
import 'package:flutter_tcc/core/widgets/app_empty_state.dart';
import 'package:flutter_tcc/core/widgets/app_loader.dart';
import 'package:flutter_tcc/core/widgets/app_tab_bar.dart';
import 'package:flutter_tcc/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_tcc/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_tcc/features/bids/data/datasources/bid_remote_data_source.dart';
import 'package:flutter_tcc/features/bids/data/models/org_match_model.dart';
import 'package:flutter_tcc/features/bids/presentation/pages/match_details_page.dart';
import 'package:flutter_tcc/features/contracts/presentation/pages/contract_detail_page.dart';
import 'package:flutter_tcc/features/home/presentation/pages/provider_messages_page.dart';
import 'package:flutter_tcc/features/home/presentation/widgets/provider_job_card.dart';
import 'package:flutter_tcc/features/notifications/data/datasources/notification_remote_data_source.dart';
import 'package:flutter_tcc/features/notifications/presentation/pages/provider_notifications_page.dart';
import 'package:flutter_tcc/features/profile/presentation/pages/provider_edit_profile_page.dart';
import 'package:flutter_tcc/features/profile/presentation/pages/provider_performance_page.dart';
import 'package:flutter_tcc/features/profile/presentation/pages/provider_profile_tab.dart';
import 'package:flutter_tcc/features/profile/presentation/pages/provider_services_catalog_page.dart';
import 'package:flutter_tcc/features/profile/presentation/pages/provider_settings_page.dart';
import 'package:flutter_tcc/features/service_flow/conversation_page.dart';
import 'package:flutter_tcc/features/service_flow/flow_api.dart';
import 'package:flutter_tcc/injection_container.dart';

class ProviderShellPage extends StatefulWidget {
  const ProviderShellPage({super.key});

  @override
  State<ProviderShellPage> createState() => _ProviderShellPageState();
}

class _ProviderShellPageState extends State<ProviderShellPage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          _ProviderPanel(),
          ProviderPerformancePage(),
          ProviderMessagesPage(),
          ProviderProfileTab(),
        ],
      ),
      bottomNavigationBar: AppTabBar(
        currentIndex: _index,
        onSelected: (i) => setState(() => _index = i),
        items: const [
          AppTabItem(icon: LucideIcons.layout_grid, label: 'Painel'),
          AppTabItem(icon: LucideIcons.trending_up, label: 'Desempenho'),
          AppTabItem(icon: LucideIcons.message_circle, label: 'Mensagens'),
          AppTabItem(icon: LucideIcons.user, label: 'Perfil'),
        ],
      ),
    );
  }
}

/// Painel do profissional: o que `GET /matches` devolve, agrupado por etapa.
class _ProviderPanel extends StatefulWidget {
  const _ProviderPanel();

  @override
  State<_ProviderPanel> createState() => _ProviderPanelState();
}

class _ProviderPanelState extends State<_ProviderPanel> {
  final _bids = sl<BidRemoteDataSource>();
  final _notifications = sl<NotificationRemoteDataSource>();
  final _flow = FlowApi();

  List<OrgMatch> _matches = const [];
  int _unread = 0;

  /// Pausar não é um campo do servidor: um profissional sem serviço ativo sai
  /// da busca, então o botão liga e desliga os serviços do catálogo.
  List<Json> _services = const [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  bool get _acceptingOrders =>
      _services.any((s) => s['isActive'] as bool? ?? false);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final matches = await _bids.listMatches();
      final settings = object(await _flow.get('provider/settings'));
      // O contador do sino é acessório: um erro nele não pode esconder o painel.
      var unread = 0;
      try {
        unread = await _notifications.fetchUnreadCount();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _matches = matches;
        _services = objects(settings['services']);
        _unread = unread;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }

  Future<void> _toggleAccepting() async {
    if (_services.isEmpty || _saving) return;
    final next = !_acceptingOrders;
    setState(() => _saving = true);
    try {
      for (final service in _services) {
        await _flow.patch('provider/services/${service['id']}', {
          'templateId': service['templateId'],
          'title': service['title'],
          'description': service['description'],
          'priceCents': service['priceCents'],
          'priceUnit': service['priceUnit'],
          'offersUrgency': service['offersUrgency'] ?? false,
          'isActive': next,
        });
      }
      await _load();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _decline(OrgMatch match) async {
    try {
      await _bids.declineMatch(match.id);
      await _load();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _open(OrgMatch match) async {
    final contractId = match.contract?.id;
    final page = switch (match.stage) {
      JobStage.awaitingResponse => MatchDetailsPage(
        serviceRequestId: match.requestId,
      ),
      _ when contractId != null && contractId.isNotEmpty => ContractDetailPage(
        contractId: contractId,
      ),
      _ => ConversationPage(matchId: match.id, provider: true),
    };
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pending = _matches
        .where((m) => m.stage == JobStage.awaitingResponse)
        .toList();
    final awaitingClient = _matches
        .where((m) => m.stage == JobStage.awaitingClient)
        .toList();
    final active = _matches.where((m) => m.stage.isOpenWork).toList();

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 80,
        title: Row(
          children: [
            GestureDetector(
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ProviderEditProfilePage(),
                  ),
                );
                await _load();
              },
              child: const _ProviderAvatar(),
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BlocBuilder<AuthBloc, AuthState>(
                    buildWhen: (_, state) => state is AuthSuccess,
                    builder: (context, state) {
                      final name = state is AuthSuccess
                          ? (state.user?.organization?.name ??
                                state.user?.name ??
                                '')
                          : '';
                      final first = name.trim().split(RegExp(r'\s+')).first;
                      return Text(
                        first.isEmpty ? 'Olá!' : 'Olá, $first!',
                        style: AppTypography.h3.copyWith(
                          fontWeight: FontWeight.w500,
                          color: colors.textPrimary,
                        ),
                      );
                    },
                  ),
                  Text(
                    'Seu dia de trabalho na Jobble',
                    style: AppTypography.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProviderNotificationsPage(),
                  ),
                );
                await _load();
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(LucideIcons.bell, size: 24, color: colors.textPrimary),
                  if (_unread > 0)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: colors.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          _unread > 9 ? '9+' : '$_unread',
                          style: AppTypography.caption.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: AppSpacing.sm),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const AppLoaderCentered(label: 'Carregando seus trabalhos…')
            : _error != null
            ? AppEmptyState(
                icon: LucideIcons.triangle_alert,
                title: 'Não foi possível carregar o painel',
                description: _error,
                actionLabel: 'Tentar de novo',
                onAction: _load,
              )
            : ListView(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                children: [
                  _statusToggle(colors),
                  SizedBox(height: AppSpacing.lg),
                  if (active.isNotEmpty)
                    _section(
                      title: 'Trabalhos em andamento (${active.length})',
                      dotColor: context.colors.accentText,
                      matches: active,
                    ),
                  if (awaitingClient.isNotEmpty)
                    _section(
                      title:
                          'Aguardando retorno do cliente (${awaitingClient.length})',
                      dotColor: context.colors.textSecondary,
                      matches: awaitingClient,
                    ),
                  if (pending.isNotEmpty)
                    _section(
                      title: 'Aguardando sua resposta (${pending.length})',
                      dotColor: context.colors.accentText,
                      matches: pending,
                      decline: true,
                    ),
                  // Vazio é não ter nada a fazer agora: chamados antigos, já
                  // concluídos ou recusados, não preenchem o painel.
                  if (pending.isEmpty &&
                      awaitingClient.isEmpty &&
                      active.isEmpty)
                    Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: AppEmptyState(
                        icon: LucideIcons.inbox,
                        title: 'Nenhum chamado por enquanto',
                        description: _acceptingOrders
                            ? 'Assim que um cliente pedir um serviço da sua região, ele aparece aqui.'
                            : 'Seus serviços estão pausados, então você não entra na busca dos clientes.',
                      ),
                    ),
                  SizedBox(height: AppSpacing.lg),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Text(
                      'Atalhos da sua conta',
                      style: AppTypography.h3.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.md),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Material(
                      color: context.colors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: colors.borderLight),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          _shortcut(
                            'Meu Catálogo e Preços',
                            LucideIcons.list,
                            const ProviderServicesCatalogPage(),
                          ),
                          const Divider(height: 1),
                          _shortcut(
                            'Desempenho e Avaliações',
                            LucideIcons.star,
                            const ProviderPerformancePage(),
                          ),
                          const Divider(height: 1),
                          _shortcut(
                            'Configurações do Perfil',
                            LucideIcons.settings,
                            const ProviderSettingsPage(),
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

  Widget _statusToggle(AppColorsTheme colors) {
    final on = _acceptingOrders;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.borderLight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: on ? context.colors.accentText : colors.textSecondary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                on ? 'Aceitando novos pedidos' : 'Pausado',
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: on ? colors.textPrimary : colors.textSecondary,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: _services.isEmpty ? null : _toggleAccepting,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 52,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: AppRadius.lgAll,
                color: on ? context.colors.accentText : colors.borderLight,
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    top: 2,
                    bottom: 2,
                    left: on ? 22 : 2,
                    right: on ? 2 : 22,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.colors.surface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({
    required String title,
    required Color dotColor,
    required List<OrgMatch> matches,
    bool decline = false,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        title: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTypography.h3.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        children: [
          for (final match in matches)
            Padding(
              padding: const EdgeInsets.only(
                bottom: AppSpacing.md,
                left: AppSpacing.md,
                right: AppSpacing.md,
              ),
              child: ProviderJobCard(
                match: match,
                onOpen: () => _open(match),
                onDecline: decline ? () => _decline(match) : null,
              ),
            ),
        ],
      ),
    );
  }

  Widget _shortcut(String title, IconData icon, Widget page) {
    return ListTile(
      leading: Icon(icon, color: context.colors.textSecondary),
      title: Text(
        title,
        style: AppTypography.body.copyWith(fontWeight: FontWeight.w500),
      ),
      trailing: Icon(
        LucideIcons.chevron_right,
        color: context.colors.textSecondary,
        size: 20,
      ),
      onTap: () =>
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => page)),
    );
  }
}

/// Avatar da organização, com as iniciais enquanto não há foto.
class _ProviderAvatar extends StatelessWidget {
  const _ProviderAvatar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (_, state) => state is AuthSuccess,
      builder: (context, state) {
        final org = state is AuthSuccess ? state.user?.organization : null;
        final url = org?.avatarUrl;
        if (url != null && url.isNotEmpty) {
          return CircleAvatar(radius: 20, backgroundImage: NetworkImage(url));
        }
        final name = (org?.name ?? '').trim();
        return CircleAvatar(
          radius: 20,
          backgroundColor: context.colors.surfaceLight,
          child: Text(
            name.isEmpty ? '?' : name[0].toUpperCase(),
            style: AppTypography.h3.copyWith(
              fontWeight: FontWeight.w500,
              color: context.colors.textPrimary,
            ),
          ),
        );
      },
    );
  }
}
