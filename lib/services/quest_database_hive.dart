import 'package:hive_flutter/hive_flutter.dart';
import '../models/quest_model.dart';
// ignore: unused_import
import '../models/task_model.dart';
import 'task_database.dart';
import 'progression_analytics_hive.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

class QuestDatabaseHive {
  static const String _questBoxName = 'hunterQuests';
  static Box<QuestModel>? _questBox;
  
  // Initialize the quest database system
  static Future<void> initialize() async {
    try {
      // Register adapters if not already registered
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(QuestModelAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(DailyQuestAdapter());
      }
      
      // Open the quest box
      _questBox = await Hive.openBox<QuestModel>(_questBoxName);
      
      debugPrint('🎯 Quest Database initialized with ${_questBox!.length} quests');
    } catch (e) {
      debugPrint('❌ Error initializing Quest Database: $e');
    }
  }
  
  static Box<QuestModel> get questBox {
    if (_questBox == null || !_questBox!.isOpen) {
      throw Exception('Quest box not initialized. Call initialize() first.');
    }
    return _questBox!;
  }
  
  // Add new quest (AI-generated or manual)
  static Future<void> addQuest(QuestModel quest) async {
    try {
      await questBox.put(quest.id, quest);
      debugPrint('🎯 Added quest: ${quest.title} (${quest.questType})');
    } catch (e) {
      debugPrint('❌ Error adding quest: $e');
    }
  }
  
  // Get quests by type for tab display
  static List<QuestModel> getQuestsByType(String questType) {
    return questBox.values
        .where((quest) => quest.questType == questType)
        .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Newest first
  }
  
  // Get ongoing quests that haven't expired
  static List<QuestModel> getActiveQuests() {
    final now = DateTime.now();
    return questBox.values
        .where((quest) => 
          quest.questType == 'ongoing' && 
          !quest.isCompleted && 
          quest.expiresAt.isAfter(now))
        .toList()
        ..sort((a, b) => a.expiresAt.compareTo(b.expiresAt)); // Expiring soonest first
  }
  
