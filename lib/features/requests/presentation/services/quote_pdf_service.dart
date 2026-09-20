import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class QuotePdfService {
  static Future<void> generateAndDownloadPdf({
    required List<Map<String, dynamic>> items,
    required double total,
    required String prazoEntrega,
    required String condicaoPagamento,
    required String garantia,
    required String observacoes,
    required bool isProviderSigned,
    String? providerSignedDate,
    List<Offset?>? providerSignaturePoints,
    bool isClientSigned = false,
    String? clientSignedDate,
    List<Offset?>? clientSignaturePoints,
  }) async {
    final bytes = await generatePdfBytes(
      items: items,
      total: total,
      prazoEntrega: prazoEntrega,
      condicaoPagamento: condicaoPagamento,
      garantia: garantia,
      observacoes: observacoes,
      isProviderSigned: isProviderSigned,
      providerSignedDate: providerSignedDate,
      providerSignaturePoints: providerSignaturePoints,
      isClientSigned: isClientSigned,
      clientSignedDate: clientSignedDate,
      clientSignaturePoints: clientSignaturePoints,
    );
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  static Future<Uint8List> generatePdfBytes({
    required List<Map<String, dynamic>> items,
    required double total,
    required String prazoEntrega,
    required String condicaoPagamento,
    required String garantia,
    required String observacoes,
    required bool isProviderSigned,
    String? providerSignedDate,
    List<Offset?>? providerSignaturePoints,
    bool isClientSigned = false,
    String? clientSignedDate,
    List<Offset?>? clientSignaturePoints,
  }) async {
    final ByteData bytes = await rootBundle.load(
      'assets/images/logo_pintor.jpg',
    );
    final Uint8List logoBytes = bytes.buffer.asUint8List();
    final logoImage = pw.MemoryImage(logoBytes);

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: pw.Font.ttf(
          await rootBundle.load('assets/fonts/Urbanist-Regular.ttf'),
        ),
        bold: pw.Font.ttf(
          await rootBundle.load('assets/fonts/Urbanist-Bold.ttf'),
        ),
      ),
    );

    final servicos = items
        .where((i) => i['type'] == 'Serviço' || i['type'] == null)
        .toList();
    final materiais = items.where((i) => i['type'] == 'Material').toList();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 26),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Cabeçalho da Empresa & Identificação do Orçamento
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.ClipOval(
                        child: pw.Image(
                          logoImage,
                          width: 50,
                          height: 50,
                          fit: pw.BoxFit.cover,
                        ),
                      ),
                      pw.SizedBox(width: 12),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Roberto Pinturas',
                            style: pw.TextStyle(
                              fontSize: 20,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'roberto@pinturas.com',
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey600,
                            ),
                          ),
                          pw.Text(
                            '(11) 99999-9999',
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'ORÇAMENTO',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromInt(0xFF10B981),
                        ),
                      ),
                      pw.Text(
                        '#0038',
                        style: const pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.grey500,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Data: 18/09/2026',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 14),

              // Dados do Cliente (Faturado para) - exatamente como gerado pelo prestador
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(6),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Faturado para:',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Gabriel',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Cliente Jobble',
                      style: const pw.TextStyle(
                        fontSize: 9.5,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      'Bairro Jardim Botânico, São Paulo - SP',
                      style: const pw.TextStyle(
                        fontSize: 9.5,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),

              // Tabela de Serviços
              _buildPdfTable('SERVIÇOS', servicos),
              pw.SizedBox(height: 8),

              // Tabela de Materiais
              _buildPdfTable('MATERIAIS', materiais),
              pw.SizedBox(height: 6),

              // Total do Orçamento
              pw.Divider(thickness: 0.8, color: PdfColors.grey300),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    'Total do Orçamento: ',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'R\$ ${total.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF111827),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),

              // Box de Prazos, Condições e Garantia
              if (prazoEntrega.isNotEmpty ||
                  condicaoPagamento.isNotEmpty ||
                  garantia.isNotEmpty ||
                  observacoes.isNotEmpty) ...[
                pw.Container(
                  width: double.infinity,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(6),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: double.infinity,
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.grey100,
                          borderRadius: pw.BorderRadius.vertical(
                            top: pw.Radius.circular(5),
                          ),
                        ),
                        child: pw.Text(
                          'PRAZOS, CONDIÇÕES E GARANTIA',
                          style: pw.TextStyle(
                            fontSize: 8.5,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Expanded(
                                  child: pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    children: [
                                      if (prazoEntrega.isNotEmpty) ...[
                                        pw.Text(
                                          'Prazo de Execução / Entrega:',
                                          style: pw.TextStyle(
                                            fontSize: 8,
                                            fontWeight: pw.FontWeight.bold,
                                            color: PdfColors.grey600,
                                          ),
                                        ),
                                        pw.SizedBox(height: 1),
                                        pw.Text(
                                          prazoEntrega,
                                          style: const pw.TextStyle(
                                            fontSize: 9,
                                          ),
                                        ),
                                        pw.SizedBox(height: 4),
                                      ],
                                      if (condicaoPagamento.isNotEmpty) ...[
                                        pw.Text(
                                          'Condição de Pagamento:',
                                          style: pw.TextStyle(
                                            fontSize: 8,
                                            fontWeight: pw.FontWeight.bold,
                                            color: PdfColors.grey600,
                                          ),
                                        ),
                                        pw.SizedBox(height: 1),
                                        pw.Text(
                                          condicaoPagamento,
                                          style: const pw.TextStyle(
                                            fontSize: 9,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                pw.SizedBox(width: 16),
                                pw.Expanded(
                                  child: pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    children: [
                                      if (garantia.isNotEmpty) ...[
                                        pw.Text(
                                          'Garantia do Serviço:',
                                          style: pw.TextStyle(
                                            fontSize: 8,
                                            fontWeight: pw.FontWeight.bold,
                                            color: PdfColors.grey600,
                                          ),
                                        ),
                                        pw.SizedBox(height: 1),
                                        pw.Text(
                                          garantia,
                                          style: const pw.TextStyle(
                                            fontSize: 9,
                                          ),
                                        ),
                                        pw.SizedBox(height: 4),
                                      ],
                                      pw.Text(
                                        'Validade da Proposta:',
                                        style: pw.TextStyle(
                                          fontSize: 8,
                                          fontWeight: pw.FontWeight.bold,
                                          color: PdfColors.grey600,
                                        ),
                                      ),
                                      pw.SizedBox(height: 1),
                                      pw.Text(
                                        '15 dias corridos',
                                        style: const pw.TextStyle(fontSize: 9),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (observacoes.isNotEmpty) ...[
                              pw.SizedBox(height: 4),
                              pw.Divider(
                                color: PdfColors.grey200,
                                thickness: 0.5,
                              ),
                              pw.SizedBox(height: 2),
                              pw.Text(
                                'Observações:',
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.grey600,
                                ),
                              ),
                              pw.SizedBox(height: 1),
                              pw.Text(
                                observacoes,
                                style: const pw.TextStyle(
                                  fontSize: 8.5,
                                  color: PdfColors.grey800,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),
              ],

              // Campo de Assinaturas Digitais das Partes
              pw.Text(
                'Assinaturas Digitais das Partes',
                style: pw.TextStyle(
                  fontSize: 9.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey800,
                ),
              ),
              pw.SizedBox(height: 5),

              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Box 1: Prestador (Roberto Pinturas)
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: isProviderSigned
                            ? PdfColor.fromInt(0xFFF0FDF4)
                            : PdfColors.grey50,
                        border: pw.Border.all(
                          color: isProviderSigned
                              ? PdfColor.fromInt(0xFF86EFAC)
                              : PdfColors.grey300,
                          width: 1,
                        ),
                        borderRadius: const pw.BorderRadius.all(
                          pw.Radius.circular(6),
                        ),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: pw.BoxDecoration(
                              color: isProviderSigned
                                  ? PdfColor.fromInt(0xFFDCFCE7)
                                  : PdfColors.orange50,
                              borderRadius: const pw.BorderRadius.all(
                                pw.Radius.circular(3),
                              ),
                            ),
                            child: pw.Text(
                              isProviderSigned
                                  ? 'ASSINADO DIGITALMENTE'
                                  : 'PENDENTE DE ASSINATURA',
                              style: pw.TextStyle(
                                fontSize: 7,
                                fontWeight: pw.FontWeight.bold,
                                color: isProviderSigned
                                    ? PdfColor.fromInt(0xFF166534)
                                    : PdfColors.orange900,
                              ),
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Roberto Pinturas',
                            style: pw.TextStyle(
                              fontSize: 9.5,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            'Prestador de Serviços',
                            style: const pw.TextStyle(
                              fontSize: 7.5,
                              color: PdfColors.grey600,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          if (isProviderSigned) ...[
                            pw.Text(
                              'Assinado em ${providerSignedDate ?? '18/09/2026 às 14:35'}',
                              style: const pw.TextStyle(
                                fontSize: 7,
                                color: PdfColors.grey600,
                              ),
                            ),
                            pw.Text(
                              'Chave: #JB-PR-9921',
                              style: const pw.TextStyle(
                                fontSize: 6.5,
                                color: PdfColors.grey500,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            // Rubrica em azul caneta
                            pw.SvgImage(
                              svg: _generateSvgSignature(
                                providerSignaturePoints,
                              ),
                              width: 120,
                              height: 26,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 12),

                  // Box 2: Cliente (Gabriel)
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: isClientSigned
                            ? PdfColor.fromInt(0xFFF0FDF4)
                            : PdfColors.grey50,
                        border: pw.Border.all(
                          color: isClientSigned
                              ? PdfColor.fromInt(0xFF86EFAC)
                              : PdfColors.grey300,
                          width: 1,
                        ),
                        borderRadius: const pw.BorderRadius.all(
                          pw.Radius.circular(6),
                        ),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: pw.BoxDecoration(
                              color: isClientSigned
                                  ? PdfColor.fromInt(0xFFDCFCE7)
                                  : PdfColors.grey200,
                              borderRadius: const pw.BorderRadius.all(
                                pw.Radius.circular(3),
                              ),
                            ),
                            child: pw.Text(
                              isClientSigned
                                  ? 'ASSINADO DIGITALMENTE'
                                  : 'AGUARDANDO CLIENTE',
                              style: pw.TextStyle(
                                fontSize: 7,
                                fontWeight: pw.FontWeight.bold,
                                color: isClientSigned
                                    ? PdfColor.fromInt(0xFF166534)
                                    : PdfColors.grey700,
                              ),
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Gabriel',
                            style: pw.TextStyle(
                              fontSize: 9.5,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            'Aceite do Cliente',
                            style: const pw.TextStyle(
                              fontSize: 7.5,
                              color: PdfColors.grey600,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          if (isClientSigned) ...[
                            pw.Text(
                              'Assinado em ${clientSignedDate ?? '18/09/2026'}',
                              style: const pw.TextStyle(
                                fontSize: 7,
                                color: PdfColors.grey600,
                              ),
                            ),
                            pw.Text(
                              'Chave: #JB-CL-5501',
                              style: const pw.TextStyle(
                                fontSize: 6.5,
                                color: PdfColors.grey500,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.SvgImage(
                              svg: _generateSvgSignature(clientSignaturePoints),
                              width: 120,
                              height: 26,
                            ),
                          ] else ...[
                            pw.Text(
                              'Aguardando retorno para início',
                              style: const pw.TextStyle(
                                fontSize: 7,
                                color: PdfColors.orange900,
                              ),
                            ),
                            pw.SizedBox(height: 8),
                            pw.Container(height: 1, color: PdfColors.grey300),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'Assinatura do Cliente',
                              style: const pw.TextStyle(
                                fontSize: 6.5,
                                color: PdfColors.grey400,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),

              // Rodapé
              pw.Divider(thickness: 0.5, color: PdfColors.grey300),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  'Obrigado pela preferência!\nEste orçamento foi emitido eletronicamente via Jobble.',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(
                    fontSize: 7.5,
                    color: PdfColors.grey500,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildPdfTable(
    String title,
    List<Map<String, dynamic>> tableItems,
  ) {
    if (tableItems.isEmpty) return pw.SizedBox.shrink();

    double tableTotal = tableItems.fold(
      0,
      (sum, item) => sum + ((item['qtd'] as num) * (item['unit'] as num)),
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 9.5,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey800,
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: const {
            0: pw.FlexColumnWidth(3),
            1: pw.FlexColumnWidth(1),
            2: pw.FlexColumnWidth(1.5),
            3: pw.FlexColumnWidth(1.5),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _buildTableCell('Descrição', isHeader: true),
                _buildTableCell(
                  'Qtd',
                  isHeader: true,
                  align: pw.TextAlign.center,
                ),
                _buildTableCell(
                  'Unitário',
                  isHeader: true,
                  align: pw.TextAlign.right,
                ),
                _buildTableCell(
                  'Subtotal',
                  isHeader: true,
                  align: pw.TextAlign.right,
                ),
              ],
            ),
            ...tableItems.map((it) {
              final double unit = (it['unit'] as num).toDouble();
              final int qtd = (it['qtd'] as num).toInt();
              final double subtotal = unit * qtd;
              return pw.TableRow(
                children: [
                  _buildTableCell(it['desc']),
                  _buildTableCell(qtd.toString(), align: pw.TextAlign.center),
                  _buildTableCell(
                    'R\$ ${unit.toStringAsFixed(2)}',
                    align: pw.TextAlign.right,
                  ),
                  _buildTableCell(
                    'R\$ ${subtotal.toStringAsFixed(2)}',
                    align: pw.TextAlign.right,
                  ),
                ],
              );
            }),
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey50),
              children: [
                _buildTableCell(''),
                _buildTableCell(''),
                _buildTableCell(
                  'Subtotal',
                  isHeader: true,
                  align: pw.TextAlign.right,
                ),
                _buildTableCell(
                  'R\$ ${tableTotal.toStringAsFixed(2)}',
                  isHeader: true,
                  align: pw.TextAlign.right,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: isHeader ? 8 : 8,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.grey800 : PdfColors.black,
        ),
      ),
    );
  }

  static String _generateSvgSignature(List<Offset?>? points) {
    if (points != null && points.isNotEmpty) {
      final strokes = <String>[];
      var stroke = StringBuffer();
      void finishStroke() {
        if (stroke.isNotEmpty) {
          strokes.add(
            '<path d="$stroke" fill="none" stroke="#0D47A1" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>',
          );
          stroke = StringBuffer();
        }
      }

      for (final point in points) {
        if (point == null) {
          finishStroke();
        } else {
          stroke.write(
            '${stroke.isEmpty ? 'M' : 'L'} ${point.dx.toStringAsFixed(1)} ${point.dy.toStringAsFixed(1)} ',
          );
        }
      }
      finishStroke();
      return '<svg viewBox="0 0 300 120" width="120" height="26" xmlns="http://www.w3.org/2000/svg">${strokes.join()}</svg>';
    }

    // Rubrica caneta formal padrão para Roberto Pinturas
    return '''<svg viewBox="0 0 160 40" width="120" height="26" xmlns="http://www.w3.org/2000/svg">
  <path d="M 8 28 C 18 8, 28 4, 38 16 C 45 28, 52 32, 62 14 C 72 4, 82 24, 94 20 C 104 16, 116 10, 130 16 C 140 20, 148 24, 155 18" fill="none" stroke="#0D47A1" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M 22 30 C 50 34, 95 32, 140 26" fill="none" stroke="#0D47A1" stroke-width="1.8" stroke-linecap="round"/>
</svg>''';
  }
}
