with open('lib/features/home/presentation/pages/provider_shell_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace(
    "child: const Icon(LucideIcons.circle_check, color: Colors.grey[800], size: 48),",
    "child: Icon(LucideIcons.circle_check, color: Colors.grey[800], size: 48),"
)

# Any other broken const Icons? Let's fix them too.
content = content.replace(
    "const Icon(LucideIcons.camera, size: 16, color: Colors.grey)",
    "Icon(LucideIcons.camera, size: 16, color: Colors.grey)"
)

with open('lib/features/home/presentation/pages/provider_shell_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)
