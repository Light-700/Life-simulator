import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
//import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '/widgets/floating_notification_guide.dart';


class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  // Initialize the notification service
  Future<void> initialize() async {
    // Android initialization
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization  
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(settings,
     onDidReceiveNotificationResponse: onNotificationResponse
     //onDidReceiveBackgroundNotificationResponse: onNotificationResponse,
     );
    await _createNotificationChannels();
    
    // Request permissions for Android 13+
    if (Platform.isAndroid) {
      await _requestAndroidPermissions();
    }
  }
  
  Future<void> _requestAndroidPermissions() async {
    final status = await Permission.notification.request();
    if (status.isDenied) {
      // Handle permission denied
      print('Notification permission denied');
    }
  }

  static bool _waitingForUserResponse = false;
  static Timer? _responseTimer;

  Future<void> intelligentFloatingDetection(BuildContext context) async {
    await _notifications.show(
      999,
      "🎯 Hunter System Test",
      "Tap this notification to confirm heads-up display works!",
      NotificationDetails(
        android: AndroidNotificationDetails(
          'hunter_system',
          'Hunter System Alerts',
          importance: Importance.max,
          priority: Priority.high,
          // Add action button for detection
          actions: [
            AndroidNotificationAction(
              'confirm_floating',
              'Heads-up works!',
              showsUserInterface: true,
            ), 
          ],
        ),
      ),
      payload: 'floating_test',
    );

    // Start detection timer
    _waitingForUserResponse = true;
    _responseTimer = Timer(Duration(seconds: 7), () {
      if (_waitingForUserResponse && context.mounted) {
        //dialog if no reaction is recorded
        showDialog(
          context: context,
          builder: (context) => FloatingNotificationGuide(),
        );
      }
      _waitingForUserResponse = false;
    });
  }

// @pragma('vm:entry-point') => tells the compiler to not consider it as dead code (not required here though)
  void onNotificationResponse(NotificationResponse response) {
    if (response.payload == 'floating_test') {
      _waitingForUserResponse = false;
      _responseTimer?.cancel();
      // User saw and tapped - heads-up is working!
    }
  }


Future<void> _createNotificationChannels() async {
  if (Platform.isAndroid) {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    // Create high-priority channel for Hunter system alerts
    await androidImplementation?.createNotificationChannel(
      const AndroidNotificationChannel(
        'hunter_system', // channel id
        'Hunter System Alerts', // channel name  
        description: 'Critical notifications for Hunter progression',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
    );
  }
}


  // BATCH COMPLETION NOTIFICATION - Multiple tasks completed simultaneously
  Future<void> showBatchCompletionNotification(
    List<String> completedTasks, 
    int totalXP, 
    Map<String, int> taskTypeXP
  ) async {
    String taskList = completedTasks.length > 3 
        ? '${completedTasks.take(3).join(', ')} and ${completedTasks.length - 3} more'
        : completedTasks.join(', ');
    
    String breakdown = taskTypeXP.entries
        .where((e) => e.value > 0)
        .map((e) => '${e.key}: ${e.value} XP')
        .join(', ');
    
    await _notifications.show(
      1001, // Unique ID for batch completion
      '🗡️ Quest Batch Completed!',
      'Tasks: $taskList\n💪 Total XP Gained: $totalXP\n📊 $breakdown',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'hunter_system', 
          'Hunter System Alerts',
      channelDescription: 'Critical notifications for Hunter progression',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color.fromARGB(238, 33, 18, 1),
          playSound: true,
          enableVibration: true,
          //vibrationPattern: Int64List.fromList([0, 200, 100, 200]),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  // SINGLE LEVEL UP - Like Jinwoo's normal level progression
  Future<void> showSingleLevelUp(int oldLevel, int newLevel) async {
    await _notifications.show(
      1002,
      '⚡ LEVEL UP!',
      'Congratulations! You have advanced from Level $oldLevel to Level $newLevel!\n🎯 Keep pushing your limits, Hunter!',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'hunter_system', 
          'Hunter System Alerts',
      channelDescription: 'Critical notifications for Hunter progression',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          color: const Color.fromARGB(238, 179, 18, 1),
          playSound: true,
          enableVibration: true,
          //vibrationPattern: Int64List.fromList([0, 300, 200, 300, 200, 300]),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  // MASSIVE POWER SPIKE - Multiple level-ups like Jinwoo's awakening moments
  Future<void> showMassivePowerSpike(int startLevel, int endLevel, int levelGains) async {
    await _notifications.show(
      1003,
      '🔥 MASSIVE POWER SURGE!',
      'INCREDIBLE! You have experienced a massive awakening!\n📈 Level $startLevel → $endLevel (+$levelGains levels)\n⚡ Your power has dramatically increased!',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'hunter_system', 
          'Hunter System Alerts',
      channelDescription: 'Critical notifications for Hunter progression',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          color: const Color.fromARGB(238, 33, 18, 1),
          playSound: true,
          enableVibration: true,
          //vibrationPattern: Int64List.fromList([0, 500, 100, 500, 100, 500, 100, 500]),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  // RANK ADVANCEMENT - Hunter class progression like E-rank to D-rank
  Future<void> showRankAdvancement(String oldRank, String newRank) async {
    String message = _getRankAdvancementMessage(oldRank, newRank);
    
    await _notifications.show(
      1004,
      '👑 RANK ADVANCEMENT!',
      'Congratulations! You have been promoted!\n🏆 $oldRank → $newRank\n$message',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'hunter_system', 
          'Hunter System Alerts',
      channelDescription: 'Critical notifications for Hunter progression',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          color: const Color.fromARGB(18, 187, 238, 1),
          playSound: true,
          enableVibration: true,
          //vibrationPattern: Int64List.fromList([0, 200, 100, 200, 100, 200, 100, 200, 100, 200]),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  // STAT POINT ALLOCATION - When stat points are distributed
  Future<void> showStatPointAllocation(Map<String, int> statBonuses, int totalPoints) async {
    String statBreakdown = statBonuses.entries
        .where((e) => e.value > 0)
        .map((e) => '${e.key.toUpperCase()}: +${e.value}')
        .join(', ');
    
    await _notifications.show(
      1005,
      '📊 Stat Points Allocated!',
      'Your training has paid off!\n💪 Total Points Gained: $totalPoints\n📈 Distribution: $statBreakdown',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'hunter_system', 
          'Hunter System Alerts',
      channelDescription: 'Critical notifications for Hunter progression',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color.fromARGB(18, 238, 227, 1),
          playSound: true,
          enableVibration: true,
          //vibrationPattern: Int64List.fromList([0, 150, 100, 150]),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  String _getRankAdvancementMessage(String oldRank, String newRank) {
    Map<String, String> rankMessages = {
      'God-Mode': '🌟 You have broken the barriers of perseverance! You are entered in GOD-Mode 🔥!',
      'S-class': '🌟 You have reached the level of the innately strongest of society! You have one of the most elite players!',
      'A-class': '⭐ congratulations! you have become A-class Player! You are among the best of the best!',
      'B-class': '🔸 congratulations! you have become B-class Player! Your skills are impressive!',
      'C-class': '🔹 congratulations! you have become C-class Player! Steady progress continues!',
      'D-class': '📋 congratulations! you have become D-class Player! Keep training!',
      'E-class': '📝 Beginner Player! Your journey starts here!',
    };
    
    return rankMessages[newRank] ?? 'Your player ranking has improved!';
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Clear specific notification
  Future<void> clearNotification(int id) async {
    await _notifications.cancel(id);
  }
}
