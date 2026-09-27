with open('lib/features/home/presentation/pages/provider_shell_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace(
    "icon: const Icon(LucideIcons.message_circle, size: 16, color: const Color(0xFF1C574A))",
    "icon: const Icon(LucideIcons.message_circle, size: 16, color: Color(0xFF475569))"
)
content = content.replace(
    "side: const BorderSide(color: const Color(0xFF1C574A))",
    "side: const BorderSide(color: Color(0xFFCBD5E1))"
)
content = content.replace(
    "label: const Text('Mensagem', style: TextStyle(color: const Color(0xFF1C574A)))",
    "label: const Text('Mensagem', style: TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.w600))"
)

# And let's make the "3 atualizacoes" text more professional
content = content.replace(
    "color: const Color(0xFF1C574A),",
    "color: Colors.grey[800],"
)
# Wait, this might replace too many things, let me be specific
content = content.replace(
    """                    style: AppTypography.caption.copyWith(
                      color: const Color(0xFF1C574A),
                      fontWeight: FontWeight.bold,
                    ),""",
    """                    style: AppTypography.caption.copyWith(
                      color: Colors.grey[800],
                      fontWeight: FontWeight.bold,
                    ),"""
)
content = content.replace(
    "const Icon(LucideIcons.camera, size: 16, color: const Color(0xFF1C574A))",
    "const Icon(LucideIcons.camera, size: 16, color: Colors.grey)"
)
content = content.replace(
    "Icon(LucideIcons.chevron_right, size: 16, color: const Color(0xFF1C574A))",
    "Icon(LucideIcons.chevron_right, size: 16, color: Colors.grey)"
)


with open('lib/features/home/presentation/pages/provider_shell_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)
