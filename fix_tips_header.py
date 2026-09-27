with open('lib/features/home/presentation/pages/provider_tips_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

import re

old_icon = """                  const Icon(
                    LucideIcons.award,
                    size: 64,
                    color: Colors.white,
                  ),"""

new_image = """                  SizedBox(
                    height: 160,
                    child: Image.asset(
                      'assets/images/joberto_tips_header.png',
                      fit: BoxFit.contain,
                    ),
                  ),"""

content = content.replace(old_icon, new_image)

with open('lib/features/home/presentation/pages/provider_tips_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)
