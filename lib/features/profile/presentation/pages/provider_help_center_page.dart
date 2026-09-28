import 'package:flutter/material.dart';

class ProviderHelpCenterPage extends StatelessWidget {
  const ProviderHelpCenterPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Central de ajuda')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        ExpansionTile(
          title: Text('Como acompanhar meu pedido?'),
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Abra Conversas e pedidos. A conversa mostra as mensagens e propostas registradas. Após aceitar uma proposta, abra o contrato para acompanhar as assinaturas e a execução.',
              ),
            ),
          ],
        ),
        ExpansionTile(
          title: Text('Como combinar o pagamento?'),
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Forma, valor e condições de pagamento ficam no contrato. A Jobble não informa saldo ou transferência sem uma operação financeira confirmada.',
              ),
            ),
          ],
        ),
        ExpansionTile(
          title: Text('Como concluir ou cancelar um serviço?'),
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Abra o contrato. As ações disponíveis dependem da etapa: o prestador informa a conclusão e o cliente confirma ou contesta. Cancelamento e rescisão exigem um motivo e ficam no histórico.',
              ),
            ),
          ],
        ),
        ExpansionTile(
          title: Text('Meus dados não carregam'),
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Confira sua conexão e tente atualizar a tela. Erros de envio não confirmam a operação; recarregue para conferir o estado registrado.',
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
