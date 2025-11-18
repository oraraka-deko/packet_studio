import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studio_packet/providers/setup_provider.dart';
import 'package:studio_packet/screens/mainAppScreen.dart';
import 'package:studio_packet/screens/splash_screen.dart';
import 'package:studio_packet/services/setup_service.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
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
