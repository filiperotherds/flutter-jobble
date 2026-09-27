/// Os objetos do fluxo de orçamento, no formato que o servidor devolve.
///
/// São os mesmos nos dois apps: o backend responde pensando em quem perguntou
/// (`mine`, `counterpart`, `waitingFor`), então nenhum dos lados precisa saber
/// de que ponta da negociação está para desenhar a tela.
library;

class Person {
  const Person({required this.id, this.name, this.avatarUrl});

  factory Person.fromJson(Map<String, dynamic> json) => Person(
    id: '${json['id']}',
    name: json['name'] as String?,
    avatarUrl: json['avatarUrl'] as String?,
  );

  final String id;
  final String? name;
  final String? avatarUrl;

  /// Nome utilizável na tela. Conta sem nome ainda assim precisa de rótulo.
  String get display => (name?.trim().isNotEmpty ?? false)
      ? name!.trim()
      : 'Profissional';
}

class QuotePhoto {
  const QuotePhoto({required this.id, required this.url});

  factory QuotePhoto.fromJson(Map<String, dynamic> json) =>
      QuotePhoto(id: '${json['id']}', url: '${json['url']}');

  final String id;

  /// Caminho relativo servido pela API, do tipo `/uploads/<arquivo>`.
  final String url;
}

class QuoteRequest {
  const QuoteRequest({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.client,
    required this.provider,
    required this.photos,
    this.conversationId,
    this.latestProposal,
  });

  factory QuoteRequest.fromJson(Map<String, dynamic> json) => QuoteRequest(
    id: '${json['id']}',
    title: '${json['title']}',
    description: '${json['description']}',
    status: '${json['status']}',
    createdAt: DateTime.parse('${json['createdAt']}'),
    client: Person.fromJson((json['client'] as Map).cast<String, dynamic>()),
    provider: Person.fromJson(
      (json['provider'] as Map).cast<String, dynamic>(),
    ),
    photos: ((json['photos'] as List?) ?? const [])
        .map((photo) => QuotePhoto.fromJson((photo as Map).cast<String, dynamic>()))
        .toList(),
    conversationId: json['conversationId'] as String?,
    latestProposal: json['latestProposal'] == null
        ? null
        : Proposal.fromJson(
            (json['latestProposal'] as Map).cast<String, dynamic>(),
          ),
  );

  final String id;
  final String title;
  final String description;

  /// PENDING | ANSWERED | DECLINED | CLOSED
  final String status;
  final DateTime createdAt;
  final Person client;
  final Person provider;
  final List<QuotePhoto> photos;
  final String? conversationId;

  /// A proposta que ainda vale para este pedido, quando já houver uma. É por
  /// ela que o painel sabe de quem é a vez de assinar.
  final Proposal? latestProposal;

  bool get isPending => status == 'PENDING';
  bool get isClosed => status == 'CLOSED';

  /// Já houve retorno do profissional — mensagem ou proposta — e a bola está
  /// com o cliente.
  bool get awaitingClient => status == 'ANSWERED';
}

class Proposal {
  const Proposal({
    required this.id,
    required this.quoteRequestId,
    required this.conversationId,
    required this.title,
    required this.amountCents,
    required this.deadlineDays,
    required this.warrantyDays,
    required this.status,
    required this.waitingFor,
    required this.client,
    required this.provider,
    this.notes,
    this.startsOn,
    this.endsOn,
    this.clientSignedAt,
    this.providerSignedAt,
    this.contractId,
  });

  factory Proposal.fromJson(Map<String, dynamic> json) => Proposal(
    id: '${json['id']}',
    quoteRequestId: '${json['quoteRequestId']}',
    conversationId: '${json['conversationId']}',
    title: '${json['title']}',
    amountCents: (json['amountCents'] as num).toInt(),
    deadlineDays: (json['deadlineDays'] as num).toInt(),
    warrantyDays: (json['warrantyDays'] as num).toInt(),
    status: '${json['status']}',
    waitingFor: '${json['waitingFor']}',
    client: Person.fromJson((json['client'] as Map).cast<String, dynamic>()),
    provider: Person.fromJson(
      (json['provider'] as Map).cast<String, dynamic>(),
    ),
    notes: json['notes'] as String?,
    startsOn: _date(json['startsOn']),
    endsOn: _date(json['endsOn']),
    clientSignedAt: _date(json['clientSignedAt']),
    providerSignedAt: _date(json['providerSignedAt']),
    contractId: json['contractId'] as String?,
  );

  final String id;
  final String quoteRequestId;
  final String conversationId;
  final String title;
  final int amountCents;
  final int deadlineDays;
  final int warrantyDays;

  /// SENT | CLIENT_SIGNED | SIGNED | DECLINED | SUPERSEDED
  final String status;

  /// CLIENT | PROVIDER | NOBODY — de quem o servidor espera a próxima
  /// assinatura. É o que decide qual botão o card mostra.
  final String waitingFor;

  final Person client;
  final Person provider;
  final String? notes;

  /// Janela combinada para executar o serviço. Nulas quando o profissional
  /// não fechou data na proposta.
  final DateTime? startsOn;
  final DateTime? endsOn;

  final DateTime? clientSignedAt;
  final DateTime? providerSignedAt;
  final String? contractId;

  bool get awaitsClient => waitingFor == 'CLIENT';
  bool get awaitsProvider => waitingFor == 'PROVIDER';
  bool get isSigned => status == 'SIGNED';
  bool get isDeclined => status == 'DECLINED';
  bool get isSuperseded => status == 'SUPERSEDED';

