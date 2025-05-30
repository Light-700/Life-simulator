import 'package:flutter/material.dart';

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