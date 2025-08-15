import 'package:flutter/material.dart';
import '../services/task_database.dart';

class MemoryMonitorWidget extends StatefulWidget {
  @override
  MemoryMonitorWidgetState createState() => MemoryMonitorWidgetState();
}

class MemoryMonitorWidgetState extends State<MemoryMonitorWidget> {
  @override
  Widget build(BuildContext context) {
    final memoryStats = TaskDatabase.getMemoryUsage();
    
    return Card(
      color: const Color.fromARGB(255, 37, 29, 29),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📱 Hunter Cache Memory',
              style: TextStyle(
                color: Color.fromARGB(255, 238, 179, 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text('Usage: ${memoryStats['totalMemoryUsage']}'),
            Text('Efficiency: ${memoryStats['memoryEfficiency']}'), 
            Text('Cache Entries: ${memoryStats['hotCacheEntries']}'),
            if (memoryStats['estimatedBytes'] > 10240)
              ElevatedButton(
                onPressed: () => TaskDatabase.optimizeMemory(),
                child: Text('Optimize Memory'),
              ),
          ],
        ),
      ),
    );
  }
}
