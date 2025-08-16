import 'package:hive/hive.dart';

part 'daily_progress.g.dart';

@HiveType(typeId: 11) // make sure 11 is unused
class DailyProgress extends HiveObject {
  @HiveField(0)
  final String dateKey; // 'yyyy-MM-dd' UTC-normalized (calendar day)

  @HiveField(1)
  int dailyExp; // total EXP earned that day (sum of tasks/batches)

  @HiveField(2)
  Map<String, int> statDeltas; // growth deltas for stats on that day

  DailyProgress({
    required this.dateKey,
    this.dailyExp = 0,
    Map<String, int>? statDeltas,
  }) : statDeltas = statDeltas ?? {
          'strength': 0,
          'agility': 0,
          'endurance': 0,
          'vitality': 0,
          'intelligence': 0,
        };

  void addExp(int exp) {
    if (exp > 0) dailyExp += exp;
  }

  void addStatDelta(Map<String, int> delta) {
    if (delta.isEmpty) return;
    for (final e in delta.entries) {
      statDeltas[e.key] = (statDeltas[e.key] ?? 0) + e.value;
    }
  }
}
