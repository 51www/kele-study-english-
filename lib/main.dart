import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'app/theme/app_colors.dart';
import 'app/theme/app_text.dart';
import 'core/logger.dart';
import 'data/db/local_store.dart';
import 'data/db/store_factory.dart';
import 'data/repositories/repositories.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 开启语义树：便于 Web 无障碍与自动化验证定位控件。
  SemanticsBinding.instance.ensureSemantics();

  FlutterError.onError = (details) {
    AppLogger.error('FlutterError: ${details.exceptionAsString()}', details.exception, details.stack);
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.error('Uncaught: $error', error, stack);
    return true;
  };
  ErrorWidget.builder = (details) => CrashView(message: details.exceptionAsString());

  LocalStore store;
  try {
    store = await createLocalStore();
  } catch (e) {
    AppLogger.error('bootstrap storage failed: $e');
    runApp(BootstrapFailure(error: '$e'));
    return;
  }

  final settingsRepository = SettingsRepository(store);
  await settingsRepository.load();

  runApp(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(store),
        settingsRepositoryProvider.overrideWithValue(settingsRepository),
      ],
      child: const KeleApp(),
    ),
  );
}

class BootstrapFailure extends StatelessWidget {
  const BootstrapFailure({super.key, required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: AppColors.primaryWash,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.storage_rounded, size: 56, color: AppColors.primary),
                  const SizedBox(height: 18),
                  Text('本地数据初始化失败', style: AppText.h1, textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  Text(
                    '请重启应用后再试。错误信息：$error',
                    style: AppText.bodySecondary,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CrashView extends StatelessWidget {
  const CrashView({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sentiment_dissatisfied_rounded, size: 48, color: AppColors.inkMuted),
              const SizedBox(height: 16),
              Text('这里出了点小问题', style: AppText.h2),
              const SizedBox(height: 8),
              Text(message, style: AppText.caption, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
