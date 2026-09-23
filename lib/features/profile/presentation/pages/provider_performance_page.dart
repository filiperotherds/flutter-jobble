import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_tcc/core/theme/app_colors.dart';
import 'package:flutter_tcc/core/theme/app_spacing.dart';
import 'package:flutter_tcc/core/theme/app_typography.dart';
import 'package:flutter_tcc/features/profile/data/performance_api.dart';
import 'package:flutter_tcc/features/reviews/data/review_models.dart';
import 'package:flutter_tcc/features/reviews/data/reviews_api.dart';
import 'package:flutter_tcc/features/reviews/presentation/pages/provider_reviews_page.dart';
import 'package:flutter_tcc/injection_container.dart';

class ProviderPerformancePage extends StatefulWidget {
  const ProviderPerformancePage({super.key});

  @override
  State<ProviderPerformancePage> createState() => _ProviderPerformancePageState();
}

class _ProviderPerformancePageState extends State<ProviderPerformancePage> {
  /// Os números do servidor. Vazios enquanto carrega ou quando não há dados —
  /// e aí a tela mostra zero, que é a verdade de quem está começando.
  Performance _data = const Performance.empty();
  ReviewSummary _reviews = const ReviewSummary.empty();

  /// O rótulo do filtro, como a tela o mostra, e a chave que o servidor
  /// entende. Andam juntos.
  static const Map<String, String> _periodKeys = {
    'Hoje': 'today',
    'Esta Semana': 'week',
    'Este Mês': 'month',
    'Últimos 6 meses': 'semester',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final period = _periodKeys[_selectedPeriod] ?? 'month';
      final data = await sl<PerformanceApi>().summary(period);
      final reviews = await sl<ReviewsApi>().received();
      if (!mounted) return;
      setState(() {
        _data = data;
        _reviews = reviews.summary;
      });
    } catch (_) {
      // Sem servidor, a tela desenha os zeros em vez de ficar em branco.
    }
  }

  String _selectedPeriod = 'Este Mês';
  double _monthlyServiceGoal = 30.0;
  final double _currentServices = 24.0;

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
              Text('Filtrar Desempenho', style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold)),
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
      trailing: isSelected ? Icon(LucideIcons.check, color: colors.primary) : null,
      onTap: () {
        setState(() {
          _selectedPeriod = title;
        });
        Navigator.of(context).pop();
        _load();
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
        title: Text(
          'Desempenho',
          style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold, color: colors.textPrimary),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _showPeriodFilterModal(colors),
            icon: Icon(LucideIcons.calendar, size: 16, color: colors.primary),
            label: Text(_selectedPeriod, style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold)),
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
                    'Avaliação Média',
                    _data.averageRating.value == 0
                        ? '—'
                        : _data.averageRating.value.toStringAsFixed(1),
                    _data.averageRating.deltaLabel,
                    _data.averageRating.improved,
                    LucideIcons.star,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _buildHighlightCard(
                    colors,
                    'Serviços Feitos',
                    '${_data.servicesDone.value.toInt()}',
                    _data.servicesDone.deltaLabel,
                    _data.servicesDone.improved,
                    LucideIcons.briefcase,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // Aqui cair é bom: menos cancelamento que no período
                  // anterior conta como melhora.
                  _buildHighlightCard(
                    colors,
                    'Serviços Cancelados',
                    '${_data.servicesCancelled.value.toInt()}',
                    _data.servicesCancelled.deltaLabel,
                    _data.servicesCancelled.delta <= 0,
                    Icons.cancel_outlined,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _buildHighlightCard(
                    colors,
                    'Tempo Médio',
                    _data.averageResponseMinutes.value == 0
                        ? '—'
                        : '${_data.averageResponseMinutes.value.toInt()} min',
                    '${_data.averageResponseMinutes.deltaLabel}m',
                    _data.averageResponseMinutes.delta <= 0,
                    LucideIcons.clock,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Gráfico de Barras (Interações)
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

  Widget _buildHighlightCard(AppColorsTheme colors, String title, String value, String change, bool isPositive, IconData icon) {
    bool isTrendUp = !change.startsWith('-');
    return Container(
      width: 140,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: colors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.textSecondary, size: 20),
          const SizedBox(height: AppSpacing.md),
          // Altura fixa para o título para manter o padrão independente se tiver 1 ou 2 linhas
          SizedBox(
            height: 34,
            child: Text(
              title,
              style: AppTypography.caption.copyWith(color: colors.textSecondary, height: 1.2),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: AppTypography.h2.copyWith(fontWeight: FontWeight.bold, color: colors.textPrimary)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(isTrendUp ? LucideIcons.trending_up : LucideIcons.trending_down, color: isPositive ? colors.primary : Colors.red, size: 14),
              const SizedBox(width: 4),
              Text(change, style: AppTypography.caption.copyWith(color: isPositive ? colors.primary : Colors.red, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }



  /// Milhar com ponto, como o funil já mostrava: 1.240.
  static String _number(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  /// A largura de cada faixa do funil, proporcional ao topo. A primeira ocupa
  /// tudo; as de baixo mostram quanto sobrou dela.
  double _funnelWidth(int value) {
    final top = _data.funnel.profileViews;
    if (top <= 0) return value > 0 ? 1.0 : 0.08;
    // Um mínimo visível: faixa com valor não pode sumir na borda.
    return (value / top).clamp(0.08, 1.0);
  }

  Widget _buildFunnelCard(AppColorsTheme colors) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderLight),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Funil de Conversão', style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.lg),
          _buildFunnelRow(
            'Visitas no Perfil',
            _number(_data.funnel.profileViews),
            _funnelWidth(_data.funnel.profileViews),
            colors.borderLight,
            colors.textPrimary,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildFunnelRow(
            'Orçamentos Solicitados',
            _number(_data.funnel.quoteRequests),
            _funnelWidth(_data.funnel.quoteRequests),
            colors.primary.withOpacity(0.4),
            colors.textPrimary,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildFunnelRow(
            'Serviços Fechados',
            _number(_data.funnel.closedServices),
            _funnelWidth(_data.funnel.closedServices),
            colors.primary,
            Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildFunnelRow(String title, String value, double percent, Color barColor, Color textColor) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(title, style: AppTypography.caption.copyWith(color: Colors.black87)),
        ),
        Expanded(
          flex: 3,
          child: LayoutBuilder(builder: (context, constraints) {
            return Container(
              height: 32,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 8),
              width: constraints.maxWidth * percent,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(value, style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: textColor)),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildBarChart(AppColorsTheme colors) {
    // A barra mais alta é o pico do próprio período: com pouco movimento, o
    // gráfico ainda mostra em que dias ele aconteceu.
    final peak = _data.peakInteractions;
    final List<Map<String, dynamic>> data = [
      for (final day in _data.dailyInteractions)
        {
          'day': day.weekday,
          'value': day.value,
          'percent': peak == 0 ? 0.0 : day.value / peak,
        },
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderLight),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Interações Diárias', style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold)),
              Text(_selectedPeriod, style: AppTypography.caption.copyWith(color: colors.textSecondary)),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            height: 180,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((d) {
                final bool isMax = peak > 0 && d['percent'] == 1.0;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: isMax ? Colors.black87 : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${d['value']}',
                        style: AppTypography.caption.copyWith(
                          color: isMax ? Colors.white : colors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      width: 28,
                      height: 120 * (d['percent'] as double),
                      decoration: BoxDecoration(
                        color: isMax ? colors.primary : colors.borderLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(d['day'], style: AppTypography.caption.copyWith(color: colors.textSecondary, fontSize: 11)),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const ProviderReviewsPage(),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Resumo de Avaliações', style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold)),
              ),
              // O resumo é a porta para os comentários: quem olha a nota
              // quer ler o que foi dito, e responder.
              Text(
                'Ver comentários',
                style: AppTypography.caption.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(LucideIcons.chevron_right, size: 16, color: colors.primary),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                children: [
                  Text(
                    _reviews.total == 0 ? '—' : _reviews.average.toStringAsFixed(1),
                    style: AppTypography.h1.copyWith(fontWeight: FontWeight.bold, fontSize: 48),
                  ),
                  Row(
                    children: List.generate(5, (index) => const Icon(Icons.star_rounded, color: Colors.orange, size: 18)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _reviews.total == 1 ? '1 cliente' : '${_reviews.total} clientes',
                    style: AppTypography.caption.copyWith(color: colors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.xl),
              Expanded(
                child: Column(
                  children: [
                    for (var stars = 5; stars >= 1; stars--)
                      _buildRatingBar('$stars', _reviews.fractionOf(stars), colors),
                  ],
                ),
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildRatingBar(String stars, double percent, AppColorsTheme colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(stars, style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold)),
          const Icon(Icons.star_rounded, color: Colors.orange, size: 12),
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


