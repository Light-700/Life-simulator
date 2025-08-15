import 'package:hive_flutter/hive_flutter.dart';
import '../models/task_model.dart';
import 'lightweight_hunter_cache.dart';
import 'package:flutter/foundation.dart';

class TaskDatabase {
  static const String _boxName = 'hunterTasks';
  static Box<TaskModel>? _taskBox;
  static final LightweightHunterCache _cache = LightweightHunterCache();
  
  static Future<void> initialize() async {
    await Hive.initFlutter();
    Hive.registerAdapter(TaskModelAdapter());
    _taskBox = await Hive.openBox<TaskModel>(_boxName);
    
    // Build cache from existing data - CRITICAL STEP
    await _buildCacheFromExistingData();
  }

  static Box<TaskModel> get taskBox {
    if (_taskBox == null || !_taskBox!.isOpen) {
      throw Exception('Task box not initialized. Call initialize() first.');
    }
    return _taskBox!;
  }

  /// UPDATED: Add task with cache integration
  static Future<void> addCompletedTask(TaskModel task) async {
    await taskBox.put(task.id, task);
    // Update cache counters for O(1) future lookups
    _cache.incrementTaskType(task.taskType, task.completedAtLevel);
  }

  /// NEW: O(1) task type count lookup
  static int getTaskTypeCountFast(String taskType) {
    return _cache.getTaskTypeCount(taskType);
  }

  /// NEW: O(1) level task count lookup  
  static int getTaskCountAtLevel(int level) {
    return _cache.getTaskCountAtLevel(level);
  }

  /// UPDATED: Optimized level range query with caching
  static List<TaskModel> getTasksBetweenLevels(int fromLevel, int toLevel) {
    // For the lightweight version, we still do the query but cache the counts
    // This maintains data accuracy while providing fast counter access
    return taskBox.values
        .where((task) => task.completedAtLevel >= fromLevel && task.completedAtLevel < toLevel)
        .toList();
  }

  /// NEW: Fast stat calculation with caching
  static Map<String, int> calculateStatsWithCache(int totalPoints, int fromLevel, int toLevel) {
    // Try cache first
    Map<String, int>? cached = _cache.getCachedStats(totalPoints, fromLevel, toLevel);
    if (cached != null) {
      return cached;
    }

    // Calculate using optimized counters
    final result = _calculateStatsUsingCounters(totalPoints, fromLevel, toLevel);
    
    // Cache the result
    _cache.cacheStats(totalPoints, fromLevel, toLevel, result);
    
    return result;
  }

  /// NEW: Calculate stats using cached counters instead of full queries
  static Map<String, int> _calculateStatsUsingCounters(int totalPoints, int fromLevel, int toLevel) {
    // Use cached task type ratios instead of expensive queries
    final strengthCount = _cache.getTaskTypeCount('strength');
    final agilityCount = _cache.getTaskTypeCount('agility'); 
    final enduranceCount = _cache.getTaskTypeCount('endurance');
    final vitalityCount = _cache.getTaskTypeCount('vitality');
    final intelligenceCount = _cache.getTaskTypeCount('intelligence');
    
    final totalTasks = strengthCount + agilityCount + enduranceCount + vitalityCount + intelligenceCount;
    
    if (totalTasks == 0) {
      // Equal distribution fallback
      final per = (totalPoints / 5).floor();
      return {
        'strength': per,
        'agility': per,
        'endurance': per,
        'vitality': per,
        'intelligence': per,
      };
    }

    // Estimate level-range distribution based on overall ratios
    int tasksInRange = 0;
    for (int level = fromLevel; level < toLevel; level++) {
      tasksInRange += _cache.getTaskCountAtLevel(level);
    }

    if (tasksInRange == 0) tasksInRange = 1; // Prevent division by zero

    // Proportional distribution
    return {
      'strength': ((strengthCount / totalTasks) * totalPoints).round(),
      'agility': ((agilityCount / totalTasks) * totalPoints).round(),
      'endurance': ((enduranceCount / totalTasks) * totalPoints).round(),
      'vitality': ((vitalityCount / totalTasks) * totalPoints).round(),
      'intelligence': ((intelligenceCount / totalTasks) * totalPoints).round(),
    };
  }

  /// NEW: Build cache from existing Hive data
  static Future<void> _buildCacheFromExistingData() async {
    final allTasks = taskBox.values;
    print('🔧 Building cache from ${allTasks.length} existing tasks...');
    
    for (final task in allTasks) {
      _cache.incrementTaskType(task.taskType, task.completedAtLevel);
    }
    
    final memStats = _cache.getMemoryStats();
    debugPrint('!!! ==> Cache built: ${memStats['totalMemoryUsage']} memory usage');
  }

  /// UPDATED: Delete with cache maintenance
  static Future<void> deleteTask(String taskId) async {
    final task = taskBox.get(taskId);
    if (task != null) {
      await taskBox.delete(taskId);
      // Rebuild cache counters (since we can't easily decrement)
      await _rebuildCache();
    }
  }

  /// NEW: Rebuild cache when needed
  static Future<void> _rebuildCache() async {
    _cache.dispose();
    await _buildCacheFromExistingData();
  }

  /// NEW: Memory usage monitoring
  static Map<String, dynamic> getMemoryUsage() {
    return _cache.getMemoryStats();
  }

  /// NEW: Memory optimization
  static void optimizeMemory() {
    _cache.compactMemory();
  }

  // Keep existing methods for compatibility
  static List<TaskModel> getAllTasks() {
    return taskBox.values.toList();
  }

  static List<TaskModel> getTasksByTypeInRange(String taskType, int fromLevel, int toLevel) {
    return taskBox.values
        .where((task) =>
            task.taskType == taskType &&
            task.completedAtLevel >= fromLevel &&
            task.completedAtLevel < toLevel)
        .toList();
  }

  static Future<void> clearAllTasks() async {
    await taskBox.clear();
    _cache.dispose();
  }
}
