import 'dart:async';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';

final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  // Channel for foreground service persistent notification
  const AndroidNotificationChannel serviceChannel = AndroidNotificationChannel(
    'smarthome_background',
    'Smart Home Background Service',
    description: 'Handles background notifications for smart home alerts',
    importance: Importance.low,
  );

  // Channel for actual alerts
  const AndroidNotificationChannel alertChannel = AndroidNotificationChannel(
    'smarthome_alerts',
    'Smart Home Alerts',
    description: 'Notifications for device status and security',
    importance: Importance.max,
  );

  await _notificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(serviceChannel);

  await _notificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(alertChannel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'smarthome_background',
      initialNotificationTitle: 'Smart Home Service',
      initialNotificationContent: 'Monitoring device status...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );

  service.startService();
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  debugPrint('[BG] Background Service Starting...');

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // Initialize notifications for this isolate
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  
  await _notificationsPlugin.initialize(
    settings: initializationSettings,
  );

  // State
  DateTime? lastElectricNotifyTime;
  DateTime? lastAcNotifyTime;
  bool phoneOnline = false;
  bool currentActive = false;
  bool currentAcActive = false;

  final dbRef = FirebaseDatabase.instance.ref();

  void runLogic() {
    debugPrint('[BG] Logic Run: PhoneOnline=$phoneOnline, Active=$currentActive, ACActive=$currentAcActive');

    if (phoneOnline) {
      if (lastElectricNotifyTime != null || lastAcNotifyTime != null) {
        debugPrint('[BG] User Home: Resetting notification timers');
        lastElectricNotifyTime = null;
        lastAcNotifyTime = null;
      }
      return;
    }

    final now = DateTime.now();
    const interval = Duration(hours: 1);

    // Condition A: Devices drawing power (>30W)
    if (currentActive) {
      if (lastElectricNotifyTime == null || now.difference(lastElectricNotifyTime!) >= interval) {
        debugPrint('[BG] Triggering Power Notification');
        _showNotification(201, "Smart Home Alert", "Devices are still drawing power while you are away!");
        lastElectricNotifyTime = now;
      }
    } else {
      lastElectricNotifyTime = null;
    }

    // Condition B: AC is running
    if (currentAcActive) {
      if (lastAcNotifyTime == null || now.difference(lastAcNotifyTime!) >= interval) {
        debugPrint('[BG] Triggering AC Notification');
        _showNotification(202, "AC Alert!", "AC is running, but no one is home");
        lastAcNotifyTime = now;
      }
    } else {
      lastAcNotifyTime = null;
    }
  }

  dbRef.child('device/state/notifyCheck').onValue.listen((event) {
    final data = event.snapshot.value as Map?;
    if (data != null) {
      currentActive = data['active'] as bool? ?? false;
      currentAcActive = data['acActive'] as bool? ?? false;
      phoneOnline = data['phoneOnline'] as bool? ?? false;
      debugPrint('[BG] State Update: Online=$phoneOnline, Active=$currentActive, AC=$currentAcActive');
      runLogic();
    }
  });

  service.on('stopService').listen((event) {
    debugPrint('[BG] Stopping Service');
    service.stopSelf();
  });
}

Future<void> _showNotification(int id, String title, String body) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'smarthome_alerts',
    'Smart Home Alerts',
    channelDescription: 'Notifications for device status and security',
    importance: Importance.max,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );
  
  const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
  
  try {
    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
    );
    debugPrint('[BG] Notification $id shown: $title');
  } catch (e) {
    debugPrint('[BG] Error showing notification: $e');
  }
}
