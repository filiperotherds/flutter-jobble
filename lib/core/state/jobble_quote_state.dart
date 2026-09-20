import 'package:flutter/material.dart';

class JobbleQuoteState extends ChangeNotifier {
  JobbleQuoteState._();
  static final JobbleQuoteState instance = JobbleQuoteState._();

  // Estado do envio da proposta
  bool isQuoteSent = true;

  // Assinatura do Prestador (Roberto Pinturas)
  bool isProviderSigned = true;
  String? providerSignedDate = '18/09/2026 às 14:35';
  List<Offset?> providerSignaturePoints = [];

  // Assinatura do Cliente (Gabriel)
  bool isClientSigned = false;
  String? clientSignedDate;
  List<Offset?> clientSignaturePoints = [];

  // Informações do serviço e partes
  String serviceTitle = 'Pintura Residencial (20m²)';
  String clientName = 'Gabriel';
  String clientAddress = 'Bairro Jardim Botânico';
  String providerName = 'Roberto Pinturas';

  // Condições do orçamento
  String prazoEntrega = '3 dias úteis';
  String condicaoPagamento = '50% na entrada + 50% na entrega';
  String garantia = '90 dias';
  String observacoes = 'Ambiente desocupado e protegido com lonas plásticas.';

  // Itens do orçamento
  List<Map<String, dynamic>> items = [
    {
      'desc': 'Pintura de Paredes e Teto',
      'qtd': 1,
      'unit': 350.0,
      'type': 'Serviço',
    },
    {
      'desc': 'Aplicação de Massa Corrida',
      'qtd': 1,
      'unit': 130.0,
      'type': 'Serviço',
    },
    {
      'desc': 'Tinta Acrílica Fosca Suvinil 18L',
      'qtd': 1,
      'unit': 280.0,
      'type': 'Material',
    },
    {'desc': 'Fita Crepe e Lixas', 'qtd': 2, 'unit': 15.0, 'type': 'Material'},
  ];

  double get total {
    return items.fold(
      0.0,
      (sum, i) => sum + ((i['qtd'] as num) * (i['unit'] as num)),
    );
  }

  void sendQuoteByProvider({
    required List<Map<String, dynamic>> quoteItems,
    required double quoteTotal,
    required String prazo,
    required String condicoes,
    required String gar,
    required String obs,
    required String signedDate,
    required List<Offset?> signaturePoints,
  }) {
    items = quoteItems.map((item) => Map<String, dynamic>.from(item)).toList();
    isClientSigned = false;
    clientSignedDate = null;
    clientSignaturePoints = [];
    prazoEntrega = prazo;
    condicaoPagamento = condicoes;
    garantia = gar;
    observacoes = obs;
    isProviderSigned = true;
    providerSignedDate = signedDate;
    providerSignaturePoints = List.from(signaturePoints);
    isQuoteSent = true;
    notifyListeners();
  }

  void signByClient({String? signedDate, List<Offset?>? signaturePoints}) {
    final now = DateTime.now();
    isClientSigned = true;
    clientSignedDate =
        signedDate ??
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} às ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    clientSignaturePoints = signaturePoints != null
        ? List.from(signaturePoints)
        : [];
    notifyListeners();
  }

  void reset() {
    isQuoteSent = false;
    isProviderSigned = false;
    providerSignedDate = null;
    providerSignaturePoints.clear();
    isClientSigned = false;
    clientSignedDate = null;
    clientSignaturePoints.clear();
    notifyListeners();
  }
}
