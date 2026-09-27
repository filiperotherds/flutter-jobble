with open('lib/features/home/presentation/pages/provider_tips_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

import re

old_image = """                  SizedBox(
                    height: 160,
                    child: Image.asset(
                      'assets/images/joberto_tips_header.png',
                      fit: BoxFit.contain,
                    ),
                  ),"""

new_image = """                  Transform.scale(
                    scale: 1.45,
                    child: SizedBox(
                      height: 190,
                      child: Image.asset(
                        'assets/images/joberto_tips_header.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),"""

content = content.replace(old_image, new_image)

with open('lib/features/home/presentation/pages/provider_tips_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)
