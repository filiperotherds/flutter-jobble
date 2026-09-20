# Migração do Jobble unificado para os aplicativos isolados

Referência: `jobble-client`, commit `68092c2`. Bases: cliente `95b13e1`; prestador `c32df3f`. Comparação realizada em 19/09/2026.

## Resultado da análise

O app unificado foi derivado do cliente. A maior parte dos modelos, datasources, contratos, autenticação, triagem e verificação legal permaneceu igual ao cliente anterior. As novidades concentram-se na apresentação, assets e estado local de orçamento. O prestador anterior tem arquitetura própria (`AuthBloc`, organização, oportunidades e contratos); ela foi preservada.

**Paridade com a referência não significa integração de todos os recursos com o servidor.** As telas novas usam nomes, serviços, saldos, avaliações e conversas de demonstração. O `JobbleQuoteState` é um singleton em memória: não sincroniza propostas entre processos ou aparelhos. A migração reproduz essas interfaces e interações; não cria endpoints ou persistência que não existem na referência. Os fluxos anteriores conectados ao backend continuam acessíveis.

## Funcionalidades por contexto

| Bloco da referência | Cliente (`jobble-client-old`) | Prestador (`flutter-jobble`) | Comportamento da referência |
| --- | --- | --- | --- |
| Navegação e identidade visual | Início, Busca, Pedidos, Perfil; ícones ativos e fundo branco | Painel, Agenda, Mensagens, Perfil | Componentes, tipografia e assets locais |
| Home do cliente | Categorias, banner, serviços recentes, profissionais ativos; mantém pendências reais e assistente | Não se aplica | Descoberta estática; pendências e triagem via API |
| Busca e perfil público | Filtros, cartões, avaliações, portfólio e solicitação de orçamento | Não se aplica | Catálogo de demonstração e formulário local |
| Pedidos do cliente | Aguardando, efetivado, finalizado, cancelado; chat, proposta, avaliação | Não se aplica | Lista demonstrativa; atalhos adicionais para solicitações/contratos reais |
| Proposta e PDF | Visualização, aceite e assinatura do cliente, download | Itens de serviço/material, quantidade/preço, prazo, pagamento, garantia, observações, prévia e assinatura profissional, PDF | Proposta local; geração real de PDF; sem envio ao servidor |
| Chat | Conversas, respostas rápidas, anexos simulados, proposta e aceite | Conversas, respostas rápidas, anexos simulados e visualização da proposta | Mensagens em memória; sem transporte de mensagens |
| Perfil do cliente | Edição e avatar, endereços, cartões/histórico, cashback, favoritos | Não se aplica | Formulários/dados locais; edição do perfil refletida no estado da sessão |
| Segurança e suporte | Segurança, senha, 2FA, biometria, ajuda, termos e privacidade | Configurações, senha, 2FA, biometria, ajuda, termos, exclusão | Controles visuais; não ativam biometria/2FA, não trocam senha nem excluem conta no servidor |
| Painel profissional | Não se aplica | Disponibilidade, métricas, trabalho em andamento, pedido pendente, proposta aguardando retorno, recusa e conclusão | Estado de demonstração; acesso adicional à central operacional real |
| Agenda | Não se aplica | Calendário, feriado, compromissos, formulário de novo evento | Calendário de setembro/2026; evento agora é adicionado à lista local |
| Progresso do serviço | Indicador no pedido | Linha do tempo, atualização, progresso e anexos ilustrativos | Estado local; notificações e fotos não são enviadas ao servidor |
| Perfil profissional | Apenas perfil público para contratar | Edição, portfólio, catálogo/preços/disponibilidade | Alterações locais; perfil real anterior preservado em Minha conta e verificação |
| Desempenho e finanças | Pagamentos do cliente | Desempenho, avaliações, dados bancários e repasses | Métricas/valores demonstrativos; não processam pagamentos, transferências ou vinculação bancária |
| Cadastro de prestador | Explicação de que o cadastro pertence ao app profissional | Apresentação e wizard de negócio, atendimento e contato/Pix | Wizard demonstrativo; cadastro real existente com OTP/onboarding/verificação preservado |
| Notificações | Nova listagem visual e avisos reais preservados | Nova listagem visual e inbox real preservado | Listas novas de demonstração; inbox/avisos originais via API |

