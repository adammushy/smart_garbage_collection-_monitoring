import 'dart:io';
import 'package:dio/dio.dart';

class ApiClientDio {
  final String baseUrl;
  final Dio dio;

  ApiClientDio({required this.baseUrl}) : dio = Dio(BaseOptions(baseUrl: baseUrl));

  Future<dynamic> getRequest(String endpoint) async {
    try {
      final response = await dio.get(endpoint);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to perform GET request: $e');
    }
  }

  Future<dynamic> postRequest(String endpoint, dynamic data) async {
    try {
      final response = await dio.post(endpoint, data: data);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to perform POST request: $e');
    }
  }

  Future<dynamic> putRequest(String endpoint, dynamic data) async {
    try {
      final response = await dio.put(endpoint, data: data);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to perform PUT request: $e');
    }
  }

  Future<dynamic> deleteRequest(String endpoint) async {
    try {
      final response = await dio.delete(endpoint);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to perform DELETE request: $e');
    }
  }

  Future<dynamic> postWithFile(String endpoint, Map<String, dynamic> data, File file) async {
    try {
      final formData = FormData.fromMap({...data, 'file': await MultipartFile.fromFile(file.path)});
      final response = await dio.post(endpoint, data: formData);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to perform POST request with file: $e');
    }
  }

  dynamic _handleResponse(Response response) {
    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception('Failed with status code ${response.statusCode}: ${response.data}');
    }
  }
}
