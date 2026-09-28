import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_tcc/core/theme/app_colors.dart';
import 'package:flutter_tcc/core/theme/app_spacing.dart';
import 'package:flutter_tcc/core/theme/app_typography.dart';
import 'package:flutter_tcc/core/widgets/app_back_button.dart';

class ClientTermsPage extends StatelessWidget {
  const ClientTermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: context.colors.background,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leadingWidth: AppBackButton.slotWidth,
          leading: const AppBackButton(),
          title: Text(
            'Termos e Políticas',
            style: AppTypography.h3.copyWith(
              fontWeight: FontWeight.w500,
              color: colors.textPrimary,
            ),
          ),
          bottom: TabBar(
            labelColor: colors.primary,
            unselectedLabelColor: colors.textSecondary,
            indicatorColor: colors.primary,
            indicatorWeight: 3,
            labelStyle: AppTypography.body.copyWith(
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: AppTypography.body.copyWith(
              fontWeight: FontWeight.normal,
            ),
            tabs: const [
              Tab(text: 'Termos Gerais'),
              Tab(text: 'Privacidade & LGPD'),
              Tab(text: 'Garantia'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildGeneralTermsTab(context),
            _buildPrivacyTab(context),
            _buildWarrantyTab(context),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralTermsTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _buildDocumentHeader(
          context,
          title: 'Termos e Condições Gerais de Uso',
          updatedAt: '15 de Janeiro de 2026',
          version: 'Versão 2.4',
        ),
        const SizedBox(height: AppSpacing.md),

        _buildSectionCard(
          context,
          number: '1',
          title: 'Objeto da Plataforma',
          content:
              'A Jobble conecta clientes que necessitam de serviços residenciais, comerciais ou corporativos a prestadores de serviços autônomos e empresas previamente cadastradas e verificadas. A plataforma atua como intermediadora tecnológica, facilitando cotações, orçamentos formais, pagamentos em custódia segura e comunicação.',
        ),
        const SizedBox(height: AppSpacing.md),

        _buildSectionCard(
          context,
          number: '2',
          title: 'Orçamentos e Assinatura Digital',
          content:
              'Todo serviço prestado exige a emissão e aprovação prévia de um Orçamento Formal. Ao assinar digitalmente o orçamento ou contrato na plataforma, o Cliente e o Prestador concordam com os valores, descrição de escopo, materiais inclusos e prazos estipulados no documento.',
        ),
        const SizedBox(height: AppSpacing.md),

        _buildSectionCard(
          context,
          number: '3',
          title: 'Custódia de Pagamentos (Jobble Pay)',
          content:
              'Os pagamentos realizados pelo Cliente (Cartão de Crédito ou Pix) são retidos com total segurança em conta de custódia Jobble. O repasse ao Prestador só é liberado após a confirmação de conclusão do serviço pelo Cliente ou transcorrido o prazo de validação técnica sem contestações.',
        ),
        const SizedBox(height: AppSpacing.md),

        _buildSectionCard(
          context,
          number: '4',
          title: 'Política de Cancelamento',
          content:
              'O cancelamento solicitado pelo Cliente com mais de 24 horas de antecedência do horário agendado confere direito ao reembolso de 100% do valor retido. Cancelamentos com prazo inferior a 24 horas podem incorrer em taxa de deslocamento em favor do prestador.',
        ),
        const SizedBox(height: AppSpacing.lg),

        _buildDownloadPdfButton(context),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _buildPrivacyTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _buildDocumentHeader(
          context,
          title: 'Política de Privacidade e LGPD',
          updatedAt: '15 de Janeiro de 2026',
          version: 'Versão 1.8 - Lei Federal nº 13.709/2018',
        ),
        const SizedBox(height: AppSpacing.md),

        _buildSectionCard(
          context,
          number: '1',
          title: 'Coleta de Dados Pessoais',
          content:
              'Coletamos apenas as informações estritamente necessárias para a prestação dos serviços: nome completo, CPF, e-mail, telefone de contato, localização aproximada para busca de profissionais e endereço de atendimento selecionado pelo cliente.',
        ),
        const SizedBox(height: AppSpacing.md),

        _buildSectionCard(
          context,
          number: '2',
          title: 'Compartilhamento com Prestadores',
          content:
              'Seu endereço exato e telefone só são compartilhados com o Prestador após a aprovação formal do orçamento e confirmação de agendamento. Nenhuma informação bancária ou de cartão é acessível pelos prestadores.',
        ),
        const SizedBox(height: AppSpacing.md),

        _buildSectionCard(
          context,
          number: '3',
          title: 'Seus Direitos como Titular',
          content:
              'Em conformidade com a LGPD, você possui o direito de: (a) acessar seus dados cadastrais; (b) solicitar a correção de dados incompletos ou desatualizados; (c) revogar consentimentos e solicitar a exclusão de sua conta a qualquer momento pela aba Segurança do aplicativo.',
        ),
        const SizedBox(height: AppSpacing.lg),

        _buildDownloadPdfButton(context),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _buildWarrantyTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _buildDocumentHeader(
          context,
          title: 'Termo de Garantia Jobble Protege',
          updatedAt: '15 de Janeiro de 2026',
          version: 'Garantia Oficial Jobble',
        ),
        const SizedBox(height: AppSpacing.md),

        _buildSectionCard(
          context,
          number: '1',
          title: 'Cobertura de Qualidade',
          content:
              'Todos os serviços contratados e transacionados integralmente dentro da plataforma Jobble contam com a proteção Jobble Protege, cobrindo defeitos de mão de obra e execução por até 90 dias após a finalização.',
        ),
        const SizedBox(height: AppSpacing.md),

        _buildSectionCard(
          context,
          number: '2',
          title: 'Como Acionar a Garantia',
          content:
              'Se identificar qualquer inconformidade com o serviço executado, basta acionar a Central de Ajuda em até 30 dias informando fotos e detalhes do problema. Nossa equipe de mediação técnica acionará o prestador para retorno sem custos.',
        ),
        const SizedBox(height: AppSpacing.md),

        _buildSectionCard(
          context,
          number: '3',
          title: 'Exclusões da Garantia',
          content:
              'A garantia não cobre: serviços negociados ou pagos "por fora" da plataforma; danos causados por mau uso ou intempéries naturais; e materiais fornecidos diretamente pelo cliente sem especificação técnica do profissional.',
        ),
        const SizedBox(height: AppSpacing.lg),

        _buildDownloadPdfButton(context),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _buildDocumentHeader(
    BuildContext context, {
    required String title,
    required String updatedAt,
    required String version,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.h3.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: context.colors.accentText.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  version,
                  style: TextStyle(
                    color: context.colors.accentText,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              Text(
                'Atualizado em $updatedAt',
                style: TextStyle(
                  color: context.colors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String number,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.colors.accentSoft,
                  borderRadius: AppRadius.pillAll,
                ),
                child: Text(
                  number,
                  style: TextStyle(
                    color: context.colors.accentText,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: AppTypography.body.copyWith(
              color: context.colors.textBody,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadPdfButton(BuildContext context) {
    return OutlinedButton.icon(
      icon: const Icon(LucideIcons.file_down, size: 18),
      label: const Text('Baixar Termos em PDF'),
      style: OutlinedButton.styleFrom(
        foregroundColor: context.colors.textPrimary,
        side: BorderSide(color: context.colors.borderLight),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: const StadiumBorder(),
      ),
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download do documento oficial em PDF iniciado...'),
            backgroundColor: context.colors.inverse,
          ),
        );
      },
    );
  }
}
