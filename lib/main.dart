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

  // Arkaplan senkron hatalarını her ekrandan bağımsız gösterebilmek için.
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final Widget home = loggedIn ? const RootScreen() : const LoginView();

    return MaterialApp(
      title: 'Hano Finans',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: messengerKey,
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
      builder: (context, child) => _SyncErrorListener(child: child ?? const SizedBox.shrink()),
      home: home,
    );
  }
}

/// Arkaplan senkron hatalarını dinler ve kullanıcıya SnackBar ile bildirir.
/// (Optimistic mutasyonlar artık await edilmediği için hatalar buradan yüzeye çıkar.)
class _SyncErrorListener extends StatefulWidget {
  final Widget child;
  const _SyncErrorListener({required this.child});

  @override
  State<_SyncErrorListener> createState() => _SyncErrorListenerState();
}

class _SyncErrorListenerState extends State<_SyncErrorListener> {
  ValueNotifier<String?>? _errorNotifier;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final notifier = context.read<FinanceProvider>().syncError;
    if (notifier != _errorNotifier) {
      _errorNotifier?.removeListener(_onError);
      _errorNotifier = notifier..addListener(_onError);
    }
  }

  void _onError() {
    final message = _errorNotifier?.value;
    if (message == null) return;
    _errorNotifier!.value = null; // aynı hatayı tekrar tetiklememek için sıfırla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MyApp.messengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(message)),
              ],
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
    });
  }

  @override
  void dispose() {
    _errorNotifier?.removeListener(_onError);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
