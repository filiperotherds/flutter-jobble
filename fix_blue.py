with open('lib/features/home/presentation/pages/provider_shell_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

import re

# Replace specific shades first
content = re.sub(r'Colors\.blue\[800\]', 'const Color(0xFF1C574A)', content)
content = re.sub(r'Colors\.blue\[700\]', 'const Color(0xFF1C574A)', content)
# Replace general blue
content = re.sub(r'Colors\.blue', 'const Color(0xFF1C574A)', content)

# But wait, there might be 'const Color(0xFF1C574A).withValues' which is fine since Color has withValues()
# And 'const Color(0xFF1C574A)' is a const, so we should be careful if it's already inside a const context.
# Let's see: 'color: const Color(0xFF1C574A)' is fine.
# 'const Icon(LucideIcons.camera, size: 16, color: const Color(0xFF1C574A))' is a syntax error if nested consts.
# Better to replace `Colors.blue` with `Color(0xFF1C574A)`.

# Let's reload and do it without const
with open('lib/features/home/presentation/pages/provider_shell_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = re.sub(r'Colors\.blue\[\d+\]\!', 'Color(0xFF1C574A)', content)
content = re.sub(r'Colors\.blue\[\d+\]', 'Color(0xFF1C574A)', content)
content = re.sub(r'Colors\.blue', 'Color(0xFF1C574A)', content)

with open('lib/features/home/presentation/pages/provider_shell_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)
