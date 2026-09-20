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
  final List<String> _tags = [
    'Visita Técnica',
    'Diária Completa',
    'Pequenos Reparos',
    'Pintura Residencial',
    'Manutenção',
  ];
  final TextEditingController _tagController = TextEditingController();

  final TextEditingController _nameController = TextEditingController(
    text: 'Roberto Pinturas e Reformas',
  );
  final TextEditingController _locationController = TextEditingController(
    text: 'São Paulo, SP',
  );
  final TextEditingController _aboutController = TextEditingController(
    text:
        'Especialista em reformas gerais e acabamento fino. Trabalho com rapidez, limpeza e garantia de serviço bem feito. Atendendo a região há mais de 5 anos.',
  );
  final TextEditingController _cnpjController = TextEditingController(
    text: '12.345.678/0001-90',
  );

  @override
  void dispose() {
    _tagController.dispose();
    _nameController.dispose();
    _locationController.dispose();
    _aboutController.dispose();
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
                'Sobre você / Biografia',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _aboutController,
                maxLines: 4,
                decoration: _inputDecoration(colors),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Tags
              Text(
                'Especialidades / Tags',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Adicione palavras-chave sobre o que você faz para ajudar os clientes a te encontrarem na busca.',
                style: AppTypography.caption.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagController,
                      decoration: _inputDecoration(
                        colors,
                      ).copyWith(hintText: 'Ex: Instalação Elétrica'),
                      onSubmitted: (val) {
                        if (val.trim().isNotEmpty) {
                          setState(() {
                            _tags.add(val.trim());
                            _tagController.clear();
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  InkWell(
                    onTap: () {
                      if (_tagController.text.trim().isNotEmpty) {
                        setState(() {
                          _tags.add(_tagController.text.trim());
                          _tagController.clear();
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 54, // Force exact height to match TextField
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        LucideIcons.plus,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _tags.map((tag) {
                  return Chip(
                    label: Text(
                      tag,
                      style: AppTypography.caption.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: Colors.grey[200],
                    deleteIcon: Icon(
                      LucideIcons.x,
                      size: 16,
                      color: colors.textSecondary,
                    ),
                    onDeleted: () {
                      setState(() {
                        _tags.remove(tag);
                      });
                    },
                    side: const BorderSide(color: Colors.transparent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  );
                }).toList(),
              ),
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
}
