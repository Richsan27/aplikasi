import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationHelper {
  static final NotificationHelper _instance = NotificationHelper._internal();
  factory NotificationHelper() => _instance;
  NotificationHelper._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    try {
      print("NotificationHelper: Initializing plugin with custom icon...");
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('ic_notification');

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );

      final initialized = await flutterLocalNotificationsPlugin.initialize(
        settings: initializationSettings,
      );
      print("NotificationHelper: Plugin initialized: $initialized");
      if (initialized != true) {
        throw Exception("Initialization returned false");
      }
    } catch (e) {
      print("NotificationHelper: Failed to initialize with custom icon, falling back to launcher icon. Error: $e");
      try {
        const AndroidInitializationSettings initializationSettingsAndroid =
            AndroidInitializationSettings('@mipmap/ic_launcher');

        const InitializationSettings initializationSettings = InitializationSettings(
          android: initializationSettingsAndroid,
        );

        final initialized = await flutterLocalNotificationsPlugin.initialize(
          settings: initializationSettings,
        );
        print("NotificationHelper: Plugin initialized with fallback launcher icon: $initialized");
      } catch (fallbackError) {
        print("NotificationHelper Error: failed fallback initialization: $fallbackError");
      }
    }
  }

  Future<void> requestPermissions() async {
    try {
      print("NotificationHelper: Requesting permissions via permission_handler...");
      final handlerStatus = await Permission.notification.request();
      print("NotificationHelper: permission_handler status: $handlerStatus");

      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        final granted = await androidImplementation.requestNotificationsPermission();
        print("NotificationHelper: Android plugin permissions status: $granted");
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
