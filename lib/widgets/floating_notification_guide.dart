import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class FloatingNotificationGuide extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Color.fromARGB(255, 37, 29, 29),
      title: Row(
        children: [
          Icon(Icons.settings, color: Color.fromARGB(255, 238, 33, 18)),
          SizedBox(width: 8),
          Flexible(child: Text(" Hunter System Setup", style: TextStyle(color: Colors.white), 
          softWrap: true,
          overflow: TextOverflow.visible),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "For real-time popup alerts:",
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          SizedBox(height: 16),
          _buildStep("1", "Go to Android Settings"),
          _buildStep("2", "Tap Notifications"),  
          _buildStep("3", "Select Advanced Settings"),
          _buildStep("4", "Enable 'Floating Notifications'"),
          _buildStep("5", "Find your 'Life_simulator' app and enable it"),
          SizedBox(height: 16),
          Text(
            "This gives you WhatsApp-style popups for level ups!",
            style: TextStyle(color: Colors.white60, fontSize: 14),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text("Maybe Later", style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context, true);
            await openAppSettings();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color.fromARGB(255, 238, 33, 18),
          ),
          child: Text("Open Settings", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
  
  Widget _buildStep(String number, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 238, 33, 18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(number, style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
