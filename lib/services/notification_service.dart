import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

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
    
    await _notifications.initialize(settings);
    
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
          'quest_completion',
          'Quest Completion',
          channelDescription: 'Notifications for completed quests and tasks',
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
          'level_up',
          'Level Up',
          channelDescription: 'Notifications for level advancement',
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
          'power_spike',
          'Power Spike',
          channelDescription: 'Notifications for massive level gains',
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
          'rank_advancement',
          'Rank Advancement',
          channelDescription: 'Notifications for hunter rank promotions',
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
          'stat_allocation',
          'Stat Allocation',
          channelDescription: 'Notifications for stat point distribution',
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
    
    return rankMessages[newRank] ?? 'Your Hunter ranking has improved!';
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
