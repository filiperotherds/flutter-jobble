import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_tcc/core/theme/app_colors.dart';
import 'package:flutter_tcc/core/theme/app_spacing.dart';
import 'package:flutter_tcc/core/theme/app_typography.dart';
import 'package:flutter_tcc/features/profile/presentation/pages/provider_portfolio_page.dart';
import 'package:flutter_tcc/features/profile/presentation/pages/provider_edit_profile_page.dart';
import 'package:flutter_tcc/features/profile/presentation/pages/provider_services_catalog_page.dart';
import 'package:flutter_tcc/features/profile/presentation/pages/provider_performance_page.dart';
import 'package:flutter_tcc/features/profile/presentation/pages/provider_banking_page.dart';
import 'package:flutter_tcc/features/profile/presentation/pages/provider_settings_page.dart';
import 'package:flutter_tcc/features/home/presentation/pages/provider_agenda_page.dart';

class ProviderProfileTab extends StatelessWidget {
  const ProviderProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
                    // Capa (Cover Image)
          Stack(
            children: [
              SizedBox(
                height: 160,
                width: double.infinity,
                child: Image.asset(
                  'assets/images/intro_bg.jpeg',
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 16 + MediaQuery.of(context).padding.top, // Add top padding to account for status bar since there's no appbar
                right: 16,
                child: IconButton(
                  style: IconButton.styleFrom(backgroundColor: Colors.black.withOpacity(0.4)),
                  icon: const Icon(LucideIcons.pencil, color: Colors.white),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const ProviderEditProfilePage()),
                    );
                  },
                ),
              ),
            ],
          ),
          
          // Header com foto e nome
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 36,
                  backgroundImage: AssetImage('assets/images/logo_pintor.jpg'),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Roberto Pinturas e Reformas',
                        style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'São Paulo, SP',
                        style: AppTypography.caption.copyWith(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 16, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text(
                            '5.0 (42 avaliações)',
                            style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppSpacing.md),

          // Cards de métricas rápidas
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Trabalhos',
                    value: '124',
                    icon: LucideIcons.briefcase,
                    colors: colors,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Avaliação',
                    value: '4.9',
                    icon: LucideIcons.star,
                    colors: colors,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppSpacing.md),

          // Menu de Opções
          Column(
            children: [
              _buildMenuItem(
                icon: LucideIcons.image,
                title: 'Meu Portfólio',
                subtitle: 'Adicione fotos dos seus trabalhos',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const ProviderPortfolioPage()),
                  );
                },
              ),
              const Divider(height: 1, indent: 56),
              _buildMenuItem(
                icon: LucideIcons.list,
                title: 'Catálogo de Serviços',
                subtitle: 'Gerencie seus preços e serviços',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const ProviderServicesCatalogPage()),
                  );
                },
              ),
              const Divider(height: 1, indent: 56),
              _buildMenuItem(
                icon: Icons.calendar_today_rounded,
                title: 'Agenda',
                subtitle: 'Controle seus compromissos',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const ProviderAgendaPage()),
                  );
                },
              ),
              const Divider(height: 1, indent: 56),
              _buildMenuItem(
                icon: LucideIcons.credit_card,
                title: 'Dados Bancários',
                subtitle: 'Onde você recebe seus pagamentos',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const ProviderBankingPage()),
                  );
                },
              ),
              const Divider(height: 1, indent: 56),
              _buildMenuItem(
                icon: LucideIcons.settings,
                title: 'Configurações',
                subtitle: 'Notificações, privacidade e conta',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const ProviderSettingsPage()),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // Botão de sair
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: ElevatedButton.icon(
              onPressed: () {
                // Desloga o prestador
              },
              icon: const Icon(LucideIcons.log_out, color: Colors.red),
              label: const Text('Sair da conta', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[50],
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildMetricCard({required String title, required String value, required IconData icon, required AppColorsTheme colors}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: colors.textSecondary),
              const SizedBox(width: AppSpacing.sm),
              Text(title, style: AppTypography.caption.copyWith(color: colors.textSecondary)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMenuItem({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.black87, size: 20),
      ),
      title: Text(title, style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: AppTypography.caption.copyWith(color: Colors.grey[600])),
      trailing: const Icon(LucideIcons.chevron_right, size: 20, color: Colors.grey),
      onTap: onTap,
    );
  }
  Widget _buildServiceInline(BuildContext context, String title, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTypography.body.copyWith(fontWeight: FontWeight.w500)),
          Text(price, style: AppTypography.caption.copyWith(color: Colors.grey[600])),
        ],
      ),
    );
  }
}


