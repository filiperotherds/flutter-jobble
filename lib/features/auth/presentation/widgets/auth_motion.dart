import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Faz um item da tela entrar subindo, com um atraso proporcional à posição.
///
/// O atraso mora dentro da própria animação, e não num `Timer`: assim nada
/// fica pendente se a tela fechar no meio da entrada.
class Entrance extends StatefulWidget {
  const Entrance({super.key, required this.index, required this.child});

  /// Ordem de entrada; cada posição espera um pouco mais que a anterior.
  final int index;
  final Widget child;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  static const _stagger = 70;
  static const _travel = 480;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: _travel + widget.index * _stagger),
  );

  late final Animation<double> _progress = CurvedAnimation(
    parent: _controller,
    curve: Interval(
      widget.index * _stagger / (_travel + widget.index * _stagger),
      1,
      curve: Curves.easeOutCubic,
    ),
  );

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _progress.value,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - _progress.value)),
          child: child,
        ),
      ),
    );
  }
}

/// Treme o conteúdo para os lados sempre que [trigger] passa a ter um valor
/// novo — o "não" de um formulário recusado.
class Shake extends StatefulWidget {
  const Shake({super.key, required this.trigger, required this.child});

  /// `null` não treme. Qualquer valor diferente do anterior dispara.
  final Object? trigger;
  final Widget child;

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void didUpdateWidget(Shake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger == null || widget.trigger == oldWidget.trigger) return;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = _controller.value;
        // Três idas e vindas que perdem força até parar no lugar.
        final dx = math.sin(t * math.pi * 6) * 9 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
    );
  }
}