  double get amount => amountCents / 100;
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.body,
    required this.kind,
    required this.senderId,
    required this.mine,
    required this.createdAt,
    this.readAt,
    this.proposal,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: '${json['id']}',
    body: '${json['body']}',
    kind: '${json['kind']}',
    senderId: '${json['senderId']}',
    mine: json['mine'] == true,
    createdAt: DateTime.parse('${json['createdAt']}'),
    readAt: _date(json['readAt']),
    proposal: json['proposal'] == null
        ? null
        : Proposal.fromJson((json['proposal'] as Map).cast<String, dynamic>()),
  );

  final String id;
  final String body;

  /// TEXT | PROPOSAL | SYSTEM
  final String kind;
  final String senderId;

  /// Enviada por quem está olhando: decide o lado da bolha no chat.
  final bool mine;
  final DateTime createdAt;
  final DateTime? readAt;
  final Proposal? proposal;

  bool get isProposal => kind == 'PROPOSAL' && proposal != null;
  bool get isSystem => kind == 'SYSTEM';
}

class ConversationSummary {
  const ConversationSummary({
    required this.id,
    required this.quoteRequestId,
    required this.title,
    required this.counterpart,
    required this.unreadCount,
    required this.updatedAt,
    this.lastMessageBody,
    this.lastMessageAt,
  });

  factory ConversationSummary.fromJson(Map<String, dynamic> json) =>
      ConversationSummary(
        id: '${json['id']}',
        quoteRequestId: '${json['quoteRequestId']}',
        title: '${json['title']}',
        counterpart: Person.fromJson(
          (json['counterpart'] as Map).cast<String, dynamic>(),
        ),
        unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
        updatedAt: DateTime.parse('${json['updatedAt']}'),
        lastMessageBody: json['lastMessageBody'] as String?,
        lastMessageAt: _date(json['lastMessageAt']),
      );

  final String id;
  final String quoteRequestId;
  final String title;

  /// A outra pessoa da conversa, já resolvida pelo servidor.
  final Person counterpart;
  final int unreadCount;
  final DateTime updatedAt;
  final String? lastMessageBody;
  final DateTime? lastMessageAt;
}

class ServiceContract {
  const ServiceContract({
    required this.id,
    required this.proposalId,
    required this.title,
    required this.amountCents,
    required this.status,
    required this.startedAt,
    required this.client,
    required this.provider,
    this.startsOn,
    this.endsOn,
    this.conversationId,
    this.proposal,
    this.completedAt,
    this.cancelledAt,
    this.reviewed = false,
  });

  factory ServiceContract.fromJson(Map<String, dynamic> json) =>
      ServiceContract(
        id: '${json['id']}',
        proposalId: '${json['proposalId']}',
        title: '${json['title']}',
        amountCents: (json['amountCents'] as num).toInt(),
        status: '${json['status']}',
        startedAt: DateTime.parse('${json['startedAt']}'),
        startsOn: _date(json['startsOn']),
        endsOn: _date(json['endsOn']),
        completedAt: _date(json['completedAt']),
        cancelledAt: _date(json['cancelledAt']),
        reviewed: json['reviewed'] == true,
        client: Person.fromJson(
          (json['client'] as Map).cast<String, dynamic>(),
        ),
        provider: Person.fromJson(
          (json['provider'] as Map).cast<String, dynamic>(),
        ),
        conversationId: json['conversationId'] as String?,
        proposal: json['proposal'] == null
            ? null
            : Proposal.fromJson(
                (json['proposal'] as Map).cast<String, dynamic>(),
              ),
      );

  final String id;
  final String proposalId;
  final String title;
  final int amountCents;

  /// IN_PROGRESS | COMPLETED | CANCELLED
  final String status;
  final DateTime startedAt;

  /// O prazo que as duas partes assinaram. Quando existe, é ele que o card de
  /// serviço em andamento mostra — e de onde sai a barra de andamento.
  final DateTime? startsOn;
  final DateTime? endsOn;

  final Person client;
  final Person provider;
  final String? conversationId;

  /// A proposta assinada pelos dois lados que deu origem a este contrato.
  final Proposal? proposal;

  final DateTime? completedAt;
  final DateTime? cancelledAt;

  /// Se o cliente já avaliou este serviço. Sem isso o app ofereceria o botão
  /// de avaliar a um serviço que já foi avaliado.
  final bool reviewed;

  double get amount => amountCents / 100;
  bool get inProgress => status == 'IN_PROGRESS';
  bool get completed => status == 'COMPLETED';
  bool get cancelled => status == 'CANCELLED';

  /// Quanto do prazo já passou, de 0 a 1.
  ///
  /// É o andamento possível quando ninguém marcou etapa nenhuma: o serviço
  /// caminha junto com o calendário, do começo combinado até a entrega. Sem
  /// as duas datas não há o que interpolar, e a barra não aparece.
  double? get scheduleProgress {
    final start = startsOn;
    final end = endsOn;
    if (start == null || end == null) return null;

    final total = end.difference(start).inMinutes;
    final now = DateTime.now();
    if (total <= 0) return now.isBefore(end) ? 0 : 1;

    return (now.difference(start).inMinutes / total).clamp(0.0, 1.0);
  }

  /// Dias que faltam para a entrega. Negativo quando o prazo já passou.
  int? get daysLeft =>
      endsOn == null ? null : endsOn!.difference(DateTime.now()).inDays;
}

DateTime? _date(Object? value) =>
    value == null ? null : DateTime.tryParse('$value');
