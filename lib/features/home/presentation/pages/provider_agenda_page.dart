import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_tcc/core/theme/app_colors.dart';
import 'package:flutter_tcc/core/theme/app_spacing.dart';
import 'package:flutter_tcc/core/theme/app_typography.dart';
import 'package:flutter_tcc/features/home/presentation/widgets/add_event_bottom_sheet.dart';

class ProviderAgendaPage extends StatefulWidget {
  const ProviderAgendaPage({super.key});

  @override
  State<ProviderAgendaPage> createState() => _ProviderAgendaPageState();
}

class _ProviderAgendaPageState extends State<ProviderAgendaPage> {
  // Simulando que estamos em Setembro de 2026
  final int _currentMonth = 9;
  final int _currentYear = 2026;
  int _selectedDay = 18; // Hoje

  // Mocks de dados
  final Map<int, List<Map<String, dynamic>>> _appointments = {
    18: [
      {
        'time': '10:00 - 12:00',
        'title': 'Instalação de Tomadas',
        'client': 'Carlos Silva',
        'address': 'Centro',
        'status': 'Confirmado',
      },
      {
        'time': '14:00 - 16:30',
        'title': 'Reparo de Infiltração',
        'client': 'Mariana',
        'address': 'Jardim Botânico',
        'status': 'Em andamento',
      },
    ],
    19: [
      {
        'time': '09:00 - 18:00',
        'title': 'Pintura Residencial Completa',
        'client': 'Fernanda',
        'address': 'Zona Sul',
        'status': 'Confirmado',
      },
    ],
  };

  final Map<int, String> _holidays = {7: 'Independência do Brasil'};

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.surfaceLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Minha Agenda',
          style: AppTypography.h3.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              top: AppSpacing.md,
              bottom: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Cabeçalho do Calendário (Mês)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(
                        LucideIcons.chevron_left,
                        color: Colors.black54,
                      ),
                      Text(
                        'Setembro 2026',
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const Icon(
                        LucideIcons.chevron_right,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ),

                // Dias da semana
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      _WeekDayLabel('D'),
                      _WeekDayLabel('S'),
                      _WeekDayLabel('T'),
                      _WeekDayLabel('Q'),
                      _WeekDayLabel('Q'),
                      _WeekDayLabel('S'),
                      _WeekDayLabel('S'),
                    ],
                  ),
                ),

                // Grid do Calendário
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 35, // 5 semanas
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 1,
                        ),
                    itemBuilder: (context, index) {
                      // Setembro 2026 começou numa terça-feira (index 2 = terça, domingo é 0)
                      int dayOffset = 2;
                      int day = index - dayOffset + 1;

                      if (day < 1 || day > 30) {
                        return const SizedBox(); // Célula vazia
                      }

                      bool isSelected = day == _selectedDay;
                      bool hasAppointments = _appointments.containsKey(day);
                      bool isHoliday = _holidays.containsKey(day);

                      return GestureDetector(
                        onTap: () async {
                          setState(() => _selectedDay = day);
                          final event = await AddEventBottomSheet.show(
                            context,
                            day,
                            _currentMonth,
                            _currentYear,
                          );
                          if (!mounted || event == null) return;
                          setState(
                            () => _appointments
                                .putIfAbsent(day, () => [])
                                .add(event),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colors.primary
                                : (isHoliday
                                      ? Colors.red.withValues(alpha: 0.1)
                                      : Colors.transparent),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? colors.primary
                                  : (isHoliday
                                        ? Colors.red.withValues(alpha: 0.3)
                                        : Colors.transparent),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                day.toString(),
                                style: AppTypography.body.copyWith(
                                  color: isSelected
                                      ? Colors.white
                                      : (isHoliday
                                            ? Colors.red
                                            : Colors.black87),
                                  fontWeight: (isSelected || isHoliday)
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              if (hasAppointments)
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white
                                        : colors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Legenda do Calendário
                Container(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    bottom: AppSpacing.md,
                    top: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      _buildLegendItem(Colors.red, 'Feriado'),
                      const SizedBox(width: AppSpacing.md),
                      _buildLegendItem(colors.primary, 'Com serviços'),
                      const SizedBox(width: AppSpacing.md),
                      _buildLegendItem(
                        Colors.black87,
                        'Disponível',
                        isBorderOnly: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Lista de Compromissos do Dia Selecionado
          Expanded(
            child: Container(
              color: colors.surfaceLight,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  // Alerta de Feriado
                  if (_holidays.containsKey(_selectedDay))
                    Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.calendar,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Feriado Nacional: ${_holidays[_selectedDay]}',
                            style: AppTypography.body.copyWith(
                              color: Colors.red[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Cabeçalho dos Compromissos
                  Text(
                    'Compromissos - Dia $_selectedDay/09',
                    style: AppTypography.h3.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Lista
                  if (_appointments.containsKey(_selectedDay))
                    ..._appointments[_selectedDay]!.map(
                      (apt) => _buildAppointmentCard(apt, colors),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xl,
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              LucideIcons.calendar_off,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Nenhum serviço agendado',
                              style: AppTypography.body.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(
    Map<String, dynamic> apt,
    AppColorsTheme colors,
  ) {
    bool isOngoing = apt['status'] == 'Em andamento';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOngoing
              ? Colors.blue.withValues(alpha: 0.5)
              : colors.borderLight,
          width: isOngoing ? 1.5 : 1,
        ),
        boxShadow: [
          if (isOngoing)
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Horário
          SizedBox(
            width: 50,
            child: Text(
              apt['time'].toString().split(' ')[0], // Só a hora inicial
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
          ),
          // Linha divisória
          Container(
            width: 2,
            height: 60,
            color: isOngoing ? Colors.blue : colors.borderLight,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          ),
          // Detalhes
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        apt['title'],
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isOngoing)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Em andamento',
                          style: AppTypography.caption.copyWith(
                            color: Colors.blue,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Cliente: ${apt['client']}',
                  style: AppTypography.caption.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  'Endereço: ${apt['address']}',
                  style: AppTypography.caption.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
    Color color,
    String label, {
    bool isBorderOnly = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isBorderOnly ? Colors.transparent : color,
            shape: BoxShape.circle,
            border: isBorderOnly ? Border.all(color: color) : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: Colors.grey[700],
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _WeekDayLabel extends StatelessWidget {
  final String label;
  const _WeekDayLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.caption.copyWith(
        color: Colors.grey[600],
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
