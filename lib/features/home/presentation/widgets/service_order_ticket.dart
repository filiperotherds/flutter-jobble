import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import 'package:flutter_tcc/core/theme/app_colors.dart';
import 'package:flutter_tcc/core/theme/app_spacing.dart';
import 'package:flutter_tcc/core/theme/app_typography.dart';

/// Em que ponto do caminho a ordem está: do pedido ao serviço. [done] é o
/// serviço entregue, com o caminho todo percorrido.
enum OrderStage { request, quote, service, done }

/// De quem é a vez. É o que decide a cor da faixa do ticket.
enum OrderTone {
  /// O profissional precisa agir: responder, orçar ou assinar.
  yourTurn,

  /// A bola está com o cliente.
  waiting,

  /// Serviço contratado, em execução.
  running,

  /// Ordem encerrada: entregue ou cancelada.
  closed,
}

/// Uma ordem de serviço desenhada como um ticket.
///
/// Em cima, o cabeçalho com o número da ordem e o carimbo da situação; no
/// meio, o serviço e o caminho que a ordem já percorreu; depois do picote, o
/// canhoto com os valores e as ações. A borda de baixo é serrilhada, como a
/// de um bloco destacado.
class ServiceOrderTicket extends StatelessWidget {
  const ServiceOrderTicket({
    super.key,
    required this.code,
    required this.note,
    required this.stamp,
    required this.tone,
    required this.title,
    required this.client,
    required this.stub,
    this.stage,
    this.place,
    this.avatar,
    this.clientIcon = LucideIcons.user,
    this.stampColor,
    this.onTap,
  });

  /// O número curto da ordem, sem o prefixo.
  final String code;

  /// A data ou o tempo de espera, ao lado do carimbo.
  final String note;
  final String stamp;
  final OrderTone tone;

  /// Sem etapa, o caminho não aparece — numa ordem cancelada, por exemplo.
  final OrderStage? stage;
  final String title;

  /// Quem está do outro lado: o cliente, no app do profissional, e o
  /// profissional, no app do cliente.
  final String client;
  final IconData clientIcon;
  final String? place;

  /// Foto ou logo de quem está do outro lado, ao lado do título.
  final Widget? avatar;

  /// Troca a cor do carimbo — o vermelho de um cancelamento, por exemplo.
  final Color? stampColor;

  /// O canhoto: o que fica abaixo do picote.
  final Widget stub;
  final VoidCallback? onTap;

  static const _paper = Color(0xFFF8F9F2);
  static const _paperEdge = Color(0xFFD9DED6);
  static const _waitingBand = Color(0xFFEDEFE6);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final (band, onBand, stampColor, edge) = switch (tone) {
      OrderTone.yourTurn => (
        colors.primary,
        colors.onPrimary,
        colors.onPrimary,
        colors.inverse,
      ),
      OrderTone.waiting => (
        _waitingBand,
        colors.textPrimary,
        colors.textSecondary,
        _paperEdge,
      ),
      OrderTone.running => (
        colors.inverse,
        colors.onInverse,
        colors.primary,
        _paperEdge,
      ),
      OrderTone.closed => (
        _waitingBand,
        colors.textSecondary,
        colors.textSecondary,
        _paperEdge,
      ),
    };
    final stamp = this.stampColor ?? stampColor;

    final ticket = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TicketPiece(
          top: true,
          fill: _paper,
          edge: edge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: band,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'OS · $code',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          color: onBand,
                        ),
                      ),
                    ),
                    Text(
                      note,
                      style: AppTypography.caption.copyWith(color: onBand),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _Stamp(label: this.stamp, color: stamp),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (avatar case final avatar?) ...[
                          SizedBox.square(dimension: 42, child: avatar),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: AppTypography.h3.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: AppSpacing.sm,
                                runSpacing: 4,
                                children: [
                                  _Detail(icon: clientIcon, text: client),
                                  if (place case final place?)
                                    _Detail(
                                      icon: LucideIcons.map_pin,
                                      text: place,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (stage case final stage?) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _StageTrack(stage: stage),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        _TicketPiece(
          top: false,
          fill: _paper,
          edge: edge,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md + _TicketPiece.tooth,
            ),
            child: stub,
          ),
        ),
      ],
    );

    if (onTap == null) return ticket;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ticket,
    );
  }
}

/// A ação principal do canhoto.
class TicketPrimaryButton extends StatelessWidget {
  const TicketPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
  });

  final String label;
  final IconData? icon;
  final IconData? trailingIcon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: colors.inverse,
        foregroundColor: colors.onInverse,
        disabledBackgroundColor: colors.disabled,
        disabledForegroundColor: colors.onDisabled,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.smAll),
        textStyle: AppTypography.button.copyWith(fontSize: 13.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 16), const SizedBox(width: 6)],
          Flexible(
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          if (trailingIcon != null) ...[
            const SizedBox(width: 6),
            Icon(trailingIcon, size: 16),
          ],
        ],
      ),
    );
  }
}

/// A ação secundária do canhoto. Sem [label], é um botão só de ícone.
class TicketSecondaryButton extends StatelessWidget {
  const TicketSecondaryButton({
    super.key,
    required this.onPressed,
    this.label,
    this.icon,
    this.tooltip,
  }) : assert(label != null || icon != null);

  final String? label;
  final IconData? icon;
  final String? tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final iconOnly = label == null;

