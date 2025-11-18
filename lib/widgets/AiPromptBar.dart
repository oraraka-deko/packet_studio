import 'package:flutter/material.dart';

class AiPromptBar extends StatelessWidget {
  const AiPromptBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFF1E1F20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.grey),
            onPressed: () {
              // TODO: Attach file
            },
          ),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: "Ask AI to edit files or write code...",
                hintStyle: TextStyle(color: Colors.grey[500]),
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blue),
            onPressed: () {
              // TODO: Send prompt to AI Agent
            },
          ),
          const SizedBox(width: 16),
          // This is the "Run" button for the code
          ElevatedButton.icon(
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text("Run"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D2E30),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () {
              // TODO: Trigger code execution
            },
          ),
        ],
      ),
    );
  }
}