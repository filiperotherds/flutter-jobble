import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_tcc/core/theme/app_colors.dart';
import 'package:flutter_tcc/core/theme/app_spacing.dart';
import 'package:flutter_tcc/core/theme/app_typography.dart';
import 'package:flutter_tcc/core/network/api_exception.dart';
import 'package:flutter_tcc/features/services/data/services_api.dart';

class ProviderServicesCatalogPage extends StatefulWidget {
  const ProviderServicesCatalogPage({super.key});

  @override
  State<ProviderServicesCatalogPage> createState() => _ProviderServicesCatalogPageState();
}

/// Preço exibido quando o serviço só pode ser orçado depois da visita.
const String _kVisitPrice = 'A combinar';

/// Unidade exibida junto do preço nesse mesmo caso.
const String _kVisitUnit = 'após a visita';

/// Unidade dos serviços deixados sem preço, mas que não pedem visita.
const String _kQuoteUnit = 'sob orçamento';

class _ProviderServicesCatalogPageState extends State<ProviderServicesCatalogPage> {
  final _api = ServicesApi();

  /// O catálogo guardado no servidor. É o mesmo que o cliente vê no perfil:
  /// um serviço que vive só nesta tela não ajuda ninguém a contratar.
  List<Map<String, dynamic>> _services = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final services = await _api.mine();
      if (!mounted) return;
      setState(() {
        _services = services.map(_toRow).toList();
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      _failed(error);
    }
  }

  /// Traduz o serviço do servidor para o formato que esta tela já desenha.
  static Map<String, dynamic> _toRow(CatalogService service) => {
    'id': service.id,
    'title': service.title,
    'price': service.priceCents == null ? _kVisitPrice : service.priceLabel,
    'unit': service.unitLabel,
    'description': service.description ?? '',
    'active': true,
    'requiresVisit': service.requiresVisit,
  };

  /// "R$ 150,00" vira 15000. O campo foi feito para uma pessoa digitar; o
  /// servidor guarda centavos, que é o que não perde um tostão na conta.
  static int? _toCents(String text) {
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    // Com vírgula ou ponto decimal, os dois últimos dígitos são os centavos.
    return text.contains(',') || text.contains('.')
        ? int.parse(digits)
        : int.parse(digits) * 100;
  }

