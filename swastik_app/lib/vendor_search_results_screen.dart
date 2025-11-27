import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'vendor_details_screen.dart';

const String apiBase = "http://10.240.92.1:5000";

class VendorSearchResultsScreen extends StatefulWidget {
  final String city;
  const VendorSearchResultsScreen({super.key, required this.city});

  @override
  State<VendorSearchResultsScreen> createState() => _VendorSearchResultsScreenState();
}

class _VendorSearchResultsScreenState extends State<VendorSearchResultsScreen> {
  bool loading = true;
  String? error;
  List vendors = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final uri = Uri.parse('$apiBase/api/vendors?city=${Uri.encodeComponent(widget.city)}');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final dec = jsonDecode(res.body);
        vendors = dec['vendors'] ?? [];
      } else {
        error = 'Server returned ${res.statusCode}';
        vendors = [];
      }
    } catch (e) {
      error = 'Failed to load vendors';
      vendors = [];
    }

    setState(() => loading = false);
  }

  Widget _vendorCard(Map v) {
    final img = (v['imageUrl'] ?? '').toString();
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: InkWell(
        onTap: () async {
          // navigate to details screen with vendor id
          final id = v['id'] ?? v['_id'] ?? v['vendorId'];
          if (id != null) {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => VendorDetailsScreen(vendorId: id.toString())),
            );
            // optionally refresh after returning
            _fetch();
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (img.isNotEmpty)
              ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(12)), child: Image.network(img, height: 160, width: double.infinity, fit: BoxFit.cover))
            else
              Container(height: 160, color: Colors.grey.shade200),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(v['name'] ?? v['businessName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 6),
                Text(v['category'] ?? '', style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(child: Text(v['location'] ?? (v['city'] ?? ''), style: TextStyle(color: Colors.grey.shade600))),
                  const Spacer(),
                  const Icon(Icons.star, color: Colors.orange, size: 14),
                  const SizedBox(width: 6),
                  Text((v['rating'] ?? '-').toString(), style: TextStyle(color: Colors.grey.shade600)),
                ])
              ]),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Vendors in ${widget.city}'), backgroundColor: Colors.orange),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(mainAxisSize: MainAxisSize.min, children: [Text(error!, style: TextStyle(color: Colors.red)), const SizedBox(height: 12), ElevatedButton(onPressed: _fetch, child: const Text('Retry'))]),
              ))
              : vendors.isEmpty
                  ? Center(child: Text('No vendors found in ${widget.city}'))
                  : ListView.builder(
                      itemCount: vendors.length,
                      itemBuilder: (_, i) => _vendorCard(vendors[i]),
                    ),
    );
  }
}
