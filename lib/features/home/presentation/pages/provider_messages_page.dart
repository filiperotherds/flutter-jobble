import 'package:flutter/material.dart';
import 'package:flutter_tcc/features/service_flow/chat_sections_page.dart';

class ProviderMessagesPage extends StatelessWidget {
  const ProviderMessagesPage({super.key});
  @override
  Widget build(BuildContext context) => const ChatSectionsPage(provider: true);
}
