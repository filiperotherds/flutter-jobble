import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tcc/core/theme/app_theme.dart';
import 'package:flutter_tcc/core/theme/app_colors.dart';
import 'package:flutter_tcc/core/widgets/app_buttons.dart';
import 'package:flutter_tcc/core/widgets/app_card.dart';
void main(){
 for(final dark in [false,true]) {
   testWidgets('dark pill actions and neutral card; dark=$dark',(tester)async{
  final theme=dark?AppTheme.dark:AppTheme.light;
  await tester.pumpWidget(MaterialApp(theme:theme,home:Scaffold(body:Padding(padding:const EdgeInsets.all(16),child:AppCard(child:Column(mainAxisSize:MainAxisSize.min,children:[AppPrimaryButton(label:'Analisar',onPressed:(){}),const SizedBox(height:12),AppAccentButton(label:'Finalizar',onPressed:(){}),const SizedBox(height:12),AppSecondaryButton(label:'Mensagem',onPressed:(){})]))))));await tester.pumpAndSettle();
  for(final style in [theme.elevatedButtonTheme.style!,theme.filledButtonTheme.style!]){
   expect(style.backgroundColor!.resolve({}),const Color(0xFF0D2F28));expect(style.foregroundColor!.resolve({}),Colors.white);
   final shape=style.shape!.resolve({})!;expect(shape.getOuterPath(const Rect.fromLTWH(0,0,200,48)).contains(const Offset(0,0)),isFalse);
  }
  final colors=theme.extension<AppColorsTheme>()!;
  final box=tester.widget<DecoratedBox>(find.descendant(of:find.byType(AppCard),matching:find.byType(DecoratedBox)).first).decoration as BoxDecoration;
  expect((box.border as Border).top.color,colors.borderLight);
  for(final shadow in box.boxShadow??<BoxShadow>[]){expect(shadow.color.r,shadow.color.g);expect(shadow.color.g,shadow.color.b);}
  expect(tester.takeException(),isNull);
 });
 }
}
