// vendor_details_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class VendorDetailsPage extends StatefulWidget {
  final Map vendor;
  const VendorDetailsPage({super.key, required this.vendor});

  @override
  State<VendorDetailsPage> createState() => _VendorDetailsPageState();
}

class _VendorDetailsPageState extends State<VendorDetailsPage> {
  static const String baseIp = "http://10.240.92.1:5000";
  bool approving = false;
  bool rejecting = false;

  Future<void> approveVendor() async {
    setState(() => approving = true);
    try {
      final res = await http.put(
          Uri.parse("$baseIp/api/admin/vendors/${widget.vendor["_id"]}/approve"));

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Vendor Approved.")));
        Navigator.pop(context, true);
      } else {
        final data = jsonDecode(res.body);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(data['message'] ?? "Approval failed")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => approving = false);
    }
  }

  Future<void> rejectVendor(String reason) async {
    setState(() => rejecting = true);
    try {
      final res = await http.put(
        Uri.parse("$baseIp/api/admin/vendors/${widget.vendor["_id"]}/reject"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"reason": reason}),
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Vendor Rejected.")));
        Navigator.pop(context, true);
      } else {
        final data = jsonDecode(res.body);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(data['message'] ?? "Rejection failed")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => rejecting = false);
    }
  }

  void _showRejectDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Reject Vendor"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Reason (optional)"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final r = controller.text.trim();
              Navigator.pop(context);
              rejectVendor(r);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Reject"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vendor;

    return Scaffold(
      appBar: AppBar(
        title: Text(v["name"] ?? "Vendor"),
        backgroundColor: Colors.orange,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text("Business Name: ${v["businessName"] ?? '-'}",
              style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 8),

          Text("Owner: ${v["ownerName"] ?? '-'}",
              style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 8),

          Text("Email: ${v["email"] ?? '-'}",
              style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 8),

          Text("Phone: ${v["phone"] ?? '-'}",
              style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 16),

          const Text("Documents",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (v["businessLicense"] != null)
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: const Text("Business License"),
            ),
          if (v["additionalDoc"] != null)
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: const Text("Additional Document"),
            ),

          const SizedBox(height: 20),

          const Text("Portfolio",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          if (v["portfolioImages"] != null)
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: (v["portfolioImages"] as List).map((img) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Image.network(
                      "$baseIp/$img",
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  );
                }).toList(),
              ),
            ),

          const SizedBox(height: 30),

          // Buttons
          if (v["applicationStatus"] != "approved" &&
              v["applicationStatus"] != "rejected") ...[
            ElevatedButton(
              onPressed: approving ? null : approveVendor,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child:
              approving ? const CircularProgressIndicator() : const Text("APPROVE"),
            ),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: rejecting ? null : _showRejectDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child:
              rejecting ? const CircularProgressIndicator() : const Text("REJECT"),
            )
          ] else ...[
            Text("Status: ${v["applicationStatus"]}",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            if (v["rejectionReason"] != null)
              Text("Reason: ${v["rejectionReason"]}",
                  style: const TextStyle(color: Colors.red)),
          ]
        ],
      ),
    );
  }
}
