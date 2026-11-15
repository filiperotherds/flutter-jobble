/// Um servidor de mentira, dentro do app, para ver as telas cheias.
///
/// Só entra em cena com `--dart-define=DEMO_DATA=true`. Responde às mesmas
/// rotas que o backend, com o mesmo formato de JSON, e guarda o estado na
/// memória: dá para recusar um pedido, mandar mensagem, assinar um orçamento
/// e ver a tela reagir. Fechou o app, volta tudo ao começo.
///
/// Nada daqui chega ao servidor de verdade. As rotas que este arquivo não
/// conhece — entrar na conta, o perfil — seguem para a rede como sempre.
library;

typedef _Json = Map<String, dynamic>;

/// A demonstração conhece a rota, mas não tem como responder.
class DemoError implements Exception {
  /// O item pedido não existe.
  const DemoError.notFound()
    : status = 404,
      message = 'Não encontrado na demonstração.';

  /// A ação existe no servidor, mas a demonstração não a imita. Recusar aqui
  /// impede que ela vaze para o servidor de verdade.
  const DemoError.unsupported()
    : status = 501,
      message = 'Esta ação não funciona no modo demonstração.';

  final int status;
  final String message;
}

class DemoBackend {
  DemoBackend._() {
    _seed();
  }

  static final DemoBackend instance = DemoBackend._();

  /// Devolvido por [handle] quando a rota não é da demonstração.
  static const Object pass = Object();

  final DateTime _now = DateTime.now();
  int _sequence = 1000;

  bool _acceptingOrders = true;
  final List<_Json> _requests = [];
  final List<_Json> _contracts = [];
  final List<_Json> _reviews = [];
  final List<_Json> _services = [];
  final List<_Json> _portfolio = [];

  /// Mensagens de cada conversa, da mais antiga para a mais nova.
  final Map<String, List<_Json>> _messages = {};

  /// O pedido que abriu cada conversa.
  final Map<String, _Json> _conversationRequest = {};

  static const _Json _provider = {
    'id': 'demo-roberto',
    'name': 'Roberto Pinturas',
    'avatarUrl': null,
  };

  String _id(String prefix) => 'demo-$prefix-${_sequence++}';

  String _ago({int days = 0, int hours = 0, int minutes = 0}) => _now
      .subtract(Duration(days: days, hours: hours, minutes: minutes))
      .toIso8601String();

  String _ahead({int days = 0}) =>
      _now.add(Duration(days: days)).toIso8601String();

  static _Json _person(String id, String name) => {
    'id': 'demo-$id',
    'name': name,
    'avatarUrl': null,
  };

  // ------------------------------------------------------------------ dados

