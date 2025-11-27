import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Import screens from your functionality (Code 2)
import 'manage_bookings_screen.dart';
import 'vendor_messages_screen.dart';
import 'vendor_earnings_screen.dart';
import 'vendor_profile_edit_screen.dart';

class VendorHomeScreen extends StatefulWidget {
  final String vendorId;
  final String vendorName;

  const VendorHomeScreen({
    super.key,
    required this.vendorId,
    required this.vendorName,
  });

  @override
  State<VendorHomeScreen> createState() => _VendorHomeScreenState();
}

class _VendorHomeScreenState extends State<VendorHomeScreen> {
  final Color primaryColor = const Color(0xFFFF7A00);
  final Color secondaryColor = const Color(0xFFFF5C00);

  bool loading = true;

  String vendorName = "Vendor";

  int totalBookings = 0;
  int totalEarnings = 0;
  double avgRating = 0.0;
  int profileViews = 0;

  List<dynamic> recentBookings = [];

  static const String baseIp = "http://10.240.92.1:5000";

  @override
  void initState() {
    super.initState();
    vendorName = widget.vendorName;
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    try {
      final url = Uri.parse("$baseIp/api/vendors/dashboard/${widget.vendorId}");
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        setState(() {
          totalBookings = data["totalBookings"] ?? 0;
          totalEarnings = data["totalEarnings"] ?? 0;
          avgRating = (data["avgRating"] ?? 0).toDouble();
          profileViews = data["profileViews"] ?? 0;
          recentBookings = data["recentBookings"] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Dashboard Error: $e");
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),

      // ❌ Removed Floating AI Button Completely
      floatingActionButton: null,

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 10),
            _buildStatsGrid(),
            _sectionTitle("Recent Bookings", showViewAll: true),
            _buildRecentBookings(),
            _sectionTitle("Quick Actions", showViewAll: false),
            _buildQuickActions(),

            // ❌ Removed AI Insights section
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------
  // HEADER (Same as Code 1)
  // --------------------------------------------------------------
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 55, 20, 25),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        gradient: LinearGradient(
          colors: [
            Color(0xFFFF7A00),
            Color(0xFFFF5C00),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          const SizedBox(width: 12),

          // Welcome Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome, ${vendorName.toLowerCase()} 👋",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Here's your business overview",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          // Notification icons (same UI)
          _headerIcon(Icons.chat_bubble_outline, "4"),
          const SizedBox(width: 12),
          _headerIcon(Icons.calendar_today, "2"),
          const SizedBox(width: 12),
          _headerIcon(Icons.settings, ""),
        ],
      ),
    );
  }

  Widget _headerIcon(IconData icon, String badge) {
    return Stack(
      children: [
        Icon(icon, color: Colors.white, size: 26),
        if (badge.isNotEmpty)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.red.shade700,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                badge,
                style: const TextStyle(color: Colors.white, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ),
          )
      ],
    );
  }

  // --------------------------------------------------------------
  // STAT CARDS (Same as Code 1)
  // --------------------------------------------------------------
  Widget _buildStatsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: GridView.count(
        crossAxisCount: 2,
        childAspectRatio: 1.35,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        children: [
          _statCard("Total Bookings", "$totalBookings",
              Icons.calendar_today, Colors.blue),
          _statCard("Total Earnings", "₹$totalEarnings",
              Icons.currency_rupee, Colors.green),
          _statCard("Avg. Rating", avgRating.toStringAsFixed(1),
              Icons.star, Colors.orange),
          _statCard("Profile Views", "$profileViews",
              Icons.people, Colors.deepPurple),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color iconColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: iconColor.withOpacity(0.15),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const Spacer(),
            ],
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          Text(
            title,
            style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------
  // RECENT BOOKINGS
  // --------------------------------------------------------------
  Widget _buildRecentBookings() {
    if (recentBookings.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 5)),
          ],
        ),
        child: const Center(
          child: Text("No bookings yet",
              style: TextStyle(color: Colors.grey, fontSize: 14)),
        ),
      );
    }

    return Column(
      children: recentBookings.map((b) {
        return ListTile(
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          title: Text(b["customerName"]),
          subtitle: Text("${b["eventType"]} • ${b["date"]}"),
          trailing: Text("₹${b["amount"]}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        );
      }).toList(),
    );
  }

  // --------------------------------------------------------------
  // QUICK ACTIONS (UI from Code 1 + FUNCTIONALITY FROM CODE 2)
  // --------------------------------------------------------------
  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 2.4,
        ),
        children: [
          _actionTile(
            "Manage Bookings",
            Icons.calendar_today,
            ManageBookingsScreen(
              vendorId: widget.vendorId,
              vendorName: widget.vendorName,
            ),
          ),
          _actionTile(
            "Messages",
            Icons.message,
            MessagesScreen(
              vendorId: widget.vendorId,
              vendorName: widget.vendorName,
            ),
          ),
          _actionTile(
            "View Earnings",
            Icons.attach_money,
            ViewEarningsScreen(
              vendorId: widget.vendorId,
              vendorName: widget.vendorName,
            ),
          ),
          _actionTile(
            "Edit Profile",
            Icons.settings,
            VendorProfileEditScreen(
              vendorId: widget.vendorId,
              vendorName: widget.vendorName,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile(String label, IconData icon, Widget screen) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => screen)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 5)),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: primaryColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------
  // SECTION TITLE
  // --------------------------------------------------------------
  Widget _sectionTitle(String title,
      {bool showViewAll = false, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style:
            const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          if (showViewAll)
            Text(
              "View All",
              style: TextStyle(
                  color: primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );
  }
}
