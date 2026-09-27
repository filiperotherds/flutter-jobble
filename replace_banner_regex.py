import re

with open('lib/features/home/presentation/pages/provider_shell_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

pattern = r'              const SizedBox\(height: AppSpacing\.lg\),\s*Padding\(\s*padding: const EdgeInsets\.symmetric\(horizontal: AppSpacing\.md\),\s*child: Container\(.*?const SizedBox\(height: AppSpacing\.lg\),'

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
                        color: const Color(0xFFF0FDF4),
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
              const SizedBox(height: AppSpacing.lg),"""

content = re.sub(pattern, new_block, content, flags=re.DOTALL)

with open('lib/features/home/presentation/pages/provider_shell_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)
