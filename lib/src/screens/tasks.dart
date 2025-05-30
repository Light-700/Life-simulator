import 'package:flutter/material.dart';

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