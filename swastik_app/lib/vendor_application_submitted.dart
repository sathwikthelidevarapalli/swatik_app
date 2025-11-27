import 'package:flutter/material.dart';

class VendorApplicationSubmitted extends StatelessWidget {
  final String vendorId;
  final String applicationStatus;

  const VendorApplicationSubmitted({
    super.key,
    required this.vendorId,
    required this.applicationStatus,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFE55836);
    const Color lightBackground = Color(0xFFF7F7F7);
    const Color cardBackground = Colors.white;
    const Color lightBlue = Color(0xFFE3F2FD);
    const Color lightOrange = Color(0xFFFFFBEA);

    Widget _buildWhatNextStep(int number, String text) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$number',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                    fontSize: 14, color: Colors.black87, height: 1.4),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: lightBackground,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 80, bottom: 40),
              decoration: const BoxDecoration(
                color: primaryColor,
                borderRadius:
                BorderRadius.vertical(bottom: Radius.circular(40)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child:
                      Icon(Icons.access_time, color: Colors.white, size: 50),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Application Submitted!',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Thank you for registering with Swastik.\nYour vendor application is currently under review.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14, color: Colors.white.withOpacity(0.8)),
                  ),
                ],
              ),
            ),

            // Status Info
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: cardBackground,
                  borderRadius: BorderRadius.circular(24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Application ID',
                      style: TextStyle(fontSize: 14, color: Colors.black54)),
                  const SizedBox(height: 4),
                  Text(
                    '#$vendorId',
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: primaryColor),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.hourglass_bottom,
                          color: Colors.orange, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        applicationStatus == 'approved'
                            ? '✅ Approved'
                            : applicationStatus == 'rejected'
                            ? '❌ Rejected'
                            : '⏳ Under Review',
                        style: TextStyle(
                          color: applicationStatus == 'approved'
                              ? Colors.green
                              : applicationStatus == 'rejected'
                              ? Colors.red
                              : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    applicationStatus == 'approved'
                        ? 'Your profile has been verified and approved by the admin.'
                        : applicationStatus == 'rejected'
                        ? 'Your application was rejected. Please contact support.'
                        : 'Our team is verifying your business details and documents.',
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ],
              ),
            ),

            // What’s Next
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardBackground,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: lightBlue,
                        borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('✅ What\'s Next?',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87)),
                        const SizedBox(height: 16),
                        _buildWhatNextStep(
                            1, 'We\'ll review your application within 24–48 hours.'),
                        _buildWhatNextStep(
                            2, 'Our team will verify your documents and details.'),
                        _buildWhatNextStep(
                            3, 'We may contact you if additional information is required.'),
                        _buildWhatNextStep(
                            4, 'Once approved, you\'ll get access to your Vendor Dashboard.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text('Need Help?',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.email_outlined),
                            label: const Text('Email Us'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: lightOrange,
                                foregroundColor: primaryColor),
                          )),
                      const SizedBox(width: 10),
                      Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.phone_outlined),
                            label: const Text('Call Us'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: lightOrange,
                                foregroundColor: primaryColor),
                          )),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Support available Mon–Sat, 9 AM – 6 PM',
                      style: TextStyle(fontSize: 12, color: Colors.black54)),
                  const Divider(height: 40),
                  ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.popUntil(context, (route) => route.isFirst),
                    icon:
                    const Icon(Icons.home_outlined, color: Colors.black87),
                    label: const Text('Back to Home',
                        style: TextStyle(color: Colors.black87)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: lightBackground, elevation: 0),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Thank you for choosing Swastik 🎉',
                    style: TextStyle(fontSize: 12, color: primaryColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
