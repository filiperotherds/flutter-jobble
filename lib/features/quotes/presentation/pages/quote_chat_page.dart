import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';

import 'package:flutter_tcc/core/theme/app_colors.dart';
import 'package:flutter_tcc/core/theme/app_spacing.dart';
import 'package:flutter_tcc/core/theme/app_typography.dart';
import 'package:flutter_tcc/features/quotes/data/quote_models.dart';
import 'package:flutter_tcc/features/quotes/data/quotes_api.dart';
import 'package:flutter_tcc/features/quotes/presentation/bloc/chat_cubit.dart';
import 'package:flutter_tcc/features/quotes/presentation/widgets/proposal_card.dart';
import 'package:flutter_tcc/injection_container.dart';

const _green = Color(0xFF10B981);
const _greenDark = Color(0xFF059669);

/// A conversa de um pedido de orçamento.
///
/// É o mesmo lugar onde o pedido nasceu, onde a proposta chega e onde as duas
/// assinaturas acontecem. Manter tudo numa linha só poupa quem contratou de
/// caçar a proposta numa aba separada — ela chega como mensagem, no meio da
/// conversa que já estava acontecendo.
///
/// No topo aparece sempre o outro lado: o cliente vê o profissional, o
/// profissional vê o cliente. Quem é "o outro" vem resolvido do servidor, em
/// `counterpart`, então esta tela serve aos dois apps sem saber de que ponta
/// da negociação está.
class QuoteChatPage extends StatefulWidget {
  const QuoteChatPage({
    super.key,
    required this.conversationId,
    required this.counterpartName,
    this.counterpartAvatarUrl,
    this.counterpartAvatarAsset,
    this.subtitle,
    this.viewerIsClient = true,
  });

  final String conversationId;
  final String counterpartName;

  /// Foto do outro lado guardada no servidor.
  final String? counterpartAvatarUrl;

  /// Foto local, para quem abriu a conversa de uma tela que já a conhece —
  /// o perfil do profissional, por exemplo. Sem nenhuma das duas, entra a
  /// inicial do nome.
  final String? counterpartAvatarAsset;

  /// Serviço do pedido. Guardado para quem quiser exibir em outro lugar; o
  /// cabeçalho segue o desenho original e mostra o estado da pessoa.
  final String? subtitle;

  final bool viewerIsClient;

  @override
  State<QuoteChatPage> createState() => _QuoteChatPageState();
}