  void _seed() {
    final camila = _person('camila', 'Camila Rocha');
    final fernanda = _person('fernanda', 'Fernanda Lima');
    final rafael = _person('rafael', 'Rafael Souza');
    final beatriz = _person('beatriz', 'Beatriz Almeida');
    final juliana = _person('juliana', 'Juliana Reis');
    final thiago = _person('thiago', 'Thiago Martins');

    // Pedido novo: ninguém respondeu ainda.
    _addRequest(
      id: 'demo-req-7k2f',
      title: 'Pintura de apartamento (2 quartos)',
      description:
          'Apartamento de 68 m², paredes em bom estado. Quero trocar o '
          'branco por um tom areia na sala e nos quartos. Teto continua '
          'branco. Tenho pressa: mudança marcada para o fim do mês.',
      client: camila,
      status: 'PENDING',
      createdAt: _ago(minutes: 25),
      chat: [
        (
          false,
          _ago(minutes: 25),
          'Olá, Roberto! Vi seu perfil e gostei dos trabalhos. Consegue me '
              'passar um orçamento?',
        ),
      ],
    );

    // Em conversa, ainda sem orçamento.
    _addRequest(
      id: 'demo-req-3m9q',
      title: 'Reparo de reboco externo',
      description:
          'O reboco do muro da frente está soltando em uns 4 metros. '
          'Preciso refazer e pintar depois.',
      client: fernanda,
      status: 'ANSWERED',
      createdAt: _ago(hours: 5),
      chat: [
        (false, _ago(hours: 5), 'Boa tarde! O muro tem uns 12 m no total.'),
        (
          true,
          _ago(hours: 4, minutes: 40),
          'Boa tarde, Fernanda! Consigo passar aí amanhã cedo para medir e '
              'ver o estado do reboco?',
        ),
        (false, _ago(hours: 4, minutes: 10), 'Pode sim, depois das 8h.'),
        (true, _ago(hours: 4), 'Combinado. Te mando o orçamento em seguida.'),
      ],
    );

    // Orçamento enviado, esperando o cliente assinar.
    final gate = _addRequest(
      id: 'demo-req-8x4d',
      title: 'Pintura de portão e grades',
      description:
          'Portão de garagem basculante e seis grades de janela. Estão com '
          'ferrugem em alguns pontos.',
      client: rafael,
      status: 'ANSWERED',
      createdAt: _ago(days: 1, hours: 3),
      chat: [
        (false, _ago(days: 1, hours: 3), 'Bom dia! Faz pintura em ferro?'),
        (
          true,
          _ago(days: 1, hours: 2),
          'Bom dia, Rafael! Faço sim: lixo, trato a ferrugem e aplico fundo '
              'antes do esmalte.',
        ),
      ],
    );
    _addProposal(
      gate,
      amountCents: 125000,
      deadlineDays: 4,
      warrantyDays: 90,
      waitingFor: 'CLIENT',
      sentAt: _ago(days: 1),
      notes: 'Inclui lixamento, fundo anticorrosivo e duas demãos de esmalte.',
    );
    _say(gate, false, _ago(hours: 20), 'Recebi! Vou ver com minha esposa.');

    // O cliente já assinou: falta o profissional confirmar.
    final facade = _addRequest(
      id: 'demo-req-5t1b',
      title: 'Pintura de fachada comercial',
      description:
          'Loja de esquina, fachada de 9 m de frente com 4 m de altura. '
          'Precisa ser feita no fim de semana, com a loja fechada.',
      client: beatriz,
      status: 'ANSWERED',
      createdAt: _ago(days: 2, hours: 6),
      chat: [
        (false, _ago(days: 2, hours: 6), 'Olá! Atende comércio também?'),
        (
          true,
          _ago(days: 2, hours: 5),
          'Atendo, Beatriz. Consigo fazer no sábado e domingo para não '
              'atrapalhar o movimento.',
        ),
      ],
    );
    _addProposal(
      facade,
      amountCents: 380000,
      deadlineDays: 7,
      warrantyDays: 180,
      waitingFor: 'PROVIDER',
      sentAt: _ago(days: 2),
      clientSignedAt: _ago(hours: 2),
      notes: 'Tinta acrílica premium, com andaime e proteção da calçada.',
    );
    _say(
      facade,
      false,
      _ago(hours: 2),
      'Assinei o orçamento. Podemos começar neste sábado?',
    );

    // Serviço contratado, em execução.
    final house = _addRequest(
      id: 'demo-req-2h6w',
      title: 'Pintura interna — casa térrea',
      description: 'Três quartos, sala, cozinha e corredor.',
      client: juliana,
      status: 'CONTRACTED',
      createdAt: _ago(days: 9),
      chat: [
        (false, _ago(days: 9), 'Oi, Roberto! A Ana Paula me indicou você.'),
        (true, _ago(days: 9), 'Que bom, Juliana! Me conta o que precisa.'),
      ],
    );
    final houseProposal = _addProposal(
      house,
      amountCents: 290000,
      deadlineDays: 7,
      warrantyDays: 90,
      waitingFor: 'NONE',
      status: 'SIGNED',
      sentAt: _ago(days: 8),
      clientSignedAt: _ago(days: 7),
      providerSignedAt: _ago(days: 6),
      startsOn: _ago(days: 3),
      endsOn: _ahead(days: 4),
    );
    _addContract(house, houseProposal, startedAt: _ago(days: 3));
    _say(house, true, _ago(hours: 6), 'Quartos prontos. Amanhã começo a sala.');
    _say(house, false, _ago(hours: 1), 'Ficou lindo! Obrigada pelas fotos.');

    // Uma conversa antiga, de serviço já entregue.
    final done = _addRequest(
      id: 'demo-req-9c3v',
      title: 'Textura na parede da sala',
      description: 'Parede de 5 m com grafiato.',
      client: thiago,
      status: 'CONTRACTED',
      createdAt: _ago(days: 20),
      chat: [
        (
          true,
          _ago(days: 12),
          'Serviço concluído, Thiago. Qualquer coisa é só chamar.',
        ),
        (false, _ago(days: 12), 'Show, ficou top. Já deixei a avaliação.'),
      ],
    );
    final doneProposal = _addProposal(
      done,
      amountCents: 98000,
      deadlineDays: 2,
      warrantyDays: 90,
      waitingFor: 'NONE',
      status: 'SIGNED',
      sentAt: _ago(days: 19),
      clientSignedAt: _ago(days: 18),
      providerSignedAt: _ago(days: 18),
      startsOn: _ago(days: 14),
      endsOn: _ago(days: 12),
      announce: false,
    );
    _addContract(
      done,
      doneProposal,
      startedAt: _ago(days: 14),
      status: 'COMPLETED',
      completedAt: _ago(days: 12),
    );

    // Tudo que o profissional escreveu já foi lido; do cliente, só as
    // mensagens mais recentes de três conversas ficam por ler.
    for (final entry in _messages.entries) {
      final unreadFrom = switch (entry.key) {
        'demo-conv-7k2f' => 0,
        'demo-conv-5t1b' || 'demo-conv-2h6w' => entry.value.length - 1,
        _ => entry.value.length,
      };
      for (var i = 0; i < entry.value.length; i++) {
        final message = entry.value[i];
        if (message['mine'] == true || i < unreadFrom) {
          message['readAt'] = message['createdAt'];
        }
      }
    }

    _reviews.addAll([
      _review(
        'Thiago Martins',
        5,
        12,
        'Trabalho impecável. Chegou no horário, protegeu os móveis e deixou tudo limpo. A textura ficou exatamente como eu queria.',
        read: false,
      ),
      _review(
        'Ana Paula',
        5,
        16,
        'Super recomendo! Pintou o apartamento inteiro em quatro dias e o acabamento ficou perfeito.',
        reply: 'Obrigado, Ana Paula! Foi um prazer.',
        read: false,
      ),
      _review(
        'Carlos Eduardo',
        4,
        23,
        'Serviço muito bom. Atrasou um dia por causa da chuva, mas avisou com antecedência.',
        reply: 'Obrigado pela compreensão, Carlos.',
      ),
      _review(
        'Marcos Vinícius',
        5,
        31,
        'Resolveu a infiltração da laje que dois outros profissionais não tinham conseguido.',
      ),
      _review(
        'Ricardo Alves',
        5,
        44,
        'Profissional sério e caprichoso. Orçamento claro, sem surpresas no final.',
        reply: 'Valeu, Ricardo!',
      ),
      _review(
        'Juliana Reis',
        3,
        58,
        'O serviço ficou bom, mas demorou para responder as mensagens no começo.',
      ),
      _review(
        'Fernanda Lima',
        5,
        73,
        'Segunda vez que contrato. Mesmo capricho da primeira.',
        reply: 'Sempre às ordens, Fernanda.',
      ),
    ]);

    _services.addAll([
      _service(
        'Pintura interna',
        'Paredes e teto, com massa corrida onde precisar.',
        2800,
        'm²',
      ),
      _service(
        'Pintura externa e fachada',
        'Tinta acrílica, com lavagem e selador.',
        3500,
        'm²',
      ),
      _service(
        'Textura e grafiato',
        'Aplicação em parede interna ou externa.',
        4200,
        'm²',
      ),
      _service(
        'Pintura de portões e grades',
        'Tratamento de ferrugem, fundo e esmalte.',
        null,
        null,
        visit: true,
      ),
      _service(
        'Impermeabilização de laje',
        'Manta líquida com teste de estanqueidade.',
        null,
        null,
        visit: true,
      ),
      _service(
        'Pequenos reparos de alvenaria',
        'Reboco, trincas e buracos antes da pintura.',
        12000,
        'hora',
      ),
    ]);

    _portfolio.addAll([
      _work('Sala com sanca e pintura nova', 'SINGLE', [
        'portfolio/portfolio_2.png',
      ], 'Massa corrida, tinta acetinada e iluminação embutida.'),
      _work('Apartamento completo — 68 m²', 'CAROUSEL', [
        'portfolio_cleaning.jpg',
        'portfolio/portfolio_5.png',
        'portfolio/portfolio_3.png',
      ], 'Sala, cozinha e dois quartos entregues em quatro dias.'),
      _work('Casa térrea — área social', 'COLLAGE', [
        'portfolio_electrical.jpg',
        'portfolio/portfolio_2.png',
        'portfolio/portfolio_5.png',
        'portfolio_cleaning.jpg',
      ], null),
      _work('Pintura interna em andamento', 'SINGLE', [
        'portfolio_painting.jpg',
      ], 'Segunda demão no rolo, com os móveis protegidos.'),
    ]);
  }

