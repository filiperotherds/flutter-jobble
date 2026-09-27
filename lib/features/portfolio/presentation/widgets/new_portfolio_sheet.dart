import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_tcc/core/network/api_exception.dart';
import 'package:flutter_tcc/core/theme/app_colors.dart';
import 'package:flutter_tcc/core/theme/app_spacing.dart';
import 'package:flutter_tcc/core/theme/app_typography.dart';
import 'package:flutter_tcc/features/portfolio/data/portfolio_api.dart';
import 'package:flutter_tcc/features/portfolio/data/portfolio_models.dart';

class _Picked {
  const _Picked({required this.bytes, required this.name, this.role});

  final Uint8List bytes;
  final String name;

  /// BEFORE ou AFTER no antes-e-depois; nulo nos outros formatos.
  final String? role;
}

/// A folha de criar um trabalho.
///
/// O formato vem primeiro, e não por último: escolhido ele, a folha já mostra
/// os espaços certos — duas vagas nomeadas "antes" e "depois", quatro molduras
/// da montagem, uma vaga de vídeo. A pessoa preenche em vez de imaginar.
class NewPortfolioSheet extends StatefulWidget {
  const NewPortfolioSheet({super.key});

  /// Devolve `true` quando algo foi criado.
  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NewPortfolioSheet(),
    );
  }

  @override
  State<NewPortfolioSheet> createState() => _NewPortfolioSheetState();
}

