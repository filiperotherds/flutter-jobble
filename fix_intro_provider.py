import re

with open('lib/features/onboard/presentation/pages/intro_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Remove the logo
pattern = r"(\s*Align\(\s*alignment: Alignment\.centerLeft,\s*child: Image\.asset\(\s*AppAssets\.logoDark,\s*height: 28,\s*color: ink\.textPrimary,\s*colorBlendMode: BlendMode\.srcIn,\s*\),\s*\),\s*const SizedBox\(height: AppSpacing\.sm\),)"
content = re.sub(pattern, "", content, flags=re.DOTALL)

# Swap buttons
old_buttons = """                    AppPrimaryButton(
                      label: 'Já tenho uma conta',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppSecondaryButton(
                      label: 'Criar nova conta',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignupPage()),
                      ),
                    ),"""

new_buttons = """                    AppPrimaryButton(
                      label: 'Criar nova conta',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignupPage()),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppSecondaryButton(
                      label: 'Já tenho uma conta',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      ),
                    ),"""

content = content.replace(old_buttons.replace("á", "Ã¡"), new_buttons)

with open('lib/features/onboard/presentation/pages/intro_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)
