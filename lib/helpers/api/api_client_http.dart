import 'dart:convert';
import 'package:SGMCS/constants/app_constants.dart';
import 'package:http/http.dart' as http;

class ApiClientHttp {
  // final String baseUrl;
  String baseUrl = AppConstants.apiBaseUrl;

  final Map<String, String> headers;

  ApiClientHttp({required this.headers});

  Future<dynamic> getRequest(String endpoint) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/$endpoint'), headers: headers);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to perform GET request: $e');
    }
  }

  Future<dynamic> postRequest(String endpoint, dynamic body, ctx) async {
    // print("BODYYYY :: ");

    try {
      final response = await http.post(Uri.parse('$baseUrl$endpoint'),
          headers: headers, body: jsonEncode(body));

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to perform POST request: $e');
    }
  }

  Future<dynamic> putRequest(String endpoint, dynamic body) async {
    try {
      final response = await http.put(Uri.parse('$baseUrl/$endpoint'),
          headers: headers, body: jsonEncode(body));
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to perform PUT request: $e');
    }
  }

  Future<dynamic> deleteRequest(String endpoint) async {
    try {
      final response =
          await http.delete(Uri.parse('$baseUrl/$endpoint'), headers: headers);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to perform DELETE request: $e');
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          'Failed with status code ${response.statusCode}: ${response.body}');
    }
  }
}
