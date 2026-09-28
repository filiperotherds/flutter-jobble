import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'flow_api.dart';
import 'package:flutter_tcc/core/widgets/app_back_button.dart';

const weekdays = [
  'Domingo',
  'Segunda-feira',
  'Terça-feira',
  'Quarta-feira',
  'Quinta-feira',
  'Sexta-feira',
  'Sábado',
];

class ProviderAttendancePage extends StatefulWidget {
  const ProviderAttendancePage({super.key, this.onSaved});
  final VoidCallback? onSaved;
  @override
  State<ProviderAttendancePage> createState() => _ProviderAttendancePageState();
}

class _ProviderAttendancePageState extends State<ProviderAttendancePage> {
  Json? _hours;
  String _zone = 'America/Sao_Paulo';
  String? _error;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s = object(await FlowApi().get('provider/settings'));
      if (mounted) {
        setState(() {
          _zone = '${s['timeZone']}';
          _hours = s['hours'] == null
              ? {
                  'allDay': false,
                  'days': List.generate(
                    7,
                    (i) => {
                      'day': i,
                      'allDay': false,
                      'windows': i > 0 && i < 6
                          ? [
                              {'start': '08:00', 'end': '18:00'},
                            ]
                          : <Json>[],
                    },
                  ),
                }
              : object(s['hours']);
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _window(Json day, {int? index}) async {
    final windows = objects(day['windows']);
    final current = index == null ? null : windows[index];
    TimeOfDay parse(String s) => TimeOfDay(
      hour: int.parse(s.substring(0, 2)),
      minute: int.parse(s.substring(3)),
    );
    final start = await showTimePicker(
      context: context,
      helpText: 'Início do atendimento',
      initialTime: current == null
          ? const TimeOfDay(hour: 8, minute: 0)
          : parse('${current['start']}'),
    );
    if (start == null || !mounted) return;
    final end = await showTimePicker(
      context: context,
      helpText: 'Fim do atendimento',
      initialTime: current == null
          ? const TimeOfDay(hour: 18, minute: 0)
          : parse('${current['end']}'),
    );
    if (end == null || !mounted) return;
    if (start == end) {
      setState(() => _error = 'Para o dia inteiro, marque 24 horas.');
      return;
    }
    String format(TimeOfDay t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    setState(() {
      final w = {'start': format(start), 'end': format(end)};
      if (index == null) {
        windows.add(w);
      } else {
        windows[index] = w;
      }
      day['windows'] = windows;
      day['allDay'] = false;
      _error = null;
    });
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await FlowApi().patch('provider/hours', {
        'hours': _hours,
        'timeZone': _zone,
      });
      if (mounted) {
        if (widget.onSaved != null) {
          widget.onSaved!();
        } else {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hours = _hours;
    return Scaffold(
      appBar: AppBar(
        leadingWidth: AppBackButton.slotWidth,
        leading: const AppBackButton(),
        title: const Text('Horários de atendimento'),
      ),
      body: hours == null
          ? Center(
              child: _error == null
                  ? const CircularProgressIndicator()
                  : TextButton(
                      onPressed: _load,
                      child: Text('$_error\nTentar novamente'),
                    ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Defina quando você atende. Solicitações urgentes só serão enviadas durante esses horários e para serviços em que você oferecer urgência.',
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue: _zone,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Fuso horário'),
                  items:
                      {
                            _zone,
                            'America/Sao_Paulo',
                            'America/Manaus',
                            'America/Rio_Branco',
                            'America/Noronha',
                            'America/Cuiaba',
                            'America/Bahia',
                            'America/Fortaleza',
                            'America/Belem',
                            'America/Porto_Velho',
                            'America/Boa_Vista',
                            'America/Campo_Grande',
                          }
                          .map(
                            (z) => DropdownMenuItem(value: z, child: Text(z)),
                          )
                          .toList(),
                  onChanged: _saving ? null : (v) => setState(() => _zone = v!),
                ),
                SwitchListTile(
                  title: const Text('Atendo 24 horas, todos os dias'),
                  value: hours['allDay'] == true,
                  onChanged: _saving
                      ? null
                      : (v) => setState(() => hours['allDay'] = v),
                ),
                if (hours['allDay'] != true)
                  for (final raw in hours['days'] as List)
                    Builder(
                      builder: (context) {
                        final day = raw as Map<String, dynamic>,
                            windows = objects(day['windows']);
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    weekdays[(day['day'] as num).toInt()],
                                  ),
                                  subtitle: Text(
                                    day['allDay'] == true
                                        ? '24 horas'
                                        : windows.isEmpty
                                        ? 'Fechado'
                                        : 'Horários definidos abaixo',
                                  ),
                                  value:
                                      day['allDay'] == true ||
                                      windows.isNotEmpty,
                                  onChanged: _saving
                                      ? null
                                      : (v) => setState(() {
                                          day['allDay'] = false;
                                          day['windows'] = v
                                              ? [
                                                  {
                                                    'start': '08:00',
                                                    'end': '18:00',
                                                  },
                                                ]
                                              : <Json>[];
                                        }),
                                ),
                                if (day['allDay'] == true || windows.isNotEmpty)
                                  CheckboxListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text('24 horas neste dia'),
                                    value: day['allDay'] == true,
                                    onChanged: _saving
                                        ? null
                                        : (v) => setState(() {
                                            day['allDay'] = v;
                                            day['windows'] = v == true
                                                ? <Json>[]
                                                : [
                                                    {
                                                      'start': '08:00',
                                                      'end': '18:00',
                                                    },
                                                  ];
                                          }),
                                  ),
                                if (day['allDay'] != true) ...[
                                  for (var i = 0; i < windows.length; i++)
                                    ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        '${windows[i]['start']}–${windows[i]['end']}',
                                      ),
                                      subtitle:
                                          '${windows[i]['start']}'.compareTo(
                                                '${windows[i]['end']}',
                                              ) >
                                              0
                                          ? const Text(
                                              'Termina no dia seguinte',
                                            )
                                          : null,
                                      onTap: _saving
                                          ? null
                                          : () => _window(day, index: i),
                                      trailing: IconButton(
                                        tooltip: 'Remover horário',
                                        onPressed: _saving
                                            ? null
                                            : () => setState(() {
                                                windows.removeAt(i);
                                                day['windows'] = windows;
                                              }),
                                        icon: const Icon(
                                          LucideIcons.circle_minus,
                                        ),
                                      ),
                                    ),
                                  if (windows.length < 6)
                                    TextButton.icon(
                                      onPressed: _saving
                                          ? null
                                          : () => _window(day),
                                      icon: const Icon(LucideIcons.plus),
                                      label: const Text(
                                        'Adicionar janela de horário',
                                      ),
                                    ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                if (_error != null)
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Salvando…' : 'Salvar horários'),
                ),
              ],
            ),
    );
  }
}

class ProviderCatalogPage extends StatefulWidget {
  const ProviderCatalogPage({super.key});
  @override
  State<ProviderCatalogPage> createState() => _ProviderCatalogPageState();
}

class _ProviderCatalogPageState extends State<ProviderCatalogPage> {
  List<Json>? _services;
  List<Json> _templates = [];
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await Future.wait([
        FlowApi().get('provider/settings'),
        FlowApi().get('templates'),
      ]);
      if (mounted) {
        setState(() {
          _services = objects(object(data[0])['services']);
          _templates = objects(
            data[1],
          ).where((t) => t['id'] != 'outros').toList();
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _edit([Json? service]) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => _ServiceEditor(service: service, templates: _templates),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leadingWidth: AppBackButton.slotWidth,
      leading: const AppBackButton(),
      title: const Text('Catálogo de serviços'),
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _templates.isEmpty ? null : () => _edit(),
      icon: const Icon(LucideIcons.plus),
      label: const Text('Novo serviço'),
    ),
    body: _services == null
        ? Center(
            child: _error == null
                ? const CircularProgressIndicator()
                : TextButton(
                    onPressed: _load,
                    child: Text('$_error\nTentar novamente'),
                  ),
          )
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              children: [
                if (_services!.isEmpty)
                  const Text(
                    'Cadastre os serviços que você oferece. A urgência pode ser ativada separadamente para cada serviço.',
                  ),
                for (final service in _services!)
                  Card(
                    child: ListTile(
                      title: Text('${service['title']}'),
                      subtitle: Text(
                        '${service['isActive'] == true ? 'Publicado' : 'Desativado'} · ${service['offersUrgency'] == true ? 'Atende com urgência' : 'Sem urgência'}\n${service['description']}',
                      ),
                      trailing: const Icon(LucideIcons.square_pen),
                      onTap: () => _edit(service),
                    ),
                  ),
              ],
            ),
          ),
  );
}

class _ServiceEditor extends StatefulWidget {
  const _ServiceEditor({this.service, required this.templates});
  final Json? service;
  final List<Json> templates;
  @override
  State<_ServiceEditor> createState() => _ServiceEditorState();
}

class _ServiceEditorState extends State<_ServiceEditor> {
  late final _title = TextEditingController(text: widget.service?['title']);
  late final _price = TextEditingController(
    text: widget.service?['priceCents'] == null
        ? ''
        : ((widget.service!['priceCents'] as num) / 100)
              .toStringAsFixed(2)
              .replaceAll('.', ','),
  );
  late final _unit = TextEditingController(
    text: widget.service?['priceUnit'] ?? '',
  );
  late final _description = TextEditingController(
    text: widget.service?['description'],
  );
  late String? _template = widget.service?['templateId'];
  late bool _urgent = widget.service?['offersUrgency'] == true,
      _active = widget.service?['isActive'] != false;
  bool _busy = false;
  String? _error;
  final _form = GlobalKey<FormState>();
  @override
  void dispose() {
    _price.dispose();
    _unit.dispose();
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final body = {
      'templateId': _template,
      'title': _title.text.trim(),
      'description': _description.text.trim(),
      'priceCents': _price.text.trim().isEmpty
          ? null
          : (double.parse(_price.text.trim().replaceAll(',', '.')) * 100)
                .round(),
      'priceUnit': _unit.text.trim().isEmpty ? null : _unit.text.trim(),
      'offersUrgency': _urgent,
      'isActive': _active,
    };
    try {
      final api = FlowApi();
      if (widget.service == null) {
        await api.post('provider/services', body);
      } else {
        await api.patch('provider/services/${widget.service!['id']}', body);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leadingWidth: AppBackButton.slotWidth,
      leading: const AppBackButton(),
      title: Text(widget.service == null ? 'Novo serviço' : 'Editar serviço'),
    ),
    body: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          DropdownButtonFormField<String>(
            initialValue: _template,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Tipo de prestação'),
            items: widget.templates
                .map(
                  (t) => DropdownMenuItem(
                    value: '${t['id']}',
                    child: Text(
                      '${t['title']}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            validator: (v) => v == null ? 'Selecione o tipo de serviço' : null,
            onChanged: (v) => setState(() => _template = v),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _title,
            decoration: const InputDecoration(
              labelText: 'Nome do serviço',
              border: OutlineInputBorder(),
            ),
            maxLength: 100,
            validator: (v) =>
                (v?.trim().length ?? 0) < 3 ? 'Informe o nome' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _description,
            decoration: const InputDecoration(
              labelText: 'O que está incluído',
              border: OutlineInputBorder(),
            ),
            maxLines: 5,
            maxLength: 3000,
            validator: (v) =>
                (v?.trim().length ?? 0) < 5 ? 'Descreva o serviço' : null,
          ),
          TextFormField(
            controller: _price,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: r'Valor de referência em R$ (opcional)',
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                v == null ||
                    v.trim().isEmpty ||
                    (double.tryParse(v.replaceAll(',', '.')) ?? 0) > 0
                ? null
                : 'Informe um valor válido',
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _unit,
            maxLength: 60,
            decoration: const InputDecoration(
              labelText: 'Unidade, por exemplo: por dia ou por m²',
              border: OutlineInputBorder(),
            ),
          ),
          SwitchListTile(
            title: const Text('Ofereço atendimento com urgência'),
            subtitle: const Text(
              'Receba solicitações urgentes somente durante seus horários. Responda em até 3 horas.',
            ),
            value: _urgent,
            onChanged: (v) => setState(() => _urgent = v),
          ),
          SwitchListTile(
            title: const Text('Serviço publicado'),
            value: _active,
            onChanged: (v) => setState(() => _active = v),
          ),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: Text(_busy ? 'Salvando…' : 'Salvar serviço'),
          ),
        ],
      ),
    ),
  );
}