  void _failed(ApiException error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.message), backgroundColor: Colors.red[700]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.surfaceLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrow_left, color: colors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Catálogo de Serviços',
          style: AppTypography.h3.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: _services.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.list, size: 64, color: colors.borderLight),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Seu catálogo está vazio',
                    style: AppTypography.h3.copyWith(color: colors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Adicione seus serviços e preços.',
                    style: AppTypography.body.copyWith(color: colors.textSecondary),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: _services.length,
              separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final service = _services[index];
                return _buildServiceCard(service, colors, index);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showServiceModal(context, colors),
        backgroundColor: colors.primary,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: const Text('Novo Serviço', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service, AppColorsTheme colors, int index) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  service['title'],
                  style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold, color: colors.textPrimary),
                ),
              ),
              CupertinoSwitch(
                value: service['active'],
                activeColor: colors.primary,
                onChanged: (val) {
                  setState(() {
                    service['active'] = val;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                service['price'],
                style: AppTypography.h2.copyWith(fontWeight: FontWeight.bold, color: colors.primary),
              ),
              const SizedBox(width: 8),
              Text(
                service['unit'],
                style: AppTypography.caption.copyWith(color: colors.textSecondary),
              ),
            ],
          ),
          if (service['requiresVisit'] == true) ...[
            const SizedBox(height: AppSpacing.sm),
            _buildVisitBadge(colors),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(
            service['description'],
            style: AppTypography.body.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _showServiceModal(context, colors, service: service, index: index),
                icon: const Icon(LucideIcons.pencil, size: 18),
                label: const Text('Editar'),
                style: TextButton.styleFrom(foregroundColor: colors.primary),
              ),
              const SizedBox(width: AppSpacing.sm),
              TextButton.icon(
                onPressed: () {
                  _api
                      .remove('${_services[index]['id']}')
                      .then((_) => _load())
                      .catchError((Object error) {
                        if (error is ApiException) _failed(error);
                      });
                  setState(() {
                    _services.removeAt(index);
                  });
                },
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Excluir'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Selo dos serviços que só têm preço depois da visita ao local.
  Widget _buildVisitBadge(AppColorsTheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
      decoration: BoxDecoration(
        color: colors.accentSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.map_pin, size: 14, color: colors.accentText),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Orçamento após visita ao local',
              style: AppTypography.caption.copyWith(
                color: colors.accentText,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showServiceModal(BuildContext context, AppColorsTheme colors, {Map<String, dynamic>? service, int? index}) {
    final bool isEditing = service != null;
    final bool startsWithVisit = isEditing && service['requiresVisit'] == true;
    final titleController = TextEditingController(text: isEditing ? service['title'] : '');
    // Serviço orçado na visita não tem preço próprio: o campo abre vazio para
    // o prestador não achar que "A combinar" é um valor que ele digitou.
    final priceController = TextEditingController(text: startsWithVisit ? '' : (isEditing ? service['price'] : ''));
    final unitController = TextEditingController(text: startsWithVisit ? '' : (isEditing ? service['unit'] : ''));
    final descriptionController = TextEditingController(text: isEditing ? service['description'] : '');
    bool requiresVisit = startsWithVisit;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final bottomPadding = MediaQuery.of(sheetContext).viewInsets.bottom;
        return StatefulBuilder(
          builder: (sheetContext, setModalState) => Container(
          padding: EdgeInsets.only(bottom: bottomPadding),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: SingleChildScrollView(
              child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'Editar Serviço' : 'Novo Serviço',
                      style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x),
                      onPressed: () => Navigator.of(sheetContext).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Nome do Serviço', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: titleController,
                  decoration: _inputDecoration(colors, 'Ex: Pintura de fachada'),
                ),
                const SizedBox(height: AppSpacing.lg),
                _buildVisitOption(
                  colors,
                  requiresVisit,
                  (value) => setModalState(() => requiresVisit = value),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (requiresVisit)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Este serviço aparece como "$_kVisitPrice" no seu catálogo. '
                      'Você visita o local e envia a proposta com o valor fechado.',
                      style: AppTypography.caption.copyWith(color: colors.textSecondary),
                    ),
                  )
                else
                  Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Preço Base', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: AppSpacing.sm),
                          TextField(
                            controller: priceController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration(colors, 'R\$ 0,00'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Unidade', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: AppSpacing.sm),
                          TextField(
                            controller: unitController,
                            decoration: _inputDecoration(colors, 'ex: por dia'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (!requiresVisit) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Sem preço definido? Deixe em branco e o serviço entra como "$_kVisitPrice".',
                    style: AppTypography.caption.copyWith(color: colors.textSecondary),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                Text('Descrição do Serviço', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: _inputDecoration(colors, 'Detalhe o que está incluso no serviço...'),
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final title = titleController.text.trim();
                      if (title.isEmpty) {
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                          const SnackBar(content: Text('Informe o nome do serviço.')),
                        );
                        return;
                      }
                      final price = priceController.text.trim();
                      final unit = unitController.text.trim();
                      final cents = requiresVisit ? null : _toCents(price);
                      final unitLabel = requiresVisit
                          ? _kVisitUnit
                          : (price.isEmpty && unit.isEmpty ? _kQuoteUnit : unit);

                      try {
                        if (isEditing && service['id'] != null) {
                          await _api.update(
                            '${service['id']}',
                            title: title,
                            description: descriptionController.text.trim(),
                            priceCents: cents,
                            unit: unitLabel,
                            requiresVisit: requiresVisit,
                          );
                        } else {
                          await _api.create(
                            title: title,
                            description: descriptionController.text.trim(),
                            priceCents: cents,
                            unit: unitLabel,
                            requiresVisit: requiresVisit,
                          );
                        }
                      } on ApiException catch (error) {
                        _failed(error);
                        return;
                      }

                      if (!mounted) return;
                      Navigator.of(sheetContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(isEditing ? 'Serviço atualizado!' : 'Serviço adicionado!')),
                      );
                      await _load();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      'Salvar',
                      style: AppTypography.h3.copyWith(color: colors.textPrimary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
            ),
          ),
          ),
        );
      },
    ).whenComplete(() {
      titleController.dispose();
      priceController.dispose();
      unitController.dispose();
      descriptionController.dispose();
    });
  }

  /// Opção que marca o serviço como orçável só depois da visita ao local.
  Widget _buildVisitOption(AppColorsTheme colors, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: value ? colors.accentSoft : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: value ? colors.primary : colors.borderLight),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.map_pin,
            size: 20,
            color: value ? colors.accentText : colors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preciso visitar o local para orçar',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'O cliente solicita a visita e você formaliza a proposta depois de ver o serviço.',
                  style: AppTypography.caption.copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          CupertinoSwitch(
            value: value,
            activeColor: colors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(AppColorsTheme colors, String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.borderLight)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.borderLight)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.primary)),
      contentPadding: const EdgeInsets.all(AppSpacing.md),
    );
  }
}

