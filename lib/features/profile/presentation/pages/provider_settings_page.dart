import 'package:flutter/material.dart';
import 'package:flutter_tcc/core/network/dio_client.dart';
import 'package:flutter_tcc/core/network/api_exception.dart';
import 'package:flutter_tcc/injection_container.dart';

class ProviderSettingsPage extends StatefulWidget {
  const ProviderSettingsPage({super.key});
  @override
  State<ProviderSettingsPage> createState() => _SettingsState();
}

class _SettingsState extends State<ProviderSettingsPage> {
  Map<String, dynamic>? _settings;
  String? _error;
  bool _saving = false;
  final _current = TextEditingController();
  final _next = TextEditingController();
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final r = await apiCall(
        () => sl<DioClient>().dio.get('/users/me/settings'),
      );
      if (mounted) {
        setState(() {
          _settings = Map<String, dynamic>.from(r.data);
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _change(String key, bool value) async {
    setState(() => _saving = true);
    try {
      final r = await apiCall(
        () =>
            sl<DioClient>().dio.patch('/users/me/settings', data: {key: value}),
      );
      if (mounted) {
        setState(() => _settings = Map<String, dynamic>.from(r.data));
      }
    } catch (e) {
      _message('$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _password() async {
    if (_next.text.length < 8) {
      _message('Use pelo menos 8 caracteres na nova senha.');
      return;
    }
    setState(() => _saving = true);
    try {
      await apiCall(
        () => sl<DioClient>().dio.post(
          '/users/me/password',
          data: {'currentPassword': _current.text, 'newPassword': _next.text},
        ),
      );
      _current.clear();
      _next.clear();
      _message('Senha atualizada.');
    } catch (e) {
      _message('$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Preferências e segurança')),
    body: _settings == null
        ? Center(
            child: _error == null
                ? const CircularProgressIndicator()
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      TextButton(
                        onPressed: _load,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
          )
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              for (final entry in const {
                'pushNotifications': 'Notificações no dispositivo',
                'emailNotifications': 'Notificações por e-mail',
                'showPhone': 'Exibir telefone no perfil',
                'showLocation': 'Exibir localização no perfil',
              }.entries)
                SwitchListTile(
                  title: Text(entry.value),
                  value: _settings![entry.key] == true,
                  onChanged: _saving ? null : (v) => _change(entry.key, v),
                ),
              const SizedBox(height: 24),
              Text(
                'Alterar senha',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _current,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Senha atual'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _next,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Nova senha'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saving ? null : _password,
                child: Text(_saving ? 'Salvando…' : 'Atualizar senha'),
              ),
            ],
          ),
  );
}
