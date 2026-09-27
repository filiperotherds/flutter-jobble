import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';

import 'package:flutter_tcc/core/theme/app_spacing.dart';
import 'package:flutter_tcc/core/theme/app_typography.dart';
import 'package:flutter_tcc/features/quotes/data/quote_models.dart';

const _green = Color(0xFF10B981);
const _greenDark = Color(0xFF059669);

/// A proposta formal, dentro da conversa.
///
/// O card mostra as duas assinaturas na ordem em que acontecem: o cliente
/// assina o que recebeu e só então o profissional confirma de volta. Enquanto
/// a vez não é de quem está olhando, o botão dá lugar a uma linha dizendo de
/// quem o fluxo está esperando — melhor do que um botão que o servidor recusa.
class ProposalCard extends StatelessWidget {
  const ProposalCard({
    super.key,
    required this.proposal,
    required this.viewerIsClient,
    required this.onSign,
    this.onDecline,
    this.onOpen,
    this.busy = false,
  });

  final Proposal proposal;

  /// De que lado está quem abriu a tela. Decide qual assinatura é "a sua".
  final bool viewerIsClient;

  final VoidCallback onSign;
  final VoidCallback? onDecline;
  final VoidCallback? onOpen;
  final bool busy;

  bool get _myTurn =>
      viewerIsClient ? proposal.awaitsClient : proposal.awaitsProvider;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        width: MediaQuery.of(context).size.width * 0.88,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _green.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _green.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            _header(),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  Text(
                    proposal.title,
                    textAlign: TextAlign.center,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    money.format(proposal.amount),
                    style: AppTypography.h1.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF111827),
                      fontSize: 26,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _MiniBadge(
                        text: 'Prazo: ${proposal.deadlineDays} dias úteis',
                        icon: Icons.schedule,
                      ),
                      _MiniBadge(
                        text: 'Garantia: ${proposal.warrantyDays} dias',
                        icon: Icons.verified_user_outlined,
                      ),
                    ],
                  ),
                  if (proposal.notes != null &&
                      proposal.notes!.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      proposal.notes!,
                      textAlign: TextAlign.center,
                      style: AppTypography.caption.copyWith(
                        color: Colors.grey[700],
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _signatures(),
                  const SizedBox(height: 14),
                  _actions(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    final label = switch (proposal.status) {
      'SIGNED' => 'CONTRATO ATIVO',
      'DECLINED' => 'RECUSADA',
      'SUPERSEDED' => 'SUBSTITUÍDA',
      _ => 'OFICIAL',
    };
    final active = proposal.isSigned;
    final stale = proposal.isDeclined || proposal.isSuperseded;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: _green.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.file_text, size: 16, color: _greenDark),
              SizedBox(width: 6),
              Text(
                'Proposta Formal de Orçamento',
                style: TextStyle(
                  fontSize: 12,
                  color: _greenDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: stale
                  ? Colors.grey[200]
                  : active
                  ? Colors.green[100]
                  : Colors.blue[50],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: stale
                    ? Colors.grey[700]
                    : active
                    ? Colors.green[900]
                    : Colors.blue[900],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// As duas assinaturas, na ordem: primeiro o cliente, depois o profissional.
  Widget _signatures() {
    return Column(
      children: [
        _SignatureRow(
          name: proposal.client.display,
          role: 'Cliente',
          signedAt: proposal.clientSignedAt,
          pendingLabel: 'Aguardando a assinatura do cliente',
        ),
        const SizedBox(height: 6),
        _SignatureRow(
          name: proposal.provider.display,
          role: 'Profissional',
          signedAt: proposal.providerSignedAt,
          pendingLabel: proposal.awaitsProvider
              ? 'Aguardando a confirmação do profissional'
              : 'Confirma depois que o cliente assinar',
        ),
      ],
    );
  }

  Widget _actions(BuildContext context) {
    if (proposal.isSigned) {
      return _Done(
        icon: Icons.check_circle,
        label: 'Assinada pelos dois • contrato aberto',
      );
    }

    if (proposal.isDeclined) {
      return const _Done(icon: Icons.cancel, label: 'Proposta recusada');
    }

    if (proposal.isSuperseded) {
      return const _Done(
        icon: Icons.history,
        label: 'Substituída por um orçamento mais novo',
      );
    }

    return Row(
      children: [
        if (onOpen != null) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onOpen,
              icon: const Icon(LucideIcons.file_text, size: 15),
              label: const Text(
                'Ver Proposta',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                side: BorderSide(color: Colors.grey[300]!),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        Expanded(child: _signSlot()),
      ],
    );
  }

  Widget _signSlot() {
    if (!_myTurn) {
      // A vez é do outro lado: dizer de quem se espera evita o botão que o
      // servidor recusaria.
      return Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.amber[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.amber[200]!),
        ),
        child: Center(
          child: Text(
            viewerIsClient
                ? 'Aguardando o profissional'
                : 'Aguardando o cliente',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.amber[900],
            ),
          ),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: busy ? null : onSign,
      icon: busy
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(LucideIcons.pen_tool, size: 15, color: Colors.white),
      label: Text(
        viewerIsClient ? 'Assinar & Iniciar' : 'Confirmar & Abrir contrato',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: _green,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 0,
      ),
    );
  }
}

class _SignatureRow extends StatelessWidget {
  const _SignatureRow({
    required this.name,
    required this.role,
    required this.signedAt,
    required this.pendingLabel,
  });

  final String name;
  final String role;
  final DateTime? signedAt;
  final String pendingLabel;

  @override
  Widget build(BuildContext context) {
    final signed = signedAt != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: signed ? const Color(0xFFF0FDF4) : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: signed ? const Color(0xFF86EFAC) : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            signed ? Icons.verified : Icons.schedule,
            color: signed ? Colors.green : Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  signed ? '$name assinou digitalmente' : pendingLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: signed
                        ? const Color(0xFF166534)
                        : Colors.grey[700],
                  ),
                ),
                Text(
                  signed
                      ? 'Em ${DateFormat("dd/MM/yyyy 'às' HH:mm").format(signedAt!)}'
                      : role,
                  style: TextStyle(fontSize: 9.5, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Done extends StatelessWidget {
  const _Done({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green[300]!),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.green, size: 16),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10.5,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
