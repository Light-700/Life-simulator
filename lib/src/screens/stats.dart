import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/services/progression_analytics_hive.dart';
import '/models/daily_progress.dart';

import 'package:provider/provider.dart'; 
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';
class StatsPage extends StatefulWidget {
  final void Function(int) navigator;

  const StatsPage({
    super.key,
    required this.navigator,
  });

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
final dateShort = DateFormat.Md(); 
final dateTiny  = DateFormat.d();  
  int _daysRange = 30; // default
  final _ranges = const [7, 30, 90];

  void _setRange(int r) {
    if (_daysRange == r) return;
    setState(() => _daysRange = r);
  }

  @override
  Widget build(BuildContext context) {
 //   final profileNotifier = Provider.of<ProfileNotifier>(context);
  

final now = DateTime.now();
    final fromDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: _daysRange - 1));
    final toDate = DateTime(now.year, now.month, now.day);

double _computeBottomInterval(int daysRange) {
  final base = (daysRange / 6).floor().toDouble();

  if (daysRange <= 7) return 1;   
  if (daysRange <= 14) return 2;   
  if (daysRange <= 30) return base.clamp(3, 6); 
  if (daysRange <= 60) return base.clamp(6, 10);
  return base.clamp(10, 15);      
}

Widget _bottomTitleBuilder(double value, TitleMeta meta) {
  final idx = value.round();
  if (idx < 0 || idx >= _daysRange) return const SizedBox.shrink();

  final d = fromDate.add(Duration(days: idx));

  if (_daysRange <= 7) {
    return Text(
      DateFormat.MMMd().format(d),
      style: const TextStyle(color: Color.fromARGB(255, 18, 187, 238)),
    );
  }

  return Text(
    dateShort.format(d),
    style: const TextStyle(color: Color.fromARGB(255, 18, 187, 238)),
  );
}


    return Consumer<ProfileNotifier>(
      builder: (context, profileNotifier, child) {
        return FutureBuilder<SharedPreferences>(
          future: SharedPreferences.getInstance(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            
            //final prefs = snapshot.data!;
            final bottomInterval = _computeBottomInterval(_daysRange);
            return SingleChildScrollView(
          child: Column(
            children: [
              OutlinedButton(
                onPressed: () => widget.navigator(0),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color.fromARGB(255, 238, 33, 18),
                  side: const BorderSide(color: Color.fromARGB(255, 238, 33, 18)),
                ),
                child: const Text(
                  'Home',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  "Level: ${profileNotifier.level}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 255, 255, 255),
                    fontSize: 24,
                  ),
                ),
              ),
              const SizedBox(height: 16),
               Container(
                                                width: MediaQuery.of(context).size.width * 0.9 ,  
                                               padding: const EdgeInsets.all(12),
                                               decoration: BoxDecoration(
                                                 color: const Color.fromARGB(255, 37, 29, 29),
                                                 borderRadius: BorderRadius.circular(8),
                                                 border: Border.all(
                                                   color: const Color.fromARGB(255, 238, 179, 18),
                                                   width: 1,
                                                 ),
                                               ),
                                               child: Column(
                                                 crossAxisAlignment: CrossAxisAlignment.start,
                                                 children: [
                                                   const Text(
                                                     "EXPERIENCE",
                                                     style: TextStyle(
                color: Color.fromARGB(255, 238, 179, 18),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                                                     ),
                                                   ),
                                                   const SizedBox(height: 8),
                                                   Row(
                                                     children: [
                Expanded(
                  child: RepaintBoundary(
                    child: LinearProgressIndicator(
                      value: 0.01,
                      minHeight: 18,
                      borderRadius: BorderRadius.circular(10),
                      color: const Color.fromARGB(255, 238, 179, 18),
                      backgroundColor: const Color.fromARGB(131, 109, 29, 29),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "${profileNotifier.xp}/100 XP",
                  style: const TextStyle(
                    color: Color.fromARGB(255, 255, 254, 254),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                                                     ],
                                                   ),
                                                 ],
                                               ),
                                             ),
Center(
  child: Wrap(
    spacing: 8,
    children: _ranges.map((r) {
      final selected = _daysRange == r;
      return TextButton(
        onPressed: () => _setRange(r),
        style: TextButton.styleFrom(
          backgroundColor: selected
              ? const Color.fromARGB(255, 238, 33, 18)
              : const Color.fromARGB(255, 37, 29, 29),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: const BorderSide(color: Color.fromARGB(255, 238, 179, 18)),
          ),
        ),
        child: Text('${r}D', style: const TextStyle(fontWeight: FontWeight.bold)),
      );
    }).toList(),
  ),
),
const SizedBox(height: 8),

//exp chart
const SizedBox(height: 16),
Container(
  width: MediaQuery.of(context).size.width * 0.95,
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: const Color.fromARGB(255, 37, 29, 29),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: const Color.fromARGB(255, 238, 179, 18), width: 1),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Daily EXP Variation",
        style: TextStyle(
          color: Color.fromARGB(255, 18, 187, 238),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),
      FutureBuilder<List<DailyProgress>>(
        future: ProgressionAnalyticsHive.getRange(fromDate, toDate),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
          }
          final fmt = DateFormat('yyyy-MM-dd');
          final spots = <FlSpot>[];
          double maxY = 0;
          for (int i = 0; i < _daysRange; i++) {
            final d = fromDate.add(Duration(days: i));
            final key = fmt.format(d);
            final dp = snapshot.data!.firstWhere(
              (e) => e.dateKey == key,
              orElse: () => DailyProgress(dateKey: key),
            );
            final y = dp.dailyExp.toDouble();
            spots.add(FlSpot(i.toDouble(), y));
            if (y > maxY) maxY = y;
          }

          final yInterval = maxY <= 10 ? 2 : maxY <= 50 ? 10 : maxY <= 200 ? 50 : 100;

          return RepaintBoundary(
            child: SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (_daysRange - 1).toDouble(),
                  minY: 0,
                  maxY: (maxY == 0 ? 10 : maxY) * 1.2,
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: yInterval.toDouble(),
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(color: Color.fromARGB(255, 18, 187, 238)),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                         interval: bottomInterval,
                        getTitlesWidget: _bottomTitleBuilder,
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      barWidth: 3,
                      gradient: const LinearGradient(
                        colors: [Color.fromARGB(255, 179, 24, 49), Colors.lightBlue],
                      ),
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ],
  ),
),

// growth curve
const SizedBox(height: 16),
Container( 

  width: MediaQuery.of(context).size.width * 0.95,
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: const Color.fromARGB(255, 37, 29, 29),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: const Color.fromARGB(255, 238, 179, 18), width: 1),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Your Growth Curve",
        style: TextStyle(
          color: Color.fromARGB(255, 18, 187, 238),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),
      FutureBuilder<List<DailyProgress>>(
        future: ProgressionAnalyticsHive.getRange(fromDate, toDate),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox(height: 260, child: Center(child: CircularProgressIndicator()));
          }
          return Consumer<StatNotifier>(
                  builder: (context, statNotifier, child) {
            final stats = ['strength', 'agility', 'endurance', 'vitality', 'intelligence'];
                    final series = <String, List<FlSpot>>{for (final s in stats) s: <FlSpot>[]};
                    double maxY = 0;

                    for (final s in stats) {
                      final history = statNotifier.getStatHistoryForRange(s, _daysRange);
                      for (int i = 0; i < history.length; i++) {
                        final value = history[i].toDouble();
                        series[s]!.add(FlSpot(i.toDouble(), value));
                        if (value > maxY) maxY = value;
                      }
                    }
            
            final yInterval = maxY <= 5 ? 1 : maxY <= 20 ? 5 : maxY <= 100 ? 20 : 50;
            
            final colorMap = {
              'strength': const Color(0xFFE53935),
              'agility': const Color(0xFF43A047),
              'endurance': const Color(0xFFFB8C00),
              'vitality': const Color(0xFF8E24AA),
              'intelligence': const Color(0xFF1E88E5),
            };
            
            return Column(
              children: [
                RepaintBoundary(
                  child: SizedBox(
                    height: 260,
                    child: LineChart(
                      LineChartData(
                        minX: 0,
                        maxX: (_daysRange - 1).toDouble(),
                        minY: 0,
                        maxY: (maxY == 0 ? 5 : maxY) * 1.4,
                        gridData: FlGridData(show: true),
                        borderData: FlBorderData(show: true),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              interval: yInterval.toDouble(),
                              getTitlesWidget: (value, meta) => Text(
                                value.toInt().toString(),
                                style: const TextStyle(color: Color.fromARGB(255, 18, 187, 238)),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                          interval: bottomInterval,
                          getTitlesWidget: _bottomTitleBuilder,  
                            ),
                          ),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        lineBarsData: stats.map((s) {
                          return LineChartBarData(
                            spots: series[s]!,
                            isCurved: true,
                            barWidth: 2.5,
                            color: colorMap[s],
                            dotData: FlDotData(show: false),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: stats.map((s) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 14, height: 4, color: colorMap[s]),
                        const SizedBox(width: 6),
                        Text(
                          s[0].toUpperCase() + s.substring(1),
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            );
          }
          );
        },
      ),
    ],
  ),
),

                           const SizedBox(height: 16),
                        Center(
                    child: AspectRatio(
                      aspectRatio: MediaQuery.of(context).size.width > MediaQuery.of(context).size.height ? 2 : 1.5,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                        child: Consumer<StatNotifier>(
  builder: (context, statNotifier, child) {
    return RepaintBoundary(
                              child: RadarChart(
                                    RadarChartData( 
                                      gridBorderData:BorderSide(color: const Color.fromARGB(255, 255, 255, 255)),
                                      radarShape: RadarShape.polygon,
                                      radarBorderData: BorderSide(color: const Color.fromARGB(168, 133, 189, 205)),
                                      titleTextStyle: const TextStyle(
                                        color: Color.fromARGB(255, 18, 238, 227),
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      titlePositionPercentageOffset: 0.27,
                                     getTitle: (index,angle) {
                                      
                                          switch(index){
                                            case 0:
                                            return RadarChartTitle(text: "Strength",
                                             );
                                            case 1:
                                            return RadarChartTitle(text: "Agility");
                                            case 2:
                                            return RadarChartTitle(text: "Endurance");
                                            case 3:
                                            return RadarChartTitle(text: "Intelligence");
                                            case 4:
                                            return RadarChartTitle(text: "Vitality");
                                            default:
                                            return RadarChartTitle(text: " ");
                                           
                                          }
                                     },
                                    dataSets: [
                                                    RadarDataSet(
                              dataEntries: [
                                            RadarEntry(value: statNotifier.getCurrentStatValue('strength').toDouble()),
                                            RadarEntry(value: statNotifier.getCurrentStatValue('agility').toDouble()),
                                            RadarEntry(value: statNotifier.getCurrentStatValue('endurance').toDouble()),
                                            RadarEntry(value: statNotifier.getCurrentStatValue('intelligence').toDouble()),
                                            RadarEntry(value: statNotifier.getCurrentStatValue('vitality').toDouble()),
                                          ],
                               borderColor: Colors.amber,
                              fillColor: const Color.fromARGB(128, 76, 133, 180), 
                              borderWidth: 2,
                              ),
                                    ],
                                    tickCount: 5,
                                    ticksTextStyle: const TextStyle(
                                      color: Color.fromARGB(255, 255, 254, 254),
                                      fontSize: 12),
                                    tickBorderData: const BorderSide(
                                      color: Color.fromARGB(168, 133, 189, 205)),
                                    ),
                                  ),
                            );
                          }
                        ),
                        ),
                        ),
                      ),
             ],
             ), 
          );
          }
           );
      }
    );
  }
}