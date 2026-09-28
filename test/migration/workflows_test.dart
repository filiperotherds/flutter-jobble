import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tcc/core/theme/app_theme.dart';
import 'package:flutter_tcc/features/home/presentation/pages/provider_agenda_page.dart';
import '../service_flow/fake_flow_network.dart';
void main(){
 tearDown(clearFlowNetwork);
 testWidgets('agenda renders server contracts instead of fixed appointments',(tester)async{
  await setupFlowNetwork((r)=>[{'id':'contract','code':'J-1','status':'SIGNED','title':'Serviço persistido','client':{'name':'Cliente da API'},'organization':{'name':'Oficina'},'startDate':'2026-12-08T12:00:00Z','needsAttention':false}]);
  await tester.pumpWidget(MaterialApp(theme:AppTheme.light,home:const ProviderAgendaPage()));await tester.pumpAndSettle();
  expect(find.text('Serviço persistido'),findsOneWidget);expect(find.text('Cliente da API'),findsOneWidget);expect(find.text('08/12/2026'),findsOneWidget);expect(find.text('Salvar Compromisso'),findsNothing);
 });
 testWidgets('agenda shows empty state when backend has no contracts',(tester)async{
  await setupFlowNetwork();await tester.pumpWidget(MaterialApp(theme:AppTheme.light,home:const ProviderAgendaPage()));await tester.pumpAndSettle();expect(find.textContaining('Nenhum serviço agendado'),findsOneWidget);
 });
}
