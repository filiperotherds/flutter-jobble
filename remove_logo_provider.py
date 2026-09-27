import re

with open('lib/features/onboard/presentation/pages/intro_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

pattern = r"(\s*Align\(\s*alignment: Alignment\.centerLeft,\s*child: Image\.asset\(\s*AppAssets\.logoDark,\s*height: 28,\s*color: ink\.textPrimary,\s*colorBlendMode: BlendMode\.srcIn,\s*\),\s*\),\s*const SizedBox\(height: AppSpacing\.sm\),)"
content = re.sub(pattern, "", content, flags=re.DOTALL)

with open('lib/features/onboard/presentation/pages/intro_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)
