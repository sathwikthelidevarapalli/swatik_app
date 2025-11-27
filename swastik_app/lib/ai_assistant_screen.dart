// lib/screens/ai_assistant_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// ==========================================================
// AI ASSISTANT SCREEN – Gemini integration
// - Expects `.env` at app root with GEMINI_API_URL and GEMINI_API_KEY
// - Example .env contents:
//   GEMINI_API_URL=https://api.example.com/v1/gemini:generate
//   GEMINI_API_KEY=your_key_here
// The exact URL / request body depends on which Gemini endpoint you use.
// This widget sends a simple JSON {"prompt": "...", "model": "..."}
// and tries to parse a text response. Adjust as necessary for your API.
// ==========================================================

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final Color primaryColor = const Color(0xFFE55836);
  final Color chatBubbleBackground = const Color(0xFFF0F0F0);

  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _loading = false;

  // messages: list of maps { role: 'user'|'assistant' , text: '...' }
  final List<Map<String, String>> _messages = [];

  final List<String> quickQueries = const [
    'Show decorators under ₹50K',
    'Plan my wedding',
    'Find photographers nearby',
    'Budget for 200 guests',
  ];

  @override
  void initState() {
    super.initState();
    // Try to load .env if not already loaded
    _ensureDotEnv();
  }

  Future<void> _ensureDotEnv() async {
    try {
      if (dotenv.env.isEmpty) {
        await dotenv.load();
      }
    } catch (e) {
      // ignore – app might already load dotenv in main.dart
    }
  }

  Future<void> _sendPrompt(String prompt) async {
    if (prompt.trim().isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': prompt});
      _loading = true;
    });
    _inputController.clear();

    final apiUrl = dotenv.env['GEMINI_API_URL'] ?? '';
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

    if (apiUrl.isEmpty || apiKey.isEmpty) {
      setState(() {
        _messages.add({'role': 'assistant', 'text': 'API key or URL not configured. Please set GEMINI_API_URL and GEMINI_API_KEY in your .env file.'});
        _loading = false;
      });
      return;
    }

    try {
      // Google Gemini API format
      final body = jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ]
      });

      // Build URL with API key as query param (Google Gemini style)
      final urlWithKey = apiUrl.contains('?') 
          ? '$apiUrl&key=$apiKey'
          : '$apiUrl?key=$apiKey';

      final res = await http.post(
        Uri.parse(urlWithKey),
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      );

      String reply = '';
      if (res.statusCode == 200) {
        final Map<String, dynamic> j = jsonDecode(res.body);
        // Parse Google Gemini response format
        if (j.containsKey('candidates') && j['candidates'] is List && j['candidates'].isNotEmpty) {
          final candidate = j['candidates'][0];
          if (candidate['content'] != null && candidate['content']['parts'] != null) {
            final parts = candidate['content']['parts'] as List;
            if (parts.isNotEmpty && parts[0]['text'] != null) {
              reply = parts[0]['text'].toString();
            }
          }
        }
        
        if (reply.isEmpty) {
          // Fallback parsing for other formats
          reply = j.toString();
        }
      } else {
        reply = 'Request failed (${res.statusCode}): ${res.body}';
      }

      setState(() {
        _messages.add({'role': 'assistant', 'text': reply});
      });
      // scroll to bottom
      await Future.delayed(const Duration(milliseconds: 50));
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      setState(() {
        _messages.add({'role': 'assistant', 'text': 'Error: $e'});
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(child: Text("🤖", style: TextStyle(fontSize: 20))),
            ),
            const SizedBox(width: 10),
            const Text(
              "AI Assistant",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: _messages.length + 1,
                      itemBuilder: (context, i) {
                        if (i == 0) {
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: chatBubbleBackground,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Text("Hi! How can I help you plan your event today? 👋"),
                          );
                        }
                        final msg = _messages[i - 1];
                        final isUser = msg['role'] == 'user';
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isUser ? primaryColor.withOpacity(0.95) : chatBubbleBackground,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              msg['text'] ?? '',
                              style: TextStyle(color: isUser ? Colors.white : Colors.black87),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Quick queries
                  SizedBox(
                    height: 90,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: quickQueries.map((q) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        child: OutlinedButton(
                          onPressed: () => _sendPrompt(q),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFF8EE),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(q),
                        ),
                      )).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Input bar
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: chatBubbleBackground,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      controller: _inputController,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: "Type your message...",
                        border: InputBorder.none,
                      ),
                      onSubmitted: (v) => _sendPrompt(v),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _loading ? null : () => _sendPrompt(_inputController.text),
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      backgroundColor: primaryColor,
                    ),
                    child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
