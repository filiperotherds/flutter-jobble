/// Atualizações de andamento que o profissional publica durante um serviço.
///
/// Ficam aqui, e não dentro da tela de acompanhamento, porque o painel também
/// precisa delas: é a contagem que aparece no card do trabalho em andamento e
/// avisa que a ferramenta existe. Enquanto não há contrato no servidor, a
/// lista vive em memória e dura o que durar o app aberto.
class JobProgressUpdates {
  const JobProgressUpdates._();

  static final List<Map<String, dynamic>> _updates = [
    {
      'title': 'Materiais comprados',
      'desc':
          'Comprei o tubo de reposição, o cimento e a argamassa. Começo a '
          'abrir a parede amanhã cedo.',
      'progress': 0.15,
      'date': DateTime.now().subtract(const Duration(days: 3, hours: 2)),
      'hasPhotos': true,
      'photos': const ['assets/images/portfolio_plumbing.jpg'],
    },
    {
      'title': 'Vazamento localizado',
      'desc':
          'Abri a parede do banheiro e achei a origem: uma conexão trincada '
          'atrás do box. Era menor do que parecia pela mancha.',
      'progress': 0.40,
      'date': DateTime.now().subtract(const Duration(days: 2, hours: 5)),
      'hasPhotos': true,
      'photos': const [
        'assets/images/portfolio_plumbing.jpg',
        'assets/images/portfolio_electrical.jpg',
      ],
    },
    {
      'title': 'Encanamento substituído',
      'desc':
          'Troquei o trecho danificado e testei a pressão por duas horas: '
          'sem gotejamento. Amanhã fecho a parede com massa e reboco.',
      'progress': 0.65,
      'date': DateTime.now().subtract(const Duration(hours: 4)),
      'hasPhotos': true,
      'photos': const ['assets/images/portfolio_painting.jpg'],
    },
  ];

  /// Da mais antiga para a mais nova.
  static List<Map<String, dynamic>> get all =>
      List<Map<String, dynamic>>.unmodifiable(_updates);

  static int get count => _updates.length;

  /// Quanto do serviço a última atualização declarou concluído.
  static double get overallProgress =>
      _updates.isEmpty ? 0 : _updates.last['progress'] as double;

  static void add(Map<String, dynamic> update) => _updates.add(update);
}
