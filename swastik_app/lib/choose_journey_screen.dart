import 'package:flutter/material.dart';
import 'customer_auth_screen.dart';
import 'vendor_auth_screen.dart';
import 'admin_login.dart'; // ✅ Correct import for Admin Login

class ChooseJourneyScreen extends StatefulWidget {
  const ChooseJourneyScreen({super.key});

  @override
  State<ChooseJourneyScreen> createState() => _ChooseJourneyScreenState();
}

class _ChooseJourneyScreenState extends State<ChooseJourneyScreen> {
  final Color primaryColor = const Color(0xFFE55836);
  String? _selectedRole;

  void _navigateToRoleScreen(String role) {
    if (role == 'customer') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CustomerAuthScreen()),
      );
    } else if (role == 'vendor') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const VendorAuthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back_ios, color: Colors.black, size: 18),
              SizedBox(width: 4),
              Text(
                'Back',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 60,
      ),

      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const SizedBox(height: 20),

                const Text(
                  'Choose Your Journey',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Select your role to get started',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 40),

                // CUSTOMER CARD
                _buildRoleCard(
                  title: "I'm a Customer",
                  subtitle: 'Plan and book your perfect event',
                  icon: Icons.person_outline,
                  footerText: ['Find vendors', 'Book services', 'Celebrate'],
                  role: 'customer',
                  isSelected: _selectedRole == 'customer',
                ),

                const SizedBox(height: 20),

                // VENDOR CARD
                _buildRoleCard(
                  title: "I'm a Vendor",
                  subtitle: 'Grow your event business',
                  icon: Icons.work_outline,
                  footerText: ['Get bookings', 'Manage clients', 'Earn more'],
                  role: 'vendor',
                  isSelected: _selectedRole == 'vendor',
                ),

                const SizedBox(height: 40),

                // ---------------------------
                // ⭐ ADMIN LOGIN BUTTON (added)
                // ---------------------------
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminLogin(), // Correct class name
                      ),
                    );
                  },
                  child: const Text(
                    "Admin Login",
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // CARD WIDGET (unchanged)
  // ------------------------------------------------------------
  Widget _buildRoleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<String> footerText,
    required String role,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
        _navigateToRoleScreen(role);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? primaryColor.withAlpha(50)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: isSelected ? const Offset(0, 4) : const Offset(0, 2),
            ),
          ],
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ICON
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(icon, size: 32, color: Colors.white),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 20),

            role == 'customer'
                ? const Text('🎉🎊🎈', style: TextStyle(fontSize: 24))
                : const Text('💼📈', style: TextStyle(fontSize: 24)),

            const SizedBox(height: 10),

            Wrap(
              alignment: WrapAlignment.center,
              spacing: 4.0,
              runSpacing: 4.0,
              children: footerText.map((text) {
                return Text(
                  text + (footerText.last != text ? ' •' : ''),
                  style: TextStyle(
                    color: primaryColor.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
