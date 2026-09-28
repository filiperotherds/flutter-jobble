import 'package:flutter_tcc/core/widgets/app_buttons.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_tcc/core/network/api_exception.dart';
import 'package:flutter_tcc/core/theme/app_colors.dart';
import 'package:flutter_tcc/core/theme/app_spacing.dart';
import 'package:flutter_tcc/core/theme/app_typography.dart';
import 'package:flutter_tcc/core/widgets/app_empty_state.dart';
import 'package:flutter_tcc/core/widgets/app_loader.dart';
import 'package:flutter_tcc/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_tcc/features/auth/presentation/bloc/auth_event.dart';
import 'package:flutter_tcc/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_tcc/features/legal/data/datasources/legal_remote_data_source.dart';
import 'package:flutter_tcc/features/legal/data/models/legal_models.dart';
import 'package:flutter_tcc/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:flutter_tcc/features/service_flow/flow_api.dart';
import 'package:flutter_tcc/injection_container.dart';
import 'package:flutter_tcc/core/widgets/app_back_button.dart';

const _dayNames = [
  'Domingo',
  'Segunda-feira',
  'Terça-feira',
  'Quarta-feira',
  'Quinta-feira',
  'Sexta-feira',
  'Sábado',
];

/// Um dia do horário de atendimento, na forma que a tela edita.
///
/// O servidor aceita várias janelas por dia; aqui a pessoa edita uma só, então
/// janelas extras vindas do servidor são preservadas apenas se o dia não for
/// tocado — o que é feito guardando o original até o salvamento.
class _Day {
  _Day({required this.open, required this.start, required this.end});

  bool open;
  TimeOfDay start;
  TimeOfDay end;

  static _Day fromJson(Json? json) {
    final windows = objects(json?['windows']);
    if (json == null || windows.isEmpty) {
      if (json?['allDay'] == true) {
        return _Day(
          open: true,
          start: const TimeOfDay(hour: 0, minute: 0),
          end: const TimeOfDay(hour: 23, minute: 59),
        );
      }
      return _Day(
        open: false,
        start: const TimeOfDay(hour: 8, minute: 0),
        end: const TimeOfDay(hour: 18, minute: 0),
      );
    }
    return _Day(
      open: true,
      start:
          _parseClock(windows.first['start'] as String?) ??
          const TimeOfDay(hour: 8, minute: 0),
      end:
          _parseClock(windows.first['end'] as String?) ??
          const TimeOfDay(hour: 18, minute: 0),
    );
  }

  Json toJson(int day) => {
    'day': day,
    'allDay': false,
    'windows': open
        ? [
            {'start': _clock(start), 'end': _clock(end)},
          ]
        : <Json>[],
  };
}

TimeOfDay? _parseClock(String? value) {
  final parts = (value ?? '').split(':');
  if (parts.length != 2) return null;
  final hour = int.tryParse(parts[0]), minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  return TimeOfDay(hour: hour, minute: minute);
}

