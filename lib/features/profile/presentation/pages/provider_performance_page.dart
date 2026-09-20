import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_tcc/core/theme/app_colors.dart';
import 'package:flutter_tcc/core/theme/app_spacing.dart';
import 'package:flutter_tcc/core/theme/app_typography.dart';

class ProviderPerformancePage extends StatefulWidget {
  const ProviderPerformancePage({super.key});

  @override
  State<ProviderPerformancePage> createState() =>
      _ProviderPerformancePageState();
}

class _ProviderPerformancePageState extends State<ProviderPerformancePage> {
  String _selectedPeriod = 'Este Mês';
  double _monthlyGoal = 5000.0;
  final double _currentRevenue = 3240.0;

  void _showPeriodFilterModal(AppColorsTheme colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.md),

              const SizedBox(height: AppSpacing.lg),
              Text(
                'Filtrar Desempenho',
                style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.md),
              _buildPeriodOption('Hoje', colors),
              _buildPeriodOption('Esta Semana', colors),
              _buildPeriodOption('Este Mês', colors),
              _buildPeriodOption('Últimos 6 meses', colors),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        );
      },
    );
  }

  void _showEditGoalModal(AppColorsTheme colors) {
    final TextEditingController goalController = TextEditingController(
      text: _monthlyGoal.toInt().toString(),
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
        return Container(
          padding: EdgeInsets.only(bottom: bottomPadding),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Definir Meta Mensal',
                      style: AppTypography.h3.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Qual o valor que você deseja faturar neste mês?',
                  style: AppTypography.body.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: goalController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixText: 'R\$ ',
                    filled: true,
                    fillColor: colors.surfaceLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.borderLight),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final newGoal = double.tryParse(goalController.text);
                      if (newGoal != null && newGoal > 0) {
                        setState(() {
                          _monthlyGoal = newGoal;
                        });
                        Navigator.of(context).pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Salvar Meta',
                      style: AppTypography.h3.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPeriodOption(String title, AppColorsTheme colors) {
    final bool isSelected = _selectedPeriod == title;
    return ListTile(
      title: Text(
        title,
        style: AppTypography.body.copyWith(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? colors.primary : colors.textPrimary,
        ),
      ),
      trailing: isSelected
          ? Icon(LucideIcons.check, color: colors.primary)
          : null,
      onTap: () {
        setState(() {
          _selectedPeriod = title;
        });
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.surfaceLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrow_left, color: colors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Desempenho',
          style: AppTypography.h3.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _showPeriodFilterModal(colors),
            icon: Icon(LucideIcons.calendar, size: 16, color: colors.primary),
            label: Text(
              _selectedPeriod,
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Destaques Horizontais
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: [
                  _buildHighlightCard(
                    colors,
                    'Receita Bruta',
                    'R\$ 3.240',
                    '+12%',
                    true,
                    LucideIcons.wallet,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _buildHighlightCard(
                    colors,
                    'Serviços Feitos',
                    '24',
                    '+5',
                    true,
                    LucideIcons.briefcase,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _buildHighlightCard(
                    colors,
                    'Tempo Médio',
                    '15 min',
                    '-2m',
                    true,
                    LucideIcons.clock,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Meta Mensal
            _buildGoalCard(colors),
            const SizedBox(height: AppSpacing.lg),

            // Gráfico de Barras (Receita)
            _buildBarChart(colors),
            const SizedBox(height: AppSpacing.lg),

            // Funil de Conversão
            _buildFunnelCard(colors),
            const SizedBox(height: AppSpacing.lg),

            // Avaliações
            _buildRatingsBreakdown(colors),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightCard(
    AppColorsTheme colors,
    String title,
    String value,
    String change,
    bool isPositive,
    IconData icon,
  ) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: colors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.textSecondary, size: 20),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: AppTypography.caption.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.h2.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isPositive
                    ? LucideIcons.trending_up
                    : LucideIcons.trending_down,
                color: isPositive ? colors.primary : Colors.red,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                change,
                style: AppTypography.caption.copyWith(
                  color: isPositive ? colors.primary : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(AppColorsTheme colors) {
    final double percent = (_currentRevenue / _monthlyGoal).clamp(0.0, 1.0);
    final String percentStr = (percent * 100).toInt().toString();

    return InkWell(
      onTap: () => _showEditGoalModal(colors),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colors.primary, colors.primary.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Meta do Mês',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        LucideIcons.pencil,
                        color: Colors.white70,
                        size: 14,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'R\$ ${_currentRevenue.toInt()} / R\$ ${_monthlyGoal.toInt()}',
                    style: AppTypography.h3.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Você está no caminho certo para bater sua meta! Continue assim.',
                    style: AppTypography.caption.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(
                    value: percent,
                    strokeWidth: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),
                Text(
                  '$percentStr%',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFunnelCard(AppColorsTheme colors) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Funil de Conversão',
            style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildFunnelRow(
            'Visitas no Perfil',
            '1.240',
            1.0,
            colors.borderLight,
            colors.textPrimary,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildFunnelRow(
            'Orçamentos Solicitados',
            '124',
            0.6,
            colors.primary.withValues(alpha: 0.4),
            colors.textPrimary,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildFunnelRow(
            'Serviços Fechados',
            '24',
            0.25,
            colors.primary,
            Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildFunnelRow(
    String title,
    String value,
    double percent,
    Color barColor,
    Color textColor,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            title,
            style: AppTypography.caption.copyWith(color: Colors.black87),
          ),
        ),
        Expanded(
          flex: 3,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                height: 32,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 8),
                width: constraints.maxWidth * percent,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  value,
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBarChart(AppColorsTheme colors) {
    final List<Map<String, dynamic>> data = [
      {'day': 'Seg', 'value': 0.3},
      {'day': 'Ter', 'value': 0.5},
      {'day': 'Qua', 'value': 0.8},
      {'day': 'Qui', 'value': 0.4},
      {'day': 'Sex', 'value': 1.0},
      {'day': 'Sáb', 'value': 0.9},
      {'day': 'Dom', 'value': 0.2},
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
              Text(
                'Receita Diária',
                style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                _selectedPeriod,
                style: AppTypography.caption.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            height: 180,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((d) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (d['value'] == 1.0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Max',
                          style: AppTypography.caption.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    Container(
                      width: 28,
                      height: 120 * (d['value'] as double),
                      decoration: BoxDecoration(
                        color: d['value'] == 1.0
                            ? colors.primary
                            : colors.borderLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      d['day'],
                      style: AppTypography.caption.copyWith(
                        color: colors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingsBreakdown(AppColorsTheme colors) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumo de Avaliações',
            style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                children: [
                  Text(
                    '4.9',
                    style: AppTypography.h1.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 48,
                    ),
                  ),
                  Row(
                    children: List.generate(
                      5,
                      (index) => const Icon(
                        LucideIcons.star,
                        color: Colors.orange,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '42 clientes',
                    style: AppTypography.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.xl),
              Expanded(
                child: Column(
                  children: [
                    _buildRatingBar('5', 0.85, colors),
                    _buildRatingBar('4', 0.10, colors),
                    _buildRatingBar('3', 0.05, colors),
                    _buildRatingBar('2', 0.0, colors),
                    _buildRatingBar('1', 0.0, colors),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(String stars, double percent, AppColorsTheme colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            stars,
            style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold),
          ),
          const Icon(LucideIcons.star, color: Colors.orange, size: 12),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent,
                backgroundColor: colors.borderLight,
                valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                minHeight: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
