// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:studio_packet/providers/setup_provider.dart';
import 'package:studio_packet/screens/mainAppScreen.dart';
import 'package:studio_packet/screens/splash_screen.dart';
import 'package:studio_packet/services/setup_service.dart';
import 'package:studio_packet/utils/telegram_reporter.dart';

void main() {
  _runInZone(() async {
    await _initApp();
    await TelegramReporter.init(
      botToken: '',
      chatId: 6865643282, // YOUR_CHAT_ID
    );
  // Catch Flutter UI framework errors
  FlutterError.onError = (details) {
    TelegramReporter.reportError(
      details.exception,
      details.stack ?? StackTrace.current,
      {
        'library': details.library,
        'stackFiltered': details.stackFilter,
      },
      'Flutter UI Error: ${details.library}',
      true,
    );
  };

  // Catch unhandled Dart runtime errors
  PlatformDispatcher.instance.onError = (error, stack) {
    TelegramReporter.reportError(error, stack, null, 'Dart Runtime Error', true);
    return true; // Keep app running
  };

  // Optional: Catch errors in the widget tree
  ErrorWidget.builder = (errorDetails) {
    TelegramReporter.reportError(errorDetails.exception, errorDetails.stack!, null, 'Error Widget', false);
    return ErrorWidget(errorDetails.exception);
  };

    runApp(const ProviderScope(child: MyApp()));
  });
}

void _runInZone(void Function() body) {
  final zoneSpec = ZoneSpecification(
    print: (_, parent, zone, line) => parent.print(zone, line),
  );

  runZonedGuarded(
    body,
    (e, s) => TelegramReporter.reportError(e, s, null, 'ZONE', true),
    zoneSpecification: zoneSpec,
  );
}

Future<void> _initApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  _setupLogger();
}


void _setupLogger() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('[${record.level.name}] ${record.loggerName}: ${record.message}');
    if (record.error != null) print('Error: ${record.error}');
    if (record.stackTrace != null) print('StackTrace: ${record.stackTrace}');
  });
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Studio Packet',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Initializer(),
    );
  }
}

class Initializer extends ConsumerStatefulWidget {
  const Initializer({super.key});

  @override
  ConsumerState<Initializer> createState() => _InitializerState();
}

class _InitializerState extends ConsumerState<Initializer> {
  final SetupService _setupService = SetupService();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final isFirstRun = await _setupService.isFirstRun();
    if (isFirstRun) {
      ref.read(setupProvider.notifier).setStatus(SetupStatus.settingUp);
      await _setupService.runInitialSetup((message) {
        ref.read(setupProvider.notifier).updateMessage(message);
      });
      ref.read(setupProvider.notifier).setStatus(SetupStatus.setupComplete);
    } else {
      ref.read(setupProvider.notifier).setStatus(SetupStatus.setupComplete);
    }
  }

  @override
  Widget build(BuildContext context) {
    final setupState = ref.watch(setupProvider);

    return setupState.status == SetupStatus.setupComplete
        ? const MainIdeLayout()
        : const SplashScreen();
  }
}
