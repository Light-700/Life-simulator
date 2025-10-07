import 'dart:async';
import 'package:flutter/foundation.dart';
import 'quest_database_hive.dart';
import 'gemini_quest_service.dart';
import 'notification_service.dart';
import '../models/quest_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DynamicQuestManager {
  static DynamicQuestManager? _instance;
  static DynamicQuestManager get instance => _instance ??= DynamicQuestManager._();
  DynamicQuestManager._();
  
  final GeminiQuestService _aiService = GeminiQuestService();
  final NotificationService _notificationService = NotificationService();
  
  Timer? _questMonitorTimer;
  Timer? _weeklyQuestTimer;
  
  static const int MIN_ACTIVE_QUESTS = 3;
  static const int MAX_ACTIVE_QUESTS = 6;
  static const int MIN_UPCOMING_QUESTS = 5;
  
  bool _isInitialized = false; 
  bool get isInitialized => _isInitialized;
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    print('🎯 Initializing Dynamic Quest Manager...');
    await _startQuestMonitoring();
    await _startWeeklyUpcomingGeneration();
    await _initialQuestCheck();
    
    _isInitialized = true;
    print('✅ Dynamic Quest Manager ready!');
  }
  
  // Check and replenish quests every 30 minutes
  Future<void> _startQuestMonitoring() async {
    _questMonitorTimer = Timer.periodic(Duration(minutes: 30), (timer) async {
      await _replenishActiveQuests();
    });
    print('⏰ Quest monitoring started (every 30 minutes)');
  }
  
  // Generate upcoming quests every week
  Future<void> _startWeeklyUpcomingGeneration() async {
    _weeklyQuestTimer = Timer.periodic(Duration(days: 7), (timer) async {
      await _generateUpcomingQuests();
    });
    print('📅 Weekly upcoming quest generation scheduled');
  }
  
  // Initial check on app start
  Future<void> _initialQuestCheck() async {
    await _replenishActiveQuests();
    
    // Check if we need upcoming quests
    final prefs = await SharedPreferences.getInstance();
    final currentLevel = prefs.getInt('level') ?? 1;
    final upcomingQuests = QuestDatabaseHive.getUpcomingQuests(currentLevel);
    
    if (upcomingQuests.length < MIN_UPCOMING_QUESTS) {
      print('🔮 Need more upcoming quests, generating...');
      await _generateUpcomingQuests();
    }
  }
  
  // Core quest replenishment logic
  Future<void> _replenishActiveQuests() async {
    try {
      // Clean expired quests first
      await QuestDatabaseHive.cleanupExpiredQuests();
      
      final activeQuests = QuestDatabaseHive.getActiveQuests();
      
      if (activeQuests.length < MIN_ACTIVE_QUESTS) {
        final questsNeeded = MIN_ACTIVE_QUESTS - activeQuests.length;
        print('🎯 System: Replenishing $questsNeeded quests for the Hunter');
        
        // Try to promote upcoming quests first
        await _promoteUpcomingQuests(questsNeeded);
        
        // If still need more quests, generate new ones
        final stillNeeded = MIN_ACTIVE_QUESTS - QuestDatabaseHive.getActiveQuests().length;
        if (stillNeeded > 0) {
          await _generateImmediateQuests(stillNeeded);
        }
        
        // Notify user about new quests
        await _notificationService.showNewQuestsAvailable(questsNeeded);
      }
    } catch (e) {
      debugPrint('Error replenishing quests: $e');
    }
  }
  
  // Promote upcoming quests to active when needed
  Future<void> _promoteUpcomingQuests(int needed) async {
    final prefs = await SharedPreferences.getInstance();
    final currentLevel = prefs.getInt('level') ?? 1;
    
    final upcomingQuests = QuestDatabaseHive.getAvailableUpcomingQuests(currentLevel)
        .take(needed)
        .toList();
    
    for (final quest in upcomingQuests) {
      final activeQuest = quest.copyWith(
        questType: 'ongoing',
        metadata: {
          ...?quest.metadata,
          'promotedAt': DateTime.now().toIso8601String(),
        },
      );
      
      await QuestDatabaseHive.addQuest(activeQuest);
      print('⬆️ Promoted quest to active: ${quest.title}');
    }
  }
  
  // Generate immediate quests when promotion isn't enough
  Future<void> _generateImmediateQuests(int needed) async {
    try {
      final newQuests = await _aiService.generateSpecificQuests(
        count: needed,
        urgency: 'immediate',
      );
      
      for (final quest in newQuests) {
        await QuestDatabaseHive.addQuest(quest);
      }
      
      print('🤖 Generated $needed immediate AI quests');
    } catch (e) {
      debugPrint('AI quest generation failed: $e');
      await _generateFallbackQuests(needed);
    }
  }
  
  // Fallback quest generation if AI fails
  Future<void> _generateFallbackQuests(int needed) async {
    final now = DateTime.now();
    final expiresAt = now.add(Duration(hours: 24));
    
    for (int i = 0; i < needed; i++) {
      final quest = QuestModel(
        id: 'fallback_${now.millisecondsSinceEpoch}_$i',
        title: '🏃‍♂️ Basic Hunter Training',
        description: 'Complete basic training to maintain your hunter abilities',
        questType: 'ongoing',
        difficulty: 'E',
        objectives: ['Complete 15 push-ups', 'Walk for 10 minutes'],
        rewards: {'xp': 40, 'strength': 1, 'endurance': 1},
        category: 'main',
        createdAt: now,
        expiresAt: expiresAt,
      );
      
      await QuestDatabaseHive.addQuest(quest);
    }
    
    print('🛡️ Generated $needed fallback quests');
  }
  
  // Generate upcoming quests for future progression
  Future<void> _generateUpcomingQuests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentLevel = prefs.getInt('level') ?? 1;
      
      final upcomingQuests = await _aiService.generateUpcomingQuests(
        currentLevel: currentLevel,
        count: 10,
      );
      
      for (final quest in upcomingQuests) {
        await QuestDatabaseHive.addQuest(quest);
      }
      
      print('🔮 Generated ${upcomingQuests.length} upcoming quests for future levels');
    } catch (e) {
      debugPrint('Error generating upcoming quests: $e');
    }
  }
  
  // Triggered when a quest is completed
  Future<void> onQuestCompleted(String questId) async {
    print('✅ Quest completed: $questId');
    
    // Immediate replenishment check after a short delay
    Timer(Duration(seconds: 5), () async {
      await _replenishActiveQuests();
    });
  }
  
  // Manual trigger for quest generation (for testing)
  Future<void> forceGenerateQuests() async {
    print('🔄 Force generating quests...');
    await _replenishActiveQuests();
  }
  
  // Get current quest manager status
  Map<String, dynamic> getStatus() {
    final questStats = QuestDatabaseHive.getQuestStats();
    return {
      'activeQuests': questStats['ongoing'] ?? 0,
      'upcomingQuests': questStats['upcoming'] ?? 0,
      'completedQuests': questStats['completed'] ?? 0,
      'totalQuests': questStats['total'] ?? 0,
      'monitoringActive': _questMonitorTimer?.isActive ?? false,
      'weeklyGenerationActive': _weeklyQuestTimer?.isActive ?? false,
    };
  }
  
  void dispose() {
    _questMonitorTimer?.cancel();
    _weeklyQuestTimer?.cancel();
  }
}
