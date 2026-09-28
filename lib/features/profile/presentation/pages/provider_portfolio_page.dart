import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_tcc/core/theme/app_colors.dart';
import 'package:flutter_tcc/core/theme/app_spacing.dart';
import 'package:flutter_tcc/core/theme/app_typography.dart';
import 'package:flutter_tcc/core/widgets/app_empty_state.dart';
import 'package:flutter_tcc/core/widgets/app_loader.dart';
import 'package:flutter_tcc/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:flutter_tcc/features/profile/data/models/project_model.dart';
import 'package:flutter_tcc/injection_container.dart';
import 'package:flutter_tcc/core/widgets/app_back_button.dart';

/// Portfólio do profissional: os projetos de `GET /projects`.
///
/// É o mesmo conteúdo que o cliente vê no perfil público, então o que sai
/// daqui sai de lá.
class ProviderPortfolioPage extends StatefulWidget {
  const ProviderPortfolioPage({super.key});

  @override
  State<ProviderPortfolioPage> createState() => _ProviderPortfolioPageState();
}

class _ProviderPortfolioPageState extends State<ProviderPortfolioPage> {
  final _profile = sl<ProfileRemoteDataSource>();

  List<ProjectModel> _projects = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final projects = await _profile.getProjects();
      if (!mounted) return;
      setState(() {
        _projects = projects;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _delete(ProjectModel project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remover projeto'),
        content: Text(
          'Remover "${project.title ?? 'este projeto'}" do portfólio?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false)) return;
    try {
      await _profile.deleteProject(project.id);
      await _load();
    } catch (error) {
      if (!mounted) return;
      _warn(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _warn(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        elevation: 0,
        leadingWidth: AppBackButton.slotWidth,
        leading: const AppBackButton(),
        title: Text(
          'Meu Portfólio',
          style: AppTypography.h3.copyWith(
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const AppLoaderCentered()
            : _error != null
            ? AppEmptyState(
                icon: LucideIcons.triangle_alert,
                title: 'Não foi possível carregar o portfólio',
                description: _error,
                actionLabel: 'Tentar de novo',
                onAction: _load,
              )
            : _projects.isEmpty
            ? const AppEmptyState(
                icon: LucideIcons.image,
                title: 'Seu portfólio está vazio',
                description:
                    'Adicione fotos dos seus trabalhos para atrair mais clientes.',
              )
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: _projects.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.lg),
                itemBuilder: (context, index) => _ProjectCard(
                  project: _projects[index],
                  onDelete: () => _delete(_projects[index]),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewProject,
        backgroundColor: colors.primary,
        icon: Icon(LucideIcons.plus, color: context.colors.onPrimary),
        label: Text(
          'Novo Projeto',
          style: TextStyle(
            color: context.colors.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _openNewProject() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NewProjectSheet(profile: _profile),
    );
    if (created ?? false) await _load();
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.project, required this.onDelete});

  final ProjectModel project;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final photos = project.photoUrls;

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (photos.isNotEmpty)
            SizedBox(
              height: 180,
              child: PageView.builder(
                itemCount: photos.length,
                itemBuilder: (context, index) => Image.network(
                  photos[index],
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: colors.surfaceLight,
                    alignment: Alignment.center,
                    child: Icon(
                      LucideIcons.image_off,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        project.title ?? 'Projeto',
                        style: AppTypography.h3.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(LucideIcons.trash_2, color: colors.error),
                      onPressed: onDelete,
                      tooltip: 'Remover',
                    ),
                  ],
                ),
                if (project.description != null &&
                    project.description!.isNotEmpty)
                  Text(
                    project.description!,
                    style: AppTypography.caption.copyWith(
                      color: colors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                if (project.city != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Text(
                      [
                        project.city,
                        project.state,
                      ].whereType<String>().join(' - '),
                      style: AppTypography.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NewProjectSheet extends StatefulWidget {
  const _NewProjectSheet({required this.profile});

  final ProfileRemoteDataSource profile;

  @override
  State<_NewProjectSheet> createState() => _NewProjectSheetState();
}

class _NewProjectSheetState extends State<_NewProjectSheet> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _photos = <File>[];
  bool _saving = false;

  @override
  void dispose() {
    for (final controller in [_title, _description, _city, _state]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    final picked = await ImagePicker().pickMultiImage(maxWidth: 1600);
    if (picked.isEmpty) return;
    setState(() => _photos.addAll(picked.map((x) => File(x.path))));
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_title.text.trim().isEmpty ||
        _city.text.trim().isEmpty ||
        _state.text.trim().length != 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe título, cidade e a sigla do estado.'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final urls = <String>[];
      for (final photo in _photos) {
        urls.add(await widget.profile.uploadPhoto(photo));
      }
      await widget.profile.createProject(
        title: _title.text.trim(),
        city: _city.text.trim(),
        state: _state.text.trim().toUpperCase(),
        description: _description.text.trim(),
        photoUrls: urls,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Adicionar Projeto',
                    style: AppTypography.h3.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              GestureDetector(
                onTap: _pickPhotos,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.borderLight),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        LucideIcons.images,
                        size: 40,
                        color: colors.textSecondary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _photos.isEmpty
                            ? 'Toque para escolher as fotos'
                            : '${_photos.length} ${_photos.length == 1 ? 'foto escolhida' : 'fotos escolhidas'}',
                        style: AppTypography.caption.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _field(_title, 'Título do projeto', colors),
              const SizedBox(height: AppSpacing.sm),
              _field(_description, 'Descrição (opcional)', colors, lines: 3),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(flex: 3, child: _field(_city, 'Cidade', colors)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: _field(_state, 'UF', colors)),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const StadiumBorder(),
                  ),
                  child: Text(_saving ? 'Publicando…' : 'Publicar projeto'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String hint,
    AppColorsTheme colors, {
    int lines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: lines,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: context.colors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.borderLight),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
      ),
    );
  }
}
