import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_tcc/core/theme/app_colors.dart';
import 'package:flutter_tcc/core/theme/app_spacing.dart';
import 'package:flutter_tcc/core/theme/app_typography.dart';
import 'package:flutter_tcc/core/widgets/app_text_field.dart';
import 'package:flutter_tcc/core/widgets/app_buttons.dart';
import 'package:flutter_tcc/features/profile/presentation/pages/provider_help_center_page.dart';
import 'package:flutter_tcc/features/profile/presentation/pages/client_terms_page.dart';

class ProviderSettingsPage extends StatefulWidget {
  const ProviderSettingsPage({super.key});

  @override
  State<ProviderSettingsPage> createState() => _ProviderSettingsPageState();
}

class _ProviderSettingsPageState extends State<ProviderSettingsPage> {
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _showPhone = true;
  bool _showLocation = true;
  bool _twoFactorEnabled = true;
  bool _biometricEnabled = true;

  void _showChangePasswordModal() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalCtx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalCtx).viewInsets.bottom + AppSpacing.lg,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.md,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Alterar Senha',
                    style: AppTypography.h3.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Escolha uma senha forte com pelo menos 8 caracteres.',
                    style: AppTypography.caption.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    controller: currentPasswordController,
                    label: 'Senha atual',
                    prefixIcon: LucideIcons.lock,
                    obscureText: obscureCurrent,
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureCurrent ? LucideIcons.eye_off : LucideIcons.eye,
                        size: 20,
                      ),
                      onPressed: () =>
                          setModalState(() => obscureCurrent = !obscureCurrent),
                    ),
                    validator: (v) => (v == null || v.length < 6)
                        ? 'Senha atual deve ter ao menos 6 caracteres'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: newPasswordController,
                    label: 'Nova senha',
                    prefixIcon: LucideIcons.key,
                    obscureText: obscureNew,
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNew ? LucideIcons.eye_off : LucideIcons.eye,
                        size: 20,
                      ),
                      onPressed: () =>
                          setModalState(() => obscureNew = !obscureNew),
                    ),
                    validator: (v) {
                      if (v == null || v.length < 8) {
                        return 'A nova senha deve ter no mínimo 8 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: confirmPasswordController,
                    label: 'Confirmar nova senha',
                    prefixIcon: LucideIcons.key,
                    obscureText: obscureConfirm,
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirm ? LucideIcons.eye_off : LucideIcons.eye,
                        size: 20,
                      ),
                      onPressed: () =>
                          setModalState(() => obscureConfirm = !obscureConfirm),
                    ),
                    validator: (v) {
                      if (v != newPasswordController.text) {
                        return 'As senhas digitadas não coincidem';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppAccentButton(
                    label: 'Salvar Nova Senha',
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      Navigator.pop(modalCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Senha alterada com sucesso!'),
                          backgroundColor: Color(0xFF10B981),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Excluir Conta'),
        content: const Text(
          'Tem certeza que deseja solicitar a exclusão da sua conta de prestador? '
          'Todos os seus dados cadastrais, histórico de orçamentos e serviços serão permanentemente removidos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Solicitação de exclusão enviada para análise.',
                  ),
                  backgroundColor: Color(0xFFEF4444),
                ),
              );
            },
            child: const Text(
              'Excluir Definitivamente',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.surfaceLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrow_left, color: colors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Configurações',
          style: AppTypography.h3.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notificações
            Text(
              'NOTIFICAÇÕES',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                      'Notificações Push',
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Avisos sobre novos orçamentos e mensagens',
                      style: AppTypography.caption,
                    ),
                    trailing: CupertinoSwitch(
                      value: _pushNotifications,
                      activeTrackColor: colors.primary,
                      onChanged: (val) =>
                          setState(() => _pushNotifications = val),
                    ),
                    onTap: () => setState(
                      () => _pushNotifications = !_pushNotifications,
                    ),
                  ),
                  const Divider(height: 1, indent: 16),
                  ListTile(
                    title: Text(
                      'E-mails Promocionais',
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Dicas e novidades do Jobble',
                      style: AppTypography.caption,
                    ),
                    trailing: CupertinoSwitch(
                      value: _emailNotifications,
                      activeTrackColor: colors.primary,
                      onChanged: (val) =>
                          setState(() => _emailNotifications = val),
                    ),
                    onTap: () => setState(
                      () => _emailNotifications = !_emailNotifications,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Privacidade
            Text(
              'PRIVACIDADE E SEGURANÇA',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                      'Autenticação em duas etapas (2FA)',
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Proteção extra usando SMS ou app',
                      style: AppTypography.caption,
                    ),
                    trailing: CupertinoSwitch(
                      value: _twoFactorEnabled,
                      activeTrackColor: colors.primary,
                      onChanged: (val) =>
                          setState(() => _twoFactorEnabled = val),
                    ),
                    onTap: () =>
                        setState(() => _twoFactorEnabled = !_twoFactorEnabled),
                  ),
                  const Divider(height: 1, indent: 16),
                  ListTile(
                    title: Text(
                      'Biometria ou Touch ID',
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Acesse com impressão digital ou rosto',
                      style: AppTypography.caption,
                    ),
                    trailing: CupertinoSwitch(
                      value: _biometricEnabled,
                      activeTrackColor: colors.primary,
                      onChanged: (val) =>
                          setState(() => _biometricEnabled = val),
                    ),
                    onTap: () =>
                        setState(() => _biometricEnabled = !_biometricEnabled),
                  ),
                  const Divider(height: 1, indent: 16),
                  ListTile(
                    title: Text(
                      'Exibir meu telefone no perfil',
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Clientes poderão te ligar diretamente',
                      style: AppTypography.caption,
                    ),
                    trailing: CupertinoSwitch(
                      value: _showPhone,
                      activeTrackColor: colors.primary,
                      onChanged: (val) => setState(() => _showPhone = val),
                    ),
                    onTap: () => setState(() => _showPhone = !_showPhone),
                  ),
                  const Divider(height: 1, indent: 16),
                  ListTile(
                    title: Text(
                      'Exibir minha localização',
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Mostra seu endereço no mapa do perfil',
                      style: AppTypography.caption,
                    ),
                    trailing: CupertinoSwitch(
                      value: _showLocation,
                      activeTrackColor: colors.primary,
                      onChanged: (val) => setState(() => _showLocation = val),
                    ),
                    onTap: () => setState(() => _showLocation = !_showLocation),
                  ),
                  const Divider(height: 1, indent: 16),
                  ListTile(
                    title: Text(
                      'Alterar Senha',
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: const Icon(LucideIcons.chevron_right, size: 20),
                    onTap: _showChangePasswordModal,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Sobre
            Text(
              'SUPORTE E OUTROS',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      LucideIcons.circle_question_mark,
                      color: Colors.blue,
                    ),
                    title: Text(
                      'Central de Ajuda',
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: const Icon(LucideIcons.chevron_right, size: 20),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProviderHelpCenterPage(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(
                      LucideIcons.file_text,
                      color: Colors.grey,
                    ),
                    title: Text(
                      'Termos de Uso',
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: const Icon(LucideIcons.chevron_right, size: 20),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ClientTermsPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Excluir Conta
            Center(
              child: TextButton.icon(
                onPressed: _showDeleteAccountDialog,
                icon: const Icon(LucideIcons.trash, color: Colors.red),
                label: const Text(
                  'Excluir minha conta',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}