    final button = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        disabledForegroundColor: colors.onDisabled,
        side: BorderSide(color: colors.borderStrong),
        minimumSize: Size(iconOnly ? 44 : 0, 44),
        fixedSize: iconOnly ? const Size(44, 44) : null,
        padding: iconOnly
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.smAll),
        textStyle: AppTypography.button.copyWith(fontSize: 13.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, size: iconOnly ? 18 : 16),
          if (icon != null && !iconOnly) const SizedBox(width: 6),
          if (label case final label?)
            Flexible(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
        ],
      ),
    );

    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: colors.textSecondary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: AppTypography.caption.copyWith(color: colors.textBody),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// O carimbo da situação, levemente torto, como batido à mão.
class _Stamp extends StatelessWidget {
  const _Stamp({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.07,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 1.5),
          borderRadius: AppRadius.xsAll,
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
            color: color,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}

/// Os três furos do caminho: pedido, orçamento e serviço.
class _StageTrack extends StatelessWidget {
  const _StageTrack({required this.stage});

  final OrderStage stage;

  static const _labels = ['Pedido', 'Orçamento', 'Serviço'];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final current = stage.index;

    return Row(
      children: [
        for (var i = 0; i < _labels.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 1.5,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                color: i <= current ? colors.inverse : colors.borderStrong,
              ),
            ),
          Container(
            width: 15,
            height: 15,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < current
                  ? colors.inverse
                  : (i == current ? colors.primary : Colors.transparent),
              border: Border.all(
                color: i <= current ? colors.inverse : colors.borderStrong,
                width: 1.5,
              ),
            ),
            child: i < current
                ? Icon(LucideIcons.check, size: 9, color: colors.onInverse)
                : null,
          ),
          const SizedBox(width: 5),
          Text(
            _labels[i],
            style: AppTypography.caption.copyWith(
              fontSize: 11.5,
              fontWeight: i == current ? FontWeight.w700 : FontWeight.w500,
              color: i <= current ? colors.textPrimary : colors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

/// Uma das duas metades do ticket: a de cima, com os cantos arredondados, ou
/// o canhoto, com a borda serrilhada. As duas se encontram no picote, onde
/// cada uma tem meio recorte de cada lado.
class _TicketPiece extends StatelessWidget {
  const _TicketPiece({
    required this.top,
    required this.fill,
    required this.edge,
    required this.child,
  });

  final bool top;
  final Color fill;
  final Color edge;
  final Widget child;

  static const corner = 14.0;
  static const notch = 8.0;
  static const tooth = 6.0;

  /// O contorno da metade, sem a linha do picote. É só ele que é traçado: a
  /// borda de baixo do canhoto segue os dentes, sem reta por baixo.
  static Path outline(Size size, {required bool top}) {
    final w = size.width;
    final h = size.height;
    const cut = Radius.circular(notch);

    if (top) {
      const round = Radius.circular(corner);
      return Path()
        ..moveTo(notch, h)
        ..arcToPoint(Offset(0, h - notch), radius: cut, clockwise: false)
        ..lineTo(0, corner)
        ..arcToPoint(const Offset(corner, 0), radius: round)
        ..lineTo(w - corner, 0)
        ..arcToPoint(Offset(w, corner), radius: round)
        ..lineTo(w, h - notch)
        ..arcToPoint(Offset(w - notch, h), radius: cut, clockwise: false);
    }

    final teeth = math.max(4, (w / 12).round());
    final step = w / teeth;
    final path = Path()
      ..moveTo(w - notch, 0)
      ..arcToPoint(Offset(w, notch), radius: cut, clockwise: false)
      ..lineTo(w, h - tooth);
    for (var i = 0; i < teeth; i++) {
      final x = w - i * step;
      path
        ..lineTo(x - step / 2, h)
        ..lineTo(x - step, h - tooth);
    }
    return path
      ..lineTo(0, notch)
      ..arcToPoint(const Offset(notch, 0), radius: cut, clockwise: false);
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FillPainter(top: top, color: fill),
      foregroundPainter: _EdgePainter(top: top, color: edge),
      child: ClipPath(
        clipper: _PieceClipper(top: top),
        child: child,
      ),
    );
  }
}

class _PieceClipper extends CustomClipper<Path> {
  const _PieceClipper({required this.top});

  final bool top;

  @override
  Path getClip(Size size) => _TicketPiece.outline(size, top: top)..close();

  @override
  bool shouldReclip(_PieceClipper oldClipper) => oldClipper.top != top;
}

class _FillPainter extends CustomPainter {
  const _FillPainter({required this.top, required this.color});

  final bool top;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      _TicketPiece.outline(size, top: top)..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_FillPainter oldDelegate) =>
      oldDelegate.top != top || oldDelegate.color != color;
}

class _EdgePainter extends CustomPainter {
  const _EdgePainter({required this.top, required this.color});

  final bool top;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    canvas.drawPath(_TicketPiece.outline(size, top: top), stroke);

    // O picote: tracejado entre os dois recortes, no alto do canhoto.
    if (top) return;
    const dash = 5.0;
    const gap = 4.0;
    final end = size.width - _TicketPiece.notch - 4;
    for (var x = _TicketPiece.notch + 4; x < end; x += dash + gap) {
      canvas.drawLine(Offset(x, 0), Offset(math.min(x + dash, end), 0), stroke);
    }
  }

  @override
  bool shouldRepaint(_EdgePainter oldDelegate) =>
      oldDelegate.top != top || oldDelegate.color != color;
}
