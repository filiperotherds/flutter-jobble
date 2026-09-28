import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';

import 'package:flutter_tcc/core/network/api_exception.dart';
import 'package:flutter_tcc/core/theme/app_colors.dart';
import 'package:flutter_tcc/core/theme/app_spacing.dart';
import 'package:flutter_tcc/core/theme/app_typography.dart';
import 'package:flutter_tcc/core/widgets/app_empty_state.dart';
import 'package:flutter_tcc/core/widgets/app_loader.dart';
import 'package:flutter_tcc/features/bids/data/datasources/bid_remote_data_source.dart';
import 'package:flutter_tcc/features/bids/data/models/org_match_model.dart';
import 'package:flutter_tcc/features/contracts/data/models/contract_model.dart';
import 'package:flutter_tcc/features/bids/data/models/service_request_detail_model.dart';
import 'package:flutter_tcc/features/contracts/domain/contract_repository.dart';
import 'package:flutter_tcc/features/service_flow/flow_api.dart';
import 'package:flutter_tcc/injection_container.dart';

/// Desempenho do profissional, com o que o servidor de fato mede.
///
/// A taxa de resposta vem de `GET /flow/provider/settings` e é a mesma que
/// decide quem entra na seleção de candidatos — por isso vale mostrá-la aqui.
class ProviderPerformancePage extends StatefulWidget {
  const ProviderPerformancePage({super.key});

  @override
  State<ProviderPerformancePage> createState() =>
      _ProviderPerformancePageState();
}

class _ProviderPerformancePageState extends State<ProviderPerformancePage> {
  final _flow = FlowApi();
  final _bids = sl<BidRemoteDataSource>();
  final _contracts = sl<ContractRepository>();

  double _rating = 0;
  int _totalReviews = 0;
  double? _responseRate;
  int _answered = 0;
  int _totalCalls = 0;
  int _pending = 0;
  int _completed = 0;
  int _received = 0;
  int _hired = 0;

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
      final settings = object(await _flow.get('provider/settings'));
      final organizationId = settings['organizationId'] as String?;
      final response = settings['response'] as Map?;
      final profile = organizationId == null
          ? <String, dynamic>{}
          : object(await _flow.get('providers/$organizationId'));

      List<OrgMatch> matches = const [];
      List<ContractSummary> contracts = const [];
      // Chamados e contratos só enriquecem o resumo: um erro aqui não pode
      // esconder a avaliação e a taxa de resposta.
      try {
        matches = await _bids.listMatches();
        contracts = await _contracts.list();
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _rating = (profile['rating'] as num?)?.toDouble() ?? 0;
        _totalReviews = (profile['totalReviews'] as num?)?.toInt() ?? 0;
        _responseRate = (response?['rate'] as num?)?.toDouble();
        _answered = (response?['answered'] as num?)?.toInt() ?? 0;
        _totalCalls = (response?['total'] as num?)?.toInt() ?? 0;
        _pending = (response?['pending'] as num?)?.toInt() ?? 0;
        _received = matches.length;
        _hired = matches.where((m) => m.status == MatchStatus.hired).length;
        _completed = contracts
            .where((c) => c.status == ContractStatus.completed)
            .length;
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

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Desempenho',
          style: AppTypography.h3.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const AppLoaderCentered()
            : _error != null
            ? AppEmptyState(
                icon: LucideIcons.triangle_alert,
                title: 'Não foi possível carregar seu desempenho',
                description: _error,
                actionLabel: 'Tentar de novo',
                onAction: _load,
              )
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _card(
                          colors,
                          'Avaliação média',
                          _totalReviews == 0
                              ? '—'
                              : NumberFormat('0.0', 'pt_BR').format(_rating),
                          _totalReviews == 0
                              ? 'Sem avaliações ainda'
                              : '$_totalReviews ${_totalReviews == 1 ? 'avaliação' : 'avaliações'}',
                          LucideIcons.star,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _card(
                          colors,
                          'Taxa de resposta',
                          _responseRate == null
                              ? '—'
                              : '${(_responseRate! * 100).round()}%',
                          _totalCalls == 0
                              ? 'Últimos 3 meses'
                              : '$_answered de $_totalCalls no prazo',
                          LucideIcons.timer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _card(
                          colors,
                          'Chamados recebidos',
                          '$_received',
                          _pending > 0
                              ? '$_pending aguardando resposta'
                              : 'Nenhum pendente',
                          LucideIcons.inbox,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _card(
                          colors,
                          'Serviços concluídos',
                          '$_completed',
                          '$_hired ${_hired == 1 ? 'contratação' : 'contratações'}',
                          LucideIcons.circle_check,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Como a Jobble escolhe quem recebe o chamado',
                          style: AppTypography.h3.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Cada pedido vai para cinco profissionais: três com '
                          'histórico e boa taxa de resposta, e dois começando '
                          'agora. Responder rápido é o que mantém você entre os '
                          'primeiros.',
                          style: AppTypography.caption.copyWith(
                            color: colors.textSecondary,
                            height: 1.5,
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

  Widget _card(
    AppColorsTheme colors,
    String title,
    String value,
    String caption,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: colors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTypography.h1.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 32,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            caption,
            style: AppTypography.caption.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