class _NewPortfolioSheetState extends State<NewPortfolioSheet> {
  final _api = PortfolioApi();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  PortfolioKind? _kind;
  final List<_Picked> _files = [];
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pick({String? role}) async {
    final kind = _kind!;
    final picker = ImagePicker();

    try {
      if (kind == PortfolioKind.video) {
        final file = await picker.pickVideo(source: ImageSource.gallery);
        if (file == null) return;
        final bytes = await file.readAsBytes();
        if (!mounted) return;
        setState(() {
          _files
            ..clear()
            ..add(_Picked(bytes: bytes, name: file.name));
        });
        return;
      }

      // Carrossel e montagem aceitam vários de uma vez; os demais, um por vez.
      if (kind.maxMedia > 1 && role == null) {
        final files = await picker.pickMultiImage(
          maxWidth: 1600,
          imageQuality: 85,
        );
        if (files.isEmpty) return;

        final room = kind.maxMedia - _files.length;
        for (final file in files.take(room)) {
          final bytes = await file.readAsBytes();
          if (!mounted) return;
          setState(() => _files.add(_Picked(bytes: bytes, name: file.name)));
        }
        return;
      }

      final file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;

      setState(() {
        // No antes-e-depois cada vaga guarda uma foto só: escolher de novo
        // troca a que estava ali.
        if (role != null) _files.removeWhere((picked) => picked.role == role);
        _files.add(_Picked(bytes: bytes, name: file.name, role: role));
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Não consegui abrir a galeria neste aparelho.');
      }
    }
  }

  Future<void> _submit() async {
    final kind = _kind!;

    if (_titleController.text.trim().length < 2) {
      setState(() => _error = 'Dê um título ao trabalho.');
      return;
    }
    if (_files.length < kind.minMedia) {
      setState(() {
        _error = kind == PortfolioKind.beforeAfter
            ? 'Escolha a foto do antes e a do depois.'
            : 'Escolha pelo menos ${kind.minMedia} arquivo(s).';
      });
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      final item = await _api.create(
        kind: kind,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      // O antes vai primeiro: é ele que define o papel de cada arquivo quando
      // o app não manda o papel explicitamente.
      final ordered = [
        ..._files.where((f) => f.role == 'BEFORE'),
        ..._files.where((f) => f.role == 'AFTER'),
        ..._files.where((f) => f.role == null),
      ];

      for (final file in ordered) {
        await _api.addMedia(
          itemId: item.id,
          bytes: file.bytes,
          filename: file.name,
          role: file.role,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _kind == null ? 'Como quer mostrar?' : _kind!.label,
                    style: AppTypography.h2.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(LucideIcons.x, color: colors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              child: _kind == null ? _formats(colors) : _form(colors),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formats(AppColorsTheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'O formato muda o que o cliente entende do seu trabalho. '
          'Escolha um e o app monta o resto.',
          style: AppTypography.caption.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final kind in PortfolioKind.values) ...[
          _FormatOption(
            kind: kind,
            onTap: () => setState(() => _kind = kind),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  Widget _form(AppColorsTheme colors) {
    final kind = _kind!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                kind.hint,
                style: AppTypography.caption.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: _sending
                  ? null
                  : () => setState(() {
                      _kind = null;
                      _files.clear();
                    }),
              child: Text(
                'Trocar formato',
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        if (kind == PortfolioKind.beforeAfter)
          _beforeAfterSlots(colors)
        else
          _slots(colors),

        const SizedBox(height: AppSpacing.xl),
        Text(
          'Título do Projeto',
          style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: 'Ex: Reforma do banheiro',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.primary, width: 2),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Descrição ou Comentários',
          style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Fale um pouco sobre o serviço realizado...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.primary, width: 2),
            ),
          ),
        ),

        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.circle_alert,
                  size: 16,
                  color: Colors.red[700],
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _error!,
                    style: AppTypography.caption.copyWith(
                      color: Colors.red[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.xl),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _sending ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _sending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Salvar Projeto',
                    style: AppTypography.h3.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  /// Duas vagas nomeadas. É o "modelo" que o app entrega: a pessoa só encaixa
  /// as fotos nos lugares certos.
  Widget _beforeAfterSlots(AppColorsTheme colors) {
    return Row(
      children: [
        Expanded(child: _slot(colors, label: 'ANTES', role: 'BEFORE')),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: _slot(colors, label: 'DEPOIS', role: 'AFTER')),
      ],
    );
  }

  Widget _slot(
    AppColorsTheme colors, {
    required String label,
    required String role,
  }) {
    final picked = _files.where((file) => file.role == role).firstOrNull;

    return GestureDetector(
      onTap: _sending ? null : () => _pick(role: role),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: colors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: picked == null ? colors.borderLight : colors.primary,
              width: picked == null ? 1 : 1.5,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: picked == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.image_plus,
                      color: colors.textSecondary,
                      size: 24,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(picked.bytes, fit: BoxFit.cover),
                    Positioned(
                      left: 6,
                      bottom: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _slots(AppColorsTheme colors) {
    final kind = _kind!;
    final canAdd = _files.length < kind.maxMedia;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            if (canAdd)
              GestureDetector(
                onTap: _sending ? null : () => _pick(),
                child: Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: colors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.borderLight),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        kind == PortfolioKind.video
                            ? LucideIcons.video
                            : LucideIcons.image_plus,
                        color: colors.primary,
                        size: 22,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        kind == PortfolioKind.video ? 'Vídeo' : 'Adicionar',
                        style: AppTypography.caption.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            for (var index = 0; index < _files.length; index++)
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: kind == PortfolioKind.video
                        ? Container(
                            width: 92,
                            height: 92,
                            color: Colors.black87,
                            alignment: Alignment.center,
                            child: const Icon(
                              LucideIcons.play,
                              color: Colors.white,
                            ),
                          )
                        : Image.memory(
                            _files[index].bytes,
                            width: 92,
                            height: 92,
                            fit: BoxFit.cover,
                          ),
                  ),
                  Positioned(
                    top: -6,
                    right: -6,
                    child: GestureDetector(
                      onTap: () => setState(() => _files.removeAt(index)),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.x,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  if (kind == PortfolioKind.carousel)
                    Positioned(
                      left: 6,
                      bottom: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
        if (kind == PortfolioKind.collage && _files.length >= 2) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            'Prévia da montagem',
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          // O arranjo vem do app: mostrar a prévia antes de salvar evita a
          // surpresa de ver a montagem só depois de publicada.
          AspectRatio(
            aspectRatio: 4 / 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _CollagePreview(files: _files),
            ),
          ),
        ],
      ],
    );
  }
}

/// A prévia da montagem com as fotos ainda em memória.
class _CollagePreview extends StatelessWidget {
  const _CollagePreview({required this.files});

  final List<_Picked> files;

  @override
  Widget build(BuildContext context) {
    final photos = files.take(4).toList();
    Widget photo(int index) =>
        Image.memory(photos[index].bytes, fit: BoxFit.cover);

    return switch (photos.length) {
      2 => Row(
        children: [
          Expanded(child: photo(0)),
          const SizedBox(width: 2),
          Expanded(child: photo(1)),
        ],
      ),
      3 => Row(
        children: [
          Expanded(flex: 3, child: photo(0)),
          const SizedBox(width: 2),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(child: photo(1)),
                const SizedBox(height: 2),
                Expanded(child: photo(2)),
              ],
            ),
          ),
        ],
      ),
      4 => Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: photo(0)),
                const SizedBox(width: 2),
                Expanded(child: photo(1)),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Row(
              children: [
                Expanded(child: photo(2)),
                const SizedBox(width: 2),
                Expanded(child: photo(3)),
              ],
            ),
          ),
        ],
      ),
      _ => photo(0),
    };
  }
}

class _FormatOption extends StatelessWidget {
  const _FormatOption({required this.kind, required this.onTap});

  final PortfolioKind kind;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final icon = switch (kind) {
      PortfolioKind.single => LucideIcons.image,
      PortfolioKind.carousel => LucideIcons.copy,
      PortfolioKind.beforeAfter => LucideIcons.chevrons_left_right,
      PortfolioKind.collage => LucideIcons.layout_grid,
      PortfolioKind.video => LucideIcons.video,
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.borderLight),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: colors.primary, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kind.label,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      kind.hint,
                      style: AppTypography.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevron_right,
                size: 18,
                color: colors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