## Adaptações necessárias à separação

- Removida a troca de cliente para painel profissional. O cadastro profissional completo só está no repositório do prestador; a divulgação no cliente direciona a esse aplicativo sem inventar URL de loja ou deep link.
- A prévia PDF do cliente foi extraída do editor profissional. Não contém a ação de assinar/enviar como prestador.
- Chat profissional não permite assinar pelo cliente. Removido o botão de desenvolvimento “Simular aceite do Gabriel”. Mensagens e respostas rápidas respeitam o ponto de vista profissional.
- O prestador entra na nova navegação depois do `AccountGatePage`. A central operacional anterior permanece em “Serviços e contratos da minha conta”; perfil/cadastro real em “Minha conta e verificação”. A alteração preexistente em `dashboard_page.dart` foi preservada integralmente.
- Cliente mantém login e verificação obrigatórios, sem credenciais de teste preenchidas. Contratos/cadastro/tema anteriores estão em “Contratos, cadastro e preferências”; pedidos têm atalhos para as listas reais.
- Logout usa o fluxo de sessão existente. Edição local do perfil do cliente não cria uma sessão autenticada se o usuário não estiver conectado.
- Assets, fontes, dependências `pdf`/`printing` e registros de plugins foram transferidos, preservando nomes dos pacotes e identificadores nativos.

## Correções durante a migração

- Configurações do prestador usam `Material` para que as áreas de toque e a pintura de `ListTile` funcionem corretamente.
- O PDF fecha cada traço da assinatura como um caminho SVG válido; geração dos bytes pode ser testada sem abrir impressão nativa.
- Reemitir orçamento invalida o aceite anterior do cliente; a prévia de um novo orçamento exige nova assinatura profissional.
- A proposta do cliente usa itens, total e condições do estado do orçamento; os traços da assinatura são preservados.
- Formulário de agenda devolve os campos preenchidos para a lista do dia; valida título e horário. Controllers dos formulários de evento e progresso são liberados.
- O mapa ilustrativo do perfil público usa o asset local da referência, evitando dependência de uma imagem remota para renderizar a tela.
- Avisos de análise e APIs Flutter obsoletas encontrados nas telas portadas foram corrigidos.

## Inventário de arquivos da referência

Comparação com o cliente anterior: **42 arquivos Dart novos**, **9 alterados**, **80 idênticos**. Arquivos novos foram distribuídos conforme a tabela abaixo; arquivos compartilhados aparecem nos dois apps quando necessários.

