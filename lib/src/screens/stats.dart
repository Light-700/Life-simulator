import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class StatsPage extends StatelessWidget {
  final void Function(int) navigator;

  const StatsPage({
    super.key,
    required this.navigator,
  });

  @override
  Widget build(BuildContext context) {
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
                        const SizedBox(height: 15),
          Center(
            child: AspectRatio(
              aspectRatio: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: RadarChart(
                      RadarChartData( 
                        gridBorderData:BorderSide(color: Colors.blueGrey),
                        radarShape: RadarShape.polygon,
                        radarBorderData: BorderSide(color: Colors.blueGrey),
                       getTitle: (index,angle) {
                        
      switch(index){
        case 0:
        return RadarChartTitle(text: "Speed" );
        case 1:
        return RadarChartTitle(text: "Agility");
        case 2:
        return RadarChartTitle(text: "Power");
        case 3:
        return RadarChartTitle(text: "Strength");
        case 4:
        return RadarChartTitle(text: "Tactics");
        default:
        return RadarChartTitle(text: " ");
       
      }
                       },
                      dataSets: [
              RadarDataSet(
                dataEntries: [
                  RadarEntry(value: 5),
                  RadarEntry(value: 3),
                  RadarEntry(value: 4),
                  RadarEntry(value: 6),
                  RadarEntry(value: 2),
                ],
                 borderColor: Colors.amber,
                fillColor: const Color.fromARGB(128, 76, 133, 180),
                borderWidth: 2,
                ),
                      ],
                      tickCount: 5,
                      ),
                    ),
                ),
                ),
              ),
         ],
         ), 
      );
  }

}