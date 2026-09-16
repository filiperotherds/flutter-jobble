import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import 'package:flutter_tcc/core/theme/app_spacing.dart';
import 'package:flutter_tcc/core/widgets/app_list_row.dart';
import 'package:flutter_tcc/features/auth/presentation/widgets/sign_out_row.dart';
import 'package:flutter_tcc/features/legal/presentation/pages/verification_center_page.dart';
import 'package:flutter_tcc/features/settings/presentation/pages/settings_page.dart';

class SettingsCenterPage extends StatelessWidget {
  const SettingsCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.md,
        AppSpacing.screenH,
        120,
      ),
      children: [
        AppListGroup(
          children: [
            AppListRow(
              icon: LucideIcons.settings_2,
              title: 'Aparência',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              ),
            ),
            AppListRow(
              title: 'Cadastro e verificação',
              subtitle: 'Dados, identidade e certidão de antecedentes',
              icon: LucideIcons.shield_check,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const VerificationCenterPage(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.section),
        const AppListGroup(children: [SignOutRow()]),
      ],
    );
  }
}
