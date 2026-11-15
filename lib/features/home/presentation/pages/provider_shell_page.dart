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
import 'package:flutter_tcc/features/home/presentation/widgets/service_order_ticket.dart';

/// Uma ordem pronta para a lista: o ticket, a etapa em que está e se é a
/// vez do profissional agir.
typedef _Order = ({OrderStage stage, bool myTurn, Widget ticket});

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

  /// A etapa escolhida no filtro das ordens; sem escolha, mostra todas.
  OrderStage? _orderFilter;
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
              
              const SizedBox(height: AppSpacing.xl),
              _buildOrdersSection(quoteState),
              const SizedBox(height: AppSpacing.xs),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProviderTipsPage()),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white, // Fundo branco mescla com a imagem
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFBBF7D0), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Mascote Segurando a Estrela
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(15),
                              bottomLeft: Radius.circular(15),
                            ),
                            child: SizedBox(
                              width: 120, // Largura fixa
                              height: 140, // Altura fixa
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8, bottom: 8, left: 4),
                                child: Image.asset(
                                  'assets/images/joberto_thumbsup.png',
                                  fit: BoxFit.contain, // Contain no fundo branco fica perfeito
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Conteúdo
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(LucideIcons.sparkles, color: Color(0xFF16A34A), size: 16),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          'Dicas do Joberto!',
                                          style: AppTypography.body.copyWith(
                                            fontWeight: FontWeight.w900,
                                            color: const Color(0xFF16A34A),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Veja o segredo para prestar um serviço 5 estrelas e ter agenda cheia!',
                                    style: AppTypography.caption.copyWith(
                                      color: const Color(0xFF475569),
                                      fontWeight: FontWeight.w600,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Text(
                                        'Ver dicas de ouro',
                                        style: AppTypography.caption.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(LucideIcons.arrow_right, size: 14, color: Color(0xFF0F172A)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
                const SizedBox(height: 48),


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
                decoration: BoxDecoration(color: const Color(0xFF1C574A).withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(LucideIcons.circle_check, color: Colors.grey[800], size: 48),
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
                        backgroundColor: const Color(0xFF1C574A),
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

  /// O número curto da ordem.
  ///
  /// O servidor ainda não numera os pedidos; até lá o código sai do fim do
  /// identificador do pedido. O contrato usa o mesmo identificador, então a
  /// ordem mantém o número enquanto muda de etapa.
  static String _orderCode(String id) {
    final clean = id.replaceAll(RegExp('[^A-Za-z0-9]'), '');
    final tail = clean.length <= 4 ? clean : clean.substring(clean.length - 4);
    return tail.toUpperCase();
  }

  static final _money = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');

  /// Pedido novo, à espera da resposta do profissional.
  ///
  /// Com [request], é um pedido real; sem ele, a demonstração de sempre. O
  /// desenho não muda entre os dois.
  _Order _newOrder(JobbleQuoteState quoteState, {QuoteRequest? request}) {
    final lucas = quoteState.isQuoteSent;

    return (
      stage: OrderStage.request,
      myTurn: true,
      ticket: ServiceOrderTicket(
        code: request != null
            ? _orderCode(request.id)
            : (lucas ? '0143' : '0142'),
        note: request != null
            ? _elapsed(request.createdAt)
            : (lucas ? 'Há 12 min' : 'Há 5 min'),
        stamp: 'Nova',
        tone: OrderTone.yourTurn,
        stage: OrderStage.request,
        title:
            request?.title ??
            (lucas ? 'Pintura de Fachada e Muro' : 'Pintura Residencial (20m²)'),
        client: request?.client.display ?? (lucas ? 'Lucas Silva' : 'Gabriel'),
        place: request != null
            ? null
            : (lucas ? 'Bairro Pinheiros' : 'Bairro Jardim Botânico'),
        stub: Row(
          children: [
            SizedBox(
              width: 104,
              child: TicketSecondaryButton(
                label: 'Recusar',
                onPressed: request != null
                    ? () => _declineRequest(request)
                    : _showDeclineJobConfirmation,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: TicketPrimaryButton(
                label: 'Analisar pedido',
                trailingIcon: LucideIcons.arrow_right,
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
              ),
            ),
          ],
        ),
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

  _Order _serviceOrder({ServiceContract? contract}) {
    final colors = context.colors;

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

    return (
      stage: OrderStage.service,
      myTurn: false,
      ticket: ServiceOrderTicket(
        code: contract == null
            ? '0139'
            : _orderCode(
                contract.proposal?.quoteRequestId ?? contract.proposalId,
              ),
        note: period,
        stamp: 'Em execução',
        tone: OrderTone.running,
        stage: OrderStage.service,
        title: contract?.title ?? 'Reparo de Infiltração',
        client: contract?.client.display ?? 'Mariana',
        place: contract == null ? 'R. das Flores, 123' : null,
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ProviderJobTrackerPage(),
            ),
          );
          // As etapas podem ter mudado lá dentro; a barra é recalculada.
          if (mounted) setState(() {});
        },
        stub: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  schedule != null ? 'Prazo do serviço' : 'Progresso do serviço',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.textBody,
                  ),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (schedule != null) ...[
              // Acompanhamento por data: barra, que é o que mostra o tempo
              // correndo. Uma régua de passos aqui ficaria parada enquanto os
              // dias passam.
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: schedule,
                  backgroundColor: colors.surfaceStrong,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.inverse),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _scheduleNote(contract!),
                style: AppTypography.caption.copyWith(
                  fontSize: 11,
                  color: colors.textSecondary,
                ),
              ),
            ] else
              // Mesmos passos da tela de acompanhamento, sem os nomes: aqui o
              // ticket só precisa mostrar onde o serviço está.
              ServiceStepper(steps: JobProgress.tasks, showLabels: false),
            const SizedBox(height: AppSpacing.sm),
            // O ticket inteiro já abre o acompanhamento, mas nada na tela
            // dizia isso: a ferramenta de publicar fotos e comentários do
            // andamento ficava escondida atrás de um toque sem convite.
            _buildProgressToolHint(),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TicketSecondaryButton(
                    label: 'Mensagem',
                    icon: LucideIcons.message_circle,
                    onPressed: () {
                      final conversationId = contract?.conversationId;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => conversationId != null
                              ? QuoteChatPage(
                                  conversationId: conversationId,
                                  counterpartName: contract!.client.display,
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
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: TicketPrimaryButton(
                    label: 'Finalizar',
                    icon: LucideIcons.circle_check,
                    onPressed: () =>
                        _showFinishJobConfirmation(contract: contract),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// As ordens de serviço do painel: pedidos novos, orçamentos em negociação
  /// e serviços em execução numa lista só.
  ///
  /// As que esperam o profissional vêm primeiro, e os números dos filtros
  /// saem do tamanho das listas, não de valores escritos à mão: some um
  /// pedido, o contador acompanha. As ordens locais de demonstração entram na
  /// mesma conta, porque também estão na tela.
  Widget _buildOrdersSection(JobbleQuoteState quoteState) {
    final requestsCubit = _requestsCubit;
    final contractsCubit = _contractsCubit;
    if (requestsCubit == null || contractsCubit == null) {
      return _buildOrders(quoteState);
    }

    return BlocBuilder<QuoteRequestsCubit, QuoteRequestsState>(
      bloc: requestsCubit,
      builder: (context, requests) =>
          BlocBuilder<ServiceContractsCubit, ServiceContractsState>(
            bloc: contractsCubit,
            builder: (context, contracts) => _buildOrders(
              quoteState,
              requests: requests,
              contracts: contracts,
            ),
          ),
    );
  }

  Widget _buildOrders(
    JobbleQuoteState quoteState, {
    QuoteRequestsState? requests,
    ServiceContractsState? contracts,
  }) {
    final colors = context.colors;

    final orders = <_Order>[
      for (final request in requests?.waiting ?? const <QuoteRequest>[])
        _newOrder(quoteState, request: request),
      if (!_isPendingJobDeclined) _newOrder(quoteState),

      // Pedidos que já tiveram retorno do profissional — uma mensagem ou o
      // orçamento — e ainda não viraram contrato. É também onde o orçamento
      // assinado pelo cliente volta, para o profissional confirmar.
      for (final request in requests?.inProgress ?? const <QuoteRequest>[])
        _quoteOrder(quoteState, request: request),
      if (quoteState.isQuoteSent && !quoteState.isClientSigned)
        _quoteOrder(quoteState),

      for (final contract in contracts?.inProgress ?? const <ServiceContract>[])
        _serviceOrder(contract: contract),
      if (!_isJobFinished) _serviceOrder(),
      if (quoteState.isClientSigned && !_isGabrielJobFinished)
        _gabrielServiceOrder(quoteState),
    ];

    final waitingForMe = orders.where((order) => order.myTurn).length;
    final sorted = [
      ...orders.where((order) => order.myTurn),
      ...orders.where((order) => !order.myTurn),
    ];
    final filter = _orderFilter;
    final visible = filter == null
        ? sorted
        : sorted.where((order) => order.stage == filter).toList();

    int count(OrderStage stage) =>
        orders.where((order) => order.stage == stage).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ordens de serviço',
                style: AppTypography.h2.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                switch (waitingForMe) {
                  0 => orders.isEmpty ? 'Nenhuma ordem aberta' : 'Tudo em dia',
                  1 => '1 esperando você',
                  _ => '$waitingForMe esperando você',
                },
                style: AppTypography.caption.copyWith(
                  color: waitingForMe > 0
                      ? colors.accentText
                      : colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              _buildOrderFilter('Todas', orders.length, null),
              _buildOrderFilter(
                'Novas',
                count(OrderStage.request),
                OrderStage.request,
              ),
              _buildOrderFilter(
                'Orçamento',
                count(OrderStage.quote),
                OrderStage.quote,
              ),
              _buildOrderFilter(
                'Execução',
                count(OrderStage.service),
                OrderStage.service,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.lg,
            ),
            child: Text(
              orders.isEmpty
                  ? 'Quando um cliente pedir um orçamento, a ordem aparece '
                        'aqui. Fique aberto para receber pedidos.'
                  : 'Nenhuma ordem nesta etapa.',
              style: AppTypography.bodySmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
          )
        else
          for (final order in visible)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: order.ticket,
            ),
      ],
    );
  }

  Widget _buildOrderFilter(String label, int count, OrderStage? stage) {
    final colors = context.colors;
    final selected = _orderFilter == stage;

    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: Material(
        color: selected ? colors.inverse : colors.surface,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? colors.inverse : colors.borderStrong,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => setState(() => _orderFilter = stage),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              '$label $count',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: selected ? colors.onInverse : colors.textBody,
              ),
            ),
          ),
        ),
      ),
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
    return const Color(0xFF475569);
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

  /// A ordem em negociação: o profissional já respondeu e o contrato ainda
  /// não abriu.
  ///
  /// Com [request], é um pedido real. Ele tem três momentos, e o ticket muda
  /// só o carimbo, o texto e o botão principal entre eles: mensagem enviada
  /// sem orçamento ainda, orçamento à espera da assinatura do cliente, e —
  /// depois que o cliente assina — a vez do profissional confirmar, que é o
  /// que abre o contrato.
  _Order _quoteOrder(JobbleQuoteState quoteState, {QuoteRequest? request}) {
    final colors = context.colors;
    final proposal = request?.latestProposal;
    final clientName = request?.client.display ?? 'Gabriel';

    // Depois que o cliente assina, quem a ordem espera é o próprio
    // profissional: o carimbo deixa de ser de espera e vira convite.
    final myTurn = proposal?.awaitsProvider ?? false;
    final needsQuote = request != null && proposal == null;
    final statusColor = _awaitingColor(request, proposal);

    final items = proposal != null ? _itemsOf(proposal) : quoteState.items;
    final total = proposal?.amount ?? quoteState.total;
    final deadline = proposal != null
        ? '${proposal.deadlineDays} dias úteis'
        : quoteState.prazoEntrega;
    final warranty = proposal != null
        ? '${proposal.warrantyDays} dias'
        : quoteState.garantia;
    final notes = proposal?.notes ?? quoteState.observacoes;

    return (
      stage: OrderStage.quote,
      myTurn: myTurn,
      ticket: ServiceOrderTicket(
        code: request != null ? _orderCode(request.id) : '0142',
        note: request == null ? 'Enviado hoje' : _elapsed(request.createdAt),
        stamp: myTurn ? 'Sua vez' : 'Aguardando',
        tone: myTurn ? OrderTone.yourTurn : OrderTone.waiting,
        stage: OrderStage.quote,
        title: request?.title ?? quoteState.serviceTitle,
        client: request != null ? clientName : quoteState.clientName,
        place: request != null ? null : quoteState.clientAddress,
        stub: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!needsQuote) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Valor do orçamento',
                          style: AppTypography.caption.copyWith(
                            fontSize: 11.5,
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _money.format(total),
                          style: AppTypography.numeric.copyWith(
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Prazo: $deadline\nGarantia: $warranty',
                    textAlign: TextAlign.right,
                    style: AppTypography.caption.copyWith(
                      fontSize: 11.5,
                      color: colors.textBody,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
            Row(
              children: [
                Icon(
                  _awaitingIcon(request, proposal),
                  size: 14,
                  color: statusColor,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    _awaitingLine(request, proposal, quoteState, clientName),
                    style: AppTypography.caption.copyWith(
                      fontSize: 11.5,
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TicketPrimaryButton(
                    label: myTurn
                        ? 'Assinar'
                        : (needsQuote ? 'Enviar proposta' : 'Ver orçamento'),
                    icon: myTurn
                        ? LucideIcons.pen_tool
                        : (needsQuote
                              ? LucideIcons.file_plus
                              : LucideIcons.file_text),
                    onPressed: () {
                      // Três caminhos, um botão: assinar de volta quando o
                      // cliente já assinou, montar o orçamento quando ainda
                      // não há um, e ver o que foi enviado no resto do tempo.
                      if (proposal != null && proposal.awaitsProvider) {
                        _signProposal(proposal);
                        return;
                      }
                      if (request != null && proposal == null) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ProviderQuoteGeneratorPage(
                              quoteRequest: request,
                            ),
                          ),
                        );
                        return;
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ProviderQuotePreviewPage(
                            items: items,
                            total: total,
                            prazoEntrega: deadline,
                            condicaoPagamento: quoteState.condicaoPagamento,
                            garantia: warranty,
                            observacoes: notes,
                            isReadOnly: true,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                TicketSecondaryButton(
                  icon: LucideIcons.download,
                  tooltip: 'Baixar PDF',
                  onPressed: needsQuote
                      ? null
                      : () {
                          QuotePdfService.generateAndDownloadPdf(
                            items: items,
                            total: total,
                            prazoEntrega: deadline,
                            condicaoPagamento: quoteState.condicaoPagamento,
                            garantia: warranty,
                            observacoes: notes,
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
                ),
                const SizedBox(width: AppSpacing.xs),
                TicketSecondaryButton(
                  icon: LucideIcons.message_circle,
                  tooltip: 'Mensagem',
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
                ),
              ],
            ),

            // Atalho para simular o aceite. Só na demonstração: com pedido de
            // verdade quem assina é o cliente, no app dele.
            if (request == null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: InkWell(
                    onTap: () {
                      quoteState.signByClient();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Row(
                            children: [
                              Icon(
                                LucideIcons.circle_check,
                                color: Colors.white,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Gabriel assinou o contrato! A ordem entrou em execução.',
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
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 8,
                      ),
                      child: Text(
                        'Simular aceite do Gabriel (demonstração)',
                        style: AppTypography.caption.copyWith(
                          fontSize: 11,
                          color: colors.textSecondary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// A ordem de demonstração do Gabriel, depois do aceite simulado.
  _Order _gabrielServiceOrder(JobbleQuoteState quoteState) {
    final colors = context.colors;

    return (
      stage: OrderStage.service,
      myTurn: false,
      ticket: ServiceOrderTicket(
        code: '0142',
        note: '15 Out - 18 Out',
        stamp: 'Em execução',
        tone: OrderTone.running,
        stage: OrderStage.service,
        title: quoteState.serviceTitle,
        client: quoteState.clientName,
        place: quoteState.clientAddress,
        stub: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progresso do serviço',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.textBody,
                  ),
                ),
                Text(
                  '15%',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: 0.15,
                minHeight: 8,
                backgroundColor: colors.surfaceStrong,
                valueColor: AlwaysStoppedAnimation<Color>(colors.inverse),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TicketSecondaryButton(
                    label: 'Mensagem',
                    icon: LucideIcons.message_circle,
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
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: TicketPrimaryButton(
                    label: 'Finalizar',
                    icon: LucideIcons.circle_check,
                    onPressed: _showFinishGabrielConfirmation,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFinishGabrielConfirmation() {
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


  /// Faixa que anuncia o acompanhamento do serviço dentro do card.
  ///
  /// Mostra quantas atualizações já foram publicadas e convida a adicionar a
  /// próxima; o toque leva ao mesmo lugar que o card.
  Widget _buildProgressToolHint() {
    final count = JobProgressUpdates.count;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1C574A).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1C574A).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.camera, size: 16, color: Colors.grey),
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
                    color: Colors.grey[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  JobProgress.tasks.isEmpty
                      ? 'Toque para adicionar fotos e comentários que a Mariana vê'
                      : 'Fotos, comentários e as ${JobProgress.tasks.length} etapas do serviço',
                  style: AppTypography.caption.copyWith(
                    color: Colors.grey[800],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Icon(LucideIcons.chevron_right, size: 16, color: Colors.grey),
        ],
      ),
    );
  }

}
