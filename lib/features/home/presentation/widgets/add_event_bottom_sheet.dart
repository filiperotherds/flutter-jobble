import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_tcc/core/theme/app_colors.dart';
import 'package:flutter_tcc/core/theme/app_spacing.dart';
import 'package:flutter_tcc/core/theme/app_typography.dart';

class AddEventBottomSheet extends StatefulWidget {
  final int day;
  final int month;
  final int year;

  const AddEventBottomSheet({
    super.key,
    required this.day,
    required this.month,
    required this.year,
  });

  static Future<Map<String, dynamic>?> show(
    BuildContext context,
    int day,
    int month,
    int year,
  ) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          AddEventBottomSheet(day: day, month: month, year: year),
    );
  }

  @override
  State<AddEventBottomSheet> createState() => _AddEventBottomSheetState();
}

class _AddEventBottomSheetState extends State<AddEventBottomSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _clientController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _clientController.dispose();
    _timeController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    final formattedDate =
        '${widget.day.toString().padLeft(2, '0')}/${widget.month.toString().padLeft(2, '0')}/${widget.year}';

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
        children: [
          // Handle

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Adicionar Evento',
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

          Divider(color: colors.borderLight),

          // Form
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data Selecionada: $formattedDate',
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w500,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Título
                  Text(
                    'Título do serviço ou compromisso',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _titleController,
                    decoration: _inputDecoration(colors, 'Ex: Pintura da sala'),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Horário
                  Text(
                    'Horário',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _timeController,
                    decoration: _inputDecoration(colors, 'Ex: 14:00 - 16:30'),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Cliente
                  Text(
                    'Nome do Cliente (Opcional)',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _clientController,
                    decoration: _inputDecoration(colors, 'Ex: Carlos Silva'),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Endereço
                  Text(
                    'Endereço (Opcional)',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _addressController,
                    decoration: _inputDecoration(
                      colors,
                      'Ex: Rua das Flores, 123',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: colors.borderLight)),
            ),
            child: SafeArea(
              top: false,
              child: ElevatedButton(
                onPressed: () {
                  if (_titleController.text.trim().isEmpty ||
                      _timeController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Preencha o título e o horário.'),
                      ),
                    );
                    return;
                  }
                  Navigator.of(context).pop({
                    'title': _titleController.text.trim(),
                    'time': _timeController.text.trim(),
                    'client': _clientController.text.trim(),
                    'address': _addressController.text.trim(),
                    'status': 'Confirmado',
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Salvar Compromisso',
                      style: AppTypography.h3.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(AppColorsTheme colors, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTypography.body.copyWith(color: colors.borderLight),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.primary),
      ),
      contentPadding: const EdgeInsets.all(AppSpacing.md),
    );
  }
}
