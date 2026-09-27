with open('lib/features/home/presentation/pages/provider_shell_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# _buildPendingSection dot color
content = content.replace(
    "dotColor: const Color(0xFFEA580C),",
    "dotColor: const Color(0xFF475569),"
)

# _buildPendingRequestCard borders and shadow
content = content.replace(
    "border: Border.all(color: const Color(0xFFF97316).withValues(alpha: 0.6), width: 1.5),",
    "border: Border.all(color: Colors.grey[300]!, width: 1.0),"
)
content = content.replace(
    "color: const Color(0xFFEA580C).withValues(alpha: 0.07),",
    "color: Colors.black.withValues(alpha: 0.03),"
)

# Novo Pedido badge
content = content.replace(
    "color: const Color(0xFFFFF7ED),",
    "color: Colors.grey[100],"
)
content = content.replace(
    "border: Border.all(color: const Color(0xFFFED7AA)),",
    "border: Border.all(color: Colors.grey[200]!),"
)
content = content.replace(
    "color: Color(0xFFC2410C)",
    "color: Color(0xFF475569)"
)

# Buttons
# Analisar button
content = content.replace(
    "backgroundColor: const Color(0xFFEA580C),",
    "backgroundColor: const Color(0xFF1C574A), elevation: 0,"
)

# Recusar button
content = content.replace(
    "foregroundColor: Colors.red[600],",
    "foregroundColor: Colors.grey[700],"
)
content = content.replace(
    "side: BorderSide(color: Colors.red[200]!),",
    "side: BorderSide(color: Colors.grey[300]!),"
)

with open('lib/features/home/presentation/pages/provider_shell_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)
