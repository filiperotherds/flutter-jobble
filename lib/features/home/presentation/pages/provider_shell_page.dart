import 'package:flutter/material.dart';
import 'package:flutter_tcc/features/profile/presentation/pages/provider_edit_profile_page.dart';

import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_tcc/core/theme/app_colors.dart';
import 'package:flutter_tcc/core/theme/app_spacing.dart';
import 'package:flutter_tcc/core/theme/app_typography.dart';
import 'package:flutter_tcc/core/widgets/app_tab_bar.dart';

import 'package:flutter_tcc/features/notifications/presentation/pages/provider_notifications_page.dart';
import 'package:flutter_tcc/features/home/presentation/pages/provider_agenda_page.dart';
import 'package:flutter_tcc/features/profile/presentation/pages/provider_services_catalog_page.dart';
import 'package:flutter_tcc/features/profile/presentation/pages/provider_performance_page.dart';
import 'package:flutter_tcc/features/profile/presentation/pages/provider_banking_page.dart';
import 'package:flutter_tcc/features/profile/presentation/pages/provider_transfers_page.dart';
import 'package:flutter_tcc/features/profile/presentation/pages/provider_settings_page.dart';
import 'package:flutter_tcc/features/contracts/presentation/pages/chat_page.dart';

import 'package:flutter_tcc/features/home/presentation/pages/provider_messages_page.dart';
import 'package:flutter_tcc/features/profile/presentation/pages/provider_profile_tab.dart';
import 'package:flutter_tcc/features/requests/presentation/pages/provider_request_detail_page.dart';
import 'package:flutter_tcc/core/state/jobble_quote_state.dart';
import 'package:flutter_tcc/features/requests/presentation/services/quote_pdf_service.dart';
import 'package:flutter_tcc/features/requests/presentation/pages/provider_quote_generator_page.dart';
import 'package:flutter_tcc/features/requests/presentation/pages/provider_job_tracker_page.dart';

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
  double _marianaProgress = 0.65;

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
      bottomNavigationBar: AppTabBar(
        currentIndex: _index,
        onSelected: (i) => setState(() => _index = i),
        items: const [
          AppTabItem(icon: LucideIcons.layout_grid, label: 'Painel'),
          AppTabItem(icon: LucideIcons.trending_up, label: 'Desempenho'),
          AppTabItem(icon: LucideIcons.message_circle, label: 'Mensagens', badge: 1),
          AppTabItem(icon: LucideIcons.user, label: 'Perfil'),
        ],
      ),
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProviderNotificationsPage()),
                );
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    LucideIcons.bell,
                    size: 24,
                    color: colors.textPrimary,
                  ),
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
                        '1',
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
                    color: _acceptingOrders ? Colors.green.withValues(alpha: 0.3) : colors.borderLight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _acceptingOrders ? Colors.green.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _acceptingOrders ? Colors.green : colors.textSecondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 300),
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _acceptingOrders ? Colors.black87 : colors.textSecondary,
                          ),
                          child: Text(
                            _acceptingOrders ? 'Aceitando novos pedidos' : 'Pausado',
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _acceptingOrders = !_acceptingOrders;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 52,
                        height: 32,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: _acceptingOrders ? Colors.green : colors.borderLight,
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

              // Trabalhos em andamento
              if (activeJobs.isNotEmpty) ...[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2563EB),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Trabalhos em andamento (${activeJobs.length})',
                        style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                ...activeJobs.map((card) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: card,
                )),
                SizedBox(height: AppSpacing.sm),
              ],

              // Seção: Aguardando retorno do cliente
              if (quoteState.isQuoteSent && !quoteState.isClientSigned) ...[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF7C3AED),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Aguardando retorno do cliente (1)',
                        style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                _buildAwaitingClientCard(quoteState),
                SizedBox(height: AppSpacing.xl),
              ],

              // Pedidos Pendentes (Aguardando orçamento)
              if (!_isPendingJobDeclined) ...[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEA580C),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Aguardando orçamento (1)',
                        style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                _buildPendingRequestCard(quoteState),
                SizedBox(height: AppSpacing.xl),
              ],

              // Atalhos Rápidos
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  'Atalhos da sua conta',
                  style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: AppSpacing.md),
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
                      _buildShortcutTile('Histórico de Repasses', LucideIcons.dollar_sign, () { Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ProviderTransfersPage())); }),
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

  void _showFinishJobConfirmation() {
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

  Widget _buildPendingRequestCard(JobbleQuoteState quoteState) {
    final title = quoteState.isQuoteSent ? 'Pintura de Fachada e Muro' : 'Pintura Residencial (20m²)';
    final client = quoteState.isQuoteSent ? 'Cliente: Lucas Silva • Bairro Pinheiros' : 'Cliente: Gabriel • Bairro Jardim Botânico';
    final time = quoteState.isQuoteSent ? 'Há 12 min' : 'Há 5 min';

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
                  onPressed: _showDeclineJobConfirmation,
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
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ProviderRequestDetailPage(),
                      ),
                    );
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

  Widget _buildInProgressCard() {
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
            final newProgress = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ProviderJobTrackerPage(),
              ),
            );
            if (newProgress != null && newProgress is double) {
              setState(() {
                _marianaProgress = newProgress;
              });
            }
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
                        '15 Out - 18 Out',
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
                  'Reparo de Infiltração',
                  style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cliente: Mariana • R. das Flores, 123',
                  style: AppTypography.caption.copyWith(color: Colors.grey[700]),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Progresso do Serviço', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[800])),
                    Text('${(_marianaProgress * 100).toInt()}%', style: AppTypography.caption.copyWith(color: Colors.blue, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _marianaProgress,
                    minHeight: 8,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
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
                        onPressed: _showFinishJobConfirmation,
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
  Widget _buildAwaitingClientCard(JobbleQuoteState quoteState) {
    final colors = context.colors;

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
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.clock, size: 13, color: Color(0xFF6D28D9)),
                    SizedBox(width: 4),
                    Text(
                      'Aguardando Gabriel',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6D28D9),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Enviado hoje',
                style: AppTypography.caption.copyWith(color: Colors.grey[600]),
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
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      'R\$ ${quoteState.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF6D28D9),
                      ),
                    ),
                    const Text('•', style: TextStyle(color: Color(0xFFC4B5FD), fontSize: 12)),
                    Text(
                      'Prazo: ${quoteState.prazoEntrega}',
                      style: AppTypography.caption.copyWith(fontSize: 11, color: Colors.grey[800]),
                    ),
                    const Text('•', style: TextStyle(color: Color(0xFFC4B5FD), fontSize: 12)),
                    Text(
                      'Garantia: ${quoteState.garantia}',
                      style: AppTypography.caption.copyWith(fontSize: 11, color: Colors.grey[800]),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(LucideIcons.badge_check, size: 14, color: Colors.green),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Você assinou digitalmente em ${quoteState.providerSignedDate ?? '18/09/2026'}',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Colors.green[800],
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
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ProviderQuotePreviewPage(
                          items: quoteState.items,
                          total: quoteState.total,
                          prazoEntrega: quoteState.prazoEntrega,
                          condicaoPagamento: quoteState.condicaoPagamento,
                          garantia: quoteState.garantia,
                          observacoes: quoteState.observacoes,
                          isReadOnly: true,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(LucideIcons.file_text, size: 16, color: Colors.white),
                  label: const Text(
                    'Ver Orçamento',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
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
                  onPressed: () {
                    QuotePdfService.generateAndDownloadPdf(
                      items: quoteState.items,
                      total: quoteState.total,
                      prazoEntrega: quoteState.prazoEntrega,
                      condicaoPagamento: quoteState.condicaoPagamento,
                      garantia: quoteState.garantia,
                      observacoes: quoteState.observacoes,
                      isProviderSigned: quoteState.isProviderSigned,
                      providerSignedDate: quoteState.providerSignedDate,
                      providerSignaturePoints: quoteState.providerSignaturePoints,
                      isClientSigned: quoteState.isClientSigned,
                      clientSignedDate: quoteState.clientSignedDate,
                      clientSignaturePoints: quoteState.clientSignaturePoints,
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
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ChatPage(
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

          // Atalho interativo para simular aceite
          Center(
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
                                            content: Text('Serviço concluído com sucesso! Repasse agendado.'),
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
}







