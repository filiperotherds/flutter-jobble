import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:flutter_tcc/features/contracts/presentation/pages/contract_detail_page.dart';
import 'flow_api.dart';
import 'quote_form_page.dart';
import 'package:flutter_tcc/core/widgets/app_back_button.dart';

class ConversationPage extends StatefulWidget {
  const ConversationPage({
    super.key,
    required this.matchId,
    this.provider = false,
  });
  final String matchId;
  final bool provider;
  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  late final _api = FlowApi();
  final _text = TextEditingController();
  final _scroll = ScrollController();
  Json? _data;
  String? _error, _pendingKey, _pendingText;
  bool _sending = false, _loading = false;
  Timer? _timer;
  String get _path =>
      '${widget.provider ? 'provider' : 'client'}/chats/${widget.matchId}';
  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_loading ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.paused) {
      return;
    }
    _loading = true;
    try {
      final value = object(await _api.get(_path));
      final changed =
          objects(value['messages']).length !=
          objects(_data?['messages']).length;
      if (mounted) {
        setState(() {
          _data = value;
          _error = null;
        });
        if (changed) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scroll.hasClients) {
              _scroll.animateTo(
                _scroll.position.maxScrollExtent,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
              );
            }
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      _loading = false;
    }
  }

  Future<void> _attach() async {
    if (_sending) return;
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1800,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;
    setState(() => _sending = true);
    try {
      await _api.upload(
        '$_path/attachments',
        await file.readAsBytes(),
        actionKey(),
      );
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
      await _load();
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _send() async {
    final value = _text.text.trim();
    if (value.isEmpty || _sending) return;
    if (_pendingText != value) {
      _pendingKey = actionKey();
      _pendingText = value;
    }
    setState(() => _sending = true);
    try {
      await _api.post('$_path/messages', {
        'text': value,
        'clientKey': _pendingKey,
      });
      _text.clear();
      _pendingKey = null;
      _pendingText = null;
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
      await _load();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _decide(Json quote, bool accept) async {
    if (accept) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Aceitar orçamento?'),
          content: const Text(
            'As outras conversas desta solicitação serão encerradas e ficarão disponíveis no histórico. O contrato será gerado para assinatura.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Voltar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Aceitar orçamento'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    if (!mounted) return;
    setState(() => _sending = true);
    try {
      await _api.post('$_path/quotes/${quote['id']}/decision', {
        'accept': accept,
      });
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
      await _load();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _date(dynamic value) => value == null
      ? 'A combinar'
      : DateFormat(
          'dd/MM/yyyy HH:mm',
        ).format(DateTime.parse('$value').toLocal());
  Widget _quote(Json quote, bool closed) {
    final t = object(quote['terms']);
    final money = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    ).format((t['priceCents'] as num) / 100);
    final pending =
        quote['status'] == 'PENDING' && !closed && _data?['contract'] == null;
    final status =
        {
          'PENDING': 'Aguardando decisão',
          'ACCEPTED': 'Aceito',
          'REFUSED': 'Recusado',
          'SUPERSEDED': 'Substituído',
          'CLOSED': 'Solicitação encerrada',
        }[quote['status']] ??
        '${quote['status']}';
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Orçamento · $money',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('${t['scope']}'),
            const Divider(),
            Text(
              'Pagamento: ${paymentLabels[t['paymentMethod']] ?? t['paymentMethod']}\n${t['paymentTerms']}',
            ),
            Text(
              'Início: ${_date(t['startDate'])}\nConclusão prevista: ${_date(t['estimatedEndDate'])}\nGarantia: ${t['warrantyDays']} dias',
            ),
            Text(
              'Materiais: ${materialLabels[t['materialsResponsibility']] ?? t['materialsResponsibility']}',
            ),
            if (t['materialsNotes'] != null) Text('${t['materialsNotes']}'),
            if (t['additionalTerms'] != null) Text('${t['additionalTerms']}'),
            const SizedBox(height: 12),
            Text(status, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (pending && !widget.provider) ...[
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _sending ? null : () => _decide(quote, true),
                child: const Text('Aceitar orçamento'),
              ),
              OutlinedButton(
                onPressed: _sending ? null : () => _decide(quote, false),
                child: const Text('Recusar orçamento'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _data, closed = data?['closed'] == true;
    final request = data == null ? null : object(data['request']);
    return Scaffold(
      appBar: AppBar(
        leadingWidth: AppBackButton.slotWidth,
        leading: const AppBackButton(),
        title: Text('${data?['name'] ?? 'Conversa'}'),
      ),
      body: data == null
          ? Center(
              child: _error == null
                  ? const CircularProgressIndicator()
                  : TextButton(
                      onPressed: _load,
                      child: Text('$_error\nTentar novamente'),
                    ),
            )
          : Column(
              children: [
                if (_error != null)
                  MaterialBanner(
                    content: Text(_error!),
                    actions: [
                      TextButton(
                        onPressed: _load,
                        child: const Text('Atualizar'),
                      ),
                    ],
                  ),
                ExpansionTile(
                  title: Text(
                    '${request!['title']} — #${request['number']}',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  subtitle: request['urgent'] == true
                      ? const Text('Urgente · prazo de resposta de 3 horas')
                      : null,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SelectableText('${request['description']}'),
                    ),
                  ],
                ),
                if (data['contract'] != null)
                  ListTile(
                    leading: const Icon(LucideIcons.file_text),
                    title: const Text('Contrato e assinaturas'),
                    subtitle: Text('${object(data['contract'])['code']}'),
                    trailing: const Icon(LucideIcons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => ContractDetailPage(
                          contractId: '${object(data['contract'])['id']}',
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: ListView(
                    controller: _scroll,
                    padding: const EdgeInsets.all(18),
                    children: [
                      for (final message in objects(data['messages']))
                        Align(
                          alignment: message['kind'] == 'SYSTEM'
                              ? Alignment.center
                              : message['mine'] == true
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            constraints: const BoxConstraints(maxWidth: 340),
                            decoration: BoxDecoration(
                              color: message['kind'] == 'SYSTEM'
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerLow
                                  : message['mine'] == true
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer
                                  : Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (message['imageUrl'] != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      '${message['imageUrl']}',
                                      width: 280,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, _, _) => const Text(
                                        'Não foi possível carregar a imagem. Atualize a conversa.',
                                      ),
                                    ),
                                  ),
                                SelectableText('${message['text']}'),
                                const SizedBox(height: 4),
                                Text(
                                  _date(message['createdAt']),
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      for (final quote in objects(data['quotes']))
                        _quote(quote, closed),
                    ],
                  ),
                ),
                if (closed)
                  const SafeArea(
                    top: false,
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.lock, size: 18),
                          SizedBox(width: 8),
                          Text('Solicitação encerrada'),
                        ],
                      ),
                    ),
                  ),
                if (!closed)
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      child: Column(
                        children: [
                          if (widget.provider && data['contract'] == null)
                            OutlinedButton.icon(
                              onPressed: _sending
                                  ? null
                                  : () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute<void>(
                                          builder: (_) => QuoteFormPage(
                                            matchId: widget.matchId,
                                            initialScope:
                                                '${request['description']}',
                                          ),
                                        ),
                                      );
                                      _load();
                                    },
                              icon: const Icon(LucideIcons.receipt_text),
                              label: const Text('Enviar orçamento'),
                            ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: _sending ? null : _attach,
                                tooltip: 'Enviar imagem',
                                icon: const Icon(LucideIcons.image),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _text,
                                  enabled: !_sending,
                                  minLines: 1,
                                  maxLines: 4,
                                  decoration: const InputDecoration(
                                    hintText: 'Escreva sua mensagem',
                                    border: OutlineInputBorder(),
                                  ),
                                  onSubmitted: (_) => _send(),
                                ),
                              ),
                              IconButton(
                                onPressed: _sending ? null : _send,
                                tooltip: 'Enviar mensagem',
                                icon: _sending
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(LucideIcons.send),
                              ),
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
