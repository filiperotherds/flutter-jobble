import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tcc/features/requests/presentation/services/quote_pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final signed in [false, true]) {
    test('generates valid PDF, signatures: $signed', () async {
      final bytes = await QuotePdfService.generatePdfBytes(
        items: [
          {'desc': 'Pintura', 'qtd': 2, 'unit': 150.0, 'type': 'Serviço'},
          {'desc': 'Tinta', 'qtd': 1, 'unit': 200.0, 'type': 'Material'},
        ],
        total: 500,
        prazoEntrega: '3 dias',
        condicaoPagamento: 'Na entrega',
        garantia: '90 dias',
        observacoes: 'Proteger móveis',
        isProviderSigned: signed,
        isClientSigned: signed,
        providerSignedDate: '19/09/2026',
        clientSignedDate: '19/09/2026',
        providerSignaturePoints: [
          const Offset(5, 5),
          const Offset(40, 20),
          null,
          const Offset(50, 10),
          const Offset(80, 30),
          null,
        ],
        clientSignaturePoints: [const Offset(3, 8), const Offset(25, 15), null],
      );
      expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
      expect(bytes.length, greaterThan(1000));
      expect(latin1.decode(bytes), contains('%%EOF'));
    });
  }
}
