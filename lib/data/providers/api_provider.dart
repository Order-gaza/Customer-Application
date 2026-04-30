import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../app/constants/app_constants.dart';
import '../../shared/services/secure_storage_service.dart';

/// Base API provider with authentication handling
class ApiProvider {
  static final _ss = SecureStorageService.instance;

  /// Get saved auth token
  static String? get token => _ss.read(AppConstants.storageToken);

  /// Check if user is logged in
  static bool get isLoggedIn => token != null && token!.isNotEmpty;

  /// Standard headers with auth token
  static Map<String, String> get _headers => {
        'Content-Type': 'application/x-www-form-urlencoded',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  /// URL pattern to strip from any message shown to user
  static final _urlPattern = RegExp(
    r'https?://[^\s,)]+|uri=[^\s,)]+',
    caseSensitive: false,
  );

  /// Check if an exception is a network/connectivity error
  static bool _isNetworkError(Object e) {
    return e is SocketException ||
        e is TimeoutException ||
        e is http.ClientException ||
        e.toString().contains('SocketException') ||
        e.toString().contains('ClientException') ||
        e.toString().contains('host lookup') ||
        e.toString().contains('Connection refused') ||
        e.toString().contains('Connection reset') ||
        e.toString().contains('HandshakeException');
  }

  /// Sanitize a message to never expose URLs or technical details
  static String _sanitizeMessage(String? message) {
    if (message == null || message.isEmpty) {
      return 'Something went wrong'.tr;
    }
    // Strip any URLs / URIs from the message
    String cleaned = message.replaceAll(_urlPattern, '').trim();
    // If the message looks technical (contains exception class names), replace it
    if (cleaned.contains('Exception') ||
        cleaned.contains('errno') ||
        cleaned.contains('OS Error') ||
        cleaned.contains('CERTIFICATE') ||
        cleaned.contains('stacktrace') ||
        cleaned.isEmpty) {
      return 'Connection error. Please try again.'.tr;
    }
    return cleaned;
  }

  /// Build a safe network-error response
  static ApiResponse _networkErrorResponse() {
    return ApiResponse(
      success: false,
      message: 'Connection error. Please try again.'.tr,
      isNetworkError: true,
    );
  }

  /// POST request
  static Future<ApiResponse> post(String url,
      {Map<String, String>? body}) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: body,
      );
      return _parseResponse(response);
    } catch (e) {
      if (_isNetworkError(e)) return _networkErrorResponse();
      return ApiResponse(
        success: false,
        message: 'Something went wrong'.tr,
      );
    }
  }

  /// GET request
  static Future<ApiResponse> get(String url,
      {Map<String, String>? queryParams}) async {
    try {
      var uri = Uri.parse(url);
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }
      final response = await http.get(uri, headers: _headers);
      return _parseResponse(response);
    } catch (e) {
      if (_isNetworkError(e)) return _networkErrorResponse();
      return ApiResponse(
        success: false,
        message: 'Something went wrong'.tr,
      );
    }
  }

  /// Multipart POST request (for file uploads)
  static Future<ApiResponse> uploadMultipart(
    String url, {
    Map<String, String>? fields,
    required String fileField,
    required String filePath,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers.addAll({
        if (token != null) 'Authorization': 'Bearer $token',
      });
      if (fields != null) request.fields.addAll(fields);
      request.files.add(await http.MultipartFile.fromPath(fileField, filePath));
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      return _parseResponse(response);
    } catch (e) {
      if (_isNetworkError(e)) return _networkErrorResponse();
      return ApiResponse(
        success: false,
        message: 'Something went wrong'.tr,
      );
    }
  }

  /// Parse the standard JSON response from our PHP backend
  static ApiResponse _parseResponse(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        final status = body['status'] as String?;
        return ApiResponse(
          success: status == 'success',
          message: _sanitizeMessage(body['message'] as String?),
          data: body['data'],
          rawBody: body,
        );
      }
      return ApiResponse(
        success: false,
        message: 'Something went wrong'.tr,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Something went wrong'.tr,
      );
    }
  }

  /// Save auth data after login.
  /// Cache is updated synchronously; encrypted persist is fire-and-forget.
  static void saveAuth({
    required String token,
    required String userId,
    required String userName,
    required String userEmail,
    String? userPhone,
    String? profileImage,
  }) {
    _ss.write(AppConstants.storageToken, token);
    _ss.write(AppConstants.storageRole, AppConstants.roleCustomer);
    _ss.write(AppConstants.storageUserId, userId);
    _ss.write(AppConstants.storageUserName, userName);
    _ss.write(AppConstants.storageUserEmail, userEmail);
    if (userPhone != null) {
      _ss.write(AppConstants.storageUserPhone, userPhone);
    }
    if (profileImage != null) {
      _ss.write(AppConstants.storageProfileImage, profileImage);
    }
  }

  /// Clear all stored auth data
  static void clearAuth() {
    _ss.remove(AppConstants.storageToken);
    _ss.remove(AppConstants.storageRole);
    _ss.remove(AppConstants.storageUserId);
    _ss.remove(AppConstants.storageUserName);
    _ss.remove(AppConstants.storageUserEmail);
    _ss.remove(AppConstants.storageUserPhone);
    _ss.remove(AppConstants.storageProfileImage);
  }

  /// Stored user accessors
  static String? get storedUserId =>
      _ss.read(AppConstants.storageUserId);
  static String? get storedUserName =>
      _ss.read(AppConstants.storageUserName);
  static String? get storedUserEmail =>
      _ss.read(AppConstants.storageUserEmail);
  static String? get storedUserPhone =>
      _ss.read(AppConstants.storageUserPhone);
  static String? get storedProfileImage =>
      _ss.read(AppConstants.storageProfileImage);
}

/// Standard API response wrapper
class ApiResponse {
  final bool success;
  final String? message;
  final dynamic data;
  final Map<String, dynamic>? rawBody;
  final bool isNetworkError;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.rawBody,
    this.isNetworkError = false,
  });
}
