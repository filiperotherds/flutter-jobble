import 'package:flutter_tcc/features/quotes/data/quotes_api.dart';

/// Os formatos em que um trabalho pode ser montado.
///
/// O formato não é deduzido da quantidade de arquivos: três fotos podem ser um
/// carrossel ou uma montagem, e quem decide é o profissional. Por isso ele é
/// escolhido antes de enviar qualquer coisa.
enum PortfolioKind {
  single('SINGLE', 'Foto única', 'Uma foto do trabalho pronto', 1, 1),
  carousel('CAROUSEL', 'Carrossel', 'Várias fotos, uma após a outra', 2, 10),
  beforeAfter(
    'BEFORE_AFTER',
    'Antes e depois',
    'Duas fotos com a régua de comparação',
    2,
    2,
  ),
  collage('COLLAGE', 'Montagem', 'Até 4 fotos num quadro só', 2, 4),
  video('VIDEO', 'Vídeo', 'Um clipe curto do serviço', 1, 1);

  const PortfolioKind(
    this.code,
    this.label,
    this.hint,
    this.minMedia,
    this.maxMedia,
  );

  final String code;
  final String label;
  final String hint;
  final int minMedia;
  final int maxMedia;

  static PortfolioKind from(String code) => PortfolioKind.values.firstWhere(
    (kind) => kind.code == code,
    orElse: () => PortfolioKind.single,
  );
}

class PortfolioMedia {
  const PortfolioMedia({
    required this.id,
    required this.url,
    required this.type,
    required this.position,
    this.role,
  });

  factory PortfolioMedia.fromJson(Map<String, dynamic> json) => PortfolioMedia(
    id: '${json['id']}',
    url: '${json['url']}',
    type: '${json['type']}',
    position: (json['position'] as num?)?.toInt() ?? 0,
    role: json['role'] as String?,
  );

  final String id;
  final String url;

  /// IMAGE | VIDEO
  final String type;

  /// BEFORE | AFTER nos antes-e-depois; nulo nos demais formatos.
  final String? role;

  final int position;

  bool get isVideo => type == 'VIDEO';
  bool get isBefore => role == 'BEFORE';

  /// URL completa, montada com a base da API.
  String get fullUrl => QuotesApi.photoUrl(url);
}

class PortfolioItem {
  const PortfolioItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.media,
    this.description,
    this.coverUrl,
  });

  factory PortfolioItem.fromJson(Map<String, dynamic> json) => PortfolioItem(
    id: '${json['id']}',
    kind: PortfolioKind.from('${json['kind']}'),
    title: '${json['title']}',
    description: json['description'] as String?,
    coverUrl: json['coverUrl'] as String?,
    media: ((json['media'] as List?) ?? const [])
        .map(
          (row) => PortfolioMedia.fromJson((row as Map).cast<String, dynamic>()),
        )
        .toList(),
  );

  final String id;
  final PortfolioKind kind;
  final String title;
  final String? description;
  final String? coverUrl;
  final List<PortfolioMedia> media;

  /// A imagem da grade. Num antes-e-depois é o "depois" — o resultado é o que
  /// convence quem está escolhendo.
  String? get fullCoverUrl =>
      coverUrl == null ? null : QuotesApi.photoUrl(coverUrl!);

  PortfolioMedia? get before =>
      media.where((m) => m.role == 'BEFORE').firstOrNull;

  PortfolioMedia? get after => media.where((m) => m.role == 'AFTER').firstOrNull;

  /// Se ainda faltam arquivos para o formato ficar completo.
  bool get incomplete => media.length < kind.minMedia;

  int get remaining => kind.maxMedia - media.length;
}

extension FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
