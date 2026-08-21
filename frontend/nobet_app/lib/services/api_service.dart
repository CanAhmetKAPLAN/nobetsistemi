import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}

class ApiService {
  final String? token;
  final String? groupId;
  ApiService({this.token, this.groupId});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
        if (groupId != null) 'X-Group-Id': groupId!,
      };

  Future<dynamic> get(String url) async {
    final res = await http.get(Uri.parse(url), headers: _headers);
    return _handle(res);
  }

  Future<dynamic> post(String url, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse(url),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handle(res);
  }

  Future<dynamic> put(String url, Map<String, dynamic> body) async {
    final res = await http.put(
      Uri.parse(url),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handle(res);
  }

  Future<void> delete(String url) async {
    final res = await http.delete(Uri.parse(url), headers: _headers);
    _handle(res);
  }

  dynamic _handle(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      return jsonDecode(res.body);
    }
    String message = 'Bir hata oluştu.';
    try {
      final body = jsonDecode(res.body);
      message = body['message'] ?? message;
    } catch (_) {}
    throw ApiException(message, res.statusCode);
  }
}
