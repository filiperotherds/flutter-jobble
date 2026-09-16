import 'dart:async';
import 'package:flutter_tcc/core/network/api_exception.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_tcc/core/theme/app_colors.dart';
import 'package:flutter_tcc/core/theme/app_spacing.dart';
import 'package:flutter_tcc/core/theme/app_typography.dart';
import 'package:flutter_tcc/core/widgets/app_empty_state.dart';
import 'package:flutter_tcc/core/network/dio_client.dart';
import 'package:flutter_tcc/injection_container.dart';
import 'package:flutter_tcc/features/notifications/data/datasources/notification_remote_data_source.dart';
import 'package:flutter_tcc/features/notifications/data/models/notification_model.dart';
import 'package:flutter_tcc/core/widgets/app_loader.dart';
import 'package:flutter_tcc/features/bids/presentation/pages/match_details_page.dart';
import 'package:flutter_tcc/features/contracts/presentation/pages/contract_detail_page.dart';

enum NotificationType { match, proposalApproved, contract }

class NotificationItem {
  final String id;
  final String personName;
  final NotificationType type;
  final DateTime dateTime;
  final bool? isUnread;
  final String? serviceRequestId;
  final String? contractId;

  /// Título escrito pelo servidor. Os avisos de contrato variam demais
  /// (assinou, pediu ajuste, concluiu…) para o app montar a frase sozinho.
  final String? serverTitle;

  NotificationItem({
    required this.id,
    required this.personName,
    required this.type,
    required this.dateTime,
    this.isUnread,
    this.serviceRequestId,
    this.contractId,
    this.serverTitle,
  });

  String get title {
    return switch (type) {
      // O aviso de chamado novo não leva o nome do cliente: ele só é
      // liberado quando o cliente escolhe o profissional.
      NotificationType.match => serverTitle ?? 'Novo chamado na sua região',
      NotificationType.proposalApproved =>
        serverTitle ?? '$personName escolheu você',
      NotificationType.contract => serverTitle ?? 'Atualização no contrato',
    };
  }

  IconData get icon => switch (type) {
    NotificationType.match => LucideIcons.sparkle,
    NotificationType.proposalApproved => LucideIcons.badge_check,
    NotificationType.contract => LucideIcons.file_text,
  };

