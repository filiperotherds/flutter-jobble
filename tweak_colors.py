with open('lib/features/home/presentation/pages/provider_shell_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

import re

# We used AppColorsTheme.primary previously. Let's replace it with a professional dark green Color(0xFF1C574A)
content = content.replace("AppColorsTheme.primary", "const Color(0xFF1C574A)")

with open('lib/features/home/presentation/pages/provider_shell_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)
