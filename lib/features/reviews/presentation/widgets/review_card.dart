import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import 'package:flutter_tcc/core/theme/app_colors.dart';
import 'package:flutter_tcc/core/theme/app_spacing.dart';
import 'package:flutter_tcc/core/theme/app_typography.dart';
import 'package:flutter_tcc/features/reviews/data/review_models.dart';
import 'package:flutter_tcc/features/reviews/presentation/pages/provider_reviews_page.dart'
    show reviewWhen;

/// Um comentário recebido e, embaixo, a resposta do profissional.
///
/// Sem resposta ainda, o card abre um campo no lugar dela: responder é a ação
/// natural de quem está lendo o que disseram do seu trabalho, e escondê-la
/// atrás de outra tela só aumenta a chance de ninguém responder.
class ReviewCard extends StatefulWidget {
  const ReviewCard({
    super.key,
    required this.review,
    required this.onReply,
    this.busy = false,
  });

  final Review review;

  /// Devolve `true` quando a resposta foi aceita pelo servidor.
  final Future<bool> Function(String reply) onReply;

  final bool busy;

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  final TextEditingController _controller = TextEditingController();
  bool _composing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final ok = await widget.onReply(text);
    if (!mounted) return;
    if (ok) {
      _controller.clear();
      setState(() => _composing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final review = widget.review;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: review.unread ? colors.primary : colors.borderLight,
          width: review.unread ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: colors.primary,
                child: Text(
                  review.author.display.characters.first.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            review.author.display,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.body.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        if (review.unread) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Nova',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      reviewWhen(review.createdAt),
                      style: AppTypography.caption.copyWith(
                        color: colors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${review.rating}',
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[800],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            review.comment,
            style: AppTypography.body.copyWith(
              color: colors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (review.answered)
            _ReplyBlock(review: review, colors: colors)
          else
            _composer(colors),
        ],
      ),
    );
  }

  Widget _composer(AppColorsTheme colors) {
    if (!_composing) {
      return Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: () => setState(() => _composing = true),
          icon: Icon(LucideIcons.reply, size: 16, color: colors.primary),
          label: Text(
            'Responder',
            style: TextStyle(
              color: colors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            side: BorderSide(color: colors.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          maxLines: 3,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Escreva sua resposta para ${widget.review.author.display}...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.primary, width: 2),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.busy
                    ? null
                    : () => setState(() => _composing = false),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: colors.borderLight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Cancelar',
                  style: TextStyle(color: colors.textSecondary),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ElevatedButton(
                onPressed: widget.busy ? null : _send,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: widget.busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Enviar resposta',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A resposta já publicada, recuada como uma réplica.
class _ReplyBlock extends StatelessWidget {
  const _ReplyBlock({required this.review, required this.colors});

  final Review review;
  final AppColorsTheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: colors.primary, width: 3),
          top: BorderSide(color: colors.borderLight),
          right: BorderSide(color: colors.borderLight),
          bottom: BorderSide(color: colors.borderLight),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.reply, size: 13, color: colors.primary),
              const SizedBox(width: 4),
              Text(
                'Sua resposta',
                style: AppTypography.caption.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              if (review.repliedAt != null)
                Text(
                  reviewWhen(review.repliedAt!),
                  style: AppTypography.caption.copyWith(
                    color: colors.textSecondary,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            review.reply!,
            style: AppTypography.caption.copyWith(
              color: colors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
