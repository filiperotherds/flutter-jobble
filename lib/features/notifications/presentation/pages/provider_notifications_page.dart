import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';

import 'package:flutter_tcc/core/network/api_exception.dart';
import 'package:flutter_tcc/core/theme/app_colors.dart';
import 'package:flutter_tcc/core/theme/app_spacing.dart';
import 'package:flutter_tcc/core/theme/app_typography.dart';
import 'package:flutter_tcc/core/widgets/app_empty_state.dart';
import 'package:flutter_tcc/core/widgets/app_loader.dart';
import 'package:flutter_tcc/features/bids/presentation/pages/match_details_page.dart';
import 'package:flutter_tcc/features/contracts/presentation/pages/contract_detail_page.dart';
import 'package:flutter_tcc/features/notifications/data/datasources/notification_remote_data_source.dart';
import 'package:flutter_tcc/features/notifications/data/models/notification_model.dart';
import 'package:flutter_tcc/injection_container.dart';
import 'package:flutter_tcc/core/widgets/app_back_button.dart';

class ProviderNotificationsPage extends StatefulWidget {
  const ProviderNotificationsPage({super.key});

  @override
  State<ProviderNotificationsPage> createState() =>
      _ProviderNotificationsPageState();
}

class _ProviderNotificationsPageState extends State<ProviderNotificationsPage> {
  final _dataSource = sl<NotificationRemoteDataSource>();

  List<NotificationModel> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _dataSource.fetchAll();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    final unread = _items.where((n) => n.isUnread).map((n) => n.id).toList();
    if (unread.isEmpty) return;
    try {
      await _dataSource.markMultipleAsRead(unread);
      await _load();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _open(NotificationModel notification) async {
    if (notification.isUnread) {
      // Abrir já marca como lida; falhar aqui não pode impedir a navegação.
      try {
        await _dataSource.markAsRead(notification.id);
      } catch (_) {}
    }
    if (!mounted) return;
    final contractId = notification.contractId;
    final requestId = notification.serviceRequestId;
    final page = contractId != null
        ? ContractDetailPage(contractId: contractId)
        : requestId != null
        ? MatchDetailsPage(serviceRequestId: requestId)
        : null;
    if (page != null) {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasUnread = _items.any((n) => n.isUnread);

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        elevation: 0,
        centerTitle: true,
        leadingWidth: AppBackButton.slotWidth,
        leading: const AppBackButton(),
        title: Text(
          'Notificações',
          style: AppTypography.h3.copyWith(
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
          ),
        ),
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                'Marcar como lidas',
                style: AppTypography.caption.copyWith(
                  color: colors.accentText,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const AppLoaderCentered()
            : _error != null
            ? AppEmptyState(
                icon: LucideIcons.triangle_alert,
                title: 'Não foi possível carregar',
                description: _error,
                actionLabel: 'Tentar de novo',
                onAction: _load,
              )
            : _items.isEmpty
            ? const AppEmptyState(
                icon: LucideIcons.bell,
                title: 'Nenhuma notificação',
                description:
                    'Avisos de novos chamados e de contratos aparecem aqui.',
              )
            : ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                children: _grouped(colors),
              ),
      ),
    );
  }

  List<Widget> _grouped(AppColorsTheme colors) {
    final widgets = <Widget>[];
    String? lastHeader;
    for (final item in _items) {
      final header = _dayLabel(item.createdAt);
      if (header != lastHeader) {
        lastHeader = header;
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Text(
              header,
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.textSecondary,
              ),
            ),
          ),
        );
      }
      widgets.add(_item(item, colors));
    }
    return widgets;
  }

  Widget _item(NotificationModel notification, AppColorsTheme colors) {
    final visual = _visualFor(notification.type, colors);
    return InkWell(
      onTap: () => _open(notification),
      child: Container(
        color: notification.isUnread
            ? colors.primary.withValues(alpha: 0.05)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: visual.$2.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(visual.$1, color: visual.$2, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: AppTypography.body.copyWith(
                            fontWeight: notification.isUnread
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        DateFormat.Hm('pt_BR').format(notification.createdAt),
                        style: AppTypography.caption.copyWith(
                          color: notification.isUnread
                              ? colors.accentText
                              : colors.textSecondary,
                          fontWeight: notification.isUnread
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.personName,
                    style: AppTypography.caption.copyWith(
                      color: colors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  (IconData, Color) _visualFor(String type, AppColorsTheme colors) {
    if (type.startsWith('CONTRACT')) {
      return (LucideIcons.file_text, colors.accentText);
    }
    return switch (type) {
      'MATCH' => (LucideIcons.map_pin, context.colors.accentText),
      'PROPOSAL_APPROVED' ||
      'HIRED' => (LucideIcons.circle_check, context.colors.success),
      _ => (LucideIcons.bell, colors.textSecondary),
    };
  }
}

String _dayLabel(DateTime moment) {
  final today = DateUtils.dateOnly(DateTime.now());
  final day = DateUtils.dateOnly(moment);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Hoje';
  if (diff == 1) return 'Ontem';
  return DateFormat("d 'de' MMMM", 'pt_BR').format(moment);
}
