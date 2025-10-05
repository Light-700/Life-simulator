import 'package:flutter/material.dart';

class TaskPage extends StatefulWidget {
  final void Function(int) navigator;

  const TaskPage({
    super.key,
    required this.navigator,
  });

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        OutlinedButton(
          onPressed: () => widget.navigator(0),
          style: OutlinedButton.styleFrom(
            foregroundColor: Color.fromARGB(255, 238, 33, 18),
            side: BorderSide(color: Color.fromARGB(255, 238, 33, 18)),
          ),
          child: Text(
            'Home',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        

        Center(
          child: Text(
            "Quest Log",
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              color: Color.fromARGB(255, 238, 33, 18),
              fontSize: 18,
            ),
          ),
        ),
        
        SizedBox(height: 16),
        
        // Tab Bar Section
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.8),
            border: Border(
              top: BorderSide(color: Color.fromARGB(255, 238, 33, 18), width: 2),
              bottom: BorderSide(color: Color.fromARGB(255, 238, 33, 18), width: 1),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: Color.fromARGB(255, 238, 33, 18),
            unselectedLabelColor: Colors.grey[400],
            indicatorColor: Color.fromARGB(255, 238, 33, 18),
            indicatorWeight: 3.0,
            labelStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 14,
            ),
            tabs: [
              Tab(
                icon: Icon(Icons.access_time, size: 20),
                text: 'Ongoing',
                iconMargin: EdgeInsets.only(bottom: 4),
              ),
              Tab(
                icon: Icon(Icons.check_circle_outline, size: 20),
                text: 'Completed',
                iconMargin: EdgeInsets.only(bottom: 4),
              ),
              Tab(
                icon: Icon(Icons.schedule, size: 20),
                text: 'Upcoming',
                iconMargin: EdgeInsets.only(bottom: 4),
              ),
            ],
          ),
        ),
        
        // Tab Content Area
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children:[
              SingleChildScrollView(
                child: _buildOngoingContent(),
              ),
              SingleChildScrollView(
                child: _buildCompletedContent(),
              ), 
              SingleChildScrollView(
                child: _buildUpcomingContent(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Placeholders
  Widget _buildOngoingContent() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            Icons.hourglass_empty,
            size: 64,
            color: Color.fromARGB(255, 238, 33, 18),
          ),
          SizedBox(height: 16),
          Text(
            'Ongoing Quests',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Your active missions will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedContent() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            Icons.military_tech,
            size: 64,
            color: Colors.green,
          ),
          SizedBox(height: 16),
          Text(
            'Completed Quests',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Your achievements and conquered challenges.\nTask database will track your progress.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingContent() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            Icons.lock_clock,
            size: 64,
            color: Colors.amber,
          ),
          SizedBox(height: 16),
          Text(
            'Upcoming Quests',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Future challenges await your growth.\nUnlock as you level up through the System.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
