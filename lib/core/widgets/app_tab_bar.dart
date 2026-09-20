import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:flutter_tcc/core/theme/app_colors.dart';
import 'package:flutter_tcc/core/theme/app_spacing.dart';
import 'package:flutter_tcc/core/theme/app_typography.dart';
import 'package:flutter_tcc/core/widgets/profile_avatar.dart';

/// Um item da [AppTabBar]: ícone ou avatar, rótulo e um ponto opcional.
class AppTabItem {
  const AppTabItem({required this.icon, required this.label, this.badge = 0})
    : avatarUrl = null,
      name = null,
      isAvatar = false;

  /// Aba de perfil: mostra o avatar da conta no lugar do ícone.
  const AppTabItem.avatar({required this.label, this.avatarUrl, this.name})
    : icon = null,
      badge = 0,
      isAvatar = true;

  final IconData? icon;
  final String label;

  /// Itens não lidos. Maior que zero mostra um ponto sobre o ícone.
  final int badge;

  final String? avatarUrl;
  final String? name;
  final bool isAvatar;
}

/// Barra de abas inferior do sistema: faixa de largura total em vidro
/// (branco a 72% sobre desfoque de 18), com borda fina no topo.
class AppTabBar extends StatelessWidget {
  const AppTabBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelected,
  });

  final List<AppTabItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface.withValues(
              alpha: 0.95,
            ), // Deixando mais branco sólido igual iFood
            border: Border(
              top: BorderSide(color: colors.borderLight, width: AppSize.border),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: AppSize.tabBar + 8,
              child: Row(
                children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(
                      child: _TabButton(
                        item: items[i],
                        isActive: i == currentIndex,
                        onTap: () => onSelected(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final AppTabItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ink = isActive ? colors.textPrimary : colors.textHint;

    final Widget glyph = item.isAvatar
        ? ProfileAvatar(
            imageUrl: item.avatarUrl,
            fallbackName: item.name,
            size: 26,
            ringed: isActive,
          )
        : SizedBox(
            width: 48,
            height: 28,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Lucide é contorno puro: o estado ativo vem da cor e do
                // peso do rótulo, não de uma variante preenchida do glifo.
                Icon(item.icon, size: 24, color: ink),
                if (item.badge > 0 && !isActive)
                  Positioned(
                    right: 6,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: colors.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.surface, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
          );

    return Semantics(
      button: true,
      selected: isActive,
      label: item.badge > 0
          ? '${item.label}, ${item.badge} não lidos'
          : item.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 30, child: Center(child: glyph)),
            const SizedBox(height: 3),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: AppTypography.caption.copyWith(
                fontSize: 10,
                color: ink,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
