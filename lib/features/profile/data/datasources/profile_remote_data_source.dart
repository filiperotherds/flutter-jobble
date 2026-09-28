import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_tcc/core/network/dio_client.dart';
import 'package:flutter_tcc/features/profile/data/models/project_model.dart';

abstract class ProfileRemoteDataSource {
  Future<List<ProjectModel>> getProjects();
  Future<String> updateOrganizationAvatar(File file);
  Future<void> updateOrganizationName(String name);
  Future<void> updateUserName(String name);

  /// Sobe a foto e devolve a URL persistente que vai no projeto.
  Future<String> uploadPhoto(File file);
  Future<ProjectModel> createProject({
    required String title,
    required String city,
    required String state,
    String? description,
    List<String> photoUrls,
  });
  Future<void> deleteProject(String id);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final DioClient dioClient;

  ProfileRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<ProjectModel>> getProjects() async {
    try {
      final response = await dioClient.dio.get('/projects');
      // O backend devolve `{ projects: [...] }`, não a lista crua.
      final list = (response.data['projects'] as List<dynamic>?) ?? const [];
      return list
          .map((e) => ProjectModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final message = e.response?.data['message'];
        if (message != null) {
          throw Exception(message);
        }
      }
      rethrow;
    }
  }

  @override
  Future<String> updateOrganizationAvatar(File file) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });
      final response = await dioClient.dio.post(
        '/organizations/avatar',
        data: formData,
      );
      return response.data['avatarUrl'] as String;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final message = e.response?.data['message'];
        if (message != null) {
          throw Exception(message);
        }
      }
      rethrow;
    }
  }

  @override
  Future<void> updateOrganizationName(String name) async {
    try {
      await dioClient.dio.patch('/organizations/name', data: {'name': name});
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final message = e.response?.data['message'];
        if (message != null) {
          throw Exception(message);
        }
      }
      rethrow;
    }
  }

  @override
  Future<String> uploadPhoto(File file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last,
      ),
    });
    final response = await dioClient.dio.post('/uploads', data: formData);
    return response.data['url'] as String;
  }

  @override
  Future<ProjectModel> createProject({
    required String title,
    required String city,
    required String state,
    String? description,
    List<String> photoUrls = const [],
  }) async {
    final response = await dioClient.dio.post(
      '/projects',
      data: {
        'title': title,
        'city': city,
        'state': state,
        if (description != null && description.isNotEmpty)
          'description': description,
        'photoUrls': photoUrls,
      },
    );
    return ProjectModel.fromJson(
      (response.data['project'] as Map).cast<String, dynamic>(),
    );
  }

  @override
  Future<void> deleteProject(String id) async {
    await dioClient.dio.delete('/projects/$id');
  }

  @override
  Future<void> updateUserName(String name) async {
    try {
      await dioClient.dio.put('/users/me/legal-profile', data: {'name': name});
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final message = e.response?.data['message'];
        if (message != null) {
          throw Exception(message);
        }
      }
      rethrow;
    }
  }
}
