with open('lib/features/onboard/presentation/pages/intro_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("                    ),\n                      ),\n                    ),\n                  ],", "                  ],")

with open('lib/features/onboard/presentation/pages/intro_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)