| Arquivo novo em `jobble-client/lib` | Destino |
| --- | --- |
| `core/state/jobble_quote_state.dart` | Cliente, Prestador |
| `features/contracts/presentation/pages/chat_page.dart` | Cliente, Prestador |
| `features/contracts/presentation/pages/client_quote_proposal_page.dart` | Cliente |
| `features/contracts/presentation/pages/mock_contracts_page.dart` | Cliente |
| `features/contracts/presentation/widgets/review_modal.dart` | Cliente |
| `features/home/presentation/pages/provider_agenda_page.dart` | Prestador |
| `features/home/presentation/pages/provider_messages_page.dart` | Prestador |
| `features/home/presentation/pages/provider_shell_page.dart` | Prestador |
| `features/home/presentation/widgets/add_event_bottom_sheet.dart` | Prestador |
| `features/home/presentation/widgets/home_active_providers.dart` | Cliente |
| `features/home/presentation/widgets/home_categories_grid.dart` | Cliente |
| `features/home/presentation/widgets/home_promo_banner.dart` | Cliente |
| `features/home/presentation/widgets/home_recent_services.dart` | Cliente |
| `features/notifications/presentation/pages/notifications_page.dart` | Cliente |
| `features/notifications/presentation/pages/provider_notifications_page.dart` | Prestador |
| `features/profile/presentation/pages/client_addresses_page.dart` | Cliente |
| `features/profile/presentation/pages/client_chats_list_page.dart` | Cliente |
| `features/profile/presentation/pages/client_edit_profile_page.dart` | Cliente |
| `features/profile/presentation/pages/client_favorites_page.dart` | Cliente |
| `features/profile/presentation/pages/client_help_center_page.dart` | Cliente |
| `features/profile/presentation/pages/client_payments_page.dart` | Cliente |
| `features/profile/presentation/pages/client_security_page.dart` | Cliente |
| `features/profile/presentation/pages/client_terms_page.dart` | Cliente, Prestador |
| `features/profile/presentation/pages/provider_banking_page.dart` | Prestador |
| `features/profile/presentation/pages/provider_edit_profile_page.dart` | Prestador |
| `features/profile/presentation/pages/provider_help_center_page.dart` | Prestador |
| `features/profile/presentation/pages/provider_performance_page.dart` | Prestador |
| `features/profile/presentation/pages/provider_portfolio_page.dart` | Prestador |
| `features/profile/presentation/pages/provider_profile_page.dart` | Cliente |
| `features/profile/presentation/pages/provider_profile_tab.dart` | Prestador |
| `features/profile/presentation/pages/provider_registration_page.dart` | Cliente, Prestador |
| `features/profile/presentation/pages/provider_services_catalog_page.dart` | Prestador |
| `features/profile/presentation/pages/provider_settings_page.dart` | Prestador |
| `features/profile/presentation/pages/provider_signup_wizard_page.dart` | Prestador |
| `features/profile/presentation/pages/provider_transfers_page.dart` | Prestador |
| `features/profile/presentation/widgets/request_quote_bottom_sheet.dart` | Cliente |
| `features/requests/presentation/pages/provider_job_tracker_page.dart` | Prestador |
| `features/requests/presentation/pages/provider_quote_generator_page.dart` | Prestador |
| `features/requests/presentation/pages/provider_request_detail_page.dart` | Prestador |
| `features/requests/presentation/services/quote_pdf_service.dart` | Cliente, Prestador |
| `features/requests/presentation/widgets/add_job_step_bottom_sheet.dart` | Prestador |
| `features/search/presentation/pages/search_page.dart` | Cliente |

Arquivos alterados na referência: `core/theme/app_colors.dart`, `core/widgets/app_tab_bar.dart`, `core/widgets/client_bottom_nav_bar.dart`, `features/auth/presentation/bloc/auth_cubit.dart`, `features/auth/presentation/pages/login_page.dart`, `features/home/presentation/pages/home_page.dart`, `features/home/presentation/pages/main_shell_page.dart`, `features/profile/presentation/profile_page.dart`, `main.dart`.


## Verificação e limites

As suítes existentes e os testes transferidos cobrem autenticação, contratos, pedidos, triagem, inbox, perfil e chat. Foram acrescentados testes de renderização das telas em 390×844 com as fontes reais, navegação/isolamento dos papéis, edição de orçamento, agenda, atualização de progresso e geração efetiva de PDFs com e sem assinaturas.

Resultado da validação local: análise estática sem avisos ou erros nos dois apps; **80 testes do cliente e 90 do prestador aprovados**. Builds web concluídos. A navegação operacional anterior permanece disponível sem perder as novas abas.

Validação reproduzível em cada repositório:

```sh
flutter pub get
flutter analyze
flutter test
flutter build web
```

Não foi realizado teste contra contas reais, gateway financeiro, envio de mensagens/notificações ou sincronização cliente–prestador. A compilação iOS em debug foi validada posteriormente com Xcode 27 e runtime iOS 26.5: cliente no iPhone 17 Pro e prestador no iPhone 17, ambos iniciados na tela de entrada. O ambiente continua sem Android SDK. A abertura do diálogo nativo de impressão e a seleção de fotos precisam de verificação em dispositivo.
