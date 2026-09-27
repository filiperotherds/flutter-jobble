with open('lib/features/onboard/presentation/pages/intro_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

import re
pattern = r"AppPrimaryButton\(\s*label: 'JÃ¡ tenho uma conta',.*?AppSecondaryButton\(\s*label: 'Criar nova conta',.*?const SignupPage\(\)\),\s*\),\s*\),"

new_buttons = """AppPrimaryButton(
                      label: 'Criar nova conta',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignupPage()),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppSecondaryButton(
                      label: 'J\u00e1 tenho uma conta',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      ),
                    ),"""

content = re.sub(pattern, new_buttons, content, flags=re.DOTALL)

with open('lib/features/onboard/presentation/pages/intro_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)
