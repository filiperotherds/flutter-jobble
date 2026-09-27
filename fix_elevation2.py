with open('lib/features/home/presentation/pages/provider_shell_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("backgroundColor: const Color(0xFF1C574A), elevation: 0,", "backgroundColor: const Color(0xFF1C574A),")

with open('lib/features/home/presentation/pages/provider_shell_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)
