import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';

import 'package:flutter_tcc/core/theme/app_colors.dart';
import 'package:flutter_tcc/core/theme/app_spacing.dart';
import 'package:flutter_tcc/core/theme/app_typography.dart';
import 'package:flutter_tcc/features/quotes/data/quote_models.dart';
import 'package:flutter_tcc/features/quotes/data/quotes_api.dart';
import 'package:flutter_tcc/features/quotes/presentation/bloc/conversations_cubit.dart';
import 'package:flutter_tcc/features/quotes/presentation/pages/quote_chat_page.dart';
import 'package:flutter_tcc/injection_container.dart';

/// Conversas do profissional.
///
/// Cada uma nasceu de um pedido de orçamento que chegou para ele. É aqui que
/// o cliente responde e, depois que o orçamento é enviado e assinado por quem
/// pediu, é daqui que sai a confirmação que abre o contrato.
class ProviderConversationsPage extends StatefulWidget {
  const ProviderConversationsPage({super.key});

  @override
  State<ProviderConversationsPage> createState() => _ProviderConversationsPageState();
}

class _ProviderConversationsPageState extends State<ProviderConversationsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  /// Esta aba é dona do seu cubit: o painel do profissional tem o dele, e
  /// compartilhar um só entre duas abas de um `IndexedStack` faria uma fechar
  /// o que a outra ainda usa.
  ConversationsCubit? _cubit;

  @override
  void initState() {
    super.initState();
    try {
      _cubit = sl<ConversationsCubit>()
        ..load()
        ..startPolling();
    } catch (_) {
      // Sem service locator (teste de tela), a lista desenha vazia.
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cubit?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final cubit = _cubit;

    // Sem servidor por trás, a tela ainda precisa desenhar: mostra o estado
    // vazio em vez de estourar.
    if (cubit == null) {
      return Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          automaticallyImplyLeading: false,
          title: Text(
            'Conversas',
            style: AppTypography.h2.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
        ),
        body: _empty(colors, const ConversationsState(loading: false)),
      );
    }

    return BlocProvider.value(
      value: cubit,
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          automaticallyImplyLeading: false,
          title: Text(
            'Conversas',
            style: AppTypography.h2.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
        ),
        body: Column(
          children: [
            _search(colors),
            Expanded(
              child: BlocBuilder<ConversationsCubit, ConversationsState>(
                builder: (context, state) {
                  if (state.loading && state.items.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final items = state.items
                      .where(
                        (item) =>
                            _query.isEmpty ||
                            item.counterpart.display.toLowerCase().contains(
                              _query,
                            ) ||
                            item.title.toLowerCase().contains(_query),
                      )
                      .toList();

                  if (items.isEmpty) return _empty(colors, state);

                  return RefreshIndicator(
                    onRefresh: () => context.read<ConversationsCubit>().load(),
                    child: ListView.separated(
                      padding: const EdgeInsets.only(bottom: 120),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        indent: 84,
                        color: colors.borderLight,
                      ),
                      itemBuilder: (context, index) => _ConversationRow(
                        conversation: items[index],
                        onTap: () => _open(items[index]),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _open(ConversationSummary conversation) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuoteChatPage(
          conversationId: conversation.id,
          counterpartName: conversation.counterpart.display,
          counterpartAvatarUrl: conversation.counterpart.avatarUrl,
          subtitle: conversation.title,
          viewerIsClient: false,
        ),
      ),
    );
    // Voltar da conversa é quando as não lidas mudaram: relê para o selo cair.
    if (mounted) _cubit?.load(silent: true);
  }

  Widget _search(AppColorsTheme colors) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _query = value.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Buscar conversa',
          prefixIcon: Icon(
            LucideIcons.search,
            size: 18,
            color: colors.textSecondary,
          ),
          filled: true,
          fillColor: colors.surfaceLight,
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _empty(AppColorsTheme colors, ConversationsState state) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      children: [
        const SizedBox(height: 60),
        Icon(
          LucideIcons.message_square,
          size: 48,
          color: colors.borderLight,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          state.error ?? 'Nenhuma conversa ainda',
          textAlign: TextAlign.center,
          style: AppTypography.h3.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Quando um cliente pedir um orçamento, a conversa aparece aqui.',
          textAlign: TextAlign.center,
          style: AppTypography.body.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }
}

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({required this.conversation, required this.onTap});

  final ConversationSummary conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final unread = conversation.unreadCount > 0;
    final avatarUrl = conversation.counterpart.avatarUrl;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: colors.primary,
        backgroundImage: avatarUrl == null
            ? null
            : NetworkImage(QuotesApi.photoUrl(avatarUrl)),
        child: avatarUrl != null
            ? null
            : Text(
                conversation.counterpart.display.characters.first
                    .toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              conversation.counterpart.display,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
          ),
          Text(
            _when(conversation.lastMessageAt ?? conversation.updatedAt),
            style: AppTypography.caption.copyWith(
              fontSize: 11,
              color: unread ? colors.primary : colors.textSecondary,
              fontWeight: unread ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              conversation.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    conversation.lastMessageBody ?? 'Conversa aberta',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: unread ? colors.textPrimary : colors.textSecondary,
                      fontWeight: unread ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                if (unread) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      // Vermelho, como o selo do sino e o da barra de abas:
                      // é o mesmo aviso de "tem algo esperando você".
                      color: colors.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${conversation.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Hora para hoje, "Ontem", data para o resto: é o que se lê numa lista.
  static String _when(DateTime moment) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(moment.year, moment.month, moment.day);
    final days = today.difference(day).inDays;

    if (days == 0) return DateFormat('HH:mm').format(moment);
    if (days == 1) return 'Ontem';
    if (days < 7) return DateFormat('EEEE', 'pt_BR').format(moment);
    return DateFormat('dd/MM').format(moment);
  }
}
