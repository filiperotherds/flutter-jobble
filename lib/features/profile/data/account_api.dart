import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'package:flutter_tcc/core/network/api_exception.dart';
import 'package:flutter_tcc/core/network/dio_client.dart';
import 'package:flutter_tcc/injection_container.dart';

/// Um endereço salvo da pessoa.
class Address {
  const Address({
    required this.id,
    required this.label,
    required this.zipCode,
    required this.street,
    required this.number,
    required this.neighborhood,
    required this.city,
    required this.state,
    required this.isDefault,
    this.complement,
  });

  factory Address.fromJson(Map<String, dynamic> json) => Address(
    id: '${json['id']}',
    label: '${json['label']}',
    zipCode: '${json['zipCode']}',
    street: '${json['street']}',
    number: '${json['number']}',
    neighborhood: '${json['neighborhood']}',
    city: '${json['city']}',
    state: '${json['state']}',
    isDefault: json['isDefault'] == true,
    complement: json['complement'] as String?,
  );

  final String id;
  final String label;
  final String zipCode;
  final String street;
  final String number;
  final String neighborhood;
  final String city;
  final String state;
  final bool isDefault;
  final String? complement;

  /// Uma linha, como as telas mostram o endereço.
  String get summary {
    final parts = [
      '$street, $number',
      if (complement != null && complement!.isNotEmpty) complement!,
      neighborhood,
      '$city - $state',
    ];
    return parts.join(' • ');
  }
}

/// Preferências da conta: notificações, privacidade e acesso.
class AccountSettings {
  const AccountSettings({
    required this.pushNotifications,
    required this.emailNotifications,
    required this.showPhone,
    required this.showLocation,
    required this.twoFactorEnabled,
    required this.biometricEnabled,
  });

  factory AccountSettings.fromJson(Map<String, dynamic> json) =>
      AccountSettings(
        pushNotifications: json['pushNotifications'] == true,
        emailNotifications: json['emailNotifications'] == true,
        showPhone: json['showPhone'] == true,
        showLocation: json['showLocation'] == true,
        twoFactorEnabled: json['twoFactorEnabled'] == true,
        biometricEnabled: json['biometricEnabled'] == true,
      );

  const AccountSettings.defaults()
    : pushNotifications = true,
      emailNotifications = false,
      showPhone = true,
      showLocation = true,
      twoFactorEnabled = false,
      biometricEnabled = false;

  final bool pushNotifications;
  final bool emailNotifications;
  final bool showPhone;
  final bool showLocation;
  final bool twoFactorEnabled;
  final bool biometricEnabled;
}

/// Um profissional favoritado.
class FavoriteProvider {
  const FavoriteProvider({
    required this.providerId,
    required this.acceptingOrders,
    this.name,
    this.avatarUrl,
    this.category,
  });

  factory FavoriteProvider.fromJson(Map<String, dynamic> json) =>
      FavoriteProvider(
        providerId: '${json['providerId']}',
        acceptingOrders: json['acceptingOrders'] == true,
        name: json['name'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
        category: json['category'] as String?,
      );

  final String providerId;
  final bool acceptingOrders;
  final String? name;
  final String? avatarUrl;
  final String? category;
}

/// As rotas da conta de quem está logado.
///
/// Nenhuma delas recebe o dono: ele sai do token. Por isso os caminhos todos
/// começam em `/users/me` — é sempre a própria conta.
class AccountApi {
  AccountApi({DioClient? client}) : _dio = (client ?? sl<DioClient>()).dio;

  final Dio _dio;

  // ------------------------------------------------------------ endereços

  Future<List<Address>> addresses() {
    return apiCall(() async {
      final response = await _dio.get('/users/me/addresses');
      return (response.data as List)
          .map((row) => Address.fromJson((row as Map).cast<String, dynamic>()))
          .toList();
    });
  }

  Future<Address> createAddress(Map<String, dynamic> data) {
    return apiCall(() async {
      final response = await _dio.post('/users/me/addresses', data: data);
      return Address.fromJson((response.data as Map).cast<String, dynamic>());
    });
  }

  Future<Address> updateAddress(String id, Map<String, dynamic> data) {
    return apiCall(() async {
      final response = await _dio.patch('/users/me/addresses/$id', data: data);
      return Address.fromJson((response.data as Map).cast<String, dynamic>());
    });
  }

  Future<void> deleteAddress(String id) {
    return apiCall(() async {
      await _dio.delete('/users/me/addresses/$id');
    });
  }

  // --------------------------------------------------------- preferências

  Future<AccountSettings> settings() {
    return apiCall(() async {
      final response = await _dio.get('/users/me/settings');
      return AccountSettings.fromJson(
        (response.data as Map).cast<String, dynamic>(),
      );
    });
  }

  Future<AccountSettings> updateSettings(Map<String, bool> changes) {
    return apiCall(() async {
      final response = await _dio.patch('/users/me/settings', data: changes);
      return AccountSettings.fromJson(
        (response.data as Map).cast<String, dynamic>(),
      );
    });
  }

  // ------------------------------------------------------------ favoritos

  Future<List<FavoriteProvider>> favorites() {
    return apiCall(() async {
      final response = await _dio.get('/users/me/favorites');
      return (response.data as List)
          .map(
            (row) =>
                FavoriteProvider.fromJson((row as Map).cast<String, dynamic>()),
          )
          .toList();
    });
  }

  Future<void> addFavorite(String providerId) {
    return apiCall(() async {
      await _dio.post('/users/me/favorites/$providerId');
    });
  }

  Future<void> removeFavorite(String providerId) {
    return apiCall(() async {
      await _dio.delete('/users/me/favorites/$providerId');
    });
  }

  // ---------------------------------------------------------------- conta

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return apiCall(() async {
      await _dio.post(
        '/users/me/password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
    });
  }

  Future<void> deleteAccount(String password) {
    return apiCall(() async {
      await _dio.delete('/users/me', data: {'password': password});
    });
  }

  // ----------------------------------------------------------- capa

  /// A capa que está no perfil hoje. Nula quando ele ainda não escolheu.
  Future<String?> cover() {
    return apiCall(() async {
      final response = await _dio.get('/users/profile');
      final url = (response.data as Map)['coverUrl'];
      return url is String && url.isNotEmpty ? url : null;
    });
  }

  /// Aponta a capa para uma imagem que já existe — uma foto do portfólio, por
  /// exemplo. Nada é enviado: é a mesma imagem, reaproveitada.
  Future<void> setCover(String url) {
    return apiCall(() async {
      await _dio.patch('/users/profile', data: {'coverUrl': url});
    });
  }

  /// Tira a capa. O app volta a desenhar a capa padrão.
  Future<void> clearCover() {
    return apiCall(() async {
      await _dio.patch('/users/profile', data: {'coverUrl': ''});
    });
  }

  /// Envia uma imagem nova para ser a capa — a arte com a logo dele, por
  /// exemplo, que não está no portfólio.
  Future<String?> uploadCover({
    required Uint8List bytes,
    required String filename,
  }) {
    return apiCall(() async {
      final form = FormData.fromMap({
        'photo': MultipartFile.fromBytes(bytes, filename: filename),
      });
      final response = await _dio.post('/users/me/cover', data: form);
      final url = (response.data as Map)['coverUrl'];
      return url is String && url.isNotEmpty ? url : null;
    });
  }
}
