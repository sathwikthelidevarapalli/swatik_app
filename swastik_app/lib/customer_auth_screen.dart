import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'customer_home_screen.dart';


class CustomerAuthScreen extends StatefulWidget {
  const CustomerAuthScreen({super.key});

  @override
  State<CustomerAuthScreen> createState() => _CustomerAuthScreenState();
}

class _CustomerAuthScreenState extends State<CustomerAuthScreen> with TickerProviderStateMixin {
  final Color primaryColor = const Color(0xFFE55836);
  final Color darkLogoColor = const Color(0xFFE55836);
  final Color secondaryColor = const Color(0xFFF0F0F0);

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  int _activeTab = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ✅ Authenticate Function (Login + Signup)
  Future<void> _authenticate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // ✅ Updated with your current IP
      String baseUrl = "http://10.240.92.1:5000";

      String url = _activeTab == 0
          ? "$baseUrl/api/users/login"
          : "$baseUrl/api/users/register";

      Map<String, String> body = _activeTab == 0
          ? {
        "email": _emailController.text.trim(),
        "password": _passwordController.text.trim(),
      }
          : {
        "name": _fullNameController.text.trim(),
        "email": _emailController.text.trim(),
        "password": _passwordController.text.trim(),
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);
      setState(() => _isLoading = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // ✅ Extract full name from backend
        final userName = data["name"] ??
            data["user"]?["name"] ??
            data["fullName"] ??
            data["user"]?["fullName"] ??
            _fullNameController.text.trim() ??
            "User";

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("${_activeTab == 0 ? 'Login' : 'Signup'} successful!"),
              backgroundColor: Colors.green,
            ),
          );

          // ✅ Go to home screen with user's full name
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CustomerHomeScreen(userName: userName),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["message"] ?? "Authentication failed"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // 🧩 Text Field Builder
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
            filled: true,
            fillColor: secondaryColor,
            hintText: isPassword ? '••••••••' : 'Enter $label',
            prefixIcon: Icon(icon, color: Colors.grey.shade600),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // 🧱 Build UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: secondaryColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back_ios, color: Colors.black, size: 18),
              SizedBox(width: 4),
              Text('Back', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w400)),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 60,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(color: darkLogoColor, borderRadius: BorderRadius.circular(12)),
                child: const Center(child: Icon(Icons.star_half_rounded, size: 30, color: Colors.white)),
              ),
              const SizedBox(height: 16),
              Text(
                _activeTab == 0 ? 'Welcome Back' : 'Create Account',
                style: const TextStyle(color: Colors.black87, fontSize: 24, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                _activeTab == 0 ? 'Login as a customer' : 'Sign up as a customer',
                style: const TextStyle(color: Colors.black54, fontSize: 14),
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
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTabSwitcher(),
                      const SizedBox(height: 24),
                      if (_activeTab == 1) ...[
                        _buildTextField(
                          controller: _fullNameController,
                          label: 'Full Name',
                          icon: Icons.person_outline,
                          validator: (v) => v!.isEmpty ? 'Enter your name' : null,
                        ),
                        _buildTextField(
                          controller: _phoneController,
                          label: 'Phone Number',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (v) => v!.length < 10 ? 'Invalid number' : null,
                        ),
                        _buildTextField(
                          controller: _addressController,
                          label: 'Address',
                          icon: Icons.location_on_outlined,
                          validator: (v) => v!.isEmpty ? 'Enter address' : null,
                        ),
                      ],
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => !v!.contains('@') ? 'Invalid email' : null,
                      ),
                      _buildTextField(
                        controller: _passwordController,
                        label: _activeTab == 0 ? 'Password' : 'Create Password',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
                      ),
                      if (_activeTab == 1)
                        _buildTextField(
                          controller: _confirmPasswordController,
                          label: 'Re-enter Password',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          validator: (v) =>
                          v != _passwordController.text ? 'Passwords do not match' : null,
                        ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _authenticate,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            backgroundColor: primaryColor,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                            _activeTab == 0 ? 'Login' : 'Sign Up',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // 🔁 Tab Switcher
  Widget _buildTabSwitcher() {
    return Container(
      decoration:
      BoxDecoration(color: secondaryColor, borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildTabButton('Login', 0),
          _buildTabButton('Sign Up', 1),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, int index) {
    final isActive = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2))
            ]
                : null,
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: isActive ? Colors.black87 : Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