  // Get today's daily quests
  static List<QuestModel> getTodaysDailyQuests() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return questBox.values
        .where((quest) => 
          quest.questType == 'daily' && 
          quest.id.contains(today))
        .toList();
  }
  
  // Complete a quest and integrate with existing stat system
  static Future<void> completeQuest(String questId, int currentLevel) async {
    try {
      final quest = questBox.get(questId);
      if (quest == null) {
        debugPrint('❌ Quest not found: $questId');
        return;
      }
      
      // Update quest as completed
      final completedQuest = quest.copyWith(
        questType: quest.questType == 'daily' ? 'daily' : 'completed',
        isCompleted: true,
        progress: 1.0,
        completedAt: DateTime.now(),
      );
      
      await questBox.put(questId, completedQuest);
      
      // Convert to TaskModel for existing stat system integration
      final taskModel = quest.toTaskModel(currentLevel);
      await TaskDatabase.addCompletedTask(taskModel);
      
      // Record in progression analytics (matches your existing system)
      if (quest.rewards.containsKey('xp')) {
        await ProgressionAnalyticsHive.recordExpGain(quest.rewards['xp']!);
      }
      
      // Record stat gains (excluding XP)
      final statDelta = Map<String, int>.from(quest.rewards);
      statDelta.remove('xp');
      if (statDelta.isNotEmpty) {
        await ProgressionAnalyticsHive.recordStatDelta(statDelta);
      }
      
      debugPrint('✅ Quest completed: ${quest.title} (+${quest.rewards['xp']} XP)');
      
    } catch (e) {
      debugPrint('❌ Error completing quest: $e');
    }
  }
  
  // Update quest progress
  static Future<void> updateQuestProgress(String questId, double progress) async {
    try {
      final quest = questBox.get(questId);
      if (quest == null) return;
      
      final updatedQuest = quest.copyWith(progress: progress.clamp(0.0, 1.0));
      await questBox.put(questId, updatedQuest);
      
      // Auto-complete if progress reaches 100%
      if (progress >= 1.0 && !quest.isCompleted) {
        // Get current level for completion
        // You might want to pass this as a parameter or get it from SharedPreferences
        await completeQuest(questId, 1); // Placeholder level
      }
      
    } catch (e) {
      debugPrint('❌ Error updating quest progress: $e');
    }
  }
  
  // Clean up expired quests (but keep completed ones for history)
  static Future<void> cleanupExpiredQuests() async {
    try {
      final now = DateTime.now();
      final expiredQuests = questBox.values
          .where((quest) => 
            quest.questType == 'ongoing' && 
            quest.expiresAt.isBefore(now) && 
            !quest.isCompleted)
          .toList();
      
      for (final quest in expiredQuests) {
        await questBox.delete(quest.id);
        debugPrint('🗑️ Removed expired quest: ${quest.title}');
      }
      
      if (expiredQuests.isNotEmpty) {
        debugPrint('🧹 Cleaned up ${expiredQuests.length} expired quests');
      }
      
    } catch (e) {
      debugPrint('❌ Error cleaning expired quests: $e');
    }
  }
  
  // Get upcoming quests based on current level
  static List<QuestModel> getUpcomingQuests(int currentLevel) {
    return questBox.values
        .where((quest) => quest.questType == 'upcoming')
        .toList()
        ..sort((a, b) => a.unlockLevel.compareTo(b.unlockLevel)); // Lowest level first
  }
  
  // Get available upcoming quests for current level
  static List<QuestModel> getAvailableUpcomingQuests(int currentLevel) {
    return getUpcomingQuests(currentLevel)
        .where((quest) => quest.unlockLevel <= currentLevel)
        .toList();
  }
  
  // Archive old completed quests to maintain performance
  static Future<void> archiveOldQuests({int daysOld = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      final oldQuests = questBox.values
          .where((quest) => 
            quest.questType == 'completed' && 
            quest.completedAt != null &&
            quest.completedAt!.isBefore(cutoffDate))
          .toList();
      
      for (final quest in oldQuests) {
        await questBox.delete(quest.id);
      }
      
      if (oldQuests.isNotEmpty) {
        debugPrint('📦 Archived ${oldQuests.length} old completed quests');
      }
      
    } catch (e) {
      debugPrint('❌ Error archiving old quests: $e');
    }
  }
  
  // Get quest statistics
  static Map<String, int> getQuestStats() {
    final allQuests = questBox.values.toList();
    
    return {
      'total': allQuests.length,
      'ongoing': allQuests.where((q) => q.questType == 'ongoing' && !q.isCompleted).length,
      'completed': allQuests.where((q) => q.isCompleted).length,
      'upcoming': allQuests.where((q) => q.questType == 'upcoming').length,
      'daily': allQuests.where((q) => q.questType == 'daily').length,
      'expired': allQuests.where((q) => q.hasExpired && !q.isCompleted).length,
    };
  }
  
  // Get quest by ID
  static QuestModel? getQuestById(String questId) {
    return questBox.get(questId);
  }
  
  // Delete specific quest
  static Future<void> deleteQuest(String questId) async {
    try {
      await questBox.delete(questId);
      debugPrint('🗑️ Deleted quest: $questId');
    } catch (e) {
      debugPrint('❌ Error deleting quest: $e');
    }
  }
  
  // Clear all quests (for testing/reset)
  static Future<void> clearAllQuests() async {
    try {
      await questBox.clear();
      debugPrint('🧹 Cleared all quests');
    } catch (e) {
      debugPrint('❌ Error clearing all quests: $e');
    }
  }
  
  // Export quests for debugging
  static List<Map<String, dynamic>> exportQuestsToJson() {
    return questBox.values.map((quest) => quest.toJson()).toList();
  }
  
  // Get memory usage info
  static Map<String, dynamic> getMemoryInfo() {
    return {
      'questCount': questBox.length,
      'boxSizeBytes': questBox.values.length * 1024, // Rough estimate
      'lastAccessed': DateTime.now().toIso8601String(),
    };
  }
}
