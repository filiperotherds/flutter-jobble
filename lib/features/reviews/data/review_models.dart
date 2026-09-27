import 'package:flutter_tcc/features/quotes/data/quote_models.dart';

/// Uma avaliação recebida, com a resposta do profissional quando houver.
class Review {
  const Review({
    required this.id,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.author,
    this.reply,
    this.repliedAt,
    this.readAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
    id: '${json['id']}',
    rating: (json['rating'] as num).toInt(),
    comment: '${json['comment']}',
    createdAt: DateTime.parse('${json['createdAt']}'),
    author: Person.fromJson((json['author'] as Map).cast<String, dynamic>()),
    reply: json['reply'] as String?,
    repliedAt: _date(json['repliedAt']),
    readAt: _date(json['readAt']),
  );

  final String id;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final Person author;

  /// O que o profissional respondeu. Nulo enquanto ele não responde.
  final String? reply;
  final DateTime? repliedAt;

  /// Quando o profissional viu. Nulo enquanto não viu — é o que acende o sino.
  final DateTime? readAt;

  bool get answered => reply != null && reply!.trim().isNotEmpty;
  bool get unread => readAt == null;
}

/// O resumo que as duas telas desenham em barras.
class ReviewSummary {
  const ReviewSummary({
    required this.average,
    required this.total,
    required this.distribution,
    required this.unanswered,
  });

  factory ReviewSummary.fromJson(Map<String, dynamic> json) => ReviewSummary(
    average: (json['average'] as num).toDouble(),
    total: (json['total'] as num).toInt(),
    distribution: {
      for (final entry in (json['distribution'] as Map).entries)
        int.parse('${entry.key}'): (entry.value as num).toInt(),
    },
    unanswered: (json['unanswered'] as num?)?.toInt() ?? 0,
  );

  const ReviewSummary.empty()
    : average = 0,
      total = 0,
      distribution = const {},
      unanswered = 0;

  final double average;
  final int total;

  /// Quantas avaliações por nota, de 1 a 5.
  final Map<int, int> distribution;

  final int unanswered;

  /// A fração de cada nota, que é o que a barra desenha. Sem avaliação
  /// nenhuma, todas as barras ficam vazias em vez de dividir por zero.
  double fractionOf(int stars) {
    if (total == 0) return 0;
    return (distribution[stars] ?? 0) / total;
  }
}

class ReviewsPage {
  const ReviewsPage({required this.summary, required this.items});

  factory ReviewsPage.fromJson(Map<String, dynamic> json) => ReviewsPage(
    summary: ReviewSummary.fromJson(
      (json['summary'] as Map).cast<String, dynamic>(),
    ),
    items: ((json['items'] as List?) ?? const [])
        .map((row) => Review.fromJson((row as Map).cast<String, dynamic>()))
        .toList(),
  );

  const ReviewsPage.empty()
    : summary = const ReviewSummary.empty(),
      items = const [];

  final ReviewSummary summary;
  final List<Review> items;

  List<Review> get unanswered => items.where((item) => !item.answered).toList();
}

DateTime? _date(Object? value) =>
    value == null ? null : DateTime.tryParse('$value');
