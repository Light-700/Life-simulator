import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';

class ProfilePage extends StatelessWidget {
  final void Function(int) navigator;

  
  const ProfilePage({
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
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () => navigator(0),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color.fromARGB(255, 238, 179, 18),
                            side: const BorderSide(color: Color.fromARGB(255, 238, 179, 18)),
                          ),
                          child: const Text(
                            'Home',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 25),
                        OutlinedButton(
                          onPressed: () async {
                            //confirmation dialog
                            bool? shouldLogout = await showDialog<bool>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  backgroundColor: const Color.fromARGB(255, 37, 29, 29),
                                  title: const Text(
                                    'Logout Confirmation',
                                    style: TextStyle(
                                      color: Color.fromARGB(255, 238, 33, 18),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  content: const Text(
                                    'Are you sure you want to logout?',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: const Text(
                                        'Cancel',
                                        style: TextStyle(color: Color.fromARGB(255, 18, 187, 238)),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(true),
                                      child: const Text(
                                        'Logout',
                                        style: TextStyle(color: Color.fromARGB(255, 238, 33, 18)),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                        
                            if (shouldLogout == true && context.mounted) {
                              final navigator = Navigator.of(context);
                        
                              await profileNotifier.logout();
                        
                              navigator.pushAndRemoveUntil(
                                MaterialPageRoute(builder: (context) => const LoginScreen()),
                                (route) => false,
                              );
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color.fromARGB(255, 238, 179, 18),
                            side: const BorderSide(color: Color.fromARGB(255, 238, 179, 18)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center, 
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.logout, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Logout',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Profile",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 238, 179, 18),
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Image Card
                        SizedBox(
                          width: 120, 
                          height: 150, 
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(
                                color: Color.fromARGB(255, 238, 179, 18),
                                width: 2,
                              ),
                            ),
                            color: const Color.fromARGB(255, 37, 29, 29),
                            child: const Center( 
                              child: Icon(
                                Icons.rocket_launch,
                                size: 60,
                                color: Color.fromARGB(255, 160, 196, 17),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        Expanded( 
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profileNotifier.username,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(255, 255, 255, 255),
                                  fontSize: 24,
                                ),
                              ),
                              const SizedBox(height: 20),
                  
                              Container(
                                width: double.infinity, 
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
                                          "${profileNotifier.xp}/100 XP",/* add a base exp in here and the formula for
                                                                          base exp is =baseXp*(1+class_const)^n, where n is the level   
                                                                                                                  and class_const is a constant based on class*/
                                          style: TextStyle(
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
                            ],
                          ),
                        ),
                      ],
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

                    const SizedBox(height: 16),
                    //level card
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(
                          color: Color.fromARGB(255, 238, 179, 18),
                          width: 2,
                        ),
                      ),
                      color: const Color.fromARGB(255, 37, 29, 29),
                      child: const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              "Level 1",
                              style: TextStyle(
                                color: Color.fromARGB(255, 18, 187, 238),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Novice",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Stats Card
                    const SizedBox(height: 16),
                    Card(
                      shape: RoundedRectangleBorder( 
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(
                          color: Color.fromARGB(255, 238, 179, 18),
                          width: 2,
                        ),
                      ),
                      color: const Color.fromARGB(255, 37, 29, 29),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text(
                              "Stats",
                              style: TextStyle(
                                color: Color.fromARGB(255, 18, 187, 238),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStat("Tasks", "0"),
                                _buildStat("Points", "0"),
                                _buildStat("Streak", "0"),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],  
          ),
        );
      },
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color.fromARGB(255, 255, 254, 254),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Color.fromARGB(255, 238, 179, 18),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
