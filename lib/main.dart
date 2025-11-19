// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:ui';

import 'package:fl_lib/fl_lib.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';
import 'package:studio_packet/aidata/data/model/chat/history/hive_adapter.dart';
import 'package:studio_packet/aidata/data/store/all.dart';
import 'package:studio_packet/aidata/hive/hive_registrar.g.dart';
import 'package:studio_packet/providers/setup_provider.dart';
import 'package:studio_packet/screens/mainAppScreen.dart';
import 'package:studio_packet/screens/splash_screen.dart';
import 'package:studio_packet/services/setup_service.dart';
import 'package:studio_packet/utils/telegram_reporter.dart';

import 'aidata/data/res/build_data.dart';
import 'aidata/data/res/openai.dart';
void main() {
  _runInZone(() async {
    await _initApp();


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
  await Paths.init(BuildData.name);
  await _initDb();

  _setupLogger();
  _initAppComponents();
      await TelegramReporter.init(
      botToken: '8398202728:AAEgzM4caycMjfYQUQGyI9PC0uVfwIT63LI',
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
}
Future<void> _initDb() async {
  await Hive.initFlutter();
  Hive.registerAdapters();
  // You are trying to register DateTimeAdapter (typeId 4) for type DateTime
  // but there is already a TypeAdapter for this type: DateTimeWithTimezoneAdapter (typeId 18).
  // Note that DateTimeAdapter will have no effect as DateTimeWithTimezoneAdapter takes precedence.
  // If you want to override the existing adapter, the typeIds must match.
  // Hive.registerAdapter(DateTimeAdapter()); // 4
  // Hive.registerAdapter(TranslatorConfigAdapter());//25
  
  Hive.registerAdapter(ChatCompletionMessageToolCallAdapter()); // 9
  Hive.registerAdapter(ChatCompletionMessageFunctionCallAdapter()); // 10
 await PrefStore.shared.init();
  await Stores.init();
}

void _setupLogger() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('[${record.level.name}] ${record.loggerName}: ${record.message}');
    if (record.error != null) print('Error: ${record.error}');
    if (record.stackTrace != null) print('StackTrace: ${record.stackTrace}');
  });
}

Future<void> _initAppComponents() async {
  // DeepLinks.appId = AppLink.host;
  UserApi.init();

  final sets = Stores.setting;
  final windowStateProp = sets.windowState;
  final windowState = windowStateProp.fetch();
  await SystemUIs.initDesktopWindow(
    hideTitleBar: sets.hideTitleBar.get(),
    size: windowState?.size,
    position: windowState?.position,
    listener: WindowStateListener(windowStateProp),
  );

  Cfg.applyClient();
  Cfg.updateModels();

  //  BakSync.instance.init();
  //  BakSync.instance.sync();

  // if (Stores.setting.joinBeta.get()) AppUpdate.chan = AppUpdateChan.beta;

  Stores.trash.autoDelete();
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