class _QuoteChatPageState extends State<QuoteChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  late final ChatCubit _cubit;

  /// Atalhos do que se costuma responder aqui. Mudam de lado: quem contratou
  /// pergunta prazo e pagamento; quem executa confirma visita e combina hora.
  List<String> get _quickReplies => widget.viewerIsClient
      ? const [
          'Qual a previsão de início?',
          'Gostei da proposta!',
          'Quais as opções de pagamento?',
          'Pode incluir o teto também?',
        ]
      : const [
          'Consigo passar para ver de perto.',
          'Vou preparar o orçamento hoje.',
          'Qual o melhor horário para você?',
          'O material entra por sua conta?',
        ];

  @override
  void initState() {
    super.initState();
    _cubit =
        ChatCubit(api: sl<QuotesApi>(), conversationId: widget.conversationId)
          ..load()
          ..startPolling();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _cubit.close();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _send([String? text]) {
    final body = (text ?? _messageController.text).trim();
    if (body.isEmpty) return;
    if (text == null) {
      _messageController.clear();
      setState(() => _isTyping = false);
    }
    _cubit.send(body);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        appBar: _appBar(colors),
        body: BlocConsumer<ChatCubit, ChatState>(
          listenWhen: (previous, current) =>
              previous.messages.length != current.messages.length ||
              previous.error != current.error,
          listener: (context, state) {
            if (state.messages.isNotEmpty) _scrollToEnd();
            final error = state.error;
            if (error != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(error),
                    backgroundColor: Colors.red[700],
                  ),
                );
              context.read<ChatCubit>().clearError();
            }
          },
          builder: (context, state) {
            if (state.loading && state.messages.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              children: [
                Expanded(child: _messages(state, colors)),
                _quickRepliesBar(),
                _composer(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _messages(ChatState state, AppColorsTheme colors) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      itemCount: state.messages.length,
      itemBuilder: (context, index) {
        final message = state.messages[index];
        final previous = index == 0 ? null : state.messages[index - 1];

        // Separador de dia: só quando a data muda, para não repetir "Hoje"
        // no meio de uma conversa que atravessou a virada.
        final showDay =
            previous == null || !_sameDay(previous.createdAt, message.createdAt);

        return Column(
          children: [
            if (showDay) _DayChip(moment: message.createdAt),
            if (message.isProposal)
              ProposalCard(
                proposal: message.proposal!,
                viewerIsClient: widget.viewerIsClient,
                busy: state.signing,
                onSign: () => _sign(message.proposal!),
                onDecline: widget.viewerIsClient
                    ? () => _cubit.decline(message.proposal!.id)
                    : null,
              )
            else if (message.isSystem)
              _SystemNote(message: message)
            else
              _Bubble(message: message, colors: colors),
          ],
        );
      },
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _sign(Proposal proposal) async {
    final signed = await _cubit.sign(proposal.id);
    if (!mounted || signed == null) return;

    final message = signed.isSigned
        ? 'Contrato aberto! O serviço já aparece na aba Contratos.'
        : widget.viewerIsClient
        ? 'Assinatura registrada. Agora falta a confirmação do profissional.'
        : 'Assinatura registrada.';

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green[700]),
      );
  }

  PreferredSizeWidget _appBar(AppColorsTheme colors) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      titleSpacing: 0,
      leading: IconButton(
        icon: Icon(LucideIcons.arrow_left, color: colors.textPrimary),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          Stack(
            children: [
              _Avatar(
                name: widget.counterpartName,
                url: widget.counterpartAvatarUrl,
                asset: widget.counterpartAvatarAsset,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.counterpartName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                    fontSize: 15,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: _green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Online agora',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: _greenDark,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.phone, color: _green, size: 20),
          onPressed: () => _notAvailable(
            'A chamada de voz ainda não está ligada. Por aqui a conversa '
            'fica registrada para os dois lados.',
          ),
        ),
        IconButton(
          icon: Icon(Icons.more_vert, color: colors.textSecondary, size: 20),
          onPressed: () => _notAvailable('Menu da conversa em construção.'),
        ),
      ],
    );
  }

  void _notAvailable(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _quickRepliesBar() {
    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        scrollDirection: Axis.horizontal,
        itemCount: _quickReplies.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final reply = _quickReplies[index];
          return ActionChip(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            side: BorderSide(color: Colors.grey[300]!),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            label: Text(
              reply,
              style: TextStyle(
                fontSize: 11.5,
                color: Colors.grey[800],
                fontWeight: FontWeight.w500,
              ),
            ),
            onPressed: () => _send(reply),
          );
        },
      ),
    );
  }

  Widget _composer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _notAvailable(
                'Por enquanto as fotos vão junto do pedido de orçamento. '
                'Anexo pelo chat ainda não está ligado.',
              ),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.paperclip,
                  color: Colors.grey[700],
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: TextField(
                  controller: _messageController,
                  onChanged: (value) {
                    final hasText = value.trim().isNotEmpty;
                    if (hasText != _isTyping) {
                      setState(() => _isTyping = hasText);
                    }
                  },
                  onSubmitted: (_) => _send(),
                  textInputAction: TextInputAction.send,
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: 'Digite uma mensagem...',
                    hintStyle: AppTypography.body.copyWith(
                      color: Colors.grey[500],
                      fontSize: 13.5,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                if (_isTyping) {
                  _send();
                } else {
                  _notAvailable('Mensagem de áudio ainda não está ligada.');
                }
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _isTyping ? _green : Colors.grey[100],
                  shape: BoxShape.circle,
                  boxShadow: _isTyping
                      ? [
                          BoxShadow(
                            color: _green.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Icon(
                    _isTyping ? LucideIcons.send : LucideIcons.mic,
                    color: _isTyping ? Colors.white : Colors.grey[700],
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A foto do outro lado da conversa, com a inicial como reserva.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.url, this.asset});

  final String name;
  final String? url;
  final String? asset;

  @override
  Widget build(BuildContext context) {
    final image = url != null
        ? NetworkImage(QuotesApi.photoUrl(url!)) as ImageProvider
        : asset != null
        ? AssetImage(asset!)
        : null;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: image == null
            ? const LinearGradient(
                colors: [_green, _greenDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        image: image == null
            ? null
            : DecorationImage(image: image, fit: BoxFit.cover),
      ),
      child: image != null
          ? null
          : Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.moment});

  final DateTime moment;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(moment.year, moment.month, moment.day);
    final days = today.difference(day).inDays;

    final label = days == 0
        ? 'Hoje'
        : days == 1
        ? 'Ontem'
        : DateFormat("dd 'de' MMMM", 'pt_BR').format(moment);

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: Colors.grey[600],
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.colors});

  final ChatMessage message;
  final AppColorsTheme colors;

  @override
  Widget build(BuildContext context) {
    final mine = message.mine;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: mine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: mine ? _green : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(mine ? 16 : 4),
                  bottomRight: Radius.circular(mine ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message.body,
                    style: TextStyle(
                      color: mine ? Colors.white : colors.textPrimary,
                      fontSize: 13.5,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(message.createdAt),
                        style: TextStyle(
                          color: mine
                              ? Colors.white.withValues(alpha: 0.8)
                              : Colors.grey[500],
                          fontSize: 10,
                        ),
                      ),
                      if (mine) ...[
                        const SizedBox(width: 4),
                        // Dois riscos azuis só depois de o outro lado abrir.
                        Icon(
                          message.readAt != null ? Icons.done_all : Icons.done,
                          size: 13,
                          color: message.readAt != null
                              ? Colors.lightBlueAccent
                              : Colors.white,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Recado do próprio sistema: assinatura, recusa, contrato aberto.
class _SystemNote extends StatelessWidget {
  const _SystemNote({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message.body,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.grey[800]),
          ),
        ),
      ),
    );
  }
}
