import 'package:hive_flutter/hive_flutter.dart';
import '../models/task_model.dart';
import 'dart:async';

class TaskDatabase {
  static const String _boxName = 'hunterTasks';
  static const String _indexBoxName = 'hunterTasksIndex';
  static Box<TaskModel>? _taskBox;
  static Box<Map<String, dynamic>>? _indexBox;
  
  // Performance caches
  static final Map<String, List<TaskModel>> _queryCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 10);
  
  // Task type counters for quick stats
  static final Map<String, int> _taskTypeCounters = {
    'Strength': 0,
    'Agility': 0,
    'Endurance': 0,
    'Vitality': 0,
    'Intelligence': 0,
  };

  static Future<void> initialize() async {
    await Hive.initFlutter();
    Hive.registerAdapter(TaskModelAdapter());
    
    _taskBox = await Hive.openBox<TaskModel>(_boxName);
    _indexBox = await Hive.openBox<Map<String, dynamic>>(_indexBoxName);
    
    // Build initial indexes and caches
    await _buildIndexes();
    await _loadTaskTypeCounters();
  }

  static Box<TaskModel> get taskBox {
    if (_taskBox == null || !_taskBox!.isOpen) {
      throw Exception('Task box not initialized. Call initialize() first.');
    }
    return _taskBox!;
  }

  static Box<Map<String, dynamic>> get indexBox {
    if (_indexBox == null || !_indexBox!.isOpen) {
      throw Exception('Index box not initialized. Call initialize() first.');
    }
    return _indexBox!;
  }

  // High-performance task addition with indexing
  static Future<void> addCompletedTask(TaskModel task) async {
    // Add to main storage
    await taskBox.put(task.id, task);
    
    // Update indexes for fast queries
    await _updateIndexes(task);
    
    // Update type counters
    final normalizedType = _normalizeTaskType(task.taskType);
    _taskTypeCounters[normalizedType] = 
        (_taskTypeCounters[normalizedType] ?? 0) + 1;
    
    // Clear related caches
    _clearRelevantCaches(task.completedAtLevel);
    
    // Persist counters
    await _saveTaskTypeCounters();
  }

  // Optimized level-based query with caching and indexing
  static Future<List<TaskModel>> getTasksBetweenLevels(int fromLevel, int toLevel) async {
    final cacheKey = 'levels_${fromLevel}_$toLevel';
    
    // Check cache first
    if (_isCacheValid(cacheKey)) {
      return _queryCache[cacheKey]!;
    }

    List<TaskModel> results;
    
    // Try to use index for faster query
    final indexKey = 'level_range_${fromLevel}_$toLevel';
    final indexedIds = indexBox.get(indexKey);
    
    if (indexedIds != null && indexedIds['ids'] is List) {
      // Use indexed IDs for O(1) lookup instead of O(n) scan
      results = (indexedIds['ids'] as List<String>)
          .map((id) => taskBox.get(id))
          .where((task) => task != null)
          .cast<TaskModel>()
          .toList();
    } else {
      // Fallback to direct query with optimization
      results = taskBox.values
          .where((task) => task.completedAtLevel >= fromLevel && 
                          task.completedAtLevel < toLevel)
          .take(1000) // Limit results to prevent memory issues
          .toList();
      
      // Cache the IDs for future queries
      await _cacheQueryIndex(indexKey, results.map((t) => t.id).toList());
    }

    // Cache the results
    _queryCache[cacheKey] = results;
    _cacheTimestamps[cacheKey] = DateTime.now();

    return results;
  }

  // Super-fast type-based query using counters and indexes
  static List<TaskModel> getTasksByTypeInRange(
    String taskType, 
    int fromLevel, 
    int toLevel
  ) {
    final normalizedType = _normalizeTaskType(taskType);
    final cacheKey = 'type_${normalizedType}_${fromLevel}_$toLevel';
    
    if (_isCacheValid(cacheKey)) {
      return _queryCache[cacheKey]!;
    }

    // Use type-specific index for faster queries
    final indexKey = 'type_${normalizedType}_levels';
    final typeIndex = indexBox.get(indexKey);
    
    List<TaskModel> results;
    
    if (typeIndex != null && typeIndex['levels'] is Map) {
      // Use level-indexed type data
      final levelMap = typeIndex['levels'] as Map<String, List<String>>;
      final relevantIds = <String>[];
      
      for (int level = fromLevel; level < toLevel; level++) {
        final levelIds = levelMap[level.toString()];
        if (levelIds != null) {
          relevantIds.addAll(levelIds);
        }
      }
      
      results = relevantIds
          .map((id) => taskBox.get(id))
          .where((task) => task != null)
          .cast<TaskModel>()
          .toList();
    } else {
      // Fallback query
      results = taskBox.values
          .where((task) => 
              _normalizeTaskType(task.taskType) == normalizedType &&
              task.completedAtLevel >= fromLevel && 
              task.completedAtLevel < toLevel)
          .take(500)
          .toList();
    }

    _queryCache[cacheKey] = results;
    _cacheTimestamps[cacheKey] = DateTime.now();

    return results;
  }

  // Get task type distribution quickly using cached counters
  static Map<String, int> getTaskTypeDistribution() {
    return Map<String, int>.from(_taskTypeCounters);
  }

  // Optimized stats calculation using cached data
  static Map<String, double> getTaskTypePercentages() {
    final total = _taskTypeCounters.values.fold<int>(0, (sum, count) => sum + count);
    if (total == 0) return {};
    
    return _taskTypeCounters.map((key, value) => 
        MapEntry(key, (value / total) * 100));
  }

  static List<TaskModel> getAllTasks() {
    return taskBox.values.toList();
  }

  static Future<void> deleteTask(String taskId) async {
    final task = taskBox.get(taskId);
    if (task != null) {
      await taskBox.delete(taskId);
      await _removeFromIndexes(task);
      
      // Update counters
      final normalizedType = _normalizeTaskType(task.taskType);
      _taskTypeCounters[normalizedType] = 
          (_taskTypeCounters[normalizedType] ?? 1) - 1;
      
      await _saveTaskTypeCounters();
      _clearRelevantCaches(task.completedAtLevel);
    }
  }

  static Future<void> clearAllTasks() async {
    await taskBox.clear();
    await indexBox.clear();
    _queryCache.clear();
    _cacheTimestamps.clear();
    _taskTypeCounters.updateAll((key, value) => 0);
    await _saveTaskTypeCounters();
  }

  // Build comprehensive indexes for fast queries
  static Future<void> _buildIndexes() async {
    final levelIndex = <int, List<String>>{};
    final typeIndexes = <String, Map<int, List<String>>>{};
    
    for (final task in taskBox.values) {
      final level = task.completedAtLevel;
      final normalizedType = _normalizeTaskType(task.taskType);
      
      // Level index
      levelIndex.putIfAbsent(level, () => []).add(task.id);
      
      // Type-level index
      typeIndexes.putIfAbsent(normalizedType, () => {})
          .putIfAbsent(level, () => []).add(task.id);
    }

    // Save level indexes
    for (final entry in levelIndex.entries) {
      await indexBox.put('level_${entry.key}', {'ids': entry.value});
    }

    // Save type indexes
    for (final typeEntry in typeIndexes.entries) {
      final levelMap = typeEntry.value.map((level, ids) => 
          MapEntry(level.toString(), ids));
      await indexBox.put('type_${typeEntry.key}_levels', {'levels': levelMap});
    }
  }

  static Future<void> _updateIndexes(TaskModel task) async {
    final level = task.completedAtLevel;
    final normalizedType = _normalizeTaskType(task.taskType);
    
    // Update level index
    final levelIndexKey = 'level_$level';
    final levelIndex = indexBox.get(levelIndexKey) ?? {'ids': <String>[]};
    (levelIndex['ids'] as List<String>).add(task.id);
    await indexBox.put(levelIndexKey, levelIndex);
    
    // Update type-level index
    final typeIndexKey = 'type_${normalizedType}_levels';
    final typeIndex = indexBox.get(typeIndexKey) ?? {'levels': <String, List<String>>{}};
    final levelMap = typeIndex['levels'] as Map<String, List<String>>;
    levelMap.putIfAbsent(level.toString(), () => []).add(task.id);
    await indexBox.put(typeIndexKey, typeIndex);
  }

  static Future<void> _removeFromIndexes(TaskModel task) async {
    final level = task.completedAtLevel;
    final normalizedType = _normalizeTaskType(task.taskType);
    
    // Remove from level index
    final levelIndexKey = 'level_$level';
    final levelIndex = indexBox.get(levelIndexKey);
    if (levelIndex != null) {
      (levelIndex['ids'] as List<String>).remove(task.id);
      await indexBox.put(levelIndexKey, levelIndex);
    }
    
    // Remove from type-level index
    final typeIndexKey = 'type_${normalizedType}_levels';
    final typeIndex = indexBox.get(typeIndexKey);
    if (typeIndex != null) {
      final levelMap = typeIndex['levels'] as Map<String, List<String>>;
      levelMap[level.toString()]?.remove(task.id);
      await indexBox.put(typeIndexKey, typeIndex);
    }
  }

  static Future<void> _cacheQueryIndex(String indexKey, List<String> ids) async {
    await indexBox.put(indexKey, {'ids': ids});
  }

  static Future<void> _loadTaskTypeCounters() async {
    final savedCounters = indexBox.get('task_type_counters');
    // ignore: unnecessary_type_check
    if (savedCounters != null && savedCounters is Map<String, dynamic>) {
      savedCounters.forEach((key, value) {
        if (_taskTypeCounters.containsKey(key) && value is int) {
          _taskTypeCounters[key] = value;
        }
      });
    } else {
      // Build counters from scratch
      for (final task in taskBox.values) {
        final normalizedType = _normalizeTaskType(task.taskType);
        _taskTypeCounters[normalizedType] = 
            (_taskTypeCounters[normalizedType] ?? 0) + 1;
      }
      await _saveTaskTypeCounters();
    }
  }

  static Future<void> _saveTaskTypeCounters() async {
    await indexBox.put('task_type_counters', Map<String, dynamic>.from(_taskTypeCounters));
  }

  static bool _isCacheValid(String cacheKey) {
    final cachedTime = _cacheTimestamps[cacheKey];
    return cachedTime != null && 
           DateTime.now().difference(cachedTime).compareTo(_cacheExpiry) < 0 &&
           _queryCache.containsKey(cacheKey);
  }

  static void _clearRelevantCaches(int level) {
    final keysToRemove = _queryCache.keys.where((key) => 
        key.contains('levels_') && key.contains('_${level}_')).toList();
    
    for (final key in keysToRemove) {
      _queryCache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  static String _normalizeTaskType(String taskType) {
    switch (taskType.toLowerCase()) {
      case 'strength':
      case 'physical':
      case 'workout':
        return 'Strength';
      case 'agility':
      case 'speed':
      case 'sports':
        return 'Agility';
      case 'endurance':
      case 'cardio':
      case 'stamina':
        return 'Endurance';
      case 'vitality':
      case 'health':
      case 'nutrition':
        return 'Vitality';
      case 'intelligence':
      case 'study':
      case 'brain':
      case 'mental':
        return 'Intelligence';
      default:
        return 'Intelligence';
    }
  }

  // Analytics methods for better insights
  static Map<String, dynamic> getTaskAnalytics() {
    final total = taskBox.length;
    final distribution = getTaskTypeDistribution();
    final percentages = getTaskTypePercentages();
    
    return {
      'totalTasks': total,
      'typeDistribution': distribution,
      'typePercentages': percentages,
      'cacheHitRate': _calculateCacheHitRate(),
    };
  }

  static double _calculateCacheHitRate() {
    // Simplified cache hit rate calculation
    final totalQueries = _queryCache.length + _cacheTimestamps.length;
    return totalQueries > 0 ? _queryCache.length / totalQueries : 0.0;
  }
}
