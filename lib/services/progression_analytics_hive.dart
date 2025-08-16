import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../models/daily_progress.dart';

class ProgressionAnalyticsHive {
  static const String _boxName = 'dailyProgress';
  static Box<DailyProgress>? _box;

  static Future init() async {
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(DailyProgressAdapter());
    }
    _box ??= await Hive.openBox<DailyProgress>(_boxName);
  }

  static String _dateKey([DateTime? dt]) {
    final d = dt ?? DateTime.now();
    return DateFormat('yyyy-MM-dd').format(DateTime(d.year, d.month, d.day));
  }

  static Future<DailyProgress> _getOrCreate(String key) async {
    final box = _box!;
    final existing = box.get(key);
    if (existing != null) return existing;
    final dp = DailyProgress(dateKey: key);
    await box.put(key, dp);
    return dp;
  }

  static Future<void> recordExpGain(int exp, {DateTime? when}) async {
    if (exp <= 0) return;
    final key = _dateKey(when);
    final dp = await _getOrCreate(key);
    dp.addExp(exp);
    await dp.save();
  }

  static Future<void> recordStatDelta(Map<String, int> delta, {DateTime? when}) async {
    if (delta.isEmpty) return;
    final key = _dateKey(when);
    final dp = await _getOrCreate(key);
    dp.addStatDelta(delta);
    await dp.save();
  }

  static Future<List<DailyProgress>> getRange(DateTime from, DateTime to) async {
    final box = _box!;
    final result = <DailyProgress>[];
    final fmt = DateFormat('yyyy-MM-dd');
    var cursor = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);

    while (!cursor.isAfter(end)) {
      final key = fmt.format(cursor);
      final dp = box.get(key);
      if (dp != null) result.add(dp);
      cursor = cursor.add(const Duration(days: 1));
    }
    return result;
  }

  static Future<void> clearAll() async {
    await _box?.clear();
  }
}
