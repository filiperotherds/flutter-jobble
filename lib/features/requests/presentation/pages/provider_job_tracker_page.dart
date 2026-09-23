import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_tcc/core/theme/app_colors.dart';
import 'package:flutter_tcc/core/theme/app_spacing.dart';
import 'package:flutter_tcc/core/theme/app_typography.dart';
import 'package:flutter_tcc/features/requests/domain/job_progress.dart';
import 'package:flutter_tcc/features/requests/domain/job_progress_updates.dart';
import 'package:intl/intl.dart';

import 'package:flutter_tcc/features/requests/presentation/widgets/add_job_step_bottom_sheet.dart';
import 'package:flutter_tcc/features/requests/presentation/widgets/job_steps_checklist.dart';
import 'package:flutter_tcc/features/requests/presentation/widgets/service_stepper.dart';

/// Acompanhamento do serviço, do lado de quem executa.
///
/// Duas partes com funções distintas. Em cima, as etapas combinadas: é onde o
/// profissional marca o que entregou, e é de lá que sai o andamento. Embaixo,
/// o diário — os relatos que o cliente lê, do mais recente para o mais antigo.
///
/// A linha do tempo vertical que ligava os relatos saiu: a régua de etapas já
/// é o indicador de progresso da tela, e duas trilhas competindo — uma para a
/// direita, outra para baixo, com o mesmo verde significando coisas
/// diferentes — só atrapalhavam a leitura.
class ProviderJobTrackerPage extends StatefulWidget {
  const ProviderJobTrackerPage({super.key});

  @override
  State<ProviderJobTrackerPage> createState() => _ProviderJobTrackerPageState();
}

class _ProviderJobTrackerPageState extends State<ProviderJobTrackerPage> {
  /// Calculado, nunca digitado: sai das tarefas concluídas ou do prazo.
  double get _overallProgress => JobProgress.value;

