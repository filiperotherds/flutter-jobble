import re

with open('lib/features/home/presentation/pages/provider_shell_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

pattern = r'              const SizedBox\(height: AppSpacing\.lg\),\s*Padding\(\s*padding: const EdgeInsets\.symmetric\(horizontal: AppSpacing\.md\),\s*child: Material\(.*?const SizedBox\(height: AppSpacing\.lg\),'

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
                        color: Colors.white, // Fundo branco mescla com a imagem
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFBBF7D0), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Mascote Segurando a Estrela
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(15),
                              bottomLeft: Radius.circular(15),
                            ),
                            child: SizedBox(
                              width: 120, // Largura fixa
                              height: 140, // Altura fixa
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8, bottom: 8, left: 4),
                                child: Image.asset(
                                  'assets/images/joberto_star.jpg',
                                  fit: BoxFit.contain, // Contain no fundo branco fica perfeito
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Conteúdo
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(LucideIcons.sparkles, color: Color(0xFF16A34A), size: 16),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          'Dicas do Joberto!',
                                          style: AppTypography.body.copyWith(
                                            fontWeight: FontWeight.w900,
                                            color: const Color(0xFF16A34A),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Veja o segredo para prestar um serviço 5 estrelas e ter agenda cheia!',
                                    style: AppTypography.caption.copyWith(
                                      color: const Color(0xFF475569),
                                      fontWeight: FontWeight.w600,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Text(
                                        'Ver dicas de ouro',
                                        style: AppTypography.caption.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(LucideIcons.arrow_right, size: 14, color: Color(0xFF0F172A)),
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

