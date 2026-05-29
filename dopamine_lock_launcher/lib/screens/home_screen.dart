import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/question.dart';
import '../services/launcher_service.dart';
import '../widgets/toll_booth_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Set<String> _distractingPackages = {
    'com.instagram.android',
    'com.google.android.youtube',
    'com.zhiliaoapp.musically',
    'com.snapchat.android',
    'com.twitter.android',
    'com.facebook.katana',
  };

  final LauncherService _launcher = LauncherService();
  final DatabaseHelper _database = DatabaseHelper();

  List<Map<String, dynamic>> _apps = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApps();
    _syncQuestions();
  }

  Future<void> _loadApps() async {
    try {
      final apps = await _launcher.getInstalledApps();
      if (!mounted) {
        return;
      }
      setState(() {
        _apps = apps;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load installed apps.')),
      );
    }
  }

  Future<void> _syncQuestions() async {
    try {
      await _launcher.syncQuestions();
    } catch (_) {
      // The bundled SQLite seed keeps the toll booth usable offline.
    }
  }

  Future<void> _handleAppTap(Map<String, dynamic> app) async {
    final packageName = app['packageName'] as String;
    final appName = app['appName'] as String;

    if (!_distractingPackages.contains(packageName)) {
      await _launcher.launchApp(packageName);
      return;
    }

    final questionMap = await _database.getRandomQuestion();
    if (!mounted) {
      return;
    }

    if (questionMap == null) {
      await _launcher.launchApp(packageName);
      return;
    }

    final question = Question.fromMap(questionMap);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => TollBoothDialog(
        question: question,
        onAnswered: (isCorrect) async {
          await _database.recordAppAttempt(
            packageName: packageName,
            appName: appName,
            unlocked: isCorrect,
          );

          if (isCorrect) {
            await _launcher.launchApp(packageName);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DopamineLock'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Refresh apps',
            onPressed: _loadApps,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _apps.isEmpty
              ? const Center(child: Text('No launchable apps found.'))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 120,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: _apps.length,
                  itemBuilder: (context, index) {
                    final app = _apps[index];
                    final icon = app['icon'];

                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _handleAppTap(app),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox.square(
                              dimension: 58,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: icon is Uint8List
                                    ? Image.memory(icon, fit: BoxFit.cover)
                                    : const Icon(Icons.android, size: 42),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              app['appName'] as String,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
