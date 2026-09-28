import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import 'package:flutter_tcc/core/widgets/app_empty_state.dart';
import 'package:flutter_tcc/core/widgets/app_back_button.dart';

class ReviewsPage extends StatelessWidget {
  const ReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    const empty = AppEmptyState(
      icon: LucideIcons.star,
      title: 'Avaliações',
      description:
          'As avaliações dos seus clientes aparecerão aqui quando esta área estiver pronta.',
    );

    return Scaffold(
      appBar: AppBar(
        leadingWidth: AppBackButton.slotWidth,
        leading: const AppBackButton(),
        title: const Text('Avaliações'),
      ),
      body: empty,
    );
  }
}
