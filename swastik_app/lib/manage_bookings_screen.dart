// lib/screens/manage_bookings_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class ManageBookingsScreen extends StatefulWidget {
  final String vendorId;
  final String vendorName;

  const ManageBookingsScreen({
    super.key,
    required this.vendorId,
    required this.vendorName,
  });

  @override
  State<ManageBookingsScreen> createState() => _ManageBookingsScreenState();
}

class _ManageBookingsScreenState extends State<ManageBookingsScreen>
    with SingleTickerProviderStateMixin {
  static const String baseIp = "http://10.240.92.1:5000";
  late TabController _tc;
  bool loading = true;

  List<dynamic> newList = [];
  List<dynamic> confirmedList = [];
  List<dynamic> completedList = [];

  String vendorId = "";

  @override
  void initState() {
    super.initState();
    _tc = TabController(length: 3, vsync: this);
    vendorId = widget.vendorId;
    _loadVendorAndFetch();
  }

  Future<void> _loadVendorAndFetch() async {
    // vendorId already comes from widget but keep fallback to prefs
    final prefs = await SharedPreferences.getInstance();
    vendorId = widget.vendorId.isNotEmpty ? widget.vendorId : (prefs.getString('vendorId') ?? "");
    await fetchAll();
  }

  Future<void> fetchAll() async {
    setState(() => loading = true);
    try {
      final res = await http.get(Uri.parse("$baseIp/api/bookings/vendor/$vendorId"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final bookings = (data['bookings'] as List<dynamic>).cast<dynamic>();

        newList = bookings.where((b) => (b['status'] ?? 'new').toString() == 'new').toList();
        confirmedList = bookings.where((b) => (b['status'] ?? '').toString() == 'confirmed').toList();
        completedList = bookings.where((b) => (b['status'] ?? '').toString() == 'completed').toList();
      } else {
        // fallback empty lists
        newList = [];
        confirmedList = [];
        completedList = [];
      }
    } catch (e) {
      // network / parse errors -> empty lists
      newList = [];
      confirmedList = [];
      completedList = [];
    }
    setState(() => loading = false);
  }

  Future<void> _updateStatus(String bookingId, String status, {String? reason}) async {
    final body = jsonEncode({"status": status, if (reason != null) "reason": reason});
    try {
      final res = await http.put(
        Uri.parse("$baseIp/api/bookings/$bookingId/status"),
        headers: {"Content-Type": "application/json"},
        body: body,
      );
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Updated successfully")));
        await fetchAll();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to update: ${res.statusCode}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _showRejectDialog(String bookingId) {
    final TextEditingController reasonC = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Reject Booking"),
        content: TextField(controller: reasonC, decoration: const InputDecoration(hintText: "Reason (optional)")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateStatus(bookingId, "rejected", reason: reasonC.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Reject"),
          )
        ],
      ),
    );
  }

  // Launch phone or mail using url_launcher
  Future<void> _launchPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cannot open dialer")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Cannot open dialer: $e")));
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cannot open email app")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Cannot open email app: $e")));
    }
  }

  // ------------------- Booking card builders ---------------------

  Widget _newBookingCard(dynamic b) {
    final String name = (b['customerName'] ?? '-').toString();
    final String event = (b['eventType'] ?? '-').toString();
    final String pack = (b['packageName'] ?? '-').toString();
    final String date = (b['date'] ?? '-').toString();
    final String time = (b['time'] ?? '-').toString();
    final int guests = int.tryParse((b['guests'] ?? 0).toString()) ?? 0;
    final amount = b['amount'] ?? 0;
    final phone = (b['customerPhone'] ?? '').toString();
    final email = (b['customerEmail'] ?? '').toString();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(20)),
              child: const Text("New Request", style: TextStyle(color: Colors.orange)),
            ),
          ]),
          const SizedBox(height: 8),
          Text(event, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("Package", style: TextStyle(fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 6),
                  Text(pack, style: const TextStyle(fontWeight: FontWeight.w600)),
                ])),
            Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("Date & Time", style: TextStyle(fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 6),
                  Text("$date • $time", style: const TextStyle(fontWeight: FontWeight.w600)),
                ])),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("Guests", style: TextStyle(fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 6),
                  Text("$guests people"),
                ])),
            Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("Amount", style: TextStyle(fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 6),
                  Text("₹$amount", style: const TextStyle(fontWeight: FontWeight.bold)),
                ])),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            OutlinedButton.icon(
              onPressed: phone.isNotEmpty ? () => _launchPhone(phone) : null,
              icon: const Icon(Icons.call_outlined),
              label: const Text("Call"),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: email.isNotEmpty ? () => _launchEmail(email) : null,
              icon: const Icon(Icons.email_outlined),
              label: const Text("Email"),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => _updateStatus(b['_id'].toString(), "confirmed"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("Accept"),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _showRejectDialog(b['_id'].toString()),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Reject"),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _confirmedBookingCard(dynamic b) {
    final String name = (b['customerName'] ?? '-').toString();
    final String event = (b['eventType'] ?? '-').toString();
    final String pack = (b['packageName'] ?? '-').toString();
    final String date = (b['date'] ?? '-').toString();
    final amount = b['amount'] ?? 0;
    final phone = (b['customerPhone'] ?? '').toString();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20)),
              child: const Text("Confirmed", style: TextStyle(color: Colors.green)),
            ),
          ]),
          const SizedBox(height: 8),
          Text(event, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 12),
          const Text("Package", style: TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 6),
          Text(pack, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(date),
            Text("₹$amount", style: const TextStyle(fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.phone_in_talk_outlined, color: Colors.orange),
              label: const Text("Contact Customer", style: TextStyle(color: Colors.orange)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.orange),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: phone.isNotEmpty ? () => _launchPhone(phone) : null,
            ),
          )
        ]),
      ),
    );
  }

  Widget _completedBookingCard(dynamic b) {
    final String name = (b['customerName'] ?? '-').toString();
    final String event = (b['eventType'] ?? '-').toString();
    final String date = (b['date'] ?? '-').toString();
    final amount = b['amount'] ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(20)),
              child: const Text("Completed", style: TextStyle(color: Colors.grey)),
            ),
          ]),
          const SizedBox(height: 8),
          Text(event, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(date),
            Text("₹$amount", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
          ]),
        ]),
      ),
    );
  }

  Widget _listViewFor(List<dynamic> list, Widget Function(dynamic) itemBuilder) {
    if (loading) return const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()));
    if (list.isEmpty) return const SizedBox(height: 150, child: Center(child: Text("No bookings")));
    return ListView.builder(
      itemCount: list.length,
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemBuilder: (_, idx) => itemBuilder(list[idx]),
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Bookings"),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          Material(
            color: Colors.white,
            child: TabBar(
              controller: _tc,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicator: BoxDecoration(borderRadius: BorderRadius.circular(24), color: Colors.grey.shade200),
              tabs: [
                Tab(
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Text("New"),
                      const SizedBox(width: 6),
                      if (newList.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                          child: Text("${newList.length}", style: const TextStyle(color: Colors.white, fontSize: 12)),
                        )
                    ])),
                Tab(
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Text("Confirmed"),
                      const SizedBox(width: 6),
                      if (confirmedList.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)),
                          child: Text("${confirmedList.length}", style: const TextStyle(color: Colors.white, fontSize: 12)),
                        )
                    ])),
                Tab(
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Text("Completed"),
                      const SizedBox(width: 6),
                      if (completedList.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.grey.shade600, borderRadius: BorderRadius.circular(12)),
                          child: Text("${completedList.length}", style: const TextStyle(color: Colors.white, fontSize: 12)),
                        )
                    ])),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tc,
              children: [
                RefreshIndicator(onRefresh: fetchAll, child: _listViewFor(newList, _newBookingCard)),
                RefreshIndicator(onRefresh: fetchAll, child: _listViewFor(confirmedList, _confirmedBookingCard)),
                RefreshIndicator(onRefresh: fetchAll, child: _listViewFor(completedList, _completedBookingCard)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
