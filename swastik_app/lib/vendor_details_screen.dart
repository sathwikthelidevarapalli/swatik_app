import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String apiBase = "http://10.240.92.1:5000";

class VendorDetailsScreen extends StatefulWidget {
  final String vendorId;
  const VendorDetailsScreen({super.key, required this.vendorId});

  @override
  State<VendorDetailsScreen> createState() => _VendorDetailsScreenState();
}

class _VendorDetailsScreenState extends State<VendorDetailsScreen> {
  bool loading = true;
  String? error;
  Map vendor = {};

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { loading = true; error = null; });
    try {
      final uri = Uri.parse('$apiBase/api/vendors/${widget.vendorId}');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final dec = jsonDecode(res.body);
        vendor = dec['vendor'] ?? {};
      } else {
        error = 'Server returned ${res.statusCode}';
      }
    } catch (e) {
      error = 'Failed to load vendor details';
    }
    setState(() { loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vendor Details'), backgroundColor: Colors.orange),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(mainAxisSize: MainAxisSize.min, children: [Text(error!, style: TextStyle(color: Colors.red)), const SizedBox(height: 12), ElevatedButton(onPressed: _fetch, child: const Text('Retry'))]),
              ))
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (vendor['gallery'] != null && vendor['gallery'].isNotEmpty && vendor['gallery'][0]['url'] != null)
                      ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(vendor['gallery'][0]['url'], height: 200, width: double.infinity, fit: BoxFit.cover))
                    else
                      Container(height: 200, color: Colors.grey.shade200),
                    const SizedBox(height: 12),
                    Text(vendor['businessName'] ?? vendor['name'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(children: [Text(vendor['category'] ?? '', style: TextStyle(color: Colors.grey.shade700)), const Spacer(), const Icon(Icons.star, color: Colors.orange), const SizedBox(width: 6), Text((vendor['rating'] ?? '-').toString())]),
                    const SizedBox(height: 12),
                    Text('Location', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(vendor['location'] ?? (vendor['city'] ?? '')),
                    const SizedBox(height: 12),
                    Text('Contact', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(vendor['phone'] ?? vendor['email'] ?? '-'),
                    const SizedBox(height: 12),
                    Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(vendor['description'] ?? '-'),
                  ]),
                ),
              ),
    );
  }
}
