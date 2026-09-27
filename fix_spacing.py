with open('lib/features/home/presentation/pages/provider_shell_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old_chunk = """                else
                  _buildPendingSection(quoteState, const []),

                // Atalhos RÃ¡pidos
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Text(
                    'Atalhos da sua conta',"""

new_chunk = """                else
                  _buildPendingSection(quoteState, const []),

                const SizedBox(height: 40),

                // Atalhos RÃ¡pidos
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Text(
                    'Atalhos da sua conta',"""

content = content.replace(old_chunk, new_chunk)

with open('lib/features/home/presentation/pages/provider_shell_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)
