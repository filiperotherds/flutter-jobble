import 'package:flutter/material.dart';
import 'package:flutter_tcc/features/service_flow/chat_sections_page.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({
    super.key,
    required this.providerName,
    required this.providerImage,
  });
  final String providerName, providerImage;
  @override
  Widget build(BuildContext context) => const ChatSectionsPage(provider: true);
}
