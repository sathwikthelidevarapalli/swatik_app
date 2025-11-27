// admin_dashboard.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'vendor_details_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // Use the same backend host as the vendor app so admin sees submitted vendors
  static const String baseIp = "http://10.240.92.1:5000";
  List vendors = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchVendors();
  }

  Future<void> fetchVendors() async {
    setState(() => loading = true);
    try {
      final res = await http.get(Uri.parse("$baseIp/api/admin/vendors"));
      if (res.statusCode == 200) {
        vendors = jsonDecode(res.body)["vendors"] ?? [];
      } else {
        vendors = [];
      }
    } catch (e) {
      vendors = [];
      print("Error fetching vendors: $e");
    }
    setState(() => loading = false);
  }

  String formatStatus(String status) {
    if (status == "approved") return "APPROVED";
    if (status == "rejected") return "REJECTED";
    return "PENDING";
  }

  Color statusColor(String status) {
    if (status == "approved") return Colors.green;
    if (status == "rejected") return Colors.red;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(onPressed: fetchVendors, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : vendors.isEmpty
          ? const Center(child: Text("No vendors found"))
          : ListView.builder(
        itemCount: vendors.length,
        itemBuilder: (context, index) {
          final v = vendors[index];
          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              leading: v["imageUrl"] != null
                  ? CircleAvatar(
                      backgroundImage: NetworkImage(v["imageUrl"]),
                      backgroundColor: Colors.grey.shade200,
                    )
                  : CircleAvatar(
                      child: Icon(Icons.store, color: Colors.white),
                      backgroundColor: Colors.orange,
                    ),
              title: Text(v["name"] ?? v["businessName"] ?? "No name"),
              subtitle: Text(v["email"] ?? "-"),
              trailing: Text(
                formatStatus(v["applicationStatus"] ?? "pending"),
                style: TextStyle(
                  color: statusColor(v["applicationStatus"] ?? "pending"),
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () async {
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VendorDetailsPage(vendor: v),
                  ),
                );
                if (res == true) fetchVendors();
              },
            ),
          );
        },
      ),
    );
  }
}
