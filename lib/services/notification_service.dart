import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/finance_entities.dart';

/// Yaklaşan ödeme/tahsilat vadeleri için yerel bildirim servisi.
/// Tüm çağrılar güvenli (hata olsa bile uygulamayı düşürmez).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _channelId = 'due_reminders';
  static const _channelName = 'Vade Hatırlatmaları';

  Future<void> init() async {
    if (_initialized) return;
    try {
      tz.initializeTimeZones();
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();
      await _plugin.initialize(
        const InitializationSettings(android: androidInit, iOS: iosInit),
      );
      _initialized = true;
    } catch (e) {
      debugPrint('NotificationService init failed: $e');
    }
  }

  Future<void> requestPermission() async {
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (e) {
      debugPrint('Notification permission request failed: $e');
    }
  }

  /// Tüm zamanlanmış bildirimleri iptal eder.
  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('cancelAll failed: $e');
    }
  }

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Yaklaşan ödeme ve tahsilat vadeleri',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );

  /// Verilen vade listesinden, gelecekteki (bugünden sonraki ~30 gün) kalemler için
  /// bildirim zamanlar. Önce mevcut bildirimleri temizler.
  Future<void> syncDueReminders(List<DuePayment> items) async {
    if (!_initialized) await init();
    if (!_initialized) return;
    await cancelAll();

    final now = DateTime.now();
    final limit = now.add(const Duration(days: 30));
    int id = 1;
    for (final item in items) {
      final d = item.date;
      if (d == null) continue;
      // Vade gününün sabahı 09:00'da hatırlat.
      final notifyTime = DateTime(d.year, d.month, d.day, 9);
      if (notifyTime.isBefore(now) || notifyTime.isAfter(limit)) continue;
      try {
        await _plugin.zonedSchedule(
          id++,
          item.isPayable ? 'Ödeme vadesi yaklaşıyor' : 'Tahsilat vadesi yaklaşıyor',
          '${item.title} — ${item.amount.toStringAsFixed(0)} ₺',
          tz.TZDateTime.from(notifyTime, tz.local),
          _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (e) {
        debugPrint('zonedSchedule failed: $e');
      }
    }
  }
}
