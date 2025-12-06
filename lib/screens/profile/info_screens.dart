import 'package:flutter/material.dart';
import '../../config/colors.dart';

// --- HALAMAN 1: HELP CENTER ---
class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Help Center", style: TextStyle(color: AppColors.darkPurple, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: AppColors.darkPurple),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          Text("FAQ", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          _FaqTile("How to Top Up?", "You can top up via BCA, Mandiri, or Indomaret."),
          _FaqTile("Is PinkyPay Safe?", "Yes! We use Supabase security and encrypted PINs."),
          _FaqTile("Can I refund?", "Refunds are processed within 3 working days."),
          _FaqTile("How to add friends?", "Use the QR Scanner or search by email."),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String q, a;
  const _FaqTile(this.q, this.a);

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(q, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkPurple)),
      children: [Padding(padding: const EdgeInsets.all(16), child: Text(a))],
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
      appBar: AppBar(leading: const BackButton(color: AppColors.darkPurple), backgroundColor: Colors.white, elevation: 0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.lightPeach, shape: BoxShape.circle),
              child: const Icon(Icons.wallet, size: 60, color: AppColors.primaryPink),
            ),
            const SizedBox(height: 24),
            const Text("Pinky Pay", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primaryPink)),
            const Text("Version 1.0.0", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 40),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "PinkyPay is a modern social fintech app designed to make transactions fun and easy. Built with Flutter & Supabase.",
                textAlign: TextAlign.center,
                style: TextStyle(height: 1.5, color: AppColors.darkPurple),
              ),
            ),
          ],
        ),
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
      appBar: AppBar(
        title: const Text("Terms & Privacy", style: TextStyle(color: AppColors.darkPurple)),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: const BackButton(color: AppColors.darkPurple),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("1. Introduction", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 8),
            Text("Welcome to PinkyPay. By using our app, you agree to these terms..."),
            SizedBox(height: 24),
            Text("2. Privacy Policy", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 8),
            Text("We respect your privacy. Your data is stored securely on Supabase servers..."),
            SizedBox(height: 24),
            Text("3. Payments", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 8),
            Text("All transactions are final. Please double-check before transferring money..."),
          ],
        ),
      ),
    );
  }
}