  /// Mesma lista que alimenta a contagem no card do painel.
  List<Map<String, dynamic>> get _updates => JobProgressUpdates.all;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // Mais recente primeiro: é o estado atual do serviço.
    final updates = _updates.reversed.toList();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(LucideIcons.arrow_left, color: colors.textPrimary),
          onPressed: () => Navigator.of(context).pop(_overallProgress),
        ),
        title: Text(
          'Progresso do Serviço',
          style: AppTypography.h3.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        // Espaço para o botão flutuante não cobrir o último relato.
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          _buildHeader(colors),
          _buildStepsSection(colors),
          if (updates.isEmpty)
            _buildEmpty(colors)
          else ...[
            _buildDiaryHeader(colors, updates.length),
            for (var i = 0; i < updates.length; i++)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  i == updates.length - 1 ? 0 : AppSpacing.md,
                ),
                child: _UpdateCard(update: updates[i], isLatest: i == 0),
              ),
          ],
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
            style: AppTypography.body.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progresso Geral',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
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
          const SizedBox(height: AppSpacing.md),
          // Só o resumo visual do andamento. Quem recebe o toque é a lista de
          // etapas logo abaixo — uma régua de bolinhas não é lugar de botão.
          ServiceStepper(steps: JobProgress.tasks, showLabels: false),
          const SizedBox(height: AppSpacing.md),
          Text(
            _stepsSummary(),
            style: AppTypography.caption.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  /// A régua em palavras, para quem não decifra o desenho de primeira.
  String _stepsSummary() {
    final tasks = JobProgress.tasks;
    if (tasks.isEmpty) return 'Avança junto com o prazo combinado.';

    final done = JobProgress.doneCount;
    if (done == tasks.length) return 'Todas as etapas concluídas.';

    final current = tasks.firstWhere((task) => !task.done);
    return '$done de ${tasks.length} etapas concluídas · '
        'agora: ${current.title}';
  }

  /// A lista onde o profissional marca o que entregou.
  Widget _buildStepsSection(AppColorsTheme colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.list_checks,
                size: 16,
                color: colors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Etapas do serviço',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${JobProgress.doneCount}/${JobProgress.tasks.length}',
                style: AppTypography.caption.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'É daqui que sai o progresso que o cliente vê. Toque na etapa '
            'quando terminar.',
            style: AppTypography.caption.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          JobStepsChecklist(
            steps: JobProgress.tasks,
            onToggle: (index) => setState(() {
              final task = JobProgress.tasks[index];
              task.done = !task.done;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDiaryHeader(AppColorsTheme colors, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Icon(LucideIcons.message_square, size: 16, color: colors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Diário do serviço',
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
          ),
          Text(
            count == 1 ? '1 relato enviado' : '$count relatos enviados',
            style: AppTypography.caption.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(AppColorsTheme colors) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        children: [
          Icon(LucideIcons.camera, size: 48, color: colors.borderLight),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Nenhum relato ainda',
            style: AppTypography.h3.copyWith(color: colors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Uma foto e duas linhas do que você fez hoje poupam o cliente de '
            'perguntar. Toque em "Nova Atualização".',
            style: AppTypography.body.copyWith(color: colors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _openAddStepModal(BuildContext context) async {
    final result = await AddJobStepBottomSheet.show(context, _overallProgress);
    if (result != null) {
      setState(() => JobProgressUpdates.add(result));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Relato publicado! O cliente já consegue ver no app dele.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}

/// "Hoje às 14:20" diz mais do que "22/09 às 14:20" para quem acompanha um
/// serviço em andamento. A data cheia volta quando o relato já é antigo.
String friendlyUpdateDate(DateTime date, {DateTime? now}) {
  final moment = now ?? DateTime.now();
  final today = DateTime(moment.year, moment.month, moment.day);
  final day = DateTime(date.year, date.month, date.day);
  final days = today.difference(day).inDays;
  final hour = DateFormat('HH:mm').format(date);

  if (days == 0) return 'Hoje às $hour';
  if (days == 1) return 'Ontem às $hour';
  if (days < 7) return 'Há $days dias, às $hour';
  return DateFormat("dd/MM 'às' HH:mm").format(date);
}

/// Um relato publicado: o que foi feito, quando, com as fotos.
class _UpdateCard extends StatelessWidget {
  const _UpdateCard({required this.update, required this.isLatest});

  final Map<String, dynamic> update;

  /// O mais recente é o que o cliente vê no topo do app dele.
  final bool isLatest;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final description = update['desc']?.toString() ?? '';
    final photos = (update['photos'] as List?)?.cast<String>() ?? const [];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLatest ? colors.primary : colors.borderLight,
          width: isLatest ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  update['title']?.toString() ?? '',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              if (isLatest) ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Mais recente',
                    style: AppTypography.caption.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(LucideIcons.clock, size: 12, color: colors.textSecondary),
              const SizedBox(width: 4),
              Text(
                friendlyUpdateDate(update['date'] as DateTime),
                style: AppTypography.caption.copyWith(
                  color: colors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              description,
              style: AppTypography.caption.copyWith(
                color: colors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
          if (photos.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 88,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) => GestureDetector(
                  onTap: () => _openPhoto(context, photos, index),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      photos[index],
                      width: 110,
                      height: 88,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ] else if (update['hasPhotos'] == true) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                _buildMiniPhoto(colors),
                const SizedBox(width: AppSpacing.sm),
                _buildMiniPhoto(colors),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniPhoto(AppColorsTheme colors) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: colors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.borderLight),
      ),
      child: Center(
        child: Icon(LucideIcons.image, size: 20, color: colors.textSecondary),
      ),
    );
  }

  /// Mesma ampliação que o cliente tem: vale conferir como a foto chegou lá.
  void _openPhoto(BuildContext context, List<String> photos, int index) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              update['title']?.toString() ?? '',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          body: Center(
            child: InteractiveViewer(child: Image.asset(photos[index])),
          ),
        ),
      ),
    );
  }
}
