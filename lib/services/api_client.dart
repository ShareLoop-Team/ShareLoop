import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/backend_config.dart';
import '../core/errors/app_exception.dart';
import '../models/photo_upload.dart';

/// Service: talks JSON to the ShareLoop Laravel API, attaching the signed-in
/// user's bearer token, and turns every failure into an [AppException] with
/// text fit to show the user.
class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  static const String _tokenKey = 'shareloop.api_token';

  /// Replaced in tests.
  http.Client httpClient = http.Client();

  String? _token;

  bool get hasToken => _token != null;

  /// Loads a token saved by a previous session.
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
  }

  Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Uri _uri(String path, [Map<String, Object?>? query]) {
    final base = BackendConfig.apiBaseUrl.endsWith('/')
        ? BackendConfig.apiBaseUrl.substring(
            0, BackendConfig.apiBaseUrl.length - 1)
        : BackendConfig.apiBaseUrl;
    final params = <String, String>{
      for (final entry in (query ?? const {}).entries)
        if (entry.value != null) entry.key: '${entry.value}',
    };
    return Uri.parse('$base$path')
        .replace(queryParameters: params.isEmpty ? null : params);
  }

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<dynamic> get(String path, {Map<String, Object?>? query}) =>
      _send(() => httpClient.get(_uri(path, query), headers: _headers));

  Future<dynamic> post(String path, [Map<String, Object?>? body]) =>
      _send(() => httpClient.post(
            _uri(path),
            headers: {..._headers, 'Content-Type': 'application/json'},
            body: jsonEncode(body ?? const {}),
          ));

  Future<dynamic> patch(String path, Map<String, Object?> body) =>
      _send(() => httpClient.patch(
            _uri(path),
            headers: {..._headers, 'Content-Type': 'application/json'},
            body: jsonEncode(body),
          ));

  Future<dynamic> delete(String path) =>
      _send(() => httpClient.delete(_uri(path), headers: _headers));

  /// Multipart POST: [fields] as form fields, [photos] as `photos[]` files.
  Future<dynamic> postMultipart(
    String path, {
    required Map<String, String> fields,
    List<PhotoUpload> photos = const [],
  }) {
    return _send(() async {
      final request = http.MultipartRequest('POST', _uri(path))
        ..headers.addAll(_headers)
        ..fields.addAll(fields);
      for (final photo in photos) {
        request.files.add(http.MultipartFile.fromBytes(
          'photos[]',
          photo.bytes,
          filename: _fileName(photo),
        ));
      }
      return http.Response.fromStream(await httpClient.send(request));
    });
  }

  static String _fileName(PhotoUpload photo) {
    final name = photo.name.split(RegExp(r'[\\/]')).last;
    if (name.contains('.')) return name;
    return switch (photo.mimeType) {
      'image/png' => '$name.png',
      'image/webp' => '$name.webp',
      _ => '$name.jpg',
    };
  }

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    http.Response response;
    try {
      response = await request().timeout(BackendConfig.requestTimeout);
    } on TimeoutException {
      throw const AppException(
        'ShareLoop is taking too long to answer. Please try again.',
      );
    } catch (_) {
      throw const AppException(
        'Could not reach ShareLoop. Check your connection and try again.',
      );
    }

    final body = _decode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    if (response.statusCode == 401 && _token != null) {
      await clearToken();
    }
    throw AppException(_message(response.statusCode, body));
  }

  static dynamic _decode(String text) {
    if (text.isEmpty) return null;
    try {
      return jsonDecode(text);
    } on FormatException {
      return null;
    }
  }

  /// The most useful message in a Laravel error body: the first validation
  /// error, else `message`, else a generic one for the status code.
  static String _message(int status, dynamic body) {
    if (body is Map<String, dynamic>) {
      final errors = body['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return '${first.first}';
      }
      final message = body['message'];
      if (message is String && message.isNotEmpty && status < 500) {
        return message;
      }
    }
    return switch (status) {
      401 => 'Your session has expired. Please sign in again.',
      403 => 'You are not allowed to do that.',
      404 => 'That could not be found. It may have been removed.',
      413 => 'Those photos are too large. Each must be 5 MB or smaller.',
      429 => 'Too many attempts. Please wait a moment and try again.',
      _ => 'Something went wrong. Please try again.',
    };
  }
}
