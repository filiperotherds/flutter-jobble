import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';

import 'package:flutter_tcc/core/theme/app_colors.dart';
import 'package:flutter_tcc/core/theme/app_spacing.dart';
import 'package:flutter_tcc/core/theme/app_typography.dart';
import 'package:flutter_tcc/features/reviews/data/review_models.dart';
import 'package:flutter_tcc/features/reviews/data/reviews_api.dart';
import 'package:flutter_tcc/features/reviews/presentation/bloc/reviews_cubit.dart';
import 'package:flutter_tcc/features/reviews/presentation/widgets/review_card.dart';
import 'package:flutter_tcc/injection_container.dart';

/// Tudo o que disseram sobre o profissional, e o lugar de responder.
///
/// Abrir esta tela marca as avaliações como vistas: quem está lendo já viu, e
/// é isso que apaga o ponto do sino. Responder continua sendo escolha dele —
/// ver não é responder.
class ProviderReviewsPage extends StatefulWidget {
  const ProviderReviewsPage({super.key, this.onlyUnanswered = false});

  /// Aberta pelo sino, a tela começa filtrada no que falta responder.
  final bool onlyUnanswered;

  @override
  State<ProviderReviewsPage> createState() => _ProviderReviewsPageState();
}

class _ProviderReviewsPageState extends State<ProviderReviewsPage> {
  late final ReviewsCubit _cubit;
  late bool _onlyUnanswered = widget.onlyUnanswered;

  @override
  void initState() {
    super.initState();
    _cubit = ReviewsCubit(api: sl<ReviewsApi>())..load();
    // Abriu, leu: o sino apaga.
    _cubit.markRead();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: IconButton(
            icon: Icon(LucideIcons.arrow_left, color: colors.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Avaliações',
            style: AppTypography.h3.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
        ),
        body: BlocConsumer<ReviewsCubit, ReviewsState>(
          listenWhen: (previous, current) => previous.error != current.error,
          listener: (context, state) {
            final error = state.error;
            if (error == null) return;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text(error), backgroundColor: Colors.red[700]),
              );
            context.read<ReviewsCubit>().clearError();
          },
          builder: (context, state) {
            if (state.loading && state.page.items.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            final all = state.page.items;
            final shown = _onlyUnanswered ? state.page.unanswered : all;

            return RefreshIndicator(
              onRefresh: () => context.read<ReviewsCubit>().load(),
              child: ListView(
                padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                children: [
                  _summary(colors, state.page.summary),
                  _filters(colors, state.page),
                  if (shown.isEmpty)
                    _empty(colors)
                  else
                    for (final review in shown)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          0,
                          AppSpacing.md,
                          AppSpacing.md,
                        ),
                        child: ReviewCard(
                          review: review,
                          busy: state.replying == review.id,
                          onReply: (text) =>
                              context.read<ReviewsCubit>().reply(
                                review.id,
                                text,
                              ),
                        ),
                      ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// O mesmo resumo do painel de desempenho: a nota grande, as estrelas e as
  /// barras por nota.
  Widget _summary(AppColorsTheme colors, ReviewSummary summary) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            children: [
              Text(
                summary.total == 0
                    ? '—'
                    : summary.average.toStringAsFixed(1),
                style: AppTypography.h1.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 48,
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < summary.average.round()
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: Colors.orange,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                summary.total == 1
                    ? '1 cliente'
                    : '${summary.total} clientes',
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
                for (var stars = 5; stars >= 1; stars--)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          '$stars',
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Icon(
                          Icons.star_rounded,
                          color: Colors.orange,
                          size: 12,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: summary.fractionOf(stars),
                              backgroundColor: colors.borderLight,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colors.primary,
                              ),
                              minHeight: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filters(AppColorsTheme colors, ReviewsPage page) {
    final pending = page.unanswered.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          _chip(
            colors,
            label: 'Todas (${page.items.length})',
            selected: !_onlyUnanswered,
            onTap: () => setState(() => _onlyUnanswered = false),
          ),
          const SizedBox(width: AppSpacing.sm),
          _chip(
            colors,
            label: 'Sem resposta ($pending)',
            selected: _onlyUnanswered,
            onTap: () => setState(() => _onlyUnanswered = true),
          ),
        ],
      ),
    );
  }

  Widget _chip(
    AppColorsTheme colors, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? colors.primary.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected ? colors.primary : colors.borderLight,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: selected ? colors.primary : colors.textSecondary,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _empty(AppColorsTheme colors) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        children: [
          Icon(LucideIcons.star, size: 48, color: colors.borderLight),
          const SizedBox(height: AppSpacing.md),
          Text(
            _onlyUnanswered
                ? 'Nenhuma avaliação esperando resposta'
                : 'Você ainda não recebeu avaliações',
            textAlign: TextAlign.center,
            style: AppTypography.h3.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _onlyUnanswered
                ? 'Você respondeu todo mundo. Isso aparece no seu perfil.'
                : 'Ao concluir um serviço, o cliente pode avaliar seu '
                      'trabalho — e o que ele escrever aparece aqui.',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Data curta para a lista: "Há 2 dias" diz mais que "20/09" numa avaliação.
String reviewWhen(DateTime moment) {
  final days = DateTime.now().difference(moment).inDays;
  if (days < 1) return 'Hoje';
  if (days == 1) return 'Ontem';
  if (days < 7) return 'Há $days dias';
  if (days < 30) {
    final weeks = days ~/ 7;
    return weeks == 1 ? 'Há 1 semana' : 'Há $weeks semanas';
  }
  if (days < 365) {
    final months = days ~/ 30;
    return months == 1 ? 'Há 1 mês' : 'Há $months meses';
  }
  return DateFormat('dd/MM/yyyy').format(moment);
}
