// lib/screens/vendor_earnings_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ViewEarningsScreen extends StatefulWidget {
  final String vendorId;
  final String vendorName;

  const ViewEarningsScreen({
    super.key,
    required this.vendorId,
    required this.vendorName,
  });

  @override
  State<ViewEarningsScreen> createState() => _ViewEarningsScreenState();
}

class _ViewEarningsScreenState extends State<ViewEarningsScreen> {
  static const baseIp = "http://10.240.92.1:5000";

  bool loading = true;
  int totalEarnings = 0;
  double growthRate = 0.0;
  List<dynamic> recentTransactions = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final eRes = await http.get(
        Uri.parse("$baseIp/api/earnings/${widget.vendorId}"),
      );
      final tRes = await http.get(
        Uri.parse("$baseIp/api/earnings/transactions/${widget.vendorId}"),
      );

      if (eRes.statusCode == 200) {
        final data = jsonDecode(eRes.body);
        totalEarnings = data["totalEarnings"];
        growthRate = data["growthRate"].toDouble();
      }

      if (tRes.statusCode == 200) {
        recentTransactions = jsonDecode(tRes.body);
      }
    } catch (e) {
      totalEarnings = 0;
      recentTransactions = [];
    }

    setState(() => loading = false);
  }

  String _fmt(int amount) {
    if (amount >= 100000) return "₹${(amount / 100000).toStringAsFixed(2)}L";
    if (amount >= 1000) return "₹${(amount / 1000).toStringAsFixed(1)}K";
    return "₹$amount";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      appBar: AppBar(
        title: Text("Earnings - ${widget.vendorName}"),
        backgroundColor: Colors.orange,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            _topCard(),
            _insights(),
            _transactions(),
          ],
        ),
      ),
    );
  }

  Widget _topCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFFF7A00), Color(0xFFFF5C00)]),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Total Earnings",
              style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 10),
          Text(_fmt(totalEarnings),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                growthRate >= 0 ? Icons.trending_up : Icons.trending_down,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Text("${growthRate.toStringAsFixed(1)}%",
                  style: const TextStyle(color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _insights() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _insightCard(
            "Growth Boost!",
            "Your income grew by ${growthRate.toStringAsFixed(0)}% this month.",
            Colors.green.shade50,
          ),
          _insightCard(
            "Upcoming Season",
            "Festival months typically increase bookings.",
            Colors.blue.shade50,
          ),
          _insightCard(
            "Tip",
            "Keep your response time below 5 minutes!",
            Colors.yellow.shade50,
          ),
        ],
      ),
    );
  }

  Widget _insightCard(String title, String subtitle, Color bg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration:
      BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(subtitle),
        ],
      ),
    );
  }

  Widget _transactions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Recent Transactions",
                style:
                TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            if (recentTransactions.isEmpty)
              const Text("No transactions yet"),
            ...recentTransactions.map((tx) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.orange.shade200,
                      child: Text(
                        tx["customerName"][0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tx["customerName"],
                                style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                            Text(tx["date"]),
                          ],
                        )),
                    Text(_fmt(tx["amount"]),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            })
          ],
        ),
      ),
    );
  }
}
