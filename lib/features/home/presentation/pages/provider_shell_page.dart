import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter_tcc/core/network/api_exception.dart';
import 'package:flutter_tcc/features/quotes/data/quote_models.dart';
import 'package:flutter_tcc/features/quotes/data/quotes_api.dart';
import 'package:flutter_tcc/features/reviews/data/reviews_api.dart';
import 'package:flutter_tcc/features/quotes/presentation/bloc/conversations_cubit.dart';
import 'package:flutter_tcc/features/quotes/presentation/bloc/quote_requests_cubit.dart';
import 'package:flutter_tcc/features/quotes/presentation/bloc/service_contracts_cubit.dart';
import 'package:flutter_tcc/features/quotes/presentation/pages/quote_chat_page.dart';
import 'package:flutter_tcc/injection_container.dart';
import 'package:flutter_tcc/features/home/presentation/pages/provider_tips_page.dart';
import 'package:flutter_tcc/features/profile/presentation/pages/provider_edit_profile_page.dart';

import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_tcc/core/network/api_exception.dart';
import 'package:flutter_tcc/core/theme/app_colors.dart';
import 'package:flutter_tcc/features/home/data/datasources/provider_availability_api.dart';
import 'package:flutter_tcc/core/theme/app_spacing.dart';
import 'package:flutter_tcc/core/theme/app_typography.dart';
import 'package:flutter_tcc/core/widgets/app_tab_bar.dart';

import 'package:flutter_tcc/features/notifications/presentation/pages/provider_notifications_page.dart';
import 'package:flutter_tcc/features/home/presentation/pages/provider_agenda_page.dart';
import 'package:flutter_tcc/features/profile/presentation/pages/provider_services_catalog_page.dart';
import 'package:flutter_tcc/features/profile/presentation/pages/provider_performance_page.dart';
import 'package:flutter_tcc/features/profile/presentation/pages/provider_settings_page.dart';
import 'package:flutter_tcc/features/contracts/presentation/pages/chat_page.dart';

import 'package:flutter_tcc/features/home/presentation/pages/provider_messages_page.dart';
import 'package:flutter_tcc/features/profile/presentation/pages/provider_profile_tab.dart';
import 'package:flutter_tcc/features/requests/presentation/pages/provider_request_detail_page.dart';
import 'package:flutter_tcc/core/state/jobble_quote_state.dart';
import 'package:flutter_tcc/features/requests/presentation/services/quote_pdf_service.dart';
import 'package:flutter_tcc/features/requests/presentation/pages/provider_quote_generator_page.dart';
import 'package:flutter_tcc/features/requests/domain/job_progress.dart';
import 'package:flutter_tcc/features/requests/domain/job_progress_updates.dart';
import 'package:flutter_tcc/features/requests/presentation/pages/provider_job_tracker_page.dart';
import 'package:flutter_tcc/features/requests/presentation/widgets/service_stepper.dart';

class ProviderShellPage extends StatefulWidget {
  const ProviderShellPage({super.key});

  @override
  State<ProviderShellPage> createState() => _ProviderShellPageState();
}

class _ProviderShellPageState extends State<ProviderShellPage> {
  int _index = 0;
  bool _acceptingOrders = true;
  bool _isJobFinished = false;
  bool _isGabrielJobFinished = false;
  bool _isPendingJobDeclined = false;
  /// Calculado a partir das etapas concluídas e do prazo — ver [JobProgress].
  double get _marianaProgress => JobProgress.value;

  /// Criada sob demanda: em teste de widget não há service locator montado,
  /// e a tela precisa desenhar mesmo assim.
  ProviderAvailabilityApi? _availabilityApi;

  ProviderAvailabilityApi get _availability =>
      _availabilityApi ??= ProviderAvailabilityApi();

  /// Enquanto o servidor não respondeu, o botão não aceita toque: alternar
  /// antes disso sobrescreveria o estado real com o palpite da tela.
  bool _availabilityLoading = true;

  /// Pedidos, conversas e contratos de verdade. Criados sob demanda porque os
  /// testes de tela montam o painel sem service locator.
  /// Avaliações que o profissional ainda não abriu. É o número do sino.
  int _unreadReviews = 0;

