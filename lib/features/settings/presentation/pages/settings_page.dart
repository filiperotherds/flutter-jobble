import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import 'package:flutter_tcc/core/theme/app_spacing.dart';
import 'package:flutter_tcc/core/theme/theme_cubit.dart';
import 'package:flutter_tcc/core/widgets/app_back_app_bar.dart';
import 'package:flutter_tcc/core/widgets/app_list_row.dart';
import 'package:flutter_tcc/features/auth/presentation/widgets/sign_out_row.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBackAppBar(title: 'Configurações'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenH),
        children: [
          AppListGroup(
            header: 'Aparência',
            children: [
              BlocBuilder<ThemeCubit, ThemeMode>(
                builder: (context, themeMode) => AppListRow(
                  icon: LucideIcons.moon,
                  title: 'Modo escuro',
                  trailing: Switch(
                    value: themeMode == ThemeMode.dark,
                    onChanged: (_) => context.read<ThemeCubit>().toggleTheme(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          const AppListGroup(children: [SignOutRow()]),
        ],
      ),
    );
  }
}
