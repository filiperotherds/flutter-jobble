import re

with open('lib/features/home/presentation/pages/provider_shell_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace _buildInProgressCard container decoration
old_decoration = """      return Container(
        margin: EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),"""

new_decoration = """      return Container(
        margin: EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),"""
content = content.replace(old_decoration, new_decoration)

# Replace the "period" badge and "Em andamento" text
old_header = """                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          period,
                          style: AppTypography.caption.copyWith(
                            color: Colors.blue[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text('Em andamento', style: AppTypography.caption.copyWith(color: Colors.blue, fontWeight: FontWeight.bold)),"""

new_header = """                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          period,
                          style: AppTypography.caption.copyWith(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppColorsTheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text('Em andamento', style: AppTypography.caption.copyWith(color: Colors.grey[800], fontWeight: FontWeight.w600)),
                        ],
                      ),"""
content = content.replace(old_header, new_header)

# Replace "Progresso do Servico" row
old_progress_row = """                    children: [
                      Text(
                        schedule != null ? 'Prazo do Serviço' : 'Progresso do Serviço',
                        style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[800]),
                      ),
                      Text('${(progress * 100).toInt()}%', style: AppTypography.caption.copyWith(color: Colors.blue, fontWeight: FontWeight.bold)),
                    ],"""

new_progress_row = """                    children: [
                      Text(
                        schedule != null ? 'Prazo do Serviço' : 'Progresso do Serviço',
                        style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600, color: Colors.grey[700]),
                      ),
                      Text('${(progress * 100).toInt()}%', style: AppTypography.caption.copyWith(color: Colors.grey[900], fontWeight: FontWeight.bold)),
                    ],"""
content = content.replace(old_progress_row, new_progress_row)
content = content.replace(
    """                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),""",
    """                        valueColor: const AlwaysStoppedAnimation<Color>(AppColorsTheme.primary),"""
)

# Replace _buildProgressToolHint
old_hint = """    Widget _buildProgressToolHint() {
      final count = JobProgressUpdates.count;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.camera, size: 16, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count == 0
                        ? 'Publique o andamento do serviço'
                        : count == 1
                        ? '1 atualização publicada'
                        : '$count atualizações publicadas',
                    style: AppTypography.caption.copyWith(
                      color: Colors.blue[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),"""

new_hint = """    Widget _buildProgressToolHint() {
      final count = JobProgressUpdates.count;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.camera, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count == 0
                        ? 'Publique o andamento do serviço'
                        : count == 1
                        ? '1 atualização publicada'
                        : '$count atualizações publicadas',
                    style: AppTypography.caption.copyWith(
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w600,
                    ),
                  ),"""
content = content.replace(old_hint, new_hint)

# Replace buttons in _buildInProgressCard
old_btn1 = """                          icon: const Icon(LucideIcons.message_circle, size: 16, color: Colors.blue),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.blue),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          label: const Text('Mensagem', style: TextStyle(color: Colors.blue)),"""

new_btn1 = """                          icon: Icon(LucideIcons.message_circle, size: 16, color: Colors.grey[700]),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey[300]!),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          label: Text('Mensagem', style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w600)),"""
content = content.replace(old_btn1, new_btn1)

old_btn2 = """                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Finalizar', style: TextStyle(color: Colors.white)),"""

new_btn2 = """                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColorsTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Finalizar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),"""
content = content.replace(old_btn2, new_btn2)

with open('lib/features/home/presentation/pages/provider_shell_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)
