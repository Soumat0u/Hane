import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hane/views/root_screen.dart';
import 'package:hane/views/auth/login_view.dart';
import 'package:hane/providers/finance_provider.dart';
import 'package:hane/providers/settings_provider.dart';
import 'package:hane/services/api_service.dart';
import 'package:hane/services/notification_service.dart';
import 'package:hane/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);
  if (!kIsWeb) await NotificationService.instance.init();

  bool loggedIn = false;
  try {
    final token = await ApiService.instance.getToken();
    loggedIn = token != null;
  } catch (e) {
    debugPrint('Token okuma hatası: $e');
    loggedIn = false;
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => FinanceProvider()),
      ],
      child: MyApp(loggedIn: loggedIn),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool loggedIn;
  const MyApp({super.key, required this.loggedIn});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final Widget home = loggedIn ? const RootScreen() : const LoginView();

    return MaterialApp(
      title: 'Hano Finans',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.themeMode,
      locale: settings.locale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('tr'), Locale('en')],
      home: home,
    );
  }
}
