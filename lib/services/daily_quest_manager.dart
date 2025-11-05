import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'quest_database_hive.dart';
import '../models/quest_model.dart';
import 'progression_analytics_hive.dart';
import 'notification_service.dart';
import 'package:intl/intl.dart';

class DailyQuestManager {
  static DailyQuestManager? _instance;
  static DailyQuestManager get instance => _instance ??= DailyQuestManager._();
  DailyQuestManager._();
  
  final NotificationService _notificationService = NotificationService();
  Timer? _midnightTimer;
  Timer? _warningTimer;
  
  // Initialize daily quest system
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  
  Future<void> initialize() async {
    if (_isInitialized) return; 
    
    print(' Initializing Daily Quest Manager...');
    await _checkAndResetDailyQuests();
    await _scheduleDailyReset();
    await _scheduleWarnings();
    
    _isInitialized = true; 
    print('Daily Quest Manager ready!');
  }

  
  
  // Generate Sung Jin-Woo style daily quests
  Future<void> _generateDailyQuests() async {
    final prefs = await SharedPreferences.getInstance();
    final currentLevel = prefs.getInt('level') ?? 1;
    final userGoal = prefs.getString('fitnessGoal') ?? 'Overall Development';
    
    // Base difficulty scales with level
    final baseReps = 20 + (currentLevel * 2);
    final baseDistance = 1.0 + (currentLevel * 0.2); // km
    final baseDuration = 10 + currentLevel; // minutes
    
    final today = _getTodayKey();
    
    final dailyQuests = [
      // Physical Training (like Sung Jin-Woo's pushups)
      QuestModel(
        id: 'daily_physical_$today',
        title: '⚔️ Hunter\'s Physical Training',
        description: 'Complete your daily physical conditioning to maintain hunter readiness',
        questType: 'daily',
        difficulty: 'E',
        objectives: [
          'Complete ${baseReps.toInt()} push-ups (can be spread throughout day)',
          'Walk/Run ${baseDistance.toStringAsFixed(1)}km total distance',
          'Hold plank for $baseDuration seconds',
        ],
        rewards: {
          'xp': 100 + (currentLevel * 10),
          'strength': 2,
          'endurance': 2,
          'vitality': 1,
        },
        category: 'mandatory',
        createdAt: DateTime.now(),
        expiresAt: _getNextMidnight(),
        isMandatory: true,
        penaltyAmount: 2,
        penaltyType: 'physical_stats',
      ),
      
      // Mental Training (adapted for user's goal)
      QuestModel(
        id: 'daily_mental_$today',
        title: '🧠 Hunter\'s Mental Conditioning',
        description: 'Sharpen your mind to handle the challenges ahead',
        questType: 'daily',
        difficulty: 'E',
        objectives: _getMentalObjectives(userGoal, currentLevel),
        rewards: {
          'xp': 75 + (currentLevel * 5),
          'intelligence': 2,
          'vitality': 1,
        },
        category: 'mandatory',
        createdAt: DateTime.now(),
        expiresAt: _getNextMidnight(),
        isMandatory: true,
        penaltyAmount: 1,
        penaltyType: 'intelligence',
      ),
      
      // Daily Discipline (habit building)
      QuestModel(
        id: 'daily_discipline_$today',
        title: '🎯 Hunter\'s Daily Discipline',
        description: 'Maintain the discipline that separates hunters from civilians',
        questType: 'daily',
        difficulty: 'E',
        objectives: [
          'Wake up before 8:00 AM',
          'Drink 8 glasses of water',
          'Complete all tasks without procrastination',
        ],
        rewards: {
          'xp': 50 + (currentLevel * 5),
          'vitality': 1,
          'intelligence': 1,
        },
        category: 'mandatory',
        createdAt: DateTime.now(),
        expiresAt: _getNextMidnight(),
        isMandatory: true,
        penaltyAmount: 1,
        penaltyType: 'all_stats',
      ),
    ];
    
    // Store daily quests
    for (final quest in dailyQuests) {
      await QuestDatabaseHive.addQuest(quest);
    }
    
    print('🎯 Generated ${dailyQuests.length} daily quests for $today');
  }
  
  List<String> _getMentalObjectives(String userGoal, int level) {
    final readingTime = 15 + (level * 2);
    
    switch (userGoal.toLowerCase()) {
      case 'brain enhancement':
      case 'brain activity enhancement':
      case 'intelligence':
        return [
          'Read educational content for $readingTime minutes',
          'Solve 5 logic puzzles or brain teasers',
          'Memorize 10 new vocabulary words or facts',
        ];
      case 'strength enhancement':
      case 'physical':
        return [
          'Study exercise techniques for $readingTime minutes',
          'Plan tomorrow\'s workout routine',
          'Learn about nutrition and recovery',
        ];
      default:
        return [
          'Read any educational material for $readingTime minutes',
          'Practice mindfulness or meditation for 10 minutes',
          'Reflect on today\'s progress and plan tomorrow',
        ];
    }
  }
  
