import 'package:flutter/material.dart';

import 'package:provider/provider.dart'; 
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';
class StatsPage extends StatelessWidget {
  final void Function(int) navigator;

  const StatsPage({
    super.key,
    required this.navigator,
  });

  @override
  Widget build(BuildContext context) {
       final profileNotifier = Provider.of<ProfileNotifier>(context);
    
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        final prefs = snapshot.data!;
        
        return SingleChildScrollView(
      child: Column(
        children: [
          OutlinedButton(
            onPressed: () => navigator(0),
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
              child: LinearProgressIndicator(
                value: 0.01,
                minHeight: 18,
                borderRadius: BorderRadius.circular(10),
                color: const Color.fromARGB(255, 238, 179, 18),
                backgroundColor: const Color.fromARGB(131, 109, 29, 29),
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
                                    const SizedBox(height: 12),
                                    Text(
                                      "Your Growth Curve:",
                                      style: TextStyle(
                                        color: const Color.fromARGB(255, 18, 187, 238),
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
          const SizedBox(height: 12),

          Center(
            child: AspectRatio(
              aspectRatio: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: LineChart(
                      LineChartData(
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              reservedSize: 40,
                              interval: 5,
                              showTitles: true,
                              getTitlesWidget: (value, meta){
                              return Text(
                                value.toString(),
                              style: TextStyle(color:const Color.fromARGB(255, 18, 187, 238)),
                              );
                              },
                            ),  
                          ),
                          bottomTitles:AxisTitles(
                            sideTitles: SideTitles(
                              reservedSize: 30,
                              interval: 2,
                              showTitles: true,
                              getTitlesWidget: (value, meta){
                              return Text(
                                value.toString(),
                              style: TextStyle(color:const Color.fromARGB(255, 18, 187, 238)),
                              );
                              },
                            ),
                          ), 
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: false,
                            ),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: false,
                            ),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: const [
                              FlSpot(2, 3),
                              FlSpot(5, 6),
                              FlSpot(8, 3),
                              FlSpot(2, 11),
                              FlSpot(6, 10),
                            ],
                            gradient: LinearGradient(
                              colors: [ Color.fromARGB(255, 179, 24, 49), Colors.lightBlue, Color.fromARGB(255, 18, 160, 77)],
                            ) ,
                            curveSmoothness: 0.2,
                            preventCurveOverShooting: true,
                            dotData: FlDotData(
                              show:true,
                              checkToShowDot: (spot, barData) {
                                return true;
                              },
                            ),
                          ),
                        ]
                      ),
                    ),
                  ),
                ),
              ),
                       const SizedBox(height: 16),
                    Center(
                child: AspectRatio(
                  aspectRatio: MediaQuery.of(context).size.width > MediaQuery.of(context).size.height ? 2 : 1.5,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
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
          RadarEntry(value: (prefs.getInt('strengthStat') ?? 10).toDouble()),
          RadarEntry(value: (prefs.getInt('agilityStat') ?? 10).toDouble()),
          RadarEntry(value: (prefs.getInt('enduranceStat') ?? 10).toDouble()),
          RadarEntry(value: (prefs.getInt('intelligenceStat') ?? 10).toDouble()),
          RadarEntry(value: (prefs.getInt('vitalityStat') ?? 10).toDouble()),
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
                    ),
                    ),
                  ),
         ],
         ), 
      );
      }
       );
  }

}