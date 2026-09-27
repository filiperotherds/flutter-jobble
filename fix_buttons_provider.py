import re

with open('lib/features/onboard/presentation/pages/intro_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

pattern = r"AppPrimaryButton\(.*?AppSecondaryButton\(.*?MaterialPageRoute\(builder: \(_\) => const LoginPage\(\)\),\s*\),\s*\),"

replacement = """AppPrimaryButton(
                      label: 'Criar conta',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignupPage()),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppSecondaryButton(
                      label: 'J\u00e1 tenho conta',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Center(child: GoogleSignInButton()),"""

content = re.sub(pattern, replacement, content, flags=re.DOTALL)

# Also need to import GoogleSignInButton if not imported
if 'google_sign_in_button.dart' not in content:
    content = "import 'package:flutter_tcc/features/auth/presentation/widgets/google_sign_in_button.dart';\n" + content

with open('lib/features/onboard/presentation/pages/intro_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)
