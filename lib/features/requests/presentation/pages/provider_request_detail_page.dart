import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';

import 'package:flutter_tcc/core/network/api_exception.dart';
import 'package:flutter_tcc/core/theme/app_colors.dart';
import 'package:flutter_tcc/core/theme/app_spacing.dart';
import 'package:flutter_tcc/core/theme/app_typography.dart';
import 'package:flutter_tcc/features/quotes/data/quote_models.dart';
import 'package:flutter_tcc/features/quotes/data/quotes_api.dart';
import 'package:flutter_tcc/features/quotes/presentation/pages/quote_chat_page.dart';
import 'package:flutter_tcc/features/requests/presentation/pages/provider_quote_generator_page.dart';
import 'package:flutter_tcc/injection_container.dart';

/// O pedido de orçamento, como o profissional o lê.
///
/// O desenho é o que a tela já tinha. Mudou o campo de valor, que saiu: ler o
/// pedido e fazer preço são dois momentos, e o preço agora vive no orçamento
/// formal. O que entrou no lugar foi o servidor — a descrição, as fotos e o
/// cliente vêm do pedido de verdade, e a mensagem digitada aqui chega na
/// conversa dele.
class ProviderRequestDetailPage extends StatefulWidget {
  const ProviderRequestDetailPage({super.key, this.request});

  /// Nulo só nos testes de tela, que montam a página sem servidor.
  final QuoteRequest? request;

  @override
  State<ProviderRequestDetailPage> createState() =>
      _ProviderRequestDetailPageState();
}

class _ProviderRequestDetailPageState extends State<ProviderRequestDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  bool _busy = false;

  /// Só há o que enviar depois de escrever: sem isto o botão de mensagem fica
  /// aceso o tempo todo, prometendo uma ação que não acontece.
  bool _hasMessage = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  QuoteRequest? get _request => widget.request;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final request = _request;
    final clientName = request?.client.display ?? 'Gabriel';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrow_left, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Analisar Pedido',
          style: AppTypography.h3.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Alerta superior
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.clock, color: Colors.orange),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'O cliente $clientName está aguardando seu orçamento. '
                    'Envie o mais rápido possível para fechar o negócio!',
                    style: AppTypography.caption.copyWith(
                      color: Colors.orange[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Informações do Serviço
          Text(
            'Detalhes do Serviço',
            style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildInfoRow(
            LucideIcons.file_text,
            'Serviço',
            request?.title ?? 'Pintura Residencial (20m²)',
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildInfoRow(LucideIcons.user, 'Cliente', clientName),
          const SizedBox(height: AppSpacing.sm),
          _buildInfoRow(
            LucideIcons.calendar,
            'Recebido',
            request == null
                ? 'O quanto antes'
                : DateFormat("dd/MM 'às' HH:mm").format(request.createdAt),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Descrição do cliente
          Text(
            'Descrição do Cliente',
            style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              request == null ? 'Sem descrição.' : '"${request.description}"',
              style: AppTypography.body.copyWith(
                color: Colors.grey[800],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

          if (request != null && request.photos.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),

            // Anexos
            Text(
              'Fotos Anexadas (${request.photos.length})',
              style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildPhotos(request),
          ],

          const SizedBox(height: AppSpacing.xxl),
          const Divider(),
          const SizedBox(height: AppSpacing.md),

          // Formulário de Orçamento
          Text(
            'Enviar Proposta',
            style: AppTypography.h2.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.md),

          Text(
            'Ficou alguma dúvida? Mande uma mensagem antes de fechar o '
            'valor. Se o pedido já diz tudo, vá direto para o orçamento.',
            style: AppTypography.caption.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: AppSpacing.md),

          Text(
            'Mensagem para o cliente (Opcional)',
            style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _messageController,
            maxLines: 3,
            onChanged: (value) {
              final has = value.trim().isNotEmpty;
              if (has != _hasMessage) setState(() => _hasMessage = has);
            },
            decoration: InputDecoration(
              hintText: 'Ex: O valor já inclui o material para lixar a parede...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.primary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // A mensagem precisa de uma saída própria: os dois botões de baixo
          // são recusar o pedido e montar o orçamento.
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _busy || request == null || !_hasMessage
                  ? null
                  : _sendMessage,
              icon: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(LucideIcons.send, size: 16, color: colors.primary),
              label: Text(
                'Enviar mensagem ao cliente',
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: colors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Botões de Ação
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy
                      ? null
                      : (request == null
                            ? () => Navigator.of(context).pop()
                            : _decline),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.grey[400]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Recusar Pedido',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            ProviderQuoteGeneratorPage(quoteRequest: request),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Enviar Proposta',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.caption.copyWith(color: Colors.grey[600]),
              ),
              Text(
                value,
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// As fotos que o cliente anexou, servidas pelo backend. Uma só ocupa a
  /// largura, como no desenho original; várias entram numa fileira rolável.
  Widget _buildPhotos(QuoteRequest request) {
    if (request.photos.length == 1) {
      return _photo(request.photos.first.url, width: double.infinity);
    }

    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: request.photos.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) =>
            _photo(request.photos[index].url, width: 280),
      ),
    );
  }

  Widget _photo(String path, {required double width}) {
    final url = QuotesApi.photoUrl(path);

    return GestureDetector(
      onTap: () => _openPhoto(url),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          url,
          height: 200,
          width: width,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            height: 200,
            width: width == double.infinity ? null : width,
            color: Colors.grey[200],
            alignment: Alignment.center,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.image, size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text('Não consegui carregar a foto'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openPhoto(String url) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(child: InteractiveViewer(child: Image.network(url))),
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final request = _request;
    final conversationId = request?.conversationId;
    final text = _messageController.text.trim();

    if (request == null || conversationId == null || text.isEmpty) return;

    setState(() => _busy = true);

    try {
      await sl<QuotesApi>().sendMessage(conversationId, text);
      if (!mounted) return;

      _messageController.clear();
      setState(() => _busy = false);

      // Leva para a conversa: a resposta do cliente chega lá, não aqui.
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => QuoteChatPage(
            conversationId: conversationId,
            counterpartName: request.client.display,
            counterpartAvatarUrl: request.client.avatarUrl,
            subtitle: request.title,
            viewerIsClient: false,
          ),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  Future<void> _decline() async {
    final request = _request;
    if (request == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recusar este pedido?'),
        content: const Text(
          'O cliente é avisado na conversa e o pedido sai da sua lista.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Voltar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Recusar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);

    try {
      await sl<QuotesApi>().declineRequest(request.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }
}
