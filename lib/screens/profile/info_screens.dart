import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Opsional: Jika ingin tombol berfungsi
import '../../config/colors.dart';

// --- HALAMAN 1: HELP CENTER (PUSAT BANTUAN) ---
class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyLight, // Background sedikit abu agar konten pop-up
      appBar: AppBar(
        title: const Text("Help Center", style: TextStyle(color: AppColors.darkPurple, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: AppColors.darkPurple),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Search Bar Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              color: Colors.white,
              child: Column(
                children: [
                  const Text("How can we help you?", style: TextStyle(color: Colors.grey, fontSize: 16)),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Search for topics or questions...",
                      prefixIcon: const Icon(Icons.search, color: AppColors.primaryPink),
                      filled: true,
                      fillColor: AppColors.greyLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),

            // 2. FAQ List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Frequently Asked Questions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.darkPurple)),
                  const SizedBox(height: 12),
                  _FaqTile(
                    question: "How do I Top Up my balance?",
                    answer: "To top up, go to the Home screen and tap the 'Top Up' icon. You can choose diverse payment methods including BCA Virtual Account, Mandiri, GoPay, or via Indomaret/Alfamart.",
                  ),
                  _FaqTile(
                    question: "Is my transaction data safe?",
                    answer: "Absolutely. PinkyPay uses end-to-end encryption and is secured by Supabase's enterprise-grade security protocols. We also require PIN or Biometric authentication for every transaction.",
                  ),
                  _FaqTile(
                    question: "How to transfer to a friend?",
                    answer: "You can transfer by entering their email address in the search bar or simply scanning their QR Code. Transfers between PinkyPay users are instant and free of charge.",
                  ),
                  _FaqTile(
                    question: "Can I request a refund?",
                    answer: "Refunds for failed transactions are processed automatically within 1x24 hours. For merchant refunds, please contact the merchant directly or reach out to our support.",
                  ),
                  _FaqTile(
                    question: "Forgot my PIN?",
                    answer: "If you forgot your PIN, please logout and click 'Forgot PIN' on the login screen. You will receive a reset link via your registered email.",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 3. Contact Support Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.headset_mic_rounded, size: 40, color: AppColors.primaryPink),
                  const SizedBox(height: 12),
                  const Text("Still need help?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text("Our support team is available 24/7 to assist you.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        // Implementasi buka email/WA
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primaryPink),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text("Contact Support", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryPink)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String question, answer;
  const _FaqTile({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.darkPurple, fontSize: 14)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(answer, style: TextStyle(color: Colors.grey[600], height: 1.5, fontSize: 13)),
        ],
      ),
    );
  }
}

// --- HALAMAN 2: ABOUT PINKY PAY ---
class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("About", style: TextStyle(color: AppColors.darkPurple, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: AppColors.darkPurple),
      ),
      body: Column(
        children: [
          const Spacer(),
          // Logo Section
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.lightPeach.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Image.asset('assets/icons/pinkypay_logo.png', width: 80, height: 80, errorBuilder: (_,__,___) => const Icon(Icons.wallet, size: 60, color: AppColors.primaryPink)),
            ),
          ),
          const SizedBox(height: 24),
          const Text("Pinky Pay", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.darkPurple)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: AppColors.greyLight, borderRadius: BorderRadius.circular(20)),
            child: const Text("v1.0.0 (Beta)", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          
          const SizedBox(height: 32),
          
          // Description
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "PinkyPay is a social fintech application designed to make financial transactions fun, easy, and pink! Send money to friends, pay bills, and track expenses in one modern interface.",
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.6, color: Colors.grey),
            ),
          ),
          
          const SizedBox(height: 40),

          // Social Media Links (Visual Only)
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SocialIcon(Icons.camera_alt_outlined), // Instagram placeholder
              SizedBox(width: 20),
              _SocialIcon(Icons.language), // Website
              SizedBox(width: 20),
              _SocialIcon(Icons.email_outlined), // Email
            ],
          ),

          const Spacer(),
          
          // Action Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("You are using the latest version! 🚀")));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.greyLight,
                foregroundColor: AppColors.darkPurple,
                elevation: 0,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Check for Updates", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          
          // Copyright
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Text("© 2025 PinkyPay Inc. All rights reserved.", style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final IconData icon;
  const _SocialIcon(this.icon);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.darkPurple, size: 24),
      ),
    );
  }
}

// --- HALAMAN 3: TERMS & PRIVACY ---
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Terms & Privacy", style: TextStyle(color: AppColors.darkPurple, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: AppColors.darkPurple),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text("Last Updated: October 2025", style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 20),

          _buildSection("1. Acceptance of Terms", "By downloading, accessing, or using the PinkyPay application, you agree to be bound by these Terms and Conditions. If you do not agree, please do not use our services."),
          _buildSection("2. User Accounts", "You are responsible for maintaining the confidentiality of your account credentials (email and PIN). PinkyPay is not liable for any loss resulting from unauthorized access due to your negligence."),
          _buildSection("3. Privacy Policy", "We collect personal data such as your name, email, and transaction history to provide our services. We store this data securely on Supabase servers and do not share it with third parties without your consent."),
          _buildSection("4. Transaction Rules", "All transactions made through PinkyPay are final. Please verify the recipient's information before confirming any transfer. We are not responsible for user errors such as entering the wrong amount or recipient."),
          _buildSection("5. Prohibited Activities", "Users may not use PinkyPay for illegal activities, money laundering, or funding terrorism. We reserve the right to suspend accounts suspected of such activities."),
          _buildSection("6. Changes to Terms", "PinkyPay reserves the right to modify these terms at any time. Continued use of the app constitutes acceptance of the new terms."),
          
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryPink.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryPink.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified_user_outlined, color: AppColors.primaryPink),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Your privacy is our priority. We use industry-standard encryption to protect your data.",
                    style: TextStyle(color: AppColors.darkPurple, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkPurple)),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.6),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }
}