import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_tcc/core/theme/app_colors.dart';
import 'package:flutter_tcc/core/theme/app_spacing.dart';
import 'package:flutter_tcc/core/theme/app_typography.dart';
import 'package:intl/intl.dart';

import 'package:flutter_tcc/features/requests/presentation/widgets/add_job_step_bottom_sheet.dart';

class ProviderJobTrackerPage extends StatefulWidget {
  const ProviderJobTrackerPage({super.key});

  @override
  State<ProviderJobTrackerPage> createState() => _ProviderJobTrackerPageState();
}

class _ProviderJobTrackerPageState extends State<ProviderJobTrackerPage> {
  double _overallProgress = 0.65;

  final List<Map<String, dynamic>> _steps = [
    {
      'title': 'Compra de materiais',
      'desc':
          'Comprei o cimento e a argamassa necessários para iniciar o trabalho amanhã cedo.',
      'progress': 0.15,
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'hasPhotos': true,
    },
    {
      'title': 'Início da demolição',
      'desc': 'Piso antigo removido com sucesso.',
      'progress': 0.40,
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'hasPhotos': false,
    },
    {
      'title': 'Preparação do contrapiso',
      'desc': 'Contrapiso nivelado e secando.',
      'progress': 0.65,
      'date': DateTime.now().subtract(const Duration(hours: 4)),
      'hasPhotos': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(LucideIcons.arrow_left, color: colors.textPrimary),
          onPressed: () => Navigator.of(
            context,
          ).pop(_overallProgress), // Return new progress
        ),
        title: Text(
          'Progresso do Serviço',
          style: AppTypography.h3.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(colors)),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final step =
                    _steps[_steps.length -
                        1 -
                        index]; // Reverse order (newest first)
                final isFirst = index == 0;
                final isLast = index == _steps.length - 1;
                return _buildTimelineItem(step, isFirst, isLast, colors);
              }, childCount: _steps.length),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddStepModal(context),
        backgroundColor: colors.primary,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: const Text(
          'Nova Atualização',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildHeader(AppColorsTheme colors) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reparo de Infiltração',
                style: AppTypography.h2.copyWith(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Em andamento',
                  style: AppTypography.caption.copyWith(
                    color: Colors.blue[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Cliente: Mariana • R. das Flores, 123',
            style: AppTypography.body.copyWith(color: Colors.grey[700]),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progresso Geral',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Text(
                '${(_overallProgress * 100).toInt()}%',
                style: AppTypography.caption.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _overallProgress,
              minHeight: 12,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    Map<String, dynamic> step,
    bool isFirst,
    bool isLast,
    AppColorsTheme colors,
  ) {
    final date = step['date'] as DateTime;
    final formattedDate = DateFormat("dd/MM 'às' HH:mm").format(date);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: isFirst ? colors.primary : Colors.grey[300],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: Colors.grey[300])),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          // Content card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            step['title'],
                            style: AppTypography.body.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          formattedDate,
                          style: AppTypography.caption.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    if (step['desc'] != null &&
                        step['desc'].toString().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        step['desc'],
                        style: AppTypography.body.copyWith(
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                    if (step['hasPhotos'] == true) ...[
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          _buildMiniPhoto(colors),
                          const SizedBox(width: AppSpacing.sm),
                          _buildMiniPhoto(colors),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Progresso: ${(step['progress'] * 100).toInt()}%',
                        style: AppTypography.caption.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.bold,
                        ),
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

  Widget _buildMiniPhoto(AppColorsTheme colors) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: colors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderLight),
      ),
      child: const Center(
        child: Icon(LucideIcons.image, size: 20, color: Colors.grey),
      ),
    );
  }

  Future<void> _openAddStepModal(BuildContext context) async {
    final result = await AddJobStepBottomSheet.show(context, _overallProgress);
    if (result != null) {
      setState(() {
        _steps.add(result);
        _overallProgress = result['progress'];
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Progresso atualizado com sucesso! O cliente foi notificado.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}
