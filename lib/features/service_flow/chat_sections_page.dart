import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'flow_api.dart';
import 'conversation_page.dart';
import 'package:flutter_tcc/core/widgets/app_back_button.dart';

class ChatSectionsPage extends StatefulWidget {
  const ChatSectionsPage({super.key, this.provider = false});
  final bool provider;
  @override
  State<ChatSectionsPage> createState() => _ChatSectionsPageState();
}

class _ChatSectionsPageState extends State<ChatSectionsPage>
    with WidgetsBindingObserver {
  late final _api = FlowApi();
  List<Json>? _sections;
  String? _error;
  String _query = '';
  bool _loading = false;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    if (_loading ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.paused) {
      return;
    }
    _loading = true;
    try {
      final data = objects(
        await _api.get('${widget.provider ? 'provider' : 'client'}/chats'),
      );
      if (mounted) {
        setState(() {
          _sections = data;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      _loading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sections = (_sections ?? [])
        .where(
          (s) =>
              '${s['title']} ${s['number']} ${objects(s['chats']).map((c) => c['name']).join(' ')}'
                  .toLowerCase()
                  .contains(_query.toLowerCase()),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(
        leadingWidth: AppBackButton.slotWidth,
        leading: const AppBackButton(),
        title: const Text('Chats'),
        automaticallyImplyLeading: Navigator.canPop(context),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: TextField(
              onChanged: (s) => setState(() => _query = s),
              decoration: const InputDecoration(
                prefixIcon: Icon(LucideIcons.search),
                hintText: 'Buscar solicitação ou conversa',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          if (_error != null)
            MaterialBanner(
              content: Text(_error!),
              actions: [
                TextButton(
                  onPressed: _load,
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          Expanded(
            child: _sections == null && _error == null
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 110),
                      children: [
                        if (sections.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              widget.provider
                                  ? 'As solicitações recebidas aparecerão aqui, agrupadas por serviço.'
                                  : 'Suas conversas aparecerão aqui quando você solicitar um serviço.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        for (final section in sections) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                            child: Text(
                              '${section['title']} — #${section['number']}${section['urgent'] == true ? ' · Urgente' : ''}',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ),
                          for (final chat in objects(section['chats']))
                            ListTile(
                              leading: CircleAvatar(
                                child: Icon(
                                  chat['closed'] == true
                                      ? LucideIcons.lock
                                      : LucideIcons.user,
                                ),
                              ),
                              title: Text('${chat['name'] ?? 'Cliente'}'),
                              subtitle: Text(
                                '${chat['lastMessage']}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: const Icon(LucideIcons.chevron_right),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => ConversationPage(
                                      matchId: '${chat['id']}',
                                      provider: widget.provider,
                                    ),
                                  ),
                                );
                                _load();
                              },
                            ),
                          const Divider(indent: 20, endIndent: 20),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
