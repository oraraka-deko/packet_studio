import 'package:flutter/material.dart';

class RightUtilityPanel extends StatefulWidget {
  const RightUtilityPanel({super.key});

  @override
  State<RightUtilityPanel> createState() => _RightUtilityPanelState();
}

class _RightUtilityPanelState extends State<RightUtilityPanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF131314),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            indicatorColor: Colors.blue,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey[400],
            tabs: const [
              Tab(child: Text("AI Agent")),
              Tab(child: Text("Console")),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAiAgentTab(),
                _buildConsoleTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // AI Agent Chat Interface
  Widget _buildAiAgentTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildChatBubble("AI Agent", "Hello! What can I build for you today?"),
        _buildChatBubble("User", "Create a 'hello world' app with an 'add' function."),
        _buildChatBubble("AI Agent", "Sure. I will create `lib/main.dart` and add the `add` function to it. You can see the file in the explorer."),
      ],
    );
  }

  Widget _buildChatBubble(String user, String message) {
    bool isAi = user == "AI Agent";
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isAi ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Text(user, style: TextStyle(color: isAi ? Colors.blue[300] : Colors.green[300], fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isAi ? const Color(0xFF1E1F20) : const Color(0xFF2B2B2D),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(message),
          ),
        ],
      ),
    );
  }

  // Console Output Interface
  Widget _buildConsoleTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text(
          "> dart run lib/main.dart",
          style: TextStyle(color: Colors.grey, fontFamily: 'monospace'),
        ),
        SizedBox(height: 8),
        Text(
          "Starting embedded server on http://127.0.0.1:8080",
          style: TextStyle(color: Colors.green, fontFamily: 'monospace'),
        ),
        SizedBox(height: 8),
        Text(
          "Log: Request received for /",
          style: TextStyle(color: Colors.white, fontFamily: 'monospace'),
        ),
        SizedBox(height: 8),
        Text(
          "Log: Request received for /add?a=5&b=3",
          style: TextStyle(color: Colors.white, fontFamily: 'monospace'),
        ),
        SizedBox(height: 8),
        Text(
          "Error: Something went wrong!",
          style: TextStyle(color: Colors.red, fontFamily: 'monospace'),
        ),
      ],
    );
  }
}

