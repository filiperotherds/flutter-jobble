with open('lib/features/home/presentation/pages/provider_shell_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

import re

# We can find the block by searching for "Preste um serviço 5 estrelas!"
# The banner is a Padding widget that starts after "const SizedBox(height: AppSpacing.lg),"
# and ends before "const SizedBox(height: AppSpacing.lg),\n              // Trabalhos em andamento"

pattern = r"Padding\(\s*padding: const EdgeInsets\.symmetric\(horizontal: AppSpacing\.md\),\s*child: Container\(\s*width: double\.infinity,\s*padding: const EdgeInsets\.all\(AppSpacing\.md\),\s*decoration: BoxDecoration\(\s*gradient: AppColorsTheme\.brandGradient,.*?Ver dicas de ouro.*?\]\s*,\s*\)\s*,\s*\)\s*,\s*\)\s*,\s*\)\s*,\s*\)\s*,\s*\)\s*,"

# Let's try to do it by string replacement of the whole block.
# Actually, since I have the exact code in my previous steps, let's just find the start of the `Padding(`
# and the end which is `// Trabalhos em andamento`.

start_idx = content.find("              const SizedBox(height: AppSpacing.lg),\n              Padding(\n                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),")
end_idx = content.find("              const SizedBox(height: AppSpacing.lg),\n              // Trabalhos em andamento")

if start_idx != -1 and end_idx != -1:
    old_block = content[start_idx:end_idx]
    
    new_block = """              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProviderTipsPage()),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4), // Fundo verde beeem clarinho
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Mascote Joberto cortado
                          SizedBox(
                            width: 100,
                            height: 120,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(15),
                                bottomLeft: Radius.circular(15),
                              ),
                              child: Align(
                                alignment: Alignment.centerRight,
                                widthFactor: 0.22, 
                                child: Image.asset(
                                  'assets/images/mascot.jpg',
                                  fit: BoxFit.cover,
                                  height: 120,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Conteúdo
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(LucideIcons.sparkles, color: Color(0xFF16A34A), size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Dicas do Joberto!',
                                        style: AppTypography.body.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF166534),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Descubra os segredos para prestar um serviço 5 estrelas e ganhar mais destaque!',
                                    style: AppTypography.caption.copyWith(
                                      color: const Color(0xFF14532D),
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text(
                                        'Ver dicas de ouro',
                                        style: AppTypography.caption.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF16A34A),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(LucideIcons.arrow_right, size: 14, color: Color(0xFF16A34A)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
"""
    content = content.replace(old_block, new_block)
    
    with open('lib/features/home/presentation/pages/provider_shell_page.dart', 'w', encoding='utf-8') as f:
        f.write(content)
    print("Replaced successfully!")
else:
    print("Block not found!")

