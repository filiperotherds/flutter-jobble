import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_tcc/core/theme/app_colors.dart';
import 'package:flutter_tcc/core/theme/app_spacing.dart';
import 'package:flutter_tcc/core/theme/app_typography.dart';

class ProviderNotificationsPage extends StatelessWidget {
  const ProviderNotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrow_left, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Notificações',
          style: AppTypography.h3.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: Text(
              'Limpar',
              style: AppTypography.caption.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        children: [
          _buildDateHeader('Hoje'),
          _buildNotificationItem(
            icon: LucideIcons.file_text,
            iconColor: Colors.green,
            iconBg: Colors.green[50]!,
            title: 'Orçamento Aprovado',
            message:
                'O cliente Gabriel aprovou seu orçamento para Pintura Residencial.',
            time: '14:35',
            isUnread: true,
            colors: colors,
          ),
          _buildNotificationItem(
            icon: LucideIcons.wallet,
            iconColor: Colors.blue,
            iconBg: Colors.blue[50]!,
            title: 'Pagamento em Custódia',
            message:
                'O valor de R\$ 790,00 foi retido e está garantido na plataforma.',
            time: '14:40',
            isUnread: true,
            colors: colors,
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildDateHeader('Ontem'),
          _buildNotificationItem(
            icon: LucideIcons.map_pin,
            iconColor: Colors.orange,
            iconBg: Colors.orange[50]!,
            title: 'Nova Solicitação Próxima',
            message:
                'Um cliente próximo a você está buscando por Reparo de Infiltração.',
            time: '18:00',
            isUnread: false,
            colors: colors,
          ),
          _buildNotificationItem(
            icon: LucideIcons.circle_check,
            iconColor: Colors.grey[700]!,
            iconBg: Colors.grey[100]!,
            title: 'Perfil Verificado',
            message:
                'Seus documentos foram validados e seu perfil está 100% ativo.',
            time: '09:00',
            isUnread: false,
            colors: colors,
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Text(
        text,
        style: AppTypography.caption.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String message,
    required String time,
    required bool isUnread,
    required AppColorsTheme colors,
  }) {
    return Container(
      color: isUnread
          ? colors.primary.withValues(alpha: 0.05)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: AppTypography.body.copyWith(
                        fontWeight: isUnread
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: isUnread ? Colors.black : Colors.grey[800],
                      ),
                    ),
                    Text(
                      time,
                      style: AppTypography.caption.copyWith(
                        color: isUnread ? colors.primary : Colors.grey[500],
                        fontWeight: isUnread
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: AppTypography.caption.copyWith(
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
