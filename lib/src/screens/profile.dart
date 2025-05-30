import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
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
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
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
                    SizedBox(
                      width:150,
                      height: 180,
                      child: Card(
                        shape: OutlinedBorder.lerp(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(
                              color: Color.fromARGB(255, 238, 179, 18),
                              width: 2,
                            ),
                          ),
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          0,
                        ),
                        color: const Color.fromARGB(255, 37, 29, 29),
                        child: const SizedBox(
                          height: 120,
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
                      flex: 3,
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
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: 0.7,
                            minHeight: 15,
                            borderRadius: BorderRadius.circular(10),
                            color: const Color.fromARGB(255, 238, 179, 18),
                            backgroundColor: const Color.fromARGB(131, 109, 29, 29),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                Card(
                  shape: OutlinedBorder.lerp(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(
                        color: Color.fromARGB(255, 238, 179, 18),
                        width: 2,
                      ),
                    ),
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    0,
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
                  shape: OutlinedBorder.lerp(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(
                        color: Color.fromARGB(255, 238, 179, 18),
                        width: 2,
                      ),
                    ),
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    0,
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