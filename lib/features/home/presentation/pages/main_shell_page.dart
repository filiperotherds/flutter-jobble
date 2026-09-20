import 'package:flutter/material.dart';
import 'package:flutter_tcc/features/home/presentation/pages/provider_shell_page.dart';

/// Casca do app do profissional.
///
/// Não confere nada antes de abrir: quem criou a conta com e-mail e senha
/// entra e vê o app. O que falta para receber chamados — perfil profissional,
/// dados, documento, certidão e horários — é assunto do onboarding guiado e do
/// aviso do painel, e o servidor é quem recusa o que ainda não pode acontecer.
class MainShellPage extends StatelessWidget {
  const MainShellPage({super.key});

  @override
  Widget build(BuildContext context) => const ProviderShellPage();
}
