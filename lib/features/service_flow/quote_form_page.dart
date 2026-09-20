import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'flow_api.dart';

const paymentLabels = {
  'PIX': 'Pix',
  'CASH': 'Dinheiro',
  'BANK_TRANSFER': 'Transferência',
  'CREDIT_CARD': 'Cartão de crédito',
  'DEBIT_CARD': 'Cartão de débito',
  'BOLETO': 'Boleto',
  'OTHER': 'Outro',
};
const materialLabels = {
  'PROVIDER': 'Fornecidos pelo prestador',
  'CLIENT': 'Fornecidos pelo cliente',
  'SHARED': 'Responsabilidade dividida',
};

class QuoteFormPage extends StatefulWidget {
  const QuoteFormPage({
    super.key,
    required this.matchId,
    required this.initialScope,
  });
  final String matchId, initialScope;
  @override
  State<QuoteFormPage> createState() => _QuoteFormPageState();
}

class _QuoteFormPageState extends State<QuoteFormPage> {
  final _form = GlobalKey<FormState>();
  late final _scope = TextEditingController(text: widget.initialScope);
  final _price = TextEditingController(),
      _payment = TextEditingController(),
      _notes = TextEditingController(),
      _extra = TextEditingController(),
      _warranty = TextEditingController(text: '90');
  String _method = 'PIX', _materials = 'PROVIDER';
  DateTime? _start, _end;
  bool _saving = false;
  String? _error;
  String _key = actionKey(), _lastPayload = '';
  @override
  void dispose() {
    for (final c in [_scope, _price, _payment, _notes, _extra, _warranty]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _date(bool start) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: (start ? _start : _end) ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (time == null || !mounted) return;
    setState(() {
      final value = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      if (start) {
        _start = value;
      } else {
        _end = value;
      }
    });
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_start == null || _end == null || _end!.isBefore(_start!)) {
      setState(
        () => _error = 'Informe o início e uma conclusão posterior ao início.',
      );
      return;
    }
    final terms = {
      'scope': _scope.text.trim(),
      'priceCents': (double.parse(_price.text.replaceAll(',', '.')) * 100)
          .round(),
      'paymentMethod': _method,
      'paymentTerms': _payment.text.trim(),
      'startDate': _start!.toUtc().toIso8601String(),
      'estimatedEndDate': _end!.toUtc().toIso8601String(),
      'warrantyDays': int.parse(_warranty.text),
      'materialsResponsibility': _materials,
      'materialsNotes': _notes.text.trim(),
      'additionalTerms': _extra.text.trim(),
    };
    if (terms.toString() != _lastPayload) {
      _key = actionKey();
      _lastPayload = terms.toString();
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await FlowApi().post('provider/chats/${widget.matchId}/quotes', {
        'clientKey': _key,
        'terms': terms,
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(
    String label,
    TextEditingController c, {
    int lines = 1,
    bool number = false,
    bool optional = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: c,
      maxLines: lines,
      keyboardType: number
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.multiline,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (v) {
        if (optional) return null;
        if (v == null || v.trim().isEmpty) return 'Preencha este campo';
        if (number && (double.tryParse(v.replaceAll(',', '.')) ?? 0) <= 0) {
          return 'Informe um valor válido';
        }
        if (c == _warranty && (int.tryParse(v) ?? 0) < 90) {
          return 'Informe ao menos 90 dias';
        }
        return null;
      },
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Enviar orçamento')),
    body: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _field('Escopo do serviço', _scope, lines: 5),
          _field('Valor total (R\$)', _price, number: true),
          DropdownButtonFormField<String>(
            initialValue: _method,
            decoration: const InputDecoration(labelText: 'Forma de pagamento'),
            items: paymentLabels.entries
                .map(
                  (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                )
                .toList(),
            onChanged: (v) => setState(() => _method = v!),
          ),
          const SizedBox(height: 16),
          _field('Condições de pagamento', _payment, lines: 2),
          ListTile(
            title: const Text('Início previsto'),
            subtitle: Text(
              _start == null
                  ? 'Selecionar data e horário'
                  : DateFormat('dd/MM/yyyy HH:mm').format(_start!),
            ),
            onTap: () => _date(true),
          ),
          ListTile(
            title: const Text('Conclusão prevista'),
            subtitle: Text(
              _end == null
                  ? 'Selecionar data e horário'
                  : DateFormat('dd/MM/yyyy HH:mm').format(_end!),
            ),
            onTap: () => _date(false),
          ),
          const SizedBox(height: 16),
          _field('Garantia (dias)', _warranty, number: true),
          DropdownButtonFormField<String>(
            initialValue: _materials,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Materiais'),
            items: materialLabels.entries
                .map(
                  (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                )
                .toList(),
            onChanged: (v) => setState(() => _materials = v!),
          ),
          const SizedBox(height: 16),
          _field('Detalhes dos materiais', _notes, lines: 2, optional: true),
          _field('Condições adicionais', _extra, lines: 3, optional: true),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          FilledButton(
            onPressed: _saving ? null : _submit,
            child: Text(_saving ? 'Enviando…' : 'Enviar orçamento'),
          ),
        ],
      ),
    ),
  );
}
