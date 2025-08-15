import 'dart:collection';
// ignore: unused_import
import '../models/task_model.dart';


class LightweightHunterCache {
  static final LightweightHunterCache _instance = LightweightHunterCache._internal();
  factory LightweightHunterCache() => _instance;
  LightweightHunterCache._internal();
  
  // Instead of full Redis-like cache, using targeted micro-caches
  final Map<String, int> _taskTypeCounts = <String, int>{}; // ~40 bytes max
  final Map<int, int> _levelTaskCounts = <int, int>{}; // ~400 bytes for 100 levels
  
  // LRU cache with strict size limits
  final LinkedHashMap<String, dynamic> _hotCache = LinkedHashMap<String, dynamic>();
  static const int _maxHotCacheSize = 50; // Only 50 most recent items
  
  // Lightweight stat cache (expires quickly)
  String? _cachedStatKey;
  Map<String, int>? _cachedStatResult;
  DateTime? _statCacheTime;
  static const Duration _statCacheLife = Duration(minutes: 2);

  void incrementTaskType(String taskType, int level) {
    final normalizedType = _normalizeTaskType(taskType);
    
    // Updating counters ->tiny memory footprint
    _taskTypeCounts[normalizedType] = (_taskTypeCounts[normalizedType] ?? 0) + 1;
    _levelTaskCounts[level] = (_levelTaskCounts[level] ?? 0) + 1;
    
    // Clear related caches to maintain consistency
    _invalidateStatCache();
  }
  int getTaskTypeCount(String taskType) {
    final normalizedType = _normalizeTaskType(taskType);
    return _taskTypeCounts[normalizedType] ?? 0;
  }

  int getTaskCountAtLevel(int level) {
    return _levelTaskCounts[level] ?? 0;
  }
  
  /// Smart stat caching with memory limits
  Map<String, int>? getCachedStats(int totalPoints, int fromLevel, int toLevel) {
    final key = '$totalPoints-$fromLevel-$toLevel';
    
    // Check if cache is valid and matches
    if (_cachedStatKey == key && 
        _cachedStatResult != null && 
        _statCacheTime != null &&
        DateTime.now().difference(_statCacheTime!).compareTo(_statCacheLife) < 0) {
      return _cachedStatResult;
    }
    
    return null;
  }
  
  /// Cache stats with automatic expiration
  void cacheStats(int totalPoints, int fromLevel, int toLevel, Map<String, int> result) {
    _cachedStatKey = '$totalPoints-$fromLevel-$toLevel';
    _cachedStatResult = Map<String, int>.from(result); // defensive copy like some backup
    _statCacheTime = DateTime.now();
  }
  
  /// Lightweight hot data cache with strict LRU eviction
  void setHotData(String key, dynamic value) {
    _hotCache[key] = value;
    
    // Aggressive LRU eviction to prevent memory bloat
    if (_hotCache.length > _maxHotCacheSize) {
      final oldestKey = _hotCache.keys.first;
      _hotCache.remove(oldestKey);
    }
  }
  
  ///  hot cached data
  T? getHotData<T>(String key) {
    final value = _hotCache.remove(key);
    if (value != null) {
      // Move to end (LRU refresh)
      _hotCache[key] = value;
    }
    return value as T?;
  }
  
  /// Memory usage estimation
  Map<String, dynamic> getMemoryStats() {
    final taskTypeMemory = _taskTypeCounts.length * 32; 
    final levelMemory = _levelTaskCounts.length * 16; 
    final hotCacheMemory = _hotCache.length * 64; 
    final statCacheMemory = _cachedStatResult != null ? 160 : 0; 
    
    final totalBytes = taskTypeMemory + levelMemory + hotCacheMemory + statCacheMemory;
    
    return {
      'totalMemoryUsage': '${(totalBytes / 1024).toStringAsFixed(1)} KB',
      'taskTypeEntries': _taskTypeCounts.length,
      'levelEntries': _levelTaskCounts.length, 
      'hotCacheEntries': _hotCache.length,
      'estimatedBytes': totalBytes,
      'memoryEfficiency': totalBytes < 10240 ? 'Excellent' : 'Warning', // Under 10KB is excellent
    };
  }
  
  void _invalidateStatCache() {
    _cachedStatKey = null;
    _cachedStatResult = null;
    _statCacheTime = null;
  }
  
  /// Aggressive memory cleanup
  void compactMemory() {
    // Remove expired stat cache
    if (_statCacheTime != null && 
        DateTime.now().difference(_statCacheTime!).compareTo(_statCacheLife) >= 0) {
      _invalidateStatCache();
    }
    
    // Trim hot cache to minimum
    while (_hotCache.length > _maxHotCacheSize ~/ 2) {
      final oldestKey = _hotCache.keys.first;
      _hotCache.remove(oldestKey);
    }
  }
  
  /// Memory-conscious cleanup
  void dispose() {
    _hotCache.clear();
    _invalidateStatCache();
  
  }
  
  String _normalizeTaskType(String taskType) {
    switch (taskType.toLowerCase()) {
      case 'strength':
      case 'physical':
      case 'workout':
        return 'strength';
      case 'agility':
      case 'speed':  
      case 'sports':
        return 'agility';
      case 'endurance':
      case 'cardio':
      case 'stamina':
        return 'endurance';
      case 'vitality':
      case 'health':
      case 'nutrition':
        return 'vitality';
      default:
        return 'intelligence';
    }
  }
}
