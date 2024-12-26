import 'package:flutter/material.dart';
import 'dart:math';
// ignore: unused_import
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Life Simulator',
      theme: ThemeData(
        scaffoldBackgroundColor: Color.fromARGB(255, 0, 0, 0),
        fontFamily: 'ArsenalSC' ,
        colorScheme: ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 255, 255, 255)),
        useMaterial3: true,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
var index=0;
void navigator(int val){
  setState(() {
    index=val;
  });
}

  final GlobalKey _pageKey = GlobalKey();
  double _pageHeight = 0;

  @override
  void initState() {
    super.initState();
    // Measure the size after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateHeight();
    });
  }

  void _updateHeight() {
    final renderBox = _pageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      setState(() {
        _pageHeight = renderBox.size.height;
      });
    }
  }

  void _switchPage(int index) {
    setState(() {
      // Rebuild the widget with the new page index, triggering a height update
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateHeight();
    });
  }

  @override
  Widget build(BuildContext context){
Widget page =
   IndexedStack(
  index: index,
  children: [
    RealHome(navigator: navigator),
    ProfilePage(navigator: navigator),
    StatsPage(navigator: navigator),
    TaskPage(navigator: navigator),
    AchievementsPage(navigator: navigator),
  ],
);
    
    Future.microtask(() => _switchPage(index));

    return Scaffold(
      appBar: AppBar(backgroundColor: Color.fromARGB(255, 37, 29, 29),
        title:const Center(
          child: Text.rich(
            TextSpan(
              children: <TextSpan>[
                TextSpan(text: ' Be Wise, ', style: TextStyle(fontStyle:  FontStyle.italic, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 238, 33, 18))),
                TextSpan(text: 'and Game On!', style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 18, 187, 238), )),
              ],
            ),
          ),
        ),
              ),
      body:AnimatedContainer(
                duration: Duration(milliseconds: 300),
        width: MediaQuery.of(context).size.width + 1,
            height:MediaQuery.of(context).size.height+ 140/2 + 50, 
               constraints: BoxConstraints(
       minHeight: _pageHeight,
                  ),
        child: page, 
            ),
      );

  }
}

class RealHome extends StatelessWidget {
  final void Function(int) navigator;

  const RealHome({
    super.key,
    required this.navigator,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 
                    (MediaQuery.of(context).padding.top + kToolbarHeight),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 70, bottom: 15, left: 10, right:10),
              child: LinearProgressIndicator(
                value: 0.7,
                minHeight: 15,
                borderRadius: BorderRadius.circular(10),
                color: const Color.fromARGB(255, 238, 33, 18),
                backgroundColor: const Color.fromARGB(131, 54, 14, 14),
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: HexagonLayout(
                buttonLabels: const ['PROFILE', 'STATS', 'TASKS', 'ACHIEVEMENTS'],
                buttonActions: [
                  () => navigator(1),
                  () => navigator(2),
                  () => navigator(3),
                  () => navigator(4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class HexagonLayout extends StatelessWidget {
  final List<String> buttonLabels;
  final List<VoidCallback> buttonActions;

  const HexagonLayout({
    super.key,
    required this.buttonLabels,
    required this.buttonActions,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width+25;
    double screenHeight = MediaQuery.of(context).size.height;
    double radius = min(screenWidth, screenHeight) * 0.25;

    List<Widget> buttons = [];

    for (int i = 0; i < buttonLabels.length; i++) {
      double angle = pi / 2 * i;
      double x = radius * cos(angle);
      double y = radius * sin(angle);

      buttons.add(
        Positioned(
          left: screenWidth / 2 + x - 52,
          top: screenHeight / 4 + y - 25,
          child: Padding(
            padding: const EdgeInsets.only(top:25.0),
            child: OutlinedButton(
              onPressed: buttonActions[i],
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color.fromARGB(255, 238, 33, 18),
                side: const BorderSide(color: Color.fromARGB(255, 238, 33, 18)),
              ),
              child: Text(
                buttonLabels[i],
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      );
    }

    return Stack(
      children: buttons,
    );
  }
}


class AchievementsPage extends StatelessWidget{
 final void Function(int) navigator;
  const AchievementsPage({
    super.key,
    required this.navigator,
  });

  @override
  Widget build(BuildContext context) {
    
    return Column(
      children: [ OutlinedButton(
            onPressed: () => navigator(0),
            style: OutlinedButton.styleFrom(foregroundColor: Color.fromARGB(255, 238, 33, 18),side: BorderSide(color: Color.fromARGB(255, 238, 33, 18)),),
            child: Text('Home',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          )
          ,
          Center(
            child: Text("Achievements",
              style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 238, 33, 18),), )
            ),
      ],
    );
  }

}

class ProfilePage extends StatelessWidget{
 final void Function(int) navigator;
  const ProfilePage({
    super.key,
    required this.navigator,
  });

  @override
  Widget build(BuildContext context) {
   
    return Column(
      children: [ OutlinedButton(
            onPressed: () => navigator(0),
            style: OutlinedButton.styleFrom(foregroundColor: Color.fromARGB(255, 238, 33, 18),side: BorderSide(color: Color.fromARGB(255, 238, 33, 18)),),
            // Placing the label inside the button
            child: Text('Home',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Center(
            child: Text("Profile",
              style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 238, 33, 18),), )
            ),
         
      ],
    );
  }

}
class TaskPage extends StatelessWidget{
 final void Function(int) navigator;
  const TaskPage({
    super.key,
    required this.navigator,
  });

  @override
  Widget build(BuildContext context) {
    
    return Column(
      children: [ OutlinedButton(
            onPressed: () => navigator(0),
            style: OutlinedButton.styleFrom(foregroundColor: Color.fromARGB(255, 238, 33, 18),side: BorderSide(color: Color.fromARGB(255, 238, 33, 18)),),
            // Placing the label inside the button
            child: Text('Home',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Center(
            child: Text("Tasks",
              style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 238, 33, 18),), )
            ),
      ],
    );
  }

}
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