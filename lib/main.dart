import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'lock.dart';
import 'pages/home_shell.dart';
import 'services/notification_service.dart';
import 'state/app_state.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Full screen: hide the status bar (swipe from the top edge to show it).
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  try {
    await NotificationService.init();
  } catch (_) {
    // The app still works without notifications.
  }
  await appState.load();
  runApp(const DayFlowApp());
}

class DayFlowApp extends StatelessWidget {
  const DayFlowApp({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: appState,
        builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'مدیریت زمان',
        builder: (context, child) => LockGate(child: child ?? const SizedBox()),
        scaffoldMessengerKey: messengerKey,
        locale: const Locale('fa', 'IR'),
        supportedLocales: const [Locale('fa', 'IR')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: appState.themeMode,
        home: const HomeShell(),
        ),
      );
}
