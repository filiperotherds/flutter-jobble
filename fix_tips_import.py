with open('lib/features/home/presentation/pages/provider_tips_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("package:jobble_client", "package:flutter_tcc")

with open('lib/features/home/presentation/pages/provider_tips_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)