  _Json _addRequest({
    required String id,
    required String title,
    required String description,
    required _Json client,
    required String status,
    required String createdAt,
    required List<(bool, String, String)> chat,
  }) {
    final conversationId = id.replaceFirst('demo-req-', 'demo-conv-');
    final request = <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'createdAt': createdAt,
      'client': client,
      'provider': _provider,
      'photos': const <Object>[],
      'conversationId': conversationId,
      'latestProposal': null,
    };
    _requests.add(request);
    _messages[conversationId] = [];
    _conversationRequest[conversationId] = request;
    for (final (mine, at, body) in chat) {
      _say(request, mine, at, body);
    }
    return request;
  }

  _Json _say(
    _Json request,
    bool mine,
    String at,
    String body, {
    String kind = 'TEXT',
    _Json? proposal,
  }) {
    final message = <String, dynamic>{
      'id': _id('msg'),
      'body': body,
      'kind': kind,
      'senderId': mine ? _provider['id'] : (request['client'] as Map)['id'],
      'mine': mine,
      'createdAt': at,
      'readAt': null,
      'proposal': proposal,
    };
    _messages[request['conversationId']]!.add(message);
    return message;
  }

  _Json _addProposal(
    _Json request, {
    required int amountCents,
    required int deadlineDays,
    required int warrantyDays,
    required String waitingFor,
    required String sentAt,
    String status = 'SENT',
    String? notes,
    String? clientSignedAt,
    String? providerSignedAt,
    String? startsOn,
    String? endsOn,
    bool announce = true,
  }) {
    final proposal = <String, dynamic>{
      'id': _id('prop'),
      'quoteRequestId': request['id'],
      'conversationId': request['conversationId'],
      'title': request['title'],
      'amountCents': amountCents,
      'deadlineDays': deadlineDays,
      'warrantyDays': warrantyDays,
      'status': status,
      'waitingFor': waitingFor,
      'client': request['client'],
      'provider': _provider,
      'notes': notes,
      'startsOn': startsOn,
      'endsOn': endsOn,
      'clientSignedAt': clientSignedAt,
      'providerSignedAt': providerSignedAt,
      'contractId': null,
    };
    request['latestProposal'] = proposal;
    if (announce) {
      _say(
        request,
        true,
        sentAt,
        'Orçamento enviado',
        kind: 'PROPOSAL',
        proposal: proposal,
      );
    }
    return proposal;
  }

  _Json _addContract(
    _Json request,
    _Json proposal, {
    required String startedAt,
    String status = 'IN_PROGRESS',
    String? completedAt,
  }) {
    final contract = <String, dynamic>{
      'id': _id('contract'),
      'proposalId': proposal['id'],
      'title': request['title'],
      'amountCents': proposal['amountCents'],
      'status': status,
      'startedAt': startedAt,
      'startsOn': proposal['startsOn'],
      'endsOn': proposal['endsOn'],
      'completedAt': completedAt,
      'cancelledAt': null,
      'reviewed': completedAt != null,
      'client': request['client'],
      'provider': _provider,
      'conversationId': request['conversationId'],
      'proposal': proposal,
    };
    proposal['contractId'] = contract['id'];
    _contracts.add(contract);
    return contract;
  }

  _Json _review(
    String author,
    int rating,
    int daysAgo,
    String comment, {
    String? reply,
    bool read = true,
  }) => {
    'id': _id('review'),
    'rating': rating,
    'comment': comment,
    'createdAt': _ago(days: daysAgo),
    'author': _person(author.toLowerCase().replaceAll(' ', '-'), author),
    'reply': reply,
    'repliedAt': reply == null ? null : _ago(days: daysAgo - 1),
    'readAt': read ? _ago(days: daysAgo - 1) : null,
  };

  _Json _service(
    String title,
    String description,
    int? priceCents,
    String? unit, {
    bool visit = false,
  }) => {
    'id': _id('service'),
    'title': title,
    'description': description,
    'priceCents': priceCents,
    'unit': unit,
    'requiresVisit': visit,
  };

  /// Um trabalho do portfólio. As fotos são as que já vêm no app: o caminho
  /// começa com `assets/` e a tela sabe abrir sem passar pela rede.
  _Json _work(String title, String kind, List<String> photos, String? text) {
    final media = [
      for (var i = 0; i < photos.length; i++)
        <String, dynamic>{
          'id': _id('media'),
          'url': 'assets/images/${photos[i]}',
          'type': 'IMAGE',
          'position': i,
          'role': null,
        },
    ];
    return {
      'id': _id('work'),
      'kind': kind,
      'title': title,
      'description': text,
      'coverUrl': media.first['url'],
      'media': media,
    };
  }
  // ------------------------------------------------------------------ rotas

  /// Responde a uma chamada. Devolve [pass] quando a rota não é daqui e joga
  /// [DemoError] quando a rota é, mas não há o que responder.
  Object? handle(
    String method,
    String path,
    Object? body,
    Map<String, dynamic> query,
  ) {
    final parts = Uri.parse(path).pathSegments;
    if (parts.isEmpty) return pass;
    final data = body is Map
        ? body.cast<String, dynamic>()
        : const <String, dynamic>{};
    final get = method == 'GET';
    final post = method == 'POST';
    String? at(int index) => index < parts.length ? parts[index] : null;

    switch (parts.first) {
      case 'quote-requests':
        if (get && at(1) == 'received') return _requests;
        if (get && at(1) == 'mine') return const <Object>[];
        final request = _find(_requests, at(1));
        if (get && parts.length == 2) return request;
        if (post && at(2) == 'decline') {
          request['status'] = 'CLOSED';
          return request;
        }
        if (post && at(2) == 'proposals') return _createProposal(request, data);
        throw const DemoError.unsupported();

      case 'conversations':
        if (get && parts.length == 1) return _conversationList();
        if (get && at(1) == 'unread-count') {
          return {
            'unreadCount': _messages.values.fold<int>(
              0,
              (total, list) => total + _unread(list),
            ),
          };
        }
        final messages = _messages[at(1)];
        if (messages == null) throw const DemoError.notFound();
        if (get && at(2) == 'messages') return messages;
        if (post && at(2) == 'messages') {
          return _say(
            _conversationRequest[at(1)]!,
            true,
            DateTime.now().toIso8601String(),
            '${data['body']}',
          )..['readAt'] = null;
        }
        if (post && at(2) == 'read') {
          for (final message in messages) {
            message['readAt'] ??= DateTime.now().toIso8601String();
          }
          return const <String, dynamic>{};
        }
        throw const DemoError.unsupported();

      case 'proposals':
        final proposal = _find([
          for (final request in _requests)
            if (request['latestProposal'] case final _Json proposal) proposal,
        ], at(1));
        if (post && at(2) == 'sign') return _sign(proposal);
        if (post && at(2) == 'decline') {
          proposal['status'] = 'DECLINED';
          proposal['waitingFor'] = 'NONE';
          return proposal;
        }
        throw const DemoError.unsupported();

      case 'contracts':
        if (get && parts.length == 1) return _contracts;
        if (!post) throw const DemoError.unsupported();
        final contract = _find(_contracts, at(1));
        if (at(2) == 'complete') {
          contract['status'] = 'COMPLETED';
          contract['completedAt'] = DateTime.now().toIso8601String();
          return contract;
        }
        if (at(2) == 'cancel') {
          contract['status'] = 'CANCELLED';
          contract['cancelledAt'] = DateTime.now().toIso8601String();
          return contract;
        }
        throw const DemoError.unsupported();

      case 'performance':
        if (get && at(1) == 'summary')
          return _performance('${query['period']}');
        throw const DemoError.unsupported();

      case 'reviews':
        if (get && at(1) == 'received') return _reviewsPage();
        if (get && at(1) == 'unread-count') {
          return {
            'unreadCount': _reviews
                .where((review) => review['readAt'] == null)
                .length,
          };
        }
        if (post && at(1) == 'read') {
          for (final review in _reviews) {
            review['readAt'] ??= DateTime.now().toIso8601String();
          }
          return const <String, dynamic>{};
        }
        if (post && at(2) == 'reply') {
          return _find(_reviews, at(1))
            ..['reply'] = '${data['reply']}'
            ..['repliedAt'] = DateTime.now().toIso8601String();
        }
        throw const DemoError.unsupported();

      case 'services':
        if (get && at(1) == 'mine') return _services;
        if (post && parts.length == 1) {
          final service = _service(
            '${data['title']}',
            '${data['description'] ?? ''}',
            (data['priceCents'] as num?)?.toInt(),
            data['unit'] as String?,
            visit: data['requiresVisit'] == true,
          );
          _services.add(service);
          return service;
        }
        if (method == 'PATCH') return _find(_services, at(1))..addAll(data);
        if (method == 'DELETE') {
          _services.remove(_find(_services, at(1)));
          return const <String, dynamic>{};
        }
        throw const DemoError.unsupported();

      case 'portfolio':
        if (get && at(1) == 'mine') return _portfolio;
        throw const DemoError.unsupported();

      case 'providers':
        if (at(1) != 'me' || at(2) != 'availability') return pass;
        if (method == 'PATCH') {
          _acceptingOrders = data['acceptingOrders'] == true;
        }
        return {'acceptingOrders': _acceptingOrders};
    }

    return pass;
  }

  _Json _find(List<_Json> items, String? id) => items.firstWhere(
    (item) => item['id'] == id,
    orElse: () => throw const DemoError.notFound(),
  );

  int _unread(List<_Json> messages) => messages
      .where((message) => message['mine'] != true && message['readAt'] == null)
      .length;

  List<_Json> _conversationList() {
    final list = [
      for (final entry in _messages.entries)
        if (entry.value.isNotEmpty)
          <String, dynamic>{
            'id': entry.key,
            'quoteRequestId': _conversationRequest[entry.key]!['id'],
            'title': _conversationRequest[entry.key]!['title'],
            'counterpart': _conversationRequest[entry.key]!['client'],
            'unreadCount': _unread(entry.value),
            'updatedAt': entry.value.last['createdAt'],
            'lastMessageBody': entry.value.last['body'],
            'lastMessageAt': entry.value.last['createdAt'],
          },
    ];
    return list
      ..sort((a, b) => '${b['updatedAt']}'.compareTo('${a['updatedAt']}'));
  }

  _Json _createProposal(_Json request, _Json data) {
    request['status'] = 'ANSWERED';
    return _addProposal(
      request,
      amountCents: (data['amountCents'] as num).toInt(),
      deadlineDays: (data['deadlineDays'] as num).toInt(),
      warrantyDays: (data['warrantyDays'] as num).toInt(),
      waitingFor: 'CLIENT',
      sentAt: DateTime.now().toIso8601String(),
      notes: data['notes'] as String?,
      startsOn: data['startsOn'] as String?,
      endsOn: data['endsOn'] as String?,
    )..['title'] = '${data['title'] ?? request['title']}';
  }

  /// A assinatura do profissional. Vindo depois da do cliente, abre o
  /// contrato e tira o pedido da negociação.
  _Json _sign(_Json proposal) {
    final now = DateTime.now().toIso8601String();
    proposal['providerSignedAt'] = now;
    if (proposal['clientSignedAt'] == null) {
      return proposal;
    }

    final request = _find(_requests, '${proposal['quoteRequestId']}');
    proposal
      ..['status'] = 'SIGNED'
      ..['waitingFor'] = 'NONE'
      ..['startsOn'] ??= now
      ..['endsOn'] ??= DateTime.now()
          .add(Duration(days: (proposal['deadlineDays'] as num).toInt()))
          .toIso8601String();
    request['status'] = 'CONTRACTED';
    _addContract(request, proposal, startedAt: now);
    _say(
      request,
      true,
      now,
      'Contrato aberto. Serviço em execução.',
      kind: 'SYSTEM',
    );
    return proposal;
  }

  _Json _reviewsPage() {
    final distribution = <String, int>{
      for (var stars = 5; stars >= 1; stars--) '$stars': 0,
    };
    for (final review in _reviews) {
      distribution['${review['rating']}'] =
          distribution['${review['rating']}']! + 1;
    }
    // O resumo conta a história inteira do profissional; a lista traz só as
    // avaliações mais recentes.
    const older = {'5': 29, '4': 5, '3': 0, '2': 1, '1': 0};
    var total = 0;
    var sum = 0;
    for (final stars in distribution.keys) {
      distribution[stars] = distribution[stars]! + older[stars]!;
      total += distribution[stars]!;
      sum += distribution[stars]! * int.parse(stars);
    }

    return {
      'summary': {
        'average': double.parse((sum / total).toStringAsFixed(1)),
        'total': total,
        'distribution': distribution,
        'unanswered': _reviews
            .where((review) => review['reply'] == null)
            .length,
      },
      'items': _reviews,
    };
  }

  _Json _performance(String period) {
    final (done, cancelled, views, requests, days) = switch (period) {
      'today' || 'day' => (1, 0, 14, 2, [0, 0, 0, 0, 0, 0, 9]),
      'week' => (4, 0, 86, 9, [9, 14, 11, 17, 21, 8, 6]),
      'month' => (18, 1, 342, 41, [38, 52, 47, 61, 74, 43, 27]),
      _ => (97, 4, 1890, 228, [212, 264, 251, 298, 341, 236, 148]),
    };
    const weekdays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

    return {
      'averageRating': {'value': 4.8, 'delta': 0.1},
      'servicesDone': {'value': done, 'delta': (done / 5).ceil()},
      'servicesCancelled': {
        'value': cancelled,
        'delta': cancelled == 0 ? 0 : -1,
      },
      'averageResponseMinutes': {'value': 12, 'delta': -3},
      'dailyInteractions': [
        for (var i = 0; i < weekdays.length; i++)
          {'weekday': weekdays[i], 'value': days[i]},
      ],
      'funnel': {
        'profileViews': views,
        'quoteRequests': requests,
        'closedServices': done,
      },
    };
  }
}
