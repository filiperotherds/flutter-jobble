with open('lib/features/home/presentation/pages/provider_shell_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

import re

# We want to remove the block starting with "if (request == null) Center(" up to the end of that Center widget.
# This might be tricky with simple regex if there are nested parentheses.
# Let's find it exactly by string matching a known chunk.
chunk = """            // Atalho interativo para simular aceite. SÃ³ na demonstraÃ§Ã£o: com
            // pedido de verdade quem assina Ã© o cliente, no app dele.
            if (request == null) Center(
              child: InkWell(
                onTap: () {
                  quoteState.signByClient();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Icon(LucideIcons.circle_check, color: Colors.white),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Gabriel assinou o contrato! ServiÃ§o iniciado e adicionado em Trabalhos em Andamento.',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 4),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.sparkles, size: 13, color: Color(0xFF7C3AED)),
                      const SizedBox(width: 4),
                      const Text(
                        'Simular aceite do Gabriel (iniciar serviÃ§o)',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),"""

content = content.replace(chunk, "")

with open('lib/features/home/presentation/pages/provider_shell_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)
