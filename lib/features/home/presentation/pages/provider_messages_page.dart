import 'package:flutter/material.dart';
import 'package:flutter_tcc/features/quotes/presentation/pages/provider_conversations_page.dart';

/// A aba Mensagens do profissional.
///
/// Lista as conversas de verdade, abertas pelos pedidos de orçamento que
/// chegaram. A tela antiga de seções continua no projeto, mas quem responde
/// cliente precisa da lista que vem do servidor.
class ProviderMessagesPage extends StatelessWidget {
  const ProviderMessagesPage({super.key});

  @override
  Widget build(BuildContext context) => const ProviderConversationsPage();
}
