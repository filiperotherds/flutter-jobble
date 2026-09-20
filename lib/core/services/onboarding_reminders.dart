import 'dart:io';
import 'dart:math';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:flutter_tcc/core/network/dio_client.dart';

/// Lembrete de "complete seu cadastro".
///
/// Quem decide se a conta precisa de empurrão é o servidor: `GET
/// /push/onboarding` devolve o que falta e o texto do aviso. O app registra o
/// aparelho em `POST /push/devices` — é por ele que o push remoto chega quando
/// há provedor configurado — e, enquanto não há, agenda o mesmo aviso
/// localmente, para o lembrete existir de verdade no aparelho.
class OnboardingReminders {
  OnboardingReminders({required this.dioClient});

  final DioClient dioClient;

  static const _storage = FlutterSecureStorage();
  static const _deviceKey = 'push_device_id';
  static const _reminderId = 4201;
  static const _channelId = 'cadastro';

  /// Distância entre abrir o app e o aviso aparecer. Curto o bastante para a
  /// pessoa ainda lembrar do que se trata, longo o bastante para não atropelar
  /// quem está preenchendo agora. `REMINDER_DELAY_MINUTES` encurta o prazo
  /// para demonstrar o aviso sem esperar duas horas.
  static const reminderDelay = Duration(
    minutes: int.fromEnvironment('REMINDER_DELAY_MINUTES', defaultValue: 120),
  );

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  String? _deviceId;

  Future<void> init() async {
    if (_ready) return;
    tz_data.initializeTimeZones();
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          // A permissão é pedida no onboarding, junto da explicação, e não na
          // primeira abertura, quando ninguém sabe do que se trata.
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _ready = true;
  }

  /// Pede a permissão do sistema. Devolve `false` se a pessoa recusou — o
  /// aviso dentro do app continua valendo.
  Future<bool> requestPermission() async {
    await init();
    if (Platform.isIOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      return await ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.requestNotificationsPermission() ?? false;
  }

  /// Identificador estável deste aparelho, criado uma vez e guardado.
  Future<String> deviceId() async {
    if (_deviceId != null) return _deviceId!;
    var id = await _storage.read(key: _deviceKey);
    if (id == null || id.isEmpty) {
      final random = Random.secure();
      id = List.generate(
        32,
        (_) => random.nextInt(16).toRadixString(16),
      ).join();
      await _storage.write(key: _deviceKey, value: id);
    }
    _deviceId = id;
    return id;
  }

  /// Registra o aparelho e agenda (ou cancela) o lembrete conforme o que o
  /// servidor responder. Chamada a cada entrada e a cada volta para o app.
  Future<OnboardingStatus?> sync() async {
    await init();
    final id = await deviceId();

    try {
      await dioClient.dio.post(
        '/push/devices',
        data: {
          'token': id,
          'platform': Platform.isIOS
              ? 'IOS'
              : Platform.isAndroid
              ? 'ANDROID'
              : 'WEB',
        },
      );
    } catch (_) {
      // Registrar é melhor-esforço: sem isso o push remoto não chega, mas o
      // lembrete local abaixo continua de pé.
    }

    final status = await _fetchStatus();
    if (status == null) return null;

    if (status.pending) {
      await _schedule(status.title, status.body);
    } else {
      await cancel();
    }
    return status;
  }

  Future<OnboardingStatus?> _fetchStatus() async {
    try {
      final response = await dioClient.dio.get('/push/onboarding');
      final data = (response.data as Map?)?.cast<String, dynamic>();
      if (data == null) return null;
      final reminder = (data['reminder'] as Map?)?.cast<String, dynamic>();
      return OnboardingStatus(
        pending: data['pending'] as bool? ?? false,
        missing: (data['missing'] as List?)?.cast<String>() ?? const [],
        title: reminder?['title'] as String? ?? 'Complete seu cadastro',
        body:
            reminder?['body'] as String? ??
            'Faltam alguns dados para sua conta ficar pronta.',
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _schedule(String title, String body) async {
    await _plugin.cancel(_reminderId);
    await _plugin.zonedSchedule(
      _reminderId,
      title,
      body,
      tz.TZDateTime.now(tz.local).add(reminderDelay),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Cadastro',
          channelDescription: 'Lembretes para completar o cadastro',
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'onboarding',
    );
  }

  /// Cadastro completo (ou sessão encerrada): nada mais a lembrar.
  Future<void> cancel() async {
    await init();
    await _plugin.cancel(_reminderId);
  }

  /// Tira o aparelho da base do servidor ao sair da conta.
  Future<void> unregister() async {
    final id = _deviceId ?? await _storage.read(key: _deviceKey);
    if (id == null) return;
    try {
      await dioClient.dio.delete('/push/devices/$id');
    } catch (_) {
      // Sair da conta não pode falhar por causa disso.
    }
  }
}

class OnboardingStatus {
  const OnboardingStatus({
    required this.pending,
    required this.missing,
    required this.title,
    required this.body,
  });

  final bool pending;
  final List<String> missing;
  final String title;
  final String body;
}