String _clock(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

class ProviderEditProfilePage extends StatefulWidget {
  const ProviderEditProfilePage({super.key});

  @override
  State<ProviderEditProfilePage> createState() =>
      _ProviderEditProfilePageState();
}

class _ProviderEditProfilePageState extends State<ProviderEditProfilePage> {
  final _legal = sl<LegalRemoteDataSource>();
  final _profile = sl<ProfileRemoteDataSource>();
  final _flow = FlowApi();

  final _name = TextEditingController();
  final _street = TextEditingController();
  final _number = TextEditingController();
  final _neighborhood = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _zip = TextEditingController();
  final _document = TextEditingController();
  final _legalName = TextEditingController();

  OrganizationLegalProfile? _organization;
  List<_Day> _days = List.generate(
    7,
    (_) => _Day(
      open: false,
      start: const TimeOfDay(hour: 8, minute: 0),
      end: const TimeOfDay(hour: 18, minute: 0),
    ),
  );
  String _timeZone = 'America/Sao_Paulo';
  String? _avatarUrl;

  bool _loading = true;
  bool _saving = false;
  String? _error;

  bool get _isCompany =>
      _organization?.legalType == OrganizationLegalType.company;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _street,
      _number,
      _neighborhood,
      _city,
      _state,
      _zip,
      _document,
      _legalName,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final authState = context.read<AuthBloc>().state;
      final organization = await _legal.getOrganizationProfile();
      final settings = object(await _flow.get('provider/settings'));
      final hours = settings['hours'] as Map?;
      final byDay = {
        for (final day in objects(hours?['days'])) day['day'] as int: day,
      };
      if (!mounted) return;
      setState(() {
        _organization = organization;
        _avatarUrl = authState is AuthSuccess
            ? authState.user?.organization?.avatarUrl
            : null;
        _name.text = organization.tradeName;
        _document.text = organization.document ?? '';
        _legalName.text = organization.legalName ?? '';
        final address = organization.address;
        _street.text = address?.street ?? '';
        _number.text = address?.number ?? '';
        _neighborhood.text = address?.neighborhood ?? '';
        _city.text = address?.city ?? '';
        _state.text = address?.state ?? '';
        _zip.text = address?.zipCode ?? '';
        _days = List.generate(
          7,
          (index) => hours?['allDay'] == true
              ? _Day(
                  open: true,
                  start: const TimeOfDay(hour: 0, minute: 0),
                  end: const TimeOfDay(hour: 23, minute: 59),
                )
              : _Day.fromJson(byDay[index]),
        );
        _timeZone = settings['timeZone'] as String? ?? _timeZone;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
    );
    if (picked == null) return;
    try {
      final url = await _profile.updateOrganizationAvatar(File(picked.path));
      if (!mounted) return;
      context.read<AuthBloc>().add(OrganizationAvatarUpdated(url));
      setState(() => _avatarUrl = url);
    } catch (error) {
      if (!mounted) return;
      _warn(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _warn(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await _profile.updateOrganizationName(_name.text.trim());

      final hasAddress = [
        _street,
        _number,
        _neighborhood,
        _city,
        _state,
        _zip,
      ].every((c) => c.text.trim().isNotEmpty);
      await _legal.updateOrganizationProfile({
        'legalType': _organization?.legalType.apiValue ?? 'INDIVIDUAL',
        if (_isCompany) 'document': _document.text.trim(),
        if (_isCompany) 'legalName': _legalName.text.trim(),
        if (hasAddress)
          'address': {
            'street': _street.text.trim(),
            'number': _number.text.trim(),
            'neighborhood': _neighborhood.text.trim(),
            'city': _city.text.trim(),
            'state': _state.text.trim().toUpperCase(),
            'zipCode': _zip.text.trim(),
          },
      });

      await _flow.patch('provider/hours', {
        'hours': {
          'allDay': false,
          'days': [
            for (var index = 0; index < 7; index++) _days[index].toJson(index),
          ],
        },
        'timeZone': _timeZone,
      });

      if (!mounted) return;
      context.read<AuthBloc>().add(UserRequested());
      Navigator.of(context).pop();
      _warn('Perfil atualizado.');
    } on ApiException catch (error) {
      if (!mounted) return;
      _warn(error.message);
    } catch (error) {
      if (!mounted) return;
      _warn(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        elevation: 0,
        leadingWidth: AppBackButton.slotWidth,
        leading: const AppBackButton(),
        title: Text(
          'Editar Perfil',
          style: AppTypography.h3.copyWith(
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: _loading
          ? const AppLoaderCentered()
          : _error != null
          ? AppEmptyState(
              icon: LucideIcons.triangle_alert,
              title: 'Não foi possível carregar o perfil',
              description: _error,
              actionLabel: 'Tentar de novo',
              onAction: _load,
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: _avatar(colors)),
                    const SizedBox(height: AppSpacing.xl),

                    _label('Nome da Empresa / Profissional'),
                    _field(_name, colors),
                    const SizedBox(height: AppSpacing.lg),

                    if (_isCompany) ...[
                      _label('Razão social'),
                      _field(_legalName, colors),
                      const SizedBox(height: AppSpacing.lg),
                      _label('CNPJ'),
                      _field(_document, colors, hint: '00.000.000/0000-00'),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    _label('Endereço'),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _field(_street, colors, hint: 'Rua'),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _field(_number, colors, hint: 'Número'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: _field(_neighborhood, colors, hint: 'Bairro'),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: _field(_city, colors, hint: 'Cidade')),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(child: _field(_state, colors, hint: 'UF')),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          flex: 2,
                          child: _field(_zip, colors, hint: 'CEP'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    _label('Horário de atendimento'),
                    _hoursEditor(colors),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _loading || _error != null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: AppAccentButton(
                  label: 'Salvar Alterações',
                  onPressed: _save,
                  isLoading: _saving,
                ),
              ),
            ),
    );
  }

  Widget _avatar(AppColorsTheme colors) {
    final url = _avatarUrl;
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.surfaceLight,
            border: Border.all(color: colors.borderLight),
            image: url != null && url.isNotEmpty
                ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
                : null,
          ),
          alignment: Alignment.center,
          child: url != null && url.isNotEmpty
              ? null
              : Icon(LucideIcons.building_2, color: colors.textSecondary),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _pickAvatar,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                LucideIcons.camera,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Text(
      text,
      style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold),
    ),
  );

  Widget _field(
    TextEditingController controller,
    AppColorsTheme colors, {
    String? hint,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.body.copyWith(color: colors.textSecondary),
        filled: true,
        fillColor: context.colors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _hoursEditor(AppColorsTheme colors) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderLight),
      ),
      child: Column(
        children: [
          for (var index = 0; index < 7; index++) ...[
            InkWell(
              onTap: () => _editDay(index),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _dayNames[index],
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w500,
                        color: colors.textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          _days[index].open
                              ? '${_clock(_days[index].start)} às ${_clock(_days[index].end)}'
                              : 'Fechado',
                          style: AppTypography.body.copyWith(
                            color: _days[index].open
                                ? colors.textSecondary
                                : colors.error,
                            fontWeight: _days[index].open
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          LucideIcons.chevron_right,
                          size: 16,
                          color: colors.textSecondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (index < 6)
              Divider(
                height: 1,
                thickness: 1,
                color: colors.borderLight,
                indent: 16,
                endIndent: 16,
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _editDay(int index) async {
    final current = _days[index];
    var open = current.open;
    var start = current.start;
    var end = current.end;

    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _dayNames[index],
                    style: AppTypography.h3.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SwitchListTile(
                    title: const Text('Atende neste dia'),
                    value: open,
                    onChanged: (value) => setSheetState(() => open = value),
                  ),
                  if (open) ...[
                    const SizedBox(height: AppSpacing.md),
                    _timeRow(
                      'Abertura',
                      start,
                      (picked) => setSheetState(() => start = picked),
                    ),
                    const Divider(),
                    _timeRow(
                      'Fechamento',
                      end,
                      (picked) => setSheetState(() => end = picked),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _days[index] = _Day(open: open, start: start, end: end);
                      });
                      Navigator.pop(sheetContext);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      'Aplicar',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _timeRow(
    String label,
    TimeOfDay value,
    ValueChanged<TimeOfDay> onPicked,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        TextButton(
          onPressed: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: value,
            );
            if (picked != null) onPicked(picked);
          },
          child: Text(
            _clock(value),
            style: AppTypography.h3.copyWith(color: context.colors.accentText),
          ),
        ),
      ],
    );
  }
}
