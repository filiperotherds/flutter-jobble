import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_tcc/core/theme/app_colors.dart';
import 'package:flutter_tcc/core/theme/app_spacing.dart';
import 'package:flutter_tcc/core/theme/app_typography.dart';

class ProviderEditProfilePage extends StatefulWidget {
  const ProviderEditProfilePage({super.key});

  @override
  State<ProviderEditProfilePage> createState() =>
      _ProviderEditProfilePageState();
}

class _ProviderEditProfilePageState extends State<ProviderEditProfilePage> {
  

  final TextEditingController _nameController = TextEditingController(
    text: 'Roberto Pinturas e Reformas',
  );
  final TextEditingController _locationController = TextEditingController(
    text: 'São Paulo, SP',
  );
  Map<String, Map<String, dynamic>> _workingHours = {
    'Segunda-feira': {'isOpen': true, 'start': const TimeOfDay(hour: 8, minute: 0), 'end': const TimeOfDay(hour: 18, minute: 0)},
    'Terça-feira': {'isOpen': true, 'start': const TimeOfDay(hour: 8, minute: 0), 'end': const TimeOfDay(hour: 18, minute: 0)},
    'Quarta-feira': {'isOpen': true, 'start': const TimeOfDay(hour: 8, minute: 0), 'end': const TimeOfDay(hour: 18, minute: 0)},
    'Quinta-feira': {'isOpen': true, 'start': const TimeOfDay(hour: 8, minute: 0), 'end': const TimeOfDay(hour: 18, minute: 0)},
    'Sexta-feira': {'isOpen': true, 'start': const TimeOfDay(hour: 8, minute: 0), 'end': const TimeOfDay(hour: 18, minute: 0)},
    'Sábado': {'isOpen': true, 'start': const TimeOfDay(hour: 8, minute: 0), 'end': const TimeOfDay(hour: 12, minute: 0)},
    'Domingo': {'isOpen': false, 'start': const TimeOfDay(hour: 8, minute: 0), 'end': const TimeOfDay(hour: 18, minute: 0)},
  };
  final TextEditingController _cnpjController = TextEditingController(
    text: '12.345.678/0001-90',
  );

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _cnpjController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrow_left, color: colors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Editar Perfil',
          style: AppTypography.h3.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Capa de Perfil
              Text(
                'Capa do Perfil',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Stack(
                children: [
                  Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/intro_bg.jpeg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        LucideIcons.camera,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Foto de Perfil
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.borderLight),
                        image: const DecorationImage(
                          image: AssetImage('assets/images/logo_pintor.jpg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          LucideIcons.camera,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Formulário
              Text(
                'Nome da Empresa / Profissional',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildTextField(_nameController, colors),
              const SizedBox(height: AppSpacing.lg),

              Text(
                'Localização',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildTextField(_locationController, colors),
              const SizedBox(height: AppSpacing.lg),

              Text(
                'CNPJ ou CPF (Opcional)',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildTextField(_cnpjController, colors),
              const SizedBox(height: AppSpacing.lg),

              Text(
                'Horário de funcionamento',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildWorkingHoursEditor(colors),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: InkWell(
            onTap: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Perfil atualizado com sucesso!')),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 56,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Salvar Alterações',
                style: AppTypography.h3.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    AppColorsTheme colors,
  ) {
    return TextField(
      controller: controller,
      decoration: _inputDecoration(colors),
    );
  }

  InputDecoration _inputDecoration(AppColorsTheme colors) {
    return InputDecoration(
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
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 16,
      ),
    );
  }

  Widget _buildWorkingHoursEditor(AppColorsTheme colors) {
    final days = [
      'Segunda-feira',
      'Terça-feira',
      'Quarta-feira',
      'Quinta-feira',
      'Sexta-feira',
      'Sábado',
      'Domingo'
    ];
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        children: List.generate(days.length, (index) {
          final day = days[index];
          final config = _workingHours[day]!;
          final isWeekend = !config['isOpen'];
          
          String formatTime(TimeOfDay time) {
            return ':';
          }
          
          final timeStr = isWeekend 
              ? 'Fechado' 
              : ' às ';
          
          return Column(
            children: [
              InkWell(
                onTap: () => _showEditDayDialog(day),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        day,
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w500,
                          color: colors.textPrimary,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            timeStr,
                            style: AppTypography.body.copyWith(
                              color: isWeekend ? colors.error : colors.textSecondary,
                              fontWeight: isWeekend ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(LucideIcons.chevron_right, size: 16, color: Colors.grey[400]),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (index < days.length - 1)
                Divider(height: 1, thickness: 1, color: Colors.grey.withOpacity(0.1), indent: 16, endIndent: 16),
            ],
          );
        }),
      ),
    );
  }

  void _showEditDayDialog(String day) {
    final config = _workingHours[day]!;
    bool tempIsOpen = config['isOpen'];
    TimeOfDay tempStart = config['start'];
    TimeOfDay tempEnd = config['end'];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            String formatTime(TimeOfDay time) {
              return ':';
            }

            return Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Horários: ',
                    style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SwitchListTile(
                    title: const Text('Aberto neste dia'),
                    value: tempIsOpen,
                    activeColor: Colors.green,
                    onChanged: (val) {
                      setModalState(() => tempIsOpen = val);
                    },
                  ),
                  if (tempIsOpen) ...[
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Abertura'),
                        TextButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: tempStart,
                            );
                            if (picked != null) {
                              setModalState(() => tempStart = picked);
                            }
                          },
                          child: Text(
                            formatTime(tempStart),
                            style: AppTypography.h3.copyWith(color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Fechamento'),
                        TextButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: tempEnd,
                            );
                            if (picked != null) {
                              setModalState(() => tempEnd = picked);
                            }
                          },
                          child: Text(
                            formatTime(tempEnd),
                            style: AppTypography.h3.copyWith(color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _workingHours[day] = {
                          'isOpen': tempIsOpen,
                          'start': tempStart,
                          'end': tempEnd,
                        };
                      });
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Salvar Alterações', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

}
