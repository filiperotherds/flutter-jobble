import 'package:flutter/material.dart';

import 'package:flutter_tcc/core/theme/app_colors.dart';
import 'package:flutter_tcc/core/widgets/app_status_chip.dart';
import 'package:flutter_tcc/features/bids/data/models/org_match_model.dart';

/// Badge da etapa: acento para ação e andamento, neutro para espera.
/// O rótulo mantém a distinção entre etapas sem depender apenas de cor.
class JobStageChip extends StatelessWidget {
  const JobStageChip({super.key, required this.stage});

  final JobStage stage;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final color = switch (stage) {
      JobStage.awaitingResponse || JobStage.contractToFill => colors.accentText,
      JobStage.awaitingClient ||
      JobStage.awaitingSignatures => colors.textSecondary,
      JobStage.inProgress => colors.primary,
      JobStage.completed => colors.success,
      JobStage.closed => colors.textHint,
    };

    return AppStatusChip(label: stage.label, color: color);
  }
}
