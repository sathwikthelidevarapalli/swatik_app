import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'choose_journey_screen.dart'; // REQUIRED: For navigation

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Swastik App',
      home: ExactImageTwoSplashScreen(), // Using the specific splash screen
    );
  }
}

class ExactImageTwoSplashScreen extends StatelessWidget {
  const ExactImageTwoSplashScreen({super.key});

  // Custom colors derived precisely from Image 2
  static const Color iconBackgroundOrange = Color(0xFFFF7A24); // Darker orange for the icon background
  static const Color iconOutlineOrange = Color(0xFFFF9233);   // Lighter orange for icon outline and glow
  static const Color appNameColor = Color(0xFFC04F18);       // Darker orange for "Swastik"
  static const Color taglineColor = Color(0xFF90451B);       // Slightly darker for tagline
  static const Color buttonBorderColor = Color(0xFFE9E9E9);  // Very light grey border for P/B/C buttons
  static const Color buttonTextColor = Color(0xFFC04F18);    // Same as app name for P/B/C text
  static const Color ctaButtonStartColor = Color(0xFFFF7A24); // Start color of gradient
  static const Color ctaButtonEndColor = Color(0xFFFF9133);   // End color of gradient

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Pure white background
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0), // Padding to match the image
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // --- Logo Circle ---
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: iconBackgroundOrange, // Darker orange background for icon
                  shape: BoxShape.circle,
                  // Adding a subtle shadow/glow matching the image
                  boxShadow: [
                    BoxShadow(
                      color: iconOutlineOrange.withOpacity(0.5), // Lighter orange glow
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  // Using Icons.star_border to get the outlined four-pointed star look
                  Icons.star_border, // This is the closest native icon for the image's logo
                  color: Colors.white,
                  size: 50,
                ),
              ),
              const SizedBox(height: 20), // Spacing below logo

              // --- App Name ---
              Text(
                'Swastik',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: appNameColor,
                ),
              ),
              const SizedBox(height: 5), // Spacing between name and tagline

              // --- Tagline ---
              Text(
                'Your One-Stop Event Planner',
                style: TextStyle(
                  fontSize: 16,
                  color: taglineColor,
                ),
              ),

              const SizedBox(height: 50), // Spacing before action buttons

              // --- Action Buttons (Plan, Book, Celebrate) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Distribute evenly
                children: [
                  _buildActionButton('Plan'),
                  _buildActionButton('Book'),
                  _buildActionButton('Celebrate'),
                ],
              ),

              const SizedBox(height: 70), // Spacing before Get Started button

              // --- Get Started Button (CTA) ---
              SizedBox(
                width: 250, // Specific width to match the image
                height: 55, // Height to match the image
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30.0),
                    gradient: const LinearGradient(
                      colors: [ctaButtonStartColor, ctaButtonEndColor],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: ctaButtonStartColor.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      // **NAVIGATION IMPLEMENTATION**
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ChooseJourneyScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent, // Make button background transparent to show gradient
                      shadowColor: Colors.transparent,    // Remove default button shadow
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      'Get Started',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget to build the "Plan/Book/Celebrate" buttons for Image 2
  Widget _buildActionButton(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), // Padding to match the image
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25), // Rounded corners
        border: Border.all(color: buttonBorderColor, width: 1.5), // Subtle border
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1), // Subtle shadow
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: buttonTextColor,
          fontSize: 16,
        ),
      ),
    );
  }
}
