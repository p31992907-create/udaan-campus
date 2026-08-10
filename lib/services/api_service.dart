import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static const String baseUrl = 'https://api.example.com';
  
  late Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    // Add interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add authentication token if available
          // options.headers['Authorization'] = 'Bearer $token';
          return handler.next(options);
        },
        onError: (error, handler) {
          // Handle errors
          // Use debugPrint in production code to avoid exposing logs unintentionally.
          debugPrint('API Error: ${error.response?.statusCode}');
          return handler.next(error);
        },
      ),
    );
  }

  // Authentication endpoints
  Future<Response> login(String email, String password) async {
    try {
      return await _dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> logout() async {
    try {
      return await _dio.post('/auth/logout');
    } catch (e) {
      rethrow;
    }
  }

  // Student endpoints
  Future<Response> getStudentProfile() async {
    try {
      return await _dio.get('/student/profile');
    } catch (e) {
      rethrow;
    }
  }

  // Attendance endpoints
  Future<Response> getAttendance() async {
    try {
      return await _dio.get('/student/attendance');
    } catch (e) {
      rethrow;
    }
  }

  // Courses endpoints
  Future<Response> getCourses() async {
    try {
      return await _dio.get('/student/courses');
    } catch (e) {
      rethrow;
    }
  }

  // Announcements endpoints
  Future<Response> getAnnouncements() async {
    try {
      return await _dio.get('/announcements');
    } catch (e) {
      rethrow;
    }
  }
}
