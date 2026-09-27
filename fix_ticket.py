with open('lib/features/home/presentation/pages/provider_shell_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

import re

# We can just run flutter format and dart fix --apply if it's easier, or just manually fix the consts.
# But instead of regex magic on colors, I will overwrite _buildInProgressCard and _buildProgressToolHint EXACTLY.
# I will use a reliable delimiter replacement.

# I'll just write a new python script that fixes 'const Icon(..., color: Color(0xFF1C574A))'
# It should be 'const Icon(..., color: const Color(0xFF1C574A))' ? No, better to just use 'const Color'.
content = content.replace("color: Color(0xFF1C574A)", "color: const Color(0xFF1C574A)")
content = content.replace("backgroundColor: Color(0xFF1C574A)", "backgroundColor: const Color(0xFF1C574A)")
content = content.replace("color: const const Color(0xFF1C574A)", "color: const Color(0xFF1C574A)")

# Make the card look like a ticket
# Change background color of tool hint to grey
content = content.replace("color: Color(0xFF1C574A).withValues(alpha: 0.06)", "color: Colors.grey[50]")
content = content.replace("border: Border.all(color: Color(0xFF1C574A).withValues(alpha: 0.2))", "border: Border.all(color: Colors.grey[200]!)")

# Change the "Em andamento" top period badge
content = content.replace("color: Color(0xFF1C574A).withValues(alpha: 0.1)", "color: Colors.grey[100]")

# Change main card border
content = content.replace("border: Border.all(color: Color(0xFF1C574A).withValues(alpha: 0.5), width: 1.5)", "border: Border.all(color: Colors.grey[300]!, width: 1.0)")
content = content.replace("color: Color(0xFF1C574A).withValues(alpha: 0.05)", "color: Colors.black.withValues(alpha: 0.03)")

with open('lib/features/home/presentation/pages/provider_shell_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)