  NotificationItem copyAsRead() => NotificationItem(
    id: id,
    personName: personName,
    type: type,
    dateTime: dateTime,
    isUnread: false,
    serviceRequestId: serviceRequestId,
    contractId: contractId,
    serverTitle: serverTitle,
  );
}

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  final NotificationRemoteDataSource _dataSource = NotificationRemoteDataSource(
    dioClient: sl<DioClient>(),
  );
  List<NotificationItem> _notifications = [];
  bool _loading = true;
  bool _fetching = false;
  String? _error;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _fetchNotifications();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchNotifications() async {
    if (_fetching) return;
    _fetching = true;
    try {
      final models = await _dataSource.fetchAll();
      if (!mounted) return;
      setState(() {
        _notifications = models.map(_toNotificationItem).toList();
        _loading = false;
        _error = null;
      });
    } catch (e) {
      debugPrint('Erro ao buscar notificações: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e is ApiException
              ? e.message
              : 'Não foi possível carregar as notificações. Tente novamente.';
        });
      }
    } finally {
      _fetching = false;
    }
  }

  NotificationItem _toNotificationItem(NotificationModel model) {
    final type = switch (model.type) {
      'MATCH' => NotificationType.match,
      final value when value.startsWith('CONTRACT_') =>
        NotificationType.contract,
      _ => NotificationType.proposalApproved,
    };
    return NotificationItem(
      id: model.id,
      personName: model.personName,
      type: type,
      dateTime: model.createdAt,
      isUnread: model.isUnread,
      serviceRequestId: model.serviceRequestId,
      contractId: model.contractId,
      serverTitle: model.title,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (_loading) {
      return const Center(child: AppLoader());
    }

    if (_notifications.isEmpty) {
      if (_error != null) {
        return AppEmptyState(
          icon: LucideIcons.triangle_alert,
          title: 'Não foi possível carregar',
          description: _error!,
          actionLabel: 'Tentar de novo',
          onAction: _fetchNotifications,
        );
      }
      return const AppEmptyState(
        icon: LucideIcons.inbox,
        title: 'Nenhuma notificação',
        description:
            'Avisos de novos serviços e propostas aceitas aparecem aqui.',
      );
    }

    final grouped = _groupByDay(_notifications);

    return RefreshIndicator(
      onRefresh: _fetchNotifications,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH,
          AppSpacing.xs,
          AppSpacing.screenH,
          // Espaço para a barra de navegação flutuante.
          120,
        ),
        children: [
          for (final group in grouped) ...[
            _buildDayHeader(colors, group.date),
            for (final notification in group.items)
              _buildNotification(colors, notification),
          ],
        ],
      ),
    );
  }

  Widget _buildDayHeader(AppColorsTheme colors, DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateDay = DateTime(date.year, date.month, date.day);

    String label;
    if (dateDay == today) {
      label = 'Hoje';
    } else if (dateDay == yesterday) {
      label = 'Ontem';
    } else {
      const months = [
        'jan',
        'fev',
        'mar',
        'abr',
        'mai',
        'jun',
        'jul',
        'ago',
        'set',
        'out',
        'nov',
        'dez',
      ];
      label =
          '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]}';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.xs,
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.overline.copyWith(color: colors.textHint),
      ),
    );
  }

  /// Abre o que o aviso anuncia e o marca como lido — antes nenhum aviso
  /// saía de "não lido", e o contador da home só crescia.
  Future<void> _open(NotificationItem item) async {
    final contractId = item.contractId;
    final requestId = item.serviceRequestId;
    final Widget? page = contractId != null && contractId.isNotEmpty
        ? ContractDetailPage(contractId: contractId)
        : requestId != null && requestId.isNotEmpty
        ? MatchDetailsPage(serviceRequestId: requestId)
        : null;
    if (page == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta notificação não tem um serviço vinculado.'),
        ),
      );
      return;
    }
    if (item.isUnread != false) {
      setState(() {
        _notifications = [
          for (final n in _notifications) n.id == item.id ? n.copyAsRead() : n,
        ];
      });
      unawaited(
        _dataSource.markAsRead(item.id).catchError((Object e) {
          debugPrint('Erro ao marcar notificação como lida: $e');
        }),
      );
    }

    // Aviso ligado a contrato (inclusive "o cliente escolheu você") abre o
    // contrato: é lá que está o próximo passo. Os demais abrem o chamado —
    // todos, não só o de chamado novo: devolutiva, avisos de contrato sem o
    // id e os mais antigos também têm a solicitação.
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => page));
    if (mounted) _fetchNotifications();
  }

  Widget _buildNotification(AppColorsTheme colors, NotificationItem item) {
    final hour = item.dateTime.hour.toString().padLeft(2, '0');
    final minute = item.dateTime.minute.toString().padLeft(2, '0');
    final timeLabel = '${hour}h$minute';
    final isUnread = item.isUnread != false;

    return GestureDetector(
      onTap: () => _open(item),
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: AppRadius.lgAll,
          ),
          child: Row(
            children: [
              Container(
                width: AppSize.categoryIcon,
                height: AppSize.categoryIcon,
                decoration: BoxDecoration(
                  color: colors.surfaceLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, size: 18, color: colors.textSecondary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  item.title,
                  style: AppTypography.body.copyWith(
                    color: isUnread ? colors.textPrimary : colors.textSecondary,
                    fontWeight: isUnread ? FontWeight.w500 : FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    timeLabel,
                    style: AppTypography.caption.copyWith(
                      color: colors.textHint,
                    ),
                  ),
                  if (isUnread) ...[
                    const SizedBox(height: AppSpacing.xs),
                    // Ponto verde: marca de não lida, no lugar de esmaecer
                    // as já lidas.
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: colors.accentText,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<DayGroup> _groupByDay(List<NotificationItem> items) {
  final sorted = List<NotificationItem>.from(items)
    ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

  final groups = <DayGroup>[];
  for (final item in sorted) {
    final day = DateTime(
      item.dateTime.year,
      item.dateTime.month,
      item.dateTime.day,
    );
    if (groups.isEmpty || groups.last.date != day) {
      groups.add(DayGroup(date: day, items: []));
    }
    groups.last.items.add(item);
  }
  return groups;
}

class DayGroup {
  final DateTime date;
  final List<NotificationItem> items;

  DayGroup({required this.date, required this.items});
}
