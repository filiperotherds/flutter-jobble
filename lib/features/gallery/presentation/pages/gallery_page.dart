import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import 'package:flutter_tcc/core/widgets/app_empty_state.dart';
import 'package:flutter_tcc/core/widgets/app_back_button.dart';

class GalleryPage extends StatelessWidget {
  const GalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    const empty = AppEmptyState(
      icon: LucideIcons.images,
      title: 'Galeria',
      description:
          'Suas fotos de trabalho aparecerão aqui quando esta área estiver pronta.',
    );

    return Scaffold(
      appBar: AppBar(
        leadingWidth: AppBackButton.slotWidth,
        leading: const AppBackButton(),
        title: const Text('Galeria'),
      ),
      body: empty,
    );
  }
}