  QuoteRequestsCubit? _requestsCubit;
  ConversationsCubit? _conversationsCubit;
  ServiceContractsCubit? _contractsCubit;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
    _startLiveData();
    _loadUnreadReviews();
  }

  Future<void> _loadUnreadReviews() async {
    try {
      final count = await sl<ReviewsApi>().unreadCount();
      if (mounted) setState(() => _unreadReviews = count);
    } catch (_) {
      // Sem servidor, o sino fica apagado em vez de mentir um número.
    }
  }

  /// Liga as consultas ao servidor. Falhar aqui nao pode derrubar o painel:
  /// sem service locator (teste de tela) ele desenha so o que e local.
  void _startLiveData() {
    try {
      _requestsCubit = sl<QuoteRequestsCubit>()
        ..load()
        ..startPolling();
      _conversationsCubit = sl<ConversationsCubit>()
        ..load()
        ..startPolling();
      _contractsCubit = sl<ServiceContractsCubit>()
        ..load()
        ..startPolling();
    } catch (_) {
      // Segue local.
    }
  }

  @override
  void dispose() {
    _requestsCubit?.close();
    _conversationsCubit?.close();
    _contractsCubit?.close();
    super.dispose();
  }

  Future<void> _loadAvailability() async {
    try {
      final acceptingOrders = await _availability.get();
      if (!mounted) return;
      setState(() {
        _acceptingOrders = acceptingOrders;
        _availabilityLoading = false;
      });
    } catch (_) {
      // Sem servidor, o painel continua utilizável; o botão é que não promete
      // um estado que ninguém guardou.
      if (mounted) setState(() => _availabilityLoading = false);
    }
  }

  /// Abre ou fecha o prestador. A tela vira na hora e volta atrás se o
  /// servidor recusar, para não mostrar "Aberto" a quem está fechado.
  Future<void> _toggleAvailability() async {
    if (_availabilityLoading) return;

    final desired = !_acceptingOrders;
    setState(() {
      _acceptingOrders = desired;
      _availabilityLoading = true;
    });

    try {
      final saved = await _availability.set(acceptingOrders: desired);
      if (!mounted) return;
      setState(() {
        _acceptingOrders = saved;
        _availabilityLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _acceptingOrders = !desired;
        _availabilityLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is ApiException
                ? error.message
                : 'Não consegui salvar seu status agora.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          _buildProviderHome(),
          const ProviderPerformancePage(),
          const ProviderMessagesPage(),
          const ProviderProfileTab(),
        ],
      ),
      // O ponto na aba de mensagens é o número real de mensagens não lidas:
      // sem nenhuma, não há ponto. Um marcador fixo ensina a pessoa a
      // ignorá-lo, que é o contrário do que ele serve.
      bottomNavigationBar: _conversationsCubit == null
          ? _tabBar(0)
          : BlocBuilder<ConversationsCubit, ConversationsState>(
              bloc: _conversationsCubit,
              builder: (context, state) => _tabBar(state.unreadTotal),
            ),
    );
  }

  Widget _tabBar(int unread) {
    return AppTabBar(
      currentIndex: _index,
      onSelected: (i) => setState(() => _index = i),
      items: [
        const AppTabItem(icon: LucideIcons.layout_grid, label: 'Painel'),
        const AppTabItem(icon: LucideIcons.trending_up, label: 'Desempenho'),
        AppTabItem(
          icon: LucideIcons.message_circle,
          label: 'Mensagens',
          badge: unread,
        ),
        const AppTabItem(icon: LucideIcons.user, label: 'Perfil'),
      ],
    );
  }

  Widget _buildProviderHome() {
    final colors = context.colors;
    
    return Scaffold(
      backgroundColor: Colors.white, // Fundo do app
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // Remove a setinha padrão de voltar
        toolbarHeight: 80,
        title: Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ProviderEditProfilePage(),
                  ),
                );
              },
              child: const CircleAvatar(
                radius: 20, // Igual o avatar do cliente
                backgroundImage: AssetImage('assets/images/logo_pintor.jpg'),
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Olá, Roberto!',
                    style: AppTypography.h3.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
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
            // Botão para voltar ao modo cliente (estilo igual ao building_2)
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colors.surfaceLight,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.borderLight),
                ),
                child: Icon(
                  LucideIcons.user,
                  size: 14,
                  color: colors.textPrimary,
                ),
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            // Sino de notificações (estilo igual ao do cliente)
            GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProviderNotificationsPage()),
                );
                // Ler as avaliações lá dentro apaga o ponto aqui.
                _loadUnreadReviews();
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    LucideIcons.bell,
                    size: 24,
                    color: colors.textPrimary,
                  ),
                  if (_unreadReviews > 0)
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
                          '$_unreadReviews',
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
            SizedBox(width: AppSpacing.sm), // padding extra na direita igual home
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: JobbleQuoteState.instance,
        builder: (context, _) {
          final quoteState = JobbleQuoteState.instance;

          final activeJobs = <Widget>[];
            if (!_isJobFinished) {
              activeJobs.add(_buildInProgressCard());
            }
            if (quoteState.isClientSigned && !_isGabrielJobFinished) {
              activeJobs.add(_buildGabrielInProgressCard(quoteState));
            }

            // Verde quando aberto, vermelho quando fechado: a cor sozinha já
            // diz o estado, sem depender de ler o rótulo.
            final statusColor = _acceptingOrders ? Colors.green : colors.error;

            return ListView(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            children: [
              // Toggle de Status (Aberto/Fechado)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 300),
                                  style: AppTypography.body.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                  child: Text(
                                    _acceptingOrders ? 'Aberto' : 'Fechado',
                                  ),
                                ),
                                const SizedBox(height: 2),
                                // O que o botão muda de verdade: aberto, o
                                // perfil aparece para quem está buscando;
                                // fechado, ele sai das buscas.
                                Text(
                                  _acceptingOrders
                                      ? 'Aparecendo para quem procura agora'
                                      : 'Fora das buscas até você reabrir',
                                  style: AppTypography.caption.copyWith(
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    GestureDetector(
                      onTap: _toggleAvailability,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 52,
                        height: 32,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: statusColor,
                        ),
                        child: Stack(
                          children: [
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              top: 2,
                              bottom: 2,
                              left: _acceptingOrders ? 22 : 2,
                              right: _acceptingOrders ? 2 : 22,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: AppSpacing.lg),

              
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    gradient: AppColorsTheme.brandGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      // Ícones de fundo estilo Jobble
                      Positioned(
                        right: -10,
                        bottom: -20,
                        child: Transform.rotate(
                          angle: -0.2,
                          child: Icon(
                            LucideIcons.award,
                            size: 110,
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 80,
                        top: -10,
                        child: Transform.rotate(
                          angle: 0.3,
                          child: Icon(
                            LucideIcons.star,
                            size: 60,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                      // Conteúdo
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Preste um serviço 5 estrelas!',
                                  style: AppTypography.h2.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF14300A),
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Um bom atendimento garante ótimas avaliações e mais clientes para você.',
                                  style: AppTypography.caption.copyWith(
                                    color: const Color(0xFF1B4310),
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const ProviderTipsPage()),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0D2506),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Ver dicas de ouro',
                                        style: AppTypography.body.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(LucideIcons.arrow_right, size: 16, color: Colors.white),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Trabalhos em andamento: os contratos do servidor e os cards
              // locais na mesma seção, para o número do título ser a conta
              // certa do que está listado embaixo dele.
              if (_contractsCubit != null)
                BlocBuilder<ServiceContractsCubit, ServiceContractsState>(
                  bloc: _contractsCubit,
                  builder: (context, state) => _buildJobsSection([
                    for (final contract in state.inProgress)
                      _buildInProgressCard(contract: contract),
                    ...activeJobs,
                  ]),
                )
              else
                _buildJobsSection(activeJobs),

              // Aguardando retorno do cliente. Entram aqui os pedidos que já
              // tiveram retorno do profissional — uma mensagem ou o orçamento
              // — e ainda não viraram contrato. É também onde o orçamento
              // assinado pelo cliente volta, para o profissional confirmar.
              if (_requestsCubit != null)
                BlocBuilder<QuoteRequestsCubit, QuoteRequestsState>(
                  bloc: _requestsCubit,
                  builder: (context, state) {
                    return _buildAwaitingSection(quoteState, [
                      for (final request in state.inProgress)
                        _buildAwaitingClientCard(quoteState, request: request),
                    ]);
                  },
                )
              else
                _buildAwaitingSection(quoteState, const []),

              // Pedidos de orçamento aguardando resposta.
              if (_requestsCubit != null)
                BlocBuilder<QuoteRequestsCubit, QuoteRequestsState>(
                  bloc: _requestsCubit,
                  builder: (context, state) {
                    return _buildPendingSection(quoteState, [
                      for (final request in state.waiting)
                        _buildPendingRequestCard(quoteState, request: request),
                    ]);
                  },
                )
              else
                _buildPendingSection(quoteState, const []),

              // Atalhos Rápidos
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  'Atalhos da sua conta',
                  textAlign: TextAlign.center,
                  style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: AppSpacing.xl),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Material(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey[200]!),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _buildShortcutTile('Meu Catálogo e Preços', LucideIcons.list, () { Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ProviderServicesCatalogPage())); }),
                      const Divider(height: 1),
                      _buildShortcutTile('Desempenho e Avaliações', LucideIcons.star, () { Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ProviderPerformancePage())); }),

                      const Divider(height: 1),
                      _buildShortcutTile('Configurações do Perfil', LucideIcons.settings, () { Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ProviderSettingsPage())); }),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Encerra o serviço no servidor.
  ///
  /// É esta chamada que faz "Serviços Feitos" andar no painel de desempenho e
  /// libera o cliente para avaliar. Sem contrato real — no card de
  /// demonstração — continua sendo só o estado local de antes.
  Future<void> _finishContract(ServiceContract contract) async {
    try {
      await sl<QuotesApi>().completeContract(contract.id);
      if (!mounted) return;
      await _contractsCubit?.load(silent: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Serviço concluído! O cliente foi convidado a avaliar.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: Colors.red[700]),
      );
    }
  }

  void _showFinishJobConfirmation({ServiceContract? contract}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(AppSpacing.xl),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              SizedBox(height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(LucideIcons.circle_check, color: Colors.blue, size: 48),
              ),
              SizedBox(height: AppSpacing.lg),
              Text('Finalizar Serviço', style: AppTypography.h2.copyWith(fontWeight: FontWeight.bold)),
              SizedBox(height: AppSpacing.sm),
              Text(
                'Tem certeza que deseja marcar este serviço como concluído?\nO cliente Mariana receberá uma notificação para avaliar o seu trabalho.',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(color: Colors.grey[700], height: 1.5),
              ),
              SizedBox(height: AppSpacing.xxl),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text('Cancelar', style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[700])),
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();

                        if (contract != null) {
                          _finishContract(contract);
                          return;
                        }

                        setState(() {
                          _isJobFinished = true;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Trabalho finalizado com sucesso!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text('Sim, Finalizar', style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDashCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 12),
            Text(value, style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(title, style: AppTypography.caption.copyWith(color: Colors.grey[600], fontSize: 10)),
          ],
        ),
      ),
    );
  }

  /// A secao de demonstracao, preservada para as telas que ainda dependem
  /// "Há 5 min" no lugar de uma data: numa fila de pedidos, o que importa é
  /// há quanto tempo a pessoa está esperando.
  static String _elapsed(DateTime moment) {
    final minutes = DateTime.now().difference(moment).inMinutes;
    if (minutes < 1) return 'Agora mesmo';
    if (minutes < 60) return 'Há $minutes min';
    final hours = minutes ~/ 60;
    if (hours < 24) return 'Há $hours h';
    final days = hours ~/ 24;
    return days == 1 ? 'Ontem' : 'Há $days dias';
  }

  Future<void> _declineRequest(QuoteRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recusar este pedido?'),
        content: const Text(
          'O cliente é avisado na conversa e o pedido sai da sua lista.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Voltar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Recusar'),
          ),
        ],
      ),
    );

    if (confirmed == true) await _requestsCubit?.decline(request.id);
  }

  Widget _buildPendingRequestCard(
    JobbleQuoteState quoteState, {
    QuoteRequest? request,
  }) {
    final title = request?.title ??
        (quoteState.isQuoteSent ? 'Pintura de Fachada e Muro' : 'Pintura Residencial (20m²)');
    final client = request != null
        ? 'Cliente: ${request.client.display}'
        : (quoteState.isQuoteSent ? 'Cliente: Lucas Silva • Bairro Pinheiros' : 'Cliente: Gabriel • Bairro Jardim Botânico');
    final time = request != null
        ? _elapsed(request.createdAt)
        : (quoteState.isQuoteSent ? 'Há 12 min' : 'Há 5 min');

    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF97316).withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEA580C).withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFED7AA)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.sparkles, size: 12, color: Color(0xFFC2410C)),
                    SizedBox(width: 4),
                    Text(
                      'Novo Pedido',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFFC2410C),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Text(time, style: AppTypography.caption.copyWith(color: Colors.grey[600])),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            client,
            style: AppTypography.caption.copyWith(color: Colors.grey[700]),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: request != null
                      ? () => _declineRequest(request)
                      : _showDeclineJobConfirmation,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red[600],
                    side: BorderSide(color: Colors.red[200]!),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Recusar', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            ProviderRequestDetailPage(request: request),
                      ),
                    );
                    // Responder ou recusar lá dentro muda a fila daqui.
                    _requestsCubit?.load(silent: true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEA580C),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: const Text('Analisar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// O card de trabalho em andamento.
  ///
  /// Com [contract], mostra o serviço que nasceu das duas assinaturas; sem
  /// ele, a demonstração de sempre. O desenho não muda entre os dois.
  /// A frase embaixo da barra: quantos dias faltam, ou que o prazo venceu.
  /// A barra sozinha diz "mais ou menos ali"; o número diz o que fazer.
  static String _scheduleNote(ServiceContract contract) {
    final days = contract.daysLeft;
    if (days == null) return '';

    final end = DateFormat("dd 'de' MMMM", 'pt_BR').format(contract.endsOn!);
    if (days < 0) {
      final late = -days;
      return late == 1
          ? 'Entrega era ontem ($end)'
          : 'Entrega era há $late dias ($end)';
    }
    if (days == 0) return 'Entrega é hoje ($end)';
    if (days == 1) return 'Falta 1 dia · entrega em $end';
    return 'Faltam $days dias · entrega em $end';
  }

  Widget _buildInProgressCard({ServiceContract? contract}) {
    // O período é o prazo que as duas partes assinaram na proposta. Sem datas
    // combinadas, resta a abertura do contrato.
    final period = contract == null
        ? '15 Out - 18 Out'
        : (contract.startsOn != null && contract.endsOn != null
              ? '${DateFormat("dd MMM", 'pt_BR').format(contract.startsOn!)} - '
                    '${DateFormat("dd MMM", 'pt_BR').format(contract.endsOn!)}'
              : DateFormat("dd MMM", 'pt_BR').format(contract.startedAt));

    // Sem etapas marcadas, o andamento é o calendário: a barra caminha
    // sozinha do começo combinado até a entrega. Com etapas, quem manda são
    // elas, e aí o lugar é da régua de passos.
    final schedule = contract?.scheduleProgress;
    final progress = schedule ?? _marianaProgress;
    final title = contract?.title ?? 'Reparo de Infiltração';
    final client = contract != null
        ? 'Cliente: ${contract.client.display}'
        : 'Cliente: Mariana • R. das Flores, 123';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ProviderJobTrackerPage(),
              ),
            );
            // As etapas podem ter mudado lá dentro; a barra é recalculada.
            if (mounted) setState(() {});
          },
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        period,
                        style: AppTypography.caption.copyWith(
                          color: Colors.blue[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text('Em andamento', style: AppTypography.caption.copyWith(color: Colors.blue, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  client,
                  style: AppTypography.caption.copyWith(color: Colors.grey[700]),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      schedule != null ? 'Prazo do Serviço' : 'Progresso do Serviço',
                      style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[800]),
                    ),
                    Text('${(progress * 100).toInt()}%', style: AppTypography.caption.copyWith(color: Colors.blue, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),
                if (schedule != null) ...[
                  // Acompanhamento por data: barra, que é o que mostra o
                  // tempo correndo. Uma régua de passos aqui ficaria parada
                  // enquanto os dias passam.
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: schedule,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _scheduleNote(contract!),
                    style: AppTypography.caption.copyWith(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ] else
                  // Mesmos passos da tela de acompanhamento, sem os nomes: aqui
                  // o card so precisa mostrar onde o servico esta.
                  ServiceStepper(
                    steps: JobProgress.tasks,
                    showLabels: false,
                  ),
                const SizedBox(height: 12),
                // O card inteiro já abria o acompanhamento, mas nada na tela
                // dizia isso: a ferramenta de publicar fotos e comentários do
                // andamento ficava escondida atras de um toque sem convite.
                _buildProgressToolHint(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final conversationId = contract?.conversationId;
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => conversationId != null
                                  ? QuoteChatPage(
                                      conversationId: conversationId,
                                      counterpartName:
                                          contract!.client.display,
                                      counterpartAvatarUrl:
                                          contract.client.avatarUrl,
                                      subtitle: contract.title,
                                      viewerIsClient: false,
                                    )
                                  : const ChatPage(
                                      providerName: 'Mariana',
                                      providerImage: 'assets/images/user2.jpg',
                                    ),
                            ),
                          );
                        },
                        icon: const Icon(LucideIcons.message_circle, size: 16, color: Colors.blue),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.blue),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        label: const Text('Mensagem', style: TextStyle(color: Colors.blue)),
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _showFinishJobConfirmation(contract: contract),
                        icon: const Icon(LucideIcons.circle_check, size: 16, color: Colors.white),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        label: const Text('Finalizar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  /// As seções do painel contam o que mostram.
  ///
  /// O número do título sai do tamanho da lista de cards, e não de um valor
  /// escrito à mão: some um contrato, o título acompanha. Os cards locais de
  /// demonstração entram na mesma conta, porque também são cards na tela.
  Widget _buildJobsSection(List<Widget> cards) {
    if (cards.isEmpty) return const SizedBox.shrink();

    return _buildExpandableSection(
      title: 'Trabalhos em andamento (${cards.length})',
      dotColor: const Color(0xFF2563EB),
      initiallyExpanded: true,
      children: [
        for (final card in cards)
          Padding(
            padding: const EdgeInsets.only(
              bottom: AppSpacing.md,
              left: AppSpacing.md,
              right: AppSpacing.md,
            ),
            child: card,
          ),
      ],
    );
  }

  Widget _buildAwaitingSection(JobbleQuoteState quoteState, List<Widget> live) {
    final cards = [
      ...live,
      if (quoteState.isQuoteSent && !quoteState.isClientSigned)
        _buildAwaitingClientCard(quoteState),
    ];
    if (cards.isEmpty) return const SizedBox.shrink();

    return _buildExpandableSection(
      title: 'Aguardando retorno do cliente (${cards.length})',
      dotColor: const Color(0xFF7C3AED),
      initiallyExpanded: true,
      children: [
        for (final card in cards) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: card,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }

  Widget _buildPendingSection(JobbleQuoteState quoteState, List<Widget> live) {
    final cards = [
      ...live,
      if (!_isPendingJobDeclined) _buildPendingRequestCard(quoteState),
    ];
    if (cards.isEmpty) return const SizedBox.shrink();

    return _buildExpandableSection(
      title: 'Aguardando orçamento (${cards.length})',
      dotColor: const Color(0xFFEA580C),
      initiallyExpanded: true,
      children: [
        for (final card in cards) ...[
          card,
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }

  /// A seção de demonstração de "aguardando retorno", preservada para quando
  /// Uma proposta do servidor não tem itens: o valor é um só. Para as telas
  /// de visualização e de PDF, que foram feitas para uma lista, ela vira um
  /// item único com o nome do serviço.
  static List<Map<String, dynamic>> _itemsOf(Proposal proposal) => [
    {
      'desc': proposal.title,
      'qtd': 1,
      'unit': proposal.amount,
      'type': 'Serviço',
    },
  ];

  IconData _awaitingIcon(QuoteRequest? request, Proposal? proposal) {
    if (request == null) return LucideIcons.badge_check;
    if (proposal == null) return LucideIcons.message_circle;
    return proposal.awaitsProvider ? LucideIcons.badge_check : LucideIcons.clock;
  }

  Color _awaitingColor(QuoteRequest? request, Proposal? proposal) {
    if (request == null) return Colors.green.shade800;
    if (proposal != null && proposal.awaitsProvider) {
      return Colors.green.shade800;
    }
    return const Color(0xFF6D28D9);
  }

  /// A linha que diz em que pé está a negociação, do ponto de vista de quem
  /// executa: esperando resposta, esperando assinatura, ou já podendo assinar.
  String _awaitingLine(
    QuoteRequest? request,
    Proposal? proposal,
    JobbleQuoteState quoteState,
    String clientName,
  ) {
    if (request == null) {
      return 'Você assinou digitalmente em '
          '${quoteState.providerSignedDate ?? '18/09/2026'}';
    }
    if (proposal == null) {
      return 'Mensagem enviada — aguardando a resposta de $clientName';
    }
    if (proposal.awaitsProvider) {
      final signedAt = proposal.clientSignedAt;
      final when = signedAt == null
          ? ''
          : ' em ${DateFormat("dd/MM 'às' HH:mm").format(signedAt)}';
      return '$clientName assinou$when — falta você confirmar';
    }
    return 'Aguardando a assinatura de $clientName';
  }

  /// A segunda assinatura. É ela que abre o contrato.
  Future<void> _signProposal(Proposal proposal) async {
    try {
      final signed = await sl<QuotesApi>().signProposal(proposal.id);
      if (!mounted) return;

      await _requestsCubit?.load(silent: true);
      await _contractsCubit?.load(silent: true);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            signed.isSigned
                ? 'Contrato aberto! O serviço entrou em Trabalhos em andamento.'
                : 'Assinatura registrada.',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// O card de "aguardando retorno do cliente".
  ///
  /// Com [request], é um pedido real que já teve retorno do profissional. Ele
  /// tem três momentos, e o card muda só o texto e o botão principal entre
  /// eles: mensagem enviada sem orçamento ainda, orçamento à espera da
  /// assinatura do cliente, e — depois que o cliente assina — a vez do
  /// profissional confirmar, que é o que abre o contrato.
  Widget _buildAwaitingClientCard(
    JobbleQuoteState quoteState, {
    QuoteRequest? request,
  }) {
    final colors = context.colors;
    final proposal = request?.latestProposal;
    final clientName = request?.client.display ?? 'Gabriel';

    // Depois que o cliente assina, quem o card espera é o próprio
    // profissional: o selo deixa de ser de espera e vira convite.
    final myTurn = proposal?.awaitsProvider ?? false;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFDDD6FE)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      myTurn ? LucideIcons.badge_check : LucideIcons.clock,
                      size: 13,
                      color: const Color(0xFF6D28D9),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      myTurn
                          ? 'Sua vez de assinar'
                          : 'Aguardando $clientName',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6D28D9),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                request == null ? 'Enviado hoje' : _elapsed(request.createdAt),
                style: AppTypography.caption.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            request?.title ?? quoteState.serviceTitle,
            style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            request != null
                ? 'Cliente: $clientName'
                : 'Cliente: ${quoteState.clientName} • ${quoteState.clientAddress}',
            style: AppTypography.caption.copyWith(color: Colors.grey[700]),
          ),
          const SizedBox(height: 12),

          // Painel resumo da proposta enviada
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF5FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEDE9FE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (request == null || proposal != null)
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        proposal != null
                            ? 'R\$ ${proposal.amount.toStringAsFixed(2)}'
                            : 'R\$ ${quoteState.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF6D28D9),
                        ),
                      ),
                      const Text('•', style: TextStyle(color: Color(0xFFC4B5FD), fontSize: 12)),
                      Text(
                        proposal != null
                            ? 'Prazo: ${proposal.deadlineDays} dias úteis'
                            : 'Prazo: ${quoteState.prazoEntrega}',
                        style: AppTypography.caption.copyWith(fontSize: 11, color: Colors.grey[800]),
                      ),
                      const Text('•', style: TextStyle(color: Color(0xFFC4B5FD), fontSize: 12)),
                      Text(
                        proposal != null
                            ? 'Garantia: ${proposal.warrantyDays} dias'
                            : 'Garantia: ${quoteState.garantia}',
                        style: AppTypography.caption.copyWith(fontSize: 11, color: Colors.grey[800]),
                      ),
                    ],
                  ),
                if (request == null || proposal != null)
                  const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      _awaitingIcon(request, proposal),
                      size: 14,
                      color: _awaitingColor(request, proposal),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _awaitingLine(request, proposal, quoteState, clientName),
                        style: TextStyle(
                          fontSize: 10.5,
                          color: _awaitingColor(request, proposal),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Botões de Ação
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Três caminhos, um botão: assinar de volta quando o
                    // cliente já assinou, montar o orçamento quando ainda não
                    // há um, e ver o que foi enviado no resto do tempo.
                    if (proposal != null && proposal.awaitsProvider) {
                      _signProposal(proposal);
                      return;
                    }
                    if (request != null && proposal == null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              ProviderQuoteGeneratorPage(quoteRequest: request),
                        ),
                      );
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ProviderQuotePreviewPage(
                          items: proposal != null
                              ? _itemsOf(proposal)
                              : quoteState.items,
                          total: proposal?.amount ?? quoteState.total,
                          prazoEntrega: proposal != null
                              ? '${proposal.deadlineDays} dias úteis'
                              : quoteState.prazoEntrega,
                          condicaoPagamento: quoteState.condicaoPagamento,
                          garantia: proposal != null
                              ? '${proposal.warrantyDays} dias'
                              : quoteState.garantia,
                          observacoes: proposal?.notes ?? quoteState.observacoes,
                          isReadOnly: true,
                        ),
                      ),
                    );
                  },
                  icon: Icon(
                    myTurn
                        ? LucideIcons.pen_tool
                        : (request != null && proposal == null
                              ? LucideIcons.file_plus
                              : LucideIcons.file_text),
                    size: 16,
                    color: Colors.white,
                  ),
                  label: Text(
                    myTurn
                        ? 'Assinar'
                        : (request != null && proposal == null
                              ? 'Enviar Proposta'
                              : 'Ver Orçamento'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 3,
                child: OutlinedButton.icon(
                  onPressed: proposal == null && request != null
                      ? null
                      : () {
                          QuotePdfService.generateAndDownloadPdf(
                            items: proposal != null
                                ? _itemsOf(proposal)
                                : quoteState.items,
                            total: proposal?.amount ?? quoteState.total,
                            prazoEntrega: proposal != null
                                ? '${proposal.deadlineDays} dias úteis'
                                : quoteState.prazoEntrega,
                            condicaoPagamento: quoteState.condicaoPagamento,
                            garantia: proposal != null
                                ? '${proposal.warrantyDays} dias'
                                : quoteState.garantia,
                            observacoes:
                                proposal?.notes ?? quoteState.observacoes,
                            isProviderSigned: proposal != null
                                ? proposal.providerSignedAt != null
                                : quoteState.isProviderSigned,
                            providerSignedDate: quoteState.providerSignedDate,
                            providerSignaturePoints:
                                quoteState.providerSignaturePoints,
                            isClientSigned: proposal != null
                                ? proposal.clientSignedAt != null
                                : quoteState.isClientSigned,
                            clientSignedDate: quoteState.clientSignedDate,
                            clientSignaturePoints:
                                quoteState.clientSignaturePoints,
                          );
                        },
                  icon: const Icon(LucideIcons.download, size: 16, color: Color(0xFF4C1D95)),
                  label: const Text(
                    'Baixar PDF',
                    style: TextStyle(color: Color(0xFF4C1D95), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFDDD6FE)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              OutlinedButton(
                onPressed: () {
                  final conversationId = request?.conversationId;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => conversationId != null
                          ? QuoteChatPage(
                              conversationId: conversationId,
                              counterpartName: clientName,
                              counterpartAvatarUrl: request!.client.avatarUrl,
                              subtitle: request.title,
                              viewerIsClient: false,
                            )
                          : const ChatPage(
                              providerName: 'Gabriel',
                              providerImage: 'assets/images/user1.jpg',
                            ),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  fixedSize: const Size(44, 44),
                  padding: EdgeInsets.zero,
                  side: const BorderSide(color: Color(0xFFDDD6FE)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Icon(LucideIcons.message_circle, size: 18, color: Color(0xFF6D28D9)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Atalho interativo para simular aceite. Só na demonstração: com
          // pedido de verdade quem assina é o cliente, no app dele.
          if (request == null) Center(
            child: InkWell(
              onTap: () {
                quoteState.signByClient();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(LucideIcons.circle_check, color: Colors.white),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Gabriel assinou o contrato! Serviço iniciado e adicionado em Trabalhos em Andamento.',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 4),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.sparkles, size: 13, color: Color(0xFF7C3AED)),
                    const SizedBox(width: 4),
                    const Text(
                      'Simular aceite do Gabriel (iniciar serviço)',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6D28D9),
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGabrielInProgressCard(JobbleQuoteState quoteState) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '15 Out - 18 Out',
                  style: AppTypography.caption.copyWith(
                    color: Colors.green[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                'Em andamento',
                style: AppTypography.caption.copyWith(
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            quoteState.serviceTitle,
            style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Cliente: ${quoteState.clientName} • ${quoteState.clientAddress}',
            style: AppTypography.caption.copyWith(color: Colors.grey[700]),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Progresso do Serviço', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[800])),
              Text('15%', style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.15,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ChatPage(
                          providerName: 'Gabriel',
                          providerImage: 'assets/images/user1.jpg',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(LucideIcons.message_circle, size: 16, color: Colors.green),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.green),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  label: const Text('Mensagem', style: TextStyle(color: Colors.green)),
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (context) {
                        return Container(
                          padding: EdgeInsets.all(AppSpacing.xl),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                
                              SizedBox(height: AppSpacing.xl),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
                                child: const Icon(LucideIcons.circle_check, color: Colors.green, size: 48),
                              ),
                              SizedBox(height: AppSpacing.lg),
                              Text('Finalizar Serviço', style: AppTypography.h2.copyWith(fontWeight: FontWeight.bold)),
                              SizedBox(height: AppSpacing.sm),
                              Text(
                                'Tem certeza que deseja marcar este serviço de Pintura Residencial como concluído?\nO cliente Gabriel receberá a notificação para liberação do pagamento e avaliação.',
                                textAlign: TextAlign.center,
                                style: AppTypography.body.copyWith(color: Colors.grey[700], height: 1.5),
                              ),
                              SizedBox(height: AppSpacing.xxl),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        side: BorderSide(color: Colors.grey[300]!),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      ),
                                      child: Text('Cancelar', style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[700])),
                                    ),
                                  ),
                                  SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        setState(() {
                                          _isGabrielJobFinished = true;
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Serviço concluído com sucesso!'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        elevation: 0,
                                      ),
                                      child: Text('Sim, Finalizar', style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: AppSpacing.md),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  icon: const Icon(LucideIcons.circle_check, size: 16, color: Colors.white),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  label: const Text('Finalizar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeclineJobConfirmation() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(AppSpacing.xl),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              SizedBox(height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(LucideIcons.x, color: Colors.red, size: 48),
              ),
              SizedBox(height: AppSpacing.lg),
              Text('Recusar Pedido', style: AppTypography.h2.copyWith(fontWeight: FontWeight.bold)),
              SizedBox(height: AppSpacing.sm),
              Text(
                'Tem certeza que deseja recusar este pedido de orçamento?\nO cliente Gabriel será notificado.',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(color: Colors.grey[700], height: 1.5),
              ),
              SizedBox(height: AppSpacing.xxl),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text('Cancelar', style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[700])),
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        setState(() {
                          _isPendingJobDeclined = true;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Pedido de orçamento recusado.'),
                            backgroundColor: Colors.grey,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text('Sim, Recusar', style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShortcutTile(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(title, style: AppTypography.body.copyWith(fontWeight: FontWeight.w500)),
      trailing: const Icon(LucideIcons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }

  Widget _buildPlaceholder(String title) {
    return Center(child: Text(title));
  }

  Widget _buildExpandableSection({
    required String title,
    required Color dotColor,
    required List<Widget> children,
    bool initiallyExpanded = true,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
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
              style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        children: children,
      ),
    );
  }

  /// Faixa que anuncia o acompanhamento do serviço dentro do card.
  ///
  /// Mostra quantas atualizações já foram publicadas e convida a adicionar a
  /// próxima; o toque leva ao mesmo lugar que o card.
  Widget _buildProgressToolHint() {
    final count = JobProgressUpdates.count;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.camera, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count == 0
                      ? 'Publique o andamento do serviço'
                      : count == 1
                      ? '1 atualização publicada'
                      : '$count atualizações publicadas',
                  style: AppTypography.caption.copyWith(
                    color: Colors.blue[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  JobProgress.tasks.isEmpty
                      ? 'Toque para adicionar fotos e comentários que a Mariana vê'
                      : 'Fotos, comentários e as ${JobProgress.tasks.length} etapas do serviço',
                  style: AppTypography.caption.copyWith(
                    color: Colors.blue[700],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Icon(LucideIcons.chevron_right, size: 16, color: Colors.blue[700]),
        ],
      ),
    );
  }

}
