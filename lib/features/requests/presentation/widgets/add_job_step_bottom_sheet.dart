import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_tcc/core/theme/app_colors.dart';
import 'package:flutter_tcc/core/theme/app_spacing.dart';
import 'package:flutter_tcc/core/theme/app_typography.dart';
import 'package:flutter_tcc/features/requests/domain/job_progress.dart';
import 'package:flutter_tcc/core/widgets/app_buttons.dart';
import 'package:flutter_tcc/core/widgets/app_text_field.dart';

class AddJobStepBottomSheet extends StatefulWidget {
  final double currentProgress;

  const AddJobStepBottomSheet({super.key, required this.currentProgress});

  static Future<Map<String, dynamic>?> show(
    BuildContext context,
    double currentProgress,
  ) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          AddJobStepBottomSheet(currentProgress: currentProgress),
    );
  }

  @override
  State<AddJobStepBottomSheet> createState() => _AddJobStepBottomSheetState();
}

class _AddJobStepBottomSheetState extends State<AddJobStepBottomSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  bool _hasPhotos = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nova Atualização',
                  style: AppTypography.h3.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Divider(color: colors.borderLight, height: 1),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(
                    controller: _titleController,
                    label: 'Título da atualização',
                    hint: 'Ex: Compra de Materiais',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    controller: _descController,
                    label: 'Descrição ou comentários',
                    hint: 'O que foi feito nesta etapa?',
                    maxLines: 3,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Fotos ou Anexos',
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (_hasPhotos)
                    Row(
                      children: [
                        _buildPhotoThumbnail(colors),
                        const SizedBox(width: AppSpacing.sm),
                        _buildPhotoThumbnail(colors),
                      ],
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _hasPhotos = true;
                        });
                      },
                      icon: const Icon(LucideIcons.camera, size: 20),
                      label: const Text('Anexar fotos'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: colors.borderLight),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xxl),
                  AppPrimaryButton(
                    onPressed: () {
                      if (_titleController.text.isEmpty) return;
                      Navigator.of(context).pop({
                        'title': _titleController.text,
                        'desc': _descController.text,
                        'progress': JobProgress.value,
                        'hasPhotos': _hasPhotos,
                        'date': DateTime.now(),
                      });
                    },
                    label: 'Salvar e Notificar Cliente',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoThumbnail(AppColorsTheme colors) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: colors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderLight),
      ),
      child: Stack(
        children: [
          const Center(child: Icon(LucideIcons.image, color: Colors.grey)),
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.x, size: 12, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
