import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'services/app_state.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState();
  await state.load();
  runApp(AppScope(state: state, child: const CalorieApp()));
  try {
    // Re-schedule on launch so reminders follow timezone or setting changes.
    await NotificationService.scheduleWaterReminders(state.waterSettings);
  } catch (e) {
    debugPrint('Không thể đặt lịch nhắc uống nước: $e');
  }
}

class CalorieApp extends StatelessWidget {
  const CalorieApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return MaterialApp(
      title: 'Calo Fit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.green,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.green,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: state.profile == null
          ? const ProfileScreen(isOnboarding: true)
          : const HomeScreen(),
    );
  }
}
