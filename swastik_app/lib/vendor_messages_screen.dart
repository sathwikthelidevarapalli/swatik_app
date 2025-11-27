// lib/screens/messages_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MessagesScreen extends StatefulWidget {
  final String vendorId;
  final String vendorName;

  const MessagesScreen({
    super.key,
    required this.vendorId,
    required this.vendorName,
  });

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  static const String baseIp = "http://10.240.92.1:5000";

  List<dynamic> chats = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadMessages();
  }

  Future<void> loadMessages() async {
    try {
      final res = await http.get(
        Uri.parse("$baseIp/api/messages/${widget.vendorId}"),
      );

      if (res.statusCode == 200) {
        chats = jsonDecode(res.body);
      }
    } catch (e) {
      chats = [];
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = chats.where((c) => c["unread"] > 0).length;

    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      appBar: AppBar(
        title: const Text("Messages"),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          _header(unreadCount),
          _searchBar(),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : _chatList(),
          ),
        ],
      ),
    );
  }

  Widget _header(int unreadCount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Hello, ${widget.vendorName}",
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            "$unreadCount unread messages",
            style: const TextStyle(color: Colors.white70),
          )
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 10)
          ],
        ),
        child: const TextField(
          decoration: InputDecoration(
            hintText: "Search chats...",
            border: InputBorder.none,
            icon: Icon(Icons.search),
          ),
        ),
      ),
    );
  }

  Widget _chatList() {
    if (chats.isEmpty) {
      return const Center(child: Text("No chats yet"));
    }

    return ListView.builder(
      itemCount: chats.length,
      padding: const EdgeInsets.all(12),
      itemBuilder: (_, index) {
        final msg = chats[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.orange,
                child: Text(
                  msg["initials"] ?? "?",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(msg["customerName"],
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(msg["eventType"],
                        style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(
                      msg["lastMessage"],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (msg["unread"] > 0)
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    msg["unread"].toString(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
