import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationHelper {
  static final NotificationHelper _instance = NotificationHelper._internal();
  factory NotificationHelper() => _instance;
  NotificationHelper._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    try {
      print("NotificationHelper: Initializing plugin...");
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('ic_notification');

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );

      final initialized = await flutterLocalNotificationsPlugin.initialize(
        settings: initializationSettings,
      );
      print("NotificationHelper: Plugin initialized successfully: $initialized");
    } catch (e) {
      print("NotificationHelper Error: failed to initialize: $e");
    }
  }

  Future<void> requestPermissions() async {
    try {
      print("NotificationHelper: Requesting permissions...");
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        final granted = await androidImplementation.requestNotificationsPermission();
        print("NotificationHelper: Android permissions status: $granted");
      } else {
        print("NotificationHelper: Android implementation was null!");
      }
    } catch (e) {
      print("NotificationHelper Error: failed to request permission: $e");
    }
  }

  Future<void> showNotification(String title, String body) async {
    try {
      print("NotificationHelper: showNotification called for '$title' - '$body'");
      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
        'barang_out_of_stock_channel',
        'Stok Habis Alert',
        channelDescription: 'Peringatan ketika stok barang habis',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
        icon: 'ic_notification',
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
      );

      final int id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
      await flutterLocalNotificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
      );
      print("NotificationHelper: Notification sent to system!");
    } catch (e) {
      print("NotificationHelper Error: failed to show notification: $e");
    }
  }
}
