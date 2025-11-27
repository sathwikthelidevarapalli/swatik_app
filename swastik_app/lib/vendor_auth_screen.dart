import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// UPDATED — Wizard screen
import 'vendor_registration_wizard.dart';
import 'vendor_home_screen.dart';

class VendorAuthScreen extends StatefulWidget {
  const VendorAuthScreen({super.key});

  @override
  State<VendorAuthScreen> createState() => _VendorAuthScreenState();
}

class _VendorAuthScreenState extends State<VendorAuthScreen> {
  final Color primaryColor = const Color(0xFFE55836);
  final Color darkLogoColor = const Color(0xFFE55836);
  final Color secondaryColor = const Color(0xFFF0F0F0);

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _isLoading = false;
  int _activeTab = 0; // 0 = Login, 1 = Sign Up

  final String baseUrl = "http://10.240.92.1:5000/api/vendors";

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // -----------------------------------------------------------------
  // AUTHENTICATION
  // -----------------------------------------------------------------
  Future<void> _authenticate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final endpoint = _activeTab == 0 ? "login" : "register";
    final url = Uri.parse("$baseUrl/$endpoint");

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          if (_activeTab == 1) 'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final vendorId = data['_id'] ?? data['vendor']?['_id'] ?? "";
        final vendorName = data['name'] ?? data['vendor']?['name'] ?? "Vendor";
        final token = data['token'] ?? '';

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('vendorId', vendorId);
        await prefs.setString('vendorName', vendorName);

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_activeTab == 0
              ? "Login Successful 🎉"
              : "Signup Successful, Continue Registration →"),
        ));

        // -------------------------------
        // UPDATED NAVIGATION
        // -------------------------------
        if (_activeTab == 1) {
          // → Go to FULL 5 STEP WIZARD
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => VendorRegistrationWizard(
                vendorId: vendorId,
                vendorName: vendorName,
              ),
            ),
          );
        } else {
          // → After login go to Vendor Dashboard (FIXED)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => VendorHomeScreen(
                vendorId: vendorId,
                vendorName: vendorName,
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Login failed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Connection Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // -----------------------------------------------------------------
  // CUSTOM TEXT FIELD UI
  // -----------------------------------------------------------------
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          validator: validator,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            filled: true,
            fillColor: Colors.white,
            hintText: isPassword
                ? "••••••••"
                : label.contains("Email")
                ? "your.email@example.com"
                : "Enter $label",
            prefixIcon: Icon(icon, color: Colors.grey.shade500),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // -----------------------------------------------------------------
  // TAB SWITCH UI (Login / Signup)
  // -----------------------------------------------------------------
  Widget _buildTabSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          _tabButton("Login", 0),
          _tabButton("Sign Up", 1),
        ],
      ),
    );
  }

  Expanded _tabButton(String text, int index) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: _activeTab == index ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: _activeTab == index
                    ? Colors.black
                    : Colors.grey.shade600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // -----------------------------------------------------------------
  // BUILD UI
  // -----------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: secondaryColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back_ios, color: Colors.black, size: 16),
              SizedBox(width: 4),
              Text("Back", style: TextStyle(color: Colors.black)),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Logo
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: darkLogoColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.star_half_rounded,
                    color: Colors.white, size: 30),
              ),
              const SizedBox(height: 16),

              Text(
                _activeTab == 0 ? "Welcome Back" : "Create Vendor Account",
                style:
                const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 30),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 8))
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTabSwitcher(),
                      const SizedBox(height: 24),

                      if (_activeTab == 1)
                        _buildTextField(
                          controller: _nameController,
                          label: "Full Name",
                          icon: Icons.person_outline,
                          validator: (v) =>
                          v!.isEmpty ? "Enter name" : null,
                        ),

                      _buildTextField(
                        controller: _emailController,
                        label: "Email",
                        icon: Icons.email_outlined,
                        validator: (v) =>
                        v!.isEmpty ? "Enter email" : null,
                      ),

                      _buildTextField(
                        controller: _passwordController,
                        label: "Password",
                        isPassword: true,
                        icon: Icons.lock_outline,
                        validator: (v) =>
                        v!.isEmpty ? "Enter password" : null,
                      ),

                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _authenticate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            padding:
                            const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                              color: Colors.white)
                              : Text(
                            _activeTab == 0
                                ? "Login"
                                : "Continue Registration →",
                            style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
