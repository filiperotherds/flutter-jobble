import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import 'package:flutter_tcc/core/theme/app_colors.dart';
import 'package:flutter_tcc/core/theme/app_spacing.dart';
import 'package:flutter_tcc/core/theme/app_typography.dart';
import 'package:flutter_tcc/features/portfolio/data/portfolio_models.dart';
import 'package:flutter_tcc/features/portfolio/presentation/widgets/portfolio_media_view.dart';

/// Um trabalho aberto em tela cheia.
///
/// A mídia ocupa o alto, no formato que o profissional escolheu, e o texto vem
/// embaixo. Serve aos dois apps: quem é dono ganha o botão de apagar, quem
/// está escolhendo um profissional só lê.
class PortfolioDetailPage extends StatelessWidget {
  const PortfolioDetailPage({
    super.key,
    required this.item,
    this.onDelete,
    this.authorName,
  });

  final PortfolioItem item;

  /// Só o dono apaga. Nulo do lado do cliente.
  final Future<void> Function()? onDelete;

  final String? authorName;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(LucideIcons.arrow_left, color: colors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          item.kind.label,
          style: AppTypography.h3.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        actions: [
          if (onDelete != null)
            IconButton(
              tooltip: 'Excluir trabalho',
              icon: Icon(LucideIcons.trash_2, color: colors.error, size: 20),
              onPressed: () => _confirmDelete(context),
            ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          AspectRatio(
            aspectRatio: item.kind == PortfolioKind.video ? 9 / 16 : 4 / 3,
            child: PortfolioMediaView(item: item),
          ),
          if (item.kind == PortfolioKind.beforeAfter)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                0,
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.chevrons_left_right,
                    size: 14,
                    color: colors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Arraste a régua para comparar',
                    style: AppTypography.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTypography.h2.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                if (authorName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    authorName!,
                    style: AppTypography.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
                if (item.description != null &&
                    item.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    item.description!,
                    style: AppTypography.body.copyWith(
                      color: colors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir este trabalho?'),
        content: const Text(
          'As fotos e o vídeo saem do seu portfólio e deixam de aparecer '
          'para quem visita seu perfil.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Voltar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await onDelete!();
    if (context.mounted) Navigator.of(context).pop(true);
  }
}
