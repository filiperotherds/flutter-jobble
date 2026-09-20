import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_tcc/core/theme/app_colors.dart';
import 'package:flutter_tcc/core/theme/app_spacing.dart';
import 'package:flutter_tcc/core/theme/app_typography.dart';
import 'package:flutter_tcc/core/state/jobble_quote_state.dart';
import 'package:flutter_tcc/features/requests/presentation/services/quote_pdf_service.dart';

class ProviderQuoteGeneratorPage extends StatefulWidget {
  const ProviderQuoteGeneratorPage({super.key});

  @override
  State<ProviderQuoteGeneratorPage> createState() =>
      _ProviderQuoteGeneratorPageState();
}

class _ProviderQuoteGeneratorPageState
    extends State<ProviderQuoteGeneratorPage> {
  final List<Map<String, dynamic>> _servicos = [
    {
      'desc': 'Remover tinta que está descascando e lixar',
      'qtd': 1,
      'unit': 450.00,
    },
  ];

  final List<Map<String, dynamic>> _materiais = [];

  final TextEditingController _prazoController = TextEditingController(
    text: '3 dias \u00fateis (15/10 a 18/10)',
  );
  final TextEditingController _condicoesController = TextEditingController(
    text: '50% de entrada e 50% na conclus\u00e3o',
  );
  final TextEditingController _garantiaController = TextEditingController(
    text: '3 meses (90 dias)',
  );
  final TextEditingController _observacoesController = TextEditingController(
    text:
        'Incluso aplica\u00e7\u00e3o de 2 dem\u00e3os de tinta e lixamento pr\u00e9vio.',
  );

  @override
  void dispose() {
    _prazoController.dispose();
    _condicoesController.dispose();
    _garantiaController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  void _addServico() {
    setState(() {
      _servicos.add({'desc': '', 'qtd': 1, 'unit': 0.00});
    });
  }

  void _addMaterial() {
    setState(() {
      _materiais.add({'desc': '', 'qtd': 1, 'unit': 0.00});
    });
  }

  void _removeServico(int index) {
    setState(() {
      _servicos.removeAt(index);
    });
  }

  void _removeMaterial(int index) {
    setState(() {
      _materiais.removeAt(index);
    });
  }

  double get _total =>
      _servicos.fold(
        0.0,
        (sum, item) => sum + ((item['qtd'] as num) * (item['unit'] as num)),
      ) +
      _materiais.fold(
        0.0,
        (sum, item) => sum + ((item['qtd'] as num) * (item['unit'] as num)),
      );

  List<Map<String, dynamic>> get _allItems {
    return [
      ..._servicos.map((e) => {...e, 'type': 'Serviço'}),
      ..._materiais.map((e) => {...e, 'type': 'Material'}),
    ];
  }

  Widget _buildSection({
    required String title,
    required List<Map<String, dynamic>> items,
    required VoidCallback onAdd,
    required void Function(int) onRemove,
  }) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(
        bottom: AppSpacing.md,
        left: AppSpacing.md,
        right: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(
                  title == 'Serviços'
                      ? LucideIcons.wrench
                      : LucideIcons.package,
                  color: colors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'Nenhum item adicionado.',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ),
          ...items.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            return Container(
              key: ObjectKey(item),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                border: idx < items.length - 1
                    ? Border(bottom: BorderSide(color: Colors.grey[200]!))
                    : null,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: item['desc'],
                          decoration: InputDecoration(
                            labelText: 'Descrição',
                            labelStyle: TextStyle(color: Colors.grey[600]),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: colors.primary),
                            ),
                          ),
                          onChanged: (val) => item['desc'] = val,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            LucideIcons.trash,
                            color: Colors.red,
                            size: 20,
                          ),
                          onPressed: () => onRemove(idx),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          initialValue: item['qtd'].toString(),
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Qtd.',
                            labelStyle: TextStyle(color: Colors.grey[600]),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: colors.primary),
                            ),
                          ),
                          onChanged: (val) => setState(
                            () => item['qtd'] = int.tryParse(val) ?? 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          initialValue: (item['unit'] as double)
                              .toStringAsFixed(2),
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Valor Unit.',
                            labelStyle: TextStyle(color: Colors.grey[600]),
                            prefixText: 'R\$ ',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: colors.primary),
                            ),
                          ),
                          onChanged: (val) => setState(
                            () => item['unit'] =
                                double.tryParse(val.replaceAll(',', '.')) ??
                                0.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          const Divider(height: 1),
          InkWell(
            onTap: onAdd,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.plus, color: colors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Adicionar',
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionsSection(AppColorsTheme colors) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: AppSpacing.md,
        left: AppSpacing.md,
        right: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(LucideIcons.clipboard_list, color: colors.primary),
                const SizedBox(width: 8),
                Text(
                  'Prazos e Condi\u00e7\u00f5es',
                  style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                TextFormField(
                  controller: _prazoController,
                  decoration: InputDecoration(
                    labelText: 'Prazo de Entrega / Execu\u00e7\u00e3o',
                    labelStyle: TextStyle(color: Colors.grey[600]),
                    hintText: 'Ex: 3 dias \u00fateis (15/10 a 18/10)',
                    prefixIcon: Icon(
                      LucideIcons.clock,
                      color: colors.primary,
                      size: 20,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _condicoesController,
                  decoration: InputDecoration(
                    labelText: 'Condi\u00e7\u00e3o de Pagamento',
                    labelStyle: TextStyle(color: Colors.grey[600]),
                    hintText: 'Ex: 50% de entrada e 50% na conclus\u00e3o',
                    prefixIcon: Icon(
                      LucideIcons.credit_card,
                      color: colors.primary,
                      size: 20,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _garantiaController,
                  decoration: InputDecoration(
                    labelText: 'Garantia do Servi\u00e7o',
                    labelStyle: TextStyle(color: Colors.grey[600]),
                    hintText: 'Ex: 3 meses (90 dias), 1 ano',
                    prefixIcon: Icon(
                      LucideIcons.shield_check,
                      color: colors.primary,
                      size: 20,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _observacoesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Observa\u00e7\u00f5es',
                    alignLabelWithHint: true,
                    labelStyle: TextStyle(color: Colors.grey[600]),
                    hintText:
                        'Ex: Local deve estar desocupado; limpeza inclusa.',
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: Icon(
                        LucideIcons.notepad_text,
                        color: colors.primary,
                        size: 20,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.primary),
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

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrow_left, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Gerar Or\u00e7amento',
          style: AppTypography.h3.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _allItems.isNotEmpty
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProviderQuotePreviewPage(
                          items: _allItems,
                          total: _total,
                          prazoEntrega: _prazoController.text,
                          condicaoPagamento: _condicoesController.text,
                          garantia: _garantiaController.text,
                          observacoes: _observacoesController.text,
                        ),
                      ),
                    );
                  }
                : null,
            child: Text(
              'Avan\u00e7ar',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _allItems.isNotEmpty ? colors.primary : Colors.grey,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(
                  top: AppSpacing.md,
                  bottom: AppSpacing.xl,
                ),
                children: [
                  _buildSection(
                    title: 'Servi\u00e7os',
                    items: _servicos,
                    onAdd: _addServico,
                    onRemove: _removeServico,
                  ),
                  _buildSection(
                    title: 'Materiais',
                    items: _materiais,
                    onAdd: _addMaterial,
                    onRemove: _removeMaterial,
                  ),
                  _buildConditionsSection(colors),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Parcial', style: AppTypography.h3),
                    Text(
                      'R\$ ${_total.toStringAsFixed(2)}',
                      style: AppTypography.h2.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProviderQuotePreviewPage extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final double total;
  final String prazoEntrega;
  final String condicaoPagamento;
  final String garantia;
  final String observacoes;
  final bool isReadOnly;

  const ProviderQuotePreviewPage({
    super.key,
    required this.items,
    required this.total,
    this.prazoEntrega = '',
    this.condicaoPagamento = '',
    this.garantia = '',
    this.observacoes = '',
    this.isReadOnly = false,
  });

  @override
  State<ProviderQuotePreviewPage> createState() =>
      _ProviderQuotePreviewPageState();
}

class _ProviderQuotePreviewPageState extends State<ProviderQuotePreviewPage> {
  bool _isProviderSigned = false;
  String? _providerSignedDate;
  List<Offset?> _savedSignaturePoints = [];

  @override
  void initState() {
    super.initState();
    final quoteState = JobbleQuoteState.instance;
    if (widget.isReadOnly && quoteState.isProviderSigned) {
      _isProviderSigned = true;
      _providerSignedDate =
          quoteState.providerSignedDate ?? '18/09/2026 às 14:35';
      _savedSignaturePoints = List.from(quoteState.providerSignaturePoints);
    }
  }

  void _openProviderSignatureModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _ProviderSignatureModal(
          totalValue: 'R\$ ${widget.total.toStringAsFixed(2)}',
          onConfirm: (List<Offset?> points) {
            final now = DateTime.now();
            final formattedDate =
                '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} às ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

            setState(() {
              _isProviderSigned = true;
              _providerSignedDate = formattedDate;
              _savedSignaturePoints = List.from(points);
            });

            JobbleQuoteState.instance.sendQuoteByProvider(
              quoteItems: widget.items,
              quoteTotal: widget.total,
              prazo: widget.prazoEntrega,
              condicoes: widget.condicaoPagamento,
              gar: widget.garantia,
              obs: widget.observacoes,
              signedDate: formattedDate,
              signaturePoints: points,
            );

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(LucideIcons.circle_check, color: Colors.white),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Orçamento assinado e enviado ao cliente com sucesso!',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 4),
              ),
            );

            Future.delayed(const Duration(milliseconds: 600), () {
              if (mounted) {
                Navigator.of(context).popUntil(
                  (route) =>
                      route.settings.name == 'provider_shell' || route.isFirst,
                );
              }
            });
          },
        );
      },
    );
  }

  Future<void> _downloadPdf(BuildContext context) async {
    final quoteState = JobbleQuoteState.instance;
    await QuotePdfService.generateAndDownloadPdf(
      items: widget.items,
      total: widget.total,
      prazoEntrega: widget.prazoEntrega,
      condicaoPagamento: widget.condicaoPagamento,
      garantia: widget.garantia,
      observacoes: widget.observacoes,
      isProviderSigned: _isProviderSigned,
      providerSignedDate: _providerSignedDate,
      providerSignaturePoints: _savedSignaturePoints,
      isClientSigned: quoteState.isClientSigned,
      clientSignedDate: quoteState.clientSignedDate,
      clientSignaturePoints: quoteState.clientSignaturePoints,
    );
  }

  Widget _buildTable(String title, List<Map<String, dynamic>> tableItems) {
    if (tableItems.isEmpty) return const SizedBox.shrink();

    double tableTotal = tableItems.fold(
      0,
      (sum, item) => sum + (item['qtd'] * item['unit']),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(3),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1.5),
                3: FlexColumnWidth(1.5),
              },
              border: TableBorder(
                horizontalInside: BorderSide(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey[100]),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Descrição',
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Qtd',
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Unitário',
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Total',
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
                ...tableItems.map((it) {
                  final double unit = it['unit'];
                  final int qtd = it['qtd'];
                  final double subtotal = unit * qtd;
                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(it['desc'], style: AppTypography.caption),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          qtd.toString(),
                          style: AppTypography.caption,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          'R\$ ${unit.toStringAsFixed(2)}',
                          style: AppTypography.caption,
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          'R\$ ${subtotal.toStringAsFixed(2)}',
                          style: AppTypography.caption,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  );
                }),
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey[50]),
                  children: [
                    const Padding(padding: EdgeInsets.all(12), child: Text('')),
                    const Padding(padding: EdgeInsets.all(12), child: Text('')),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Subtotal',
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'R\$ ${tableTotal.toStringAsFixed(2)}',
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final List<Map<String, dynamic>> servicos = widget.items
        .where((i) => i['type'] == 'Serviço' || i['type'] == null)
        .toList();
    final List<Map<String, dynamic>> materiais = widget.items
        .where((i) => i['type'] == 'Material')
        .toList();

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrow_left, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Pré-visualização do PDF',
          style: AppTypography.h3.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner informativo
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isProviderSigned
                            ? Colors.green[50]
                            : Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _isProviderSigned
                              ? Colors.green[300]!
                              : Colors.blue[200]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isProviderSigned
                                ? LucideIcons.badge_check
                                : LucideIcons.signature,
                            color: _isProviderSigned
                                ? Colors.green[700]
                                : Colors.blue[700],
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isProviderSigned
                                      ? 'Orçamento Assinado Digitalmente'
                                      : 'Revise os dados antes de assinar e enviar',
                                  style: AppTypography.caption.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: _isProviderSigned
                                        ? Colors.green[900]
                                        : Colors.blue[900],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _isProviderSigned
                                      ? 'Sua assinatura foi registrada no documento. O cliente receberá a proposta formal.'
                                      : 'Ao assinar, este orçamento será enviado formalmente para o cliente Gabriel.',
                                  style: AppTypography.caption.copyWith(
                                    fontSize: 11,
                                    color: _isProviderSigned
                                        ? Colors.green[800]
                                        : Colors.blue[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const CircleAvatar(
                              radius: 24,
                              backgroundImage: AssetImage(
                                'assets/images/logo_pintor.jpg',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Roberto Pinturas',
                                  style: AppTypography.h3.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'roberto@pinturas.com',
                                  style: AppTypography.caption.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  '(11) 99999-9999',
                                  style: AppTypography.caption.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'ORÇAMENTO',
                              style: AppTypography.h2.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colors.primary,
                              ),
                            ),
                            Text(
                              '#0038',
                              style: AppTypography.h3.copyWith(
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Data: 18/09/2026',
                              style: AppTypography.caption.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Faturado para:',
                                  style: AppTypography.caption.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Gabriel',
                                  style: AppTypography.body.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Rua das Flores, 123',
                                  style: AppTypography.caption,
                                ),
                                Text(
                                  'Bairro Jardim Botânico',
                                  style: AppTypography.caption,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    _buildTable('Serviços', servicos),
                    _buildTable('Materiais', materiais),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: 250,
                          child: Column(
                            children: [
                              if (servicos.isNotEmpty &&
                                  materiais.isNotEmpty) ...[
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total Serviços',
                                      style: AppTypography.body,
                                    ),
                                    Text(
                                      'R\$ ${servicos.fold(0.0, (sum, item) => sum + (item['qtd'] * item['unit'])).toStringAsFixed(2)}',
                                      style: AppTypography.body,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total Materiais',
                                      style: AppTypography.body,
                                    ),
                                    Text(
                                      'R\$ ${materiais.fold(0.0, (sum, item) => sum + (item['qtd'] * item['unit'])).toStringAsFixed(2)}',
                                      style: AppTypography.body,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Divider(),
                                const SizedBox(height: 8),
                              ],
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'TOTAL GERAL',
                                    style: AppTypography.h3.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'R\$ ${widget.total.toStringAsFixed(2)}',
                                    style: AppTypography.h3.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (widget.prazoEntrega.isNotEmpty ||
                        widget.condicaoPagamento.isNotEmpty ||
                        widget.garantia.isNotEmpty ||
                        widget.observacoes.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xl),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(8),
                                ),
                              ),
                              child: Text(
                                'PRAZOS, CONDIÇÕES E GARANTIA',
                                style: AppTypography.caption.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (widget
                                                .prazoEntrega
                                                .isNotEmpty) ...[
                                              Text(
                                                'Prazo de Execução / Entrega:',
                                                style: AppTypography.caption
                                                    .copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.grey[600],
                                                    ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                widget.prazoEntrega,
                                                style: AppTypography.body
                                                    .copyWith(fontSize: 13),
                                              ),
                                              const SizedBox(height: 8),
                                            ],
                                            if (widget
                                                .condicaoPagamento
                                                .isNotEmpty) ...[
                                              Text(
                                                'Condição de Pagamento:',
                                                style: AppTypography.caption
                                                    .copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.grey[600],
                                                    ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                widget.condicaoPagamento,
                                                style: AppTypography.body
                                                    .copyWith(fontSize: 13),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (widget.garantia.isNotEmpty) ...[
                                              Text(
                                                'Garantia do Serviço:',
                                                style: AppTypography.caption
                                                    .copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.grey[600],
                                                    ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                widget.garantia,
                                                style: AppTypography.body
                                                    .copyWith(fontSize: 13),
                                              ),
                                              const SizedBox(height: 8),
                                            ],
                                            Text(
                                              'Validade da Proposta:',
                                              style: AppTypography.caption
                                                  .copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.grey[600],
                                                  ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '15 dias corridos',
                                              style: AppTypography.body
                                                  .copyWith(fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (widget.observacoes.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    const Divider(),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Observações:',
                                      style: AppTypography.caption.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.observacoes,
                                      style: AppTypography.caption.copyWith(
                                        fontSize: 12,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xxl),
                    Text(
                      'Assinaturas Digitais das Partes',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _isProviderSigned
                                  ? Colors.green[50]?.withValues(alpha: 0.5)
                                  : Colors.orange[50]?.withValues(alpha: 0.5),
                              border: Border.all(
                                color: _isProviderSigned
                                    ? Colors.green[300]!
                                    : Colors.orange[300]!,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _isProviderSigned
                                          ? LucideIcons.circle_check
                                          : LucideIcons.clock,
                                      size: 14,
                                      color: _isProviderSigned
                                          ? Colors.green[700]
                                          : Colors.orange[800],
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        _isProviderSigned
                                            ? 'ASSINADO DIGITALMENTE'
                                            : 'PENDENTE DE ASSINATURA',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: _isProviderSigned
                                              ? Colors.green[800]
                                              : Colors.orange[800],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Roberto Pinturas',
                                  style: AppTypography.caption.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Prestador de Serviços',
                                  style: AppTypography.caption.copyWith(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                if (_isProviderSigned) ...[
                                  Text(
                                    _providerSignedDate ?? 'Hoje',
                                    style: AppTypography.caption.copyWith(
                                      fontSize: 9,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    'Chave: #JB-PR-9921',
                                    style: AppTypography.caption.copyWith(
                                      fontSize: 8.5,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                  if (_savedSignaturePoints.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    SizedBox(
                                      height: 24,
                                      width: double.infinity,
                                      child: CustomPaint(
                                        painter:
                                            _ProviderSignaturePreviewPainter(
                                              _savedSignaturePoints,
                                            ),
                                      ),
                                    ),
                                  ],
                                ] else ...[
                                  Text(
                                    'Você assinará ao enviar',
                                    style: AppTypography.caption.copyWith(
                                      fontSize: 9,
                                      color: Colors.orange[900],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: JobbleQuoteState.instance.isClientSigned
                                  ? Colors.green[50]?.withValues(alpha: 0.5)
                                  : Colors.grey[50],
                              border: Border.all(
                                color: JobbleQuoteState.instance.isClientSigned
                                    ? Colors.green[300]!
                                    : Colors.grey[300]!,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      JobbleQuoteState.instance.isClientSigned
                                          ? LucideIcons.circle_check
                                          : LucideIcons.clock,
                                      size: 14,
                                      color:
                                          JobbleQuoteState
                                              .instance
                                              .isClientSigned
                                          ? Colors.green[700]
                                          : Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      JobbleQuoteState.instance.isClientSigned
                                          ? 'ASSINADO DIGITALMENTE'
                                          : 'AGUARDANDO CLIENTE',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            JobbleQuoteState
                                                .instance
                                                .isClientSigned
                                            ? Colors.green[800]
                                            : Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Gabriel',
                                  style: AppTypography.caption.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Aceite do Cliente',
                                  style: AppTypography.caption.copyWith(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                if (JobbleQuoteState
                                    .instance
                                    .isClientSigned) ...[
                                  Text(
                                    JobbleQuoteState
                                            .instance
                                            .clientSignedDate ??
                                        'Hoje',
                                    style: AppTypography.caption.copyWith(
                                      fontSize: 9,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    'Chave: #JB-CL-5501',
                                    style: AppTypography.caption.copyWith(
                                      fontSize: 8.5,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ] else ...[
                                  Text(
                                    'Aguardando retorno',
                                    style: AppTypography.caption.copyWith(
                                      fontSize: 9,
                                      color: Colors.orange[900],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const Divider(),
                    const SizedBox(height: AppSpacing.sm),
                    Center(
                      child: Text(
                        'Obrigado pela preferência!\nEste orçamento foi emitido eletronicamente via Jobble.',
                        textAlign: TextAlign.center,
                        style: AppTypography.caption.copyWith(
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: OutlinedButton.icon(
                      onPressed: () => _downloadPdf(context),
                      icon: const Icon(LucideIcons.download, size: 20),
                      label: const Text('Baixar PDF'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 1,
                    child: (widget.isReadOnly || _isProviderSigned)
                        ? ElevatedButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              LucideIcons.arrow_left,
                              color: Colors.white,
                              size: 20,
                            ),
                            label: const Text(
                              'Voltar ao Painel',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.colors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: _openProviderSignatureModal,
                            icon: const Icon(
                              LucideIcons.pen_tool,
                              color: Colors.white,
                              size: 20,
                            ),
                            label: const Text(
                              'Assinar e Enviar',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.colors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Modal de Assinatura Digital do Prestador
class _ProviderSignatureModal extends StatefulWidget {
  final String totalValue;
  final void Function(List<Offset?> points) onConfirm;

  const _ProviderSignatureModal({
    required this.totalValue,
    required this.onConfirm,
  });

  @override
  State<_ProviderSignatureModal> createState() =>
      _ProviderSignatureModalState();
}

class _ProviderSignatureModalState extends State<_ProviderSignatureModal> {
  final List<Offset?> _points = [];
  bool _agreed = true;
  int _signatureMode = 0; // 0 = Desenhar rubrica, 1 = Certificado Profissional

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.pen_tool,
                  color: colors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assinatura Digital do Orçamento',
                      style: AppTypography.h3.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Roberto Pinturas • Valor Total: ${widget.totalValue}',
                      style: AppTypography.caption.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.x, color: Colors.grey),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Alternador de modo de assinatura
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _signatureMode = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _signatureMode == 0
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: _signatureMode == 0
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Desenhar Rubrica',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _signatureMode == 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _signatureMode == 0
                              ? Colors.black
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _signatureMode = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _signatureMode == 1
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: _signatureMode == 1
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Certificado Profissional',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _signatureMode == 1
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _signatureMode == 1
                              ? Colors.black
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Conteúdo do modo selecionado
          if (_signatureMode == 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Desenhe sua rubrica no espaço abaixo:',
                  style: AppTypography.caption.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _points.clear()),
                  icon: const Icon(
                    LucideIcons.refresh_cw,
                    size: 14,
                    color: Colors.grey,
                  ),
                  label: const Text(
                    'Limpar',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Positioned(
                      bottom: 35,
                      left: 20,
                      right: 20,
                      child: Container(height: 1, color: Colors.grey[300]),
                    ),
                    Positioned(
                      bottom: 12,
                      right: 20,
                      child: Text(
                        'Rubrica do Prestador',
                        style: TextStyle(color: Colors.grey[400], fontSize: 10),
                      ),
                    ),
                    GestureDetector(
                      onPanUpdate: (DragUpdateDetails details) {
                        setState(() {
                          _points.add(details.localPosition);
                        });
                      },
                      onPanEnd: (DragEndDetails details) {
                        setState(() {
                          _points.add(null);
                        });
                      },
                      child: CustomPaint(
                        painter: _ProviderSignaturePainter(_points),
                        size: Size.infinite,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.badge_check,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Certificado Digital Profissional (Jobble Pro)',
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Titular: Roberto da Silva (Roberto Pinturas)',
                    style: AppTypography.caption,
                  ),
                  Text(
                    'Documento: CNPJ 38.921.402/0001-88',
                    style: AppTypography.caption,
                  ),
                  Text(
                    'Autenticação: Assinatura Eletrônica Homologada',
                    style: AppTypography.caption.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),

          // Checkbox estilizado (fundo branco, ícone verde, sem pintar o quadrado todo)
          GestureDetector(
            onTap: () => setState(() => _agreed = !_agreed),
            behavior: HitTestBehavior.opaque,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _agreed ? colors.primary : Colors.grey[400]!,
                      width: _agreed ? 2.0 : 1.5,
                    ),
                    boxShadow: _agreed
                        ? [
                            BoxShadow(
                              color: colors.primary.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: _agreed
                      ? Icon(LucideIcons.check, size: 17, color: colors.primary)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Declaro que revisei os itens, prazos e condições deste orçamento e firmo a proposta comercial.',
                    style: AppTypography.caption.copyWith(
                      fontSize: 12,
                      color: Colors.grey[800],
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Nota de validade jurídica
          Row(
            children: [
              const Icon(LucideIcons.lock, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Assinatura com validade jurídica garantida conforme MP nº 2.200-2/2001.',
                  style: AppTypography.caption.copyWith(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Botão Confirmar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _agreed
                  ? () {
                      Navigator.of(context).pop();
                      widget.onConfirm(_points);
                    }
                  : null,
              icon: const Icon(LucideIcons.send, color: Colors.white, size: 18),
              label: const Text(
                'Confirmar Assinatura e Enviar Proposta',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Pintor da assinatura do prestador
class _ProviderSignaturePainter extends CustomPainter {
  final List<Offset?> points;

  _ProviderSignaturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color =
          const Color(0xFF0D47A1) // Azul caneta formal
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_ProviderSignaturePainter oldDelegate) => true;
}

// Pintor da assinatura miniatura no preview do prestador
class _ProviderSignaturePreviewPainter extends CustomPainter {
  final List<Offset?> points;

  _ProviderSignaturePreviewPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0D47A1)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.5;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(
          Offset(points[i]!.dx * 0.4, points[i]!.dy * 0.3),
          Offset(points[i + 1]!.dx * 0.4, points[i + 1]!.dy * 0.3),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ProviderSignaturePreviewPainter oldDelegate) => true;
}