  // Check and reset daily quests at midnight
  Future<void> _checkAndResetDailyQuests() async {
    final prefs = await SharedPreferences.getInstance();
    final lastReset = prefs.getString('lastDailyReset') ?? '';
    final today = _getTodayKey();
    
    if (lastReset != today) {
      print('🌅 New day detected - resetting daily quests');
      
      // Check for incomplete daily quests from yesterday
      await _applyPenaltiesForIncompleteQuests();
      
      // Clear old daily quests
      await _clearOldDailyQuests();
      
      // Generate new daily quests
      await _generateDailyQuests();
      
      // Update last reset date
      await prefs.setString('lastDailyReset', today);
    }
  }
  
  // Apply penalties for incomplete daily quests (like Sung Jin-Woo's penalty)
  Future<void> _applyPenaltiesForIncompleteQuests() async {
    final yesterday = _getYesterdayKey();
    final incompleteQuests = QuestDatabaseHive.questBox.values
        .where((quest) => 
          quest.questType == 'daily' && 
          quest.id.contains(yesterday) && 
          !quest.isCompleted &&
          quest.isMandatory)
        .toList();
    
    if (incompleteQuests.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      
      for (final quest in incompleteQuests) {
        // Apply stat penalty
        await _applyStatPenalty(quest.penaltyType, quest.penaltyAmount, prefs);
        
        // Show penalty notification
        await _notificationService.showPenaltyNotification(
          quest.title,
          quest.penaltyAmount,
          quest.penaltyType,
        );
      }
      
      print('⚠️ Applied penalties for ${incompleteQuests.length} incomplete daily quests');
    }
  }
  
  Future<void> _applyStatPenalty(String penaltyType, int amount, SharedPreferences prefs) async {
    switch (penaltyType) {
      case 'all_stats':
        await _reduceAllStats(amount, prefs);
      case 'physical_stats':
        await _reduceStat('strengthStat', amount, prefs);
        await _reduceStat('enduranceStat', amount, prefs);
        await _reduceStat('vitalityStat', amount, prefs);
      case 'intelligence':
        await _reduceStat('intelligenceStat', amount, prefs);
      default:
        await _reduceStat('${penaltyType}Stat', amount, prefs);
    }
    
    // Record penalty in analytics
    await ProgressionAnalyticsHive.recordStatDelta({
      'penalty_$penaltyType': -amount,
    });
  }
  
  Future<void> _reduceAllStats(int amount, SharedPreferences prefs) async {
    final stats = ['strengthStat', 'agilityStat', 'enduranceStat', 'vitalityStat', 'intelligenceStat'];
    for (final stat in stats) {
      await _reduceStat(stat, amount, prefs);
    }
  }
  
  Future<void> _reduceStat(String statKey, int amount, SharedPreferences prefs) async {
    final currentValue = prefs.getInt(statKey) ?? 30;
    final newValue = (currentValue - amount).clamp(1, 999); // Don't go below 1
    await prefs.setInt(statKey, newValue);
    print('💀 Reduced $statKey by $amount ($currentValue → $newValue)');
  }
  
  // Schedule daily reset at midnight
  Future<void> _scheduleDailyReset() async {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = tomorrow.difference(now);
    
    _midnightTimer = Timer(timeUntilMidnight, () {
      _checkAndResetDailyQuests();
      
      // Schedule next day
      _midnightTimer = Timer.periodic(Duration(days: 1), (timer) {
        _checkAndResetDailyQuests();
      });
    });
    
    print('⏰ Midnight reset scheduled in ${timeUntilMidnight.inHours}h ${timeUntilMidnight.inMinutes % 60}m');
  }
  
  // Schedule warning notifications
  Future<void> _scheduleWarnings() async {
    // Warning at 8 PM if daily quests not completed
    _warningTimer = Timer.periodic(Duration(hours: 1), (timer) async {
      final now = DateTime.now();
      if (now.hour == 20) { // 8 PM
        await _checkAndWarnIncompleteQuests();
      }
    });
  }
  
  Future<void> _checkAndWarnIncompleteQuests() async {
    final today = _getTodayKey();
    final incompleteQuests = QuestDatabaseHive.questBox.values
        .where((quest) => 
          quest.questType == 'daily' && 
          quest.id.contains(today) && 
          !quest.isCompleted)
        .toList();
    
    if (incompleteQuests.isNotEmpty) {
      await _notificationService.showDailyQuestWarning(incompleteQuests.length);
    }
  }
  
  String _getTodayKey() => DateFormat('yyyy-MM-dd').format(DateTime.now());
  String _getYesterdayKey() => DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(Duration(days: 1)));
  
  DateTime _getNextMidnight() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1);
  }
  
  Future<void> _clearOldDailyQuests() async {
    final oldQuests = QuestDatabaseHive.questBox.values
        .where((quest) => quest.questType == 'daily' && quest.expiresAt.isBefore(DateTime.now()))
        .toList();
    
    for (final quest in oldQuests) {
      await QuestDatabaseHive.questBox.delete(quest.id);
    }
  }
  
  void dispose() {
    _midnightTimer?.cancel();
    _warningTimer?.cancel();
  }
}
