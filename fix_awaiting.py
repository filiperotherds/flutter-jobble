with open('lib/features/home/presentation/pages/provider_shell_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Trabalhos em andamento dot
content = content.replace(
    "dotColor: const Color(0xFF2563EB),",
    "dotColor: const Color(0xFF1C574A),"
)

# Aguardando retorno dot
content = content.replace(
    "dotColor: const Color(0xFF7C3AED),",
    "dotColor: const Color(0xFF475569),"
)

# _awaitingColor
content = content.replace(
    "return const Color(0xFF6D28D9);",
    "return const Color(0xFF475569);"
)

# Card styling
content = content.replace(
    "border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.5), width: 1.5),",
    "border: Border.all(color: Colors.grey[300]!, width: 1.0),"
)
content = content.replace(
    "color: const Color(0xFF7C3AED).withValues(alpha: 0.07),",
    "color: Colors.black.withValues(alpha: 0.03),"
)

# Badge styling
content = content.replace(
    "color: const Color(0xFFF3E8FF),",
    "color: Colors.grey[100],"
)
content = content.replace(
    "border: Border.all(color: const Color(0xFFDDD6FE)),",
    "border: Border.all(color: Colors.grey[200]!),"
)
content = content.replace(
    "color: const Color(0xFF6D28D9),",
    "color: const Color(0xFF475569),"
)
content = content.replace(
    "color: Color(0xFF6D28D9),",
    "color: Color(0xFF475569),"
)

# Painel resumo styling
content = content.replace(
    "color: const Color(0xFFFAF5FF),",
    "color: Colors.grey[50],"
)
content = content.replace(
    "border: Border.all(color: const Color(0xFFEDE9FE)),",
    "border: Border.all(color: Colors.grey[200]!),"
)

# Buttons
content = content.replace(
    "backgroundColor: const Color(0xFF7C3AED),",
    "backgroundColor: const Color(0xFF475569), elevation: 0,"
)
content = content.replace(
    "side: const BorderSide(color: const Color(0xFF7C3AED)),",
    "side: BorderSide(color: Colors.grey[300]!),"
)
content = content.replace(
    "icon: const Icon(LucideIcons.download, size: 16, color: const Color(0xFF7C3AED)),",
    "icon: const Icon(LucideIcons.download, size: 16, color: Color(0xFF475569)),"
)
content = content.replace(
    "label: const Text('Baixar PDF', style: TextStyle(color: const Color(0xFF7C3AED))),",
    "label: const Text('Baixar PDF', style: TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.w600)),"
)
content = content.replace(
    "icon: const Icon(LucideIcons.message_circle, size: 18, color: const Color(0xFF7C3AED)),",
    "icon: const Icon(LucideIcons.message_circle, size: 18, color: Color(0xFF475569)),"
)
content = content.replace(
    "child: const Icon(LucideIcons.message_circle, size: 18, color: Color(0xFF6D28D9)),",
    "child: const Icon(LucideIcons.message_circle, size: 18, color: Color(0xFF475569)),"
)


with open('lib/features/home/presentation/pages/provider_shell_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)
