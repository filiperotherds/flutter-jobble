import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_tcc/features/contracts/domain/contract_repository.dart';
import 'package:flutter_tcc/features/contracts/data/models/contract_model.dart';
import 'package:flutter_tcc/features/contracts/presentation/pages/contract_detail_page.dart';
import 'package:flutter_tcc/core/widgets/app_card.dart';
import 'package:flutter_tcc/injection_container.dart';

class ProviderAgendaPage extends StatefulWidget {
  const ProviderAgendaPage({super.key});
  @override
  State<ProviderAgendaPage> createState() => _AgendaState();
}

class _AgendaState extends State<ProviderAgendaPage> {
  late Future<List<ContractSummary>> _future;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = sl<ContractRepository>().list();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Agenda de serviços')),
    body: FutureBuilder<List<ContractSummary>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: TextButton(
              onPressed: () => setState(_load),
              child: const Text('Não foi possível carregar. Tentar novamente'),
            ),
          );
        }
        final rows =
            (snapshot.data ?? [])
                .where(
                  (c) =>
                      c.startDate != null &&
                      c.status != ContractStatus.canceled &&
                      c.status != ContractStatus.terminated,
                )
                .toList()
              ..sort((a, b) => a.startDate!.compareTo(b.startDate!));
        return RefreshIndicator(
          onRefresh: () async {
            setState(_load);
            await _future;
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              if (rows.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Nenhum serviço agendado. As datas combinadas nos contratos aparecerão aqui.',
                  ),
                ),
              for (final row in rows)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat(
                            'dd/MM/yyyy',
                          ).format(row.startDate!.toLocal()),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          row.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(row.clientName),
                        Text(row.status.label),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    ContractDetailPage(contractId: row.id),
                              ),
                            );
                            if (mounted) setState(_load);
                          },
                          child: const Text('Ver contrato'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );
}
