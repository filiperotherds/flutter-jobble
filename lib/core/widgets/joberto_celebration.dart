import 'package:flutter/material.dart';

import 'package:flutter_tcc/core/theme/app_typography.dart';
import 'package:flutter_tcc/core/widgets/joberto_stage.dart';

/// Dispara a comemoração de quem acabou de entrar.
class JobertoCelebrationController extends ChangeNotifier {
  void play() => notifyListeners();
}

/// Comemoração do login, compartilhada entre quem dispara (a autenticação) e
/// quem mostra (o `builder` do `MaterialApp`).
final loginCelebration = JobertoCelebrationController();

/// O Joberto comemorando por cima do app, logo depois do login.
///
/// Fica acima do `Navigator`: entrar troca a árvore inteira de uma vez, e uma
/// tela comum sumiria junto com a de login antes de o clipe tocar. Aqui o app
/// carrega por baixo enquanto a comemoração cobre a troca.
class JobertoCelebration extends StatefulWidget {
  const JobertoCelebration({
    super.key,
    required this.controller,
    required this.child,
  });

  final JobertoCelebrationController controller;
  final Widget child;

  static const layerKey = ValueKey<String>('joberto-celebration');
  static const duration = Duration(milliseconds: 3800);

  @override
  State<JobertoCelebration> createState() => _JobertoCelebrationState();
}

class _JobertoCelebrationState extends State<JobertoCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _timeline = AnimationController(
    vsync: this,
    duration: JobertoCelebration.duration,
  );

  bool _visible = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_play);
  }

  @override
  void didUpdateWidget(JobertoCelebration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_play);
    widget.controller.addListener(_play);
  }

  void _play() {
    if (!mounted || _visible) return;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return;

    setState(() => _visible = true);
    _timeline.forward(from: 0).whenComplete(() {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_play);
    _timeline.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return widget.child;

    // Entra rápido, para cobrir a troca de tela, e sai devagar.
    final opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 5),
      TweenSequenceItem(tween: ConstantTween(1), weight: 83),
      TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 12),
    ]).animate(_timeline);

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        AbsorbPointer(
          key: JobertoCelebration.layerKey,
          child: FadeTransition(
            opacity: opacity,
            child: Material(
              color: jobertoPaper,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const JobertoStage(clip: JobertoClip.success, height: 360),
                  const SizedBox(height: 12),
                  Text(
                    'Tudo certo!',
                    style: AppTypography.h1.copyWith(
                      color: const Color(0xFF0D2F28),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
