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
 print('\n🔧 Initializing Notification Service...');

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
    
    try {
    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: onNotificationResponse
   //onDidReceiveBackgroundNotificationResponse: onNotificationResponse,
     );
    print('   ✅ Notification plugin initialized');
  } catch (e) {
    print('   ❌ Failed to initialize: $e');
  }
     
    await _createNotificationChannels();
    
    // Request permissions for Android 13+
    if (Platform.isAndroid) {
      await _requestAndroidPermissions();
    }

     print('   ✅ Notification Service Ready\n');
  }
  
 Future<void> _requestAndroidPermissions() async {
  print('\n🔐 Requesting Android notification permissions...');
  
  final status = await Permission.notification.request();
  
  if (status.isGranted) {
    print('   ✅ Notification permission GRANTED');
  } else if (status.isDenied) {
    print('   ⚠️  Notification permission DENIED');
  } else if (status.isPermanentlyDenied) {
    print('   ❌ Notification permission PERMANENTLY DENIED');
  } else {
    print('   ⚠️  Notification permission status: $status');
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


  // BATCH COMPLETION NOTIFICATION 
 Future<void> showBatchCompletionNotification(
  List<String> completedTasks,
  int totalXP,
  Map<String, int> taskTypeXP
) async {
  print('\n┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('┃ 📬 NOTIFICATION: Batch Completion');
  print('┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('┃ ID: 1001');
  print('┃ Tasks: $completedTasks');
  print('┃ Total XP: $totalXP');
  print('┃ Breakdown: $taskTypeXP');
  
  try {
    String taskList = completedTasks.length > 3
        ? '${completedTasks.take(3).join(', ')} and ${completedTasks.length - 3} more'
        : completedTasks.join(', ');
    
    String breakdown = taskTypeXP.entries
        .where((e) => e.value > 0)
        .map((e) => '${e.key}: ${e.value} XP')
        .join(', ');
    
    await _notifications.show(
      1001,
      '🗡️ Quest Completed!',
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
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
    
    print('┃ Status: ✅ SENT SUCCESSFULLY');
  } catch (e, stackTrace) {
    print('┃ Status: ❌ FAILED');
    print('┃ Error: $e');
    print('┃ Stack: $stackTrace');
  }
  
  print('┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
}

  // SINGLE LEVEL UP 
Future<void> showSingleLevelUp(int oldLevel, int newLevel) async {
  print('\n┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('┃ ⚡ NOTIFICATION: Single Level Up');
  print('┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('┃ ID: 1002');
  print('┃ Level Transition: $oldLevel → $newLevel');
  
  try {
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
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
    
    print('┃ Status: ✅ SENT SUCCESSFULLY');
  } catch (e, stackTrace) {
    print('┃ Status: ❌ FAILED');
    print('┃ Error: $e');
    print('┃ Stack: $stackTrace');
  }
  
  print('┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
}

  
 Future<void> showMassivePowerSpike(int startLevel, int endLevel, int levelGains) async {
  print('\n┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('┃ 🔥 NOTIFICATION: Massive Power Spike');
  print('┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('┃ ID: 1003');
  print('┃ Level Jump: $startLevel → $endLevel (+$levelGains levels)');
  
  try {
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
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
    
    print('┃ Status: ✅ SENT SUCCESSFULLY');
  } catch (e, stackTrace) {
    print('┃ Status: ❌ FAILED');
    print('┃ Error: $e');
    print('┃ Stack: $stackTrace');
  }
  
  print('┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
}


Future<void> showRankAdvancement(String oldRank, String newRank) async {
  print('\n┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('┃ 👑 NOTIFICATION: Rank Advancement');
  print('┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('┃ ID: 1004');
  print('┃ Rank Transition: $oldRank → $newRank');
  
  try {
    String message = _getRankAdvancementMessage(oldRank, newRank);
    print('┃ Message: $message');
    
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
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
    
    print('┃ Status: ✅ SENT SUCCESSFULLY');
  } catch (e, stackTrace) {
    print('┃ Status: ❌ FAILED');
    print('┃ Error: $e');
    print('┃ Stack: $stackTrace');
  }
  
  print('┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
}

Future<void> showStatPointAllocation(Map<String, int> statBonuses, int totalPoints) async {
  print('\n┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('┃ 📊 NOTIFICATION: Stat Point Allocation');
  print('┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('┃ ID: 1005');
  print('┃ Total Points: $totalPoints');
  print('┃ Stat Breakdown: $statBonuses');
  
  try {
    String statBreakdown = statBonuses.entries
        .where((e) => e.value > 0)
        .map((e) => '${e.key.toUpperCase()}: +${e.value}')
        .join(', ');
    
    print('┃ Formatted: $statBreakdown');
    
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
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
    
    print('┃ Status: ✅ SENT SUCCESSFULLY');
  } catch (e, stackTrace) {
    print('┃ Status: ❌ FAILED');
    print('┃ Error: $e');
    print('┃ Stack: $stackTrace');
  }
  
  print('┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
}

  String _getRankAdvancementMessage(String oldRank, String newRank) {
    Map<String, String> rankMessages = {
      'God-Mode': '🔱 You have broken the barriers of perseverance! You are entered the GOD-Mode 🔥!',
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

  // Add to your existing NotificationService class
Future<void> showNewQuestsAvailable(int count) async {
  await _notifications.show(
    2004,
    '🎯 New Quests Available!',
    'The System has generated $count new quests for your progression!',
    NotificationDetails(
      android: AndroidNotificationDetails(
        'hunter_system',
        'Hunter System Alerts',
        importance: Importance.high,
        priority: Priority.high,
        color: const Color.fromARGB(255, 238, 33, 18),
      ),
    ),
  );
}

Future<void> showDailyQuestWarning(int incompleteCount) async {
  await _notifications.show(
    2002,
    '⚠️ Daily Quest Warning!',
    'You have $incompleteCount incomplete daily quests. Complete them before midnight to avoid stat penalties!',
    NotificationDetails(
      android: AndroidNotificationDetails(
        'hunter_system',
        'Hunter System Alerts',
        importance: Importance.max,
        priority: Priority.high,
        color: const Color.fromARGB(255, 255, 152, 0),
        playSound: true,
        enableVibration: true,
      ),
    ),
  );
}

Future<void> showPenaltyNotification(String questTitle, int amount, String penaltyType) async {
  await _notifications.show(
    2003,
    '💀 PENALTY APPLIED!',
    'Failed to complete "$questTitle"\n-$amount ${penaltyType.replaceAll('_', ' ')} stats!\nThe System demands discipline!',
    NotificationDetails(
      android: AndroidNotificationDetails(
        'hunter_system',
        'Hunter System Alerts',
        importance: Importance.max,
        priority: Priority.max,
        color: const Color.fromARGB(255, 211, 47, 47),
        playSound: true,
        enableVibration: true,
      ),
    ),
  );
}

}
