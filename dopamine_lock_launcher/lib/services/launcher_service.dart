import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../database/database_helper.dart';

class LauncherService {
  static const MethodChannel _platform = MethodChannel(
    'com.dopaminelock/launcher',
  );

  Future<List<Map<String, dynamic>>> getInstalledApps() async {
    final result = await _platform.invokeListMethod<dynamic>('getInstalledApps');
    if (result == null) {
      return [];
    }

    return result
        .whereType<Map<dynamic, dynamic>>()
        .map((app) => Map<String, dynamic>.from(app))
        .toList();
  }

  Future<bool> launchApp(String packageName) async {
    final launched = await _platform.invokeMethod<bool>(
      'launchApp',
      {'packageName': packageName},
    );
    return launched ?? false;
  }

  Future<int> syncQuestions({
    String baseUrl = 'http://10.0.2.2:8000',
  }) async {
    final response = await http.get(Uri.parse('$baseUrl/sync/questions'));
    if (response.statusCode != 200) {
      throw StateError('Question sync failed: ${response.statusCode}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final questions = (data['questions'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    await DatabaseHelper().insertQuestions(questions);
    return questions.length;
  }
}
