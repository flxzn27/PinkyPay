import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../config/colors.dart';
import '../../models/user_model.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  UserModel? user;
  bool _isLoading = true;
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      if (mounted) {
        setState(() {
          user = UserModel.fromJson(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading wallet: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyLight,
      appBar: AppBar(
        title: const Text(
          'My Wallet',
          style: TextStyle(
            color: AppColors.darkPurple,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryPink))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. VIRTUAL CARD
                  _buildVirtualCard(),
                  
                  const SizedBox(height: 30),

                  // 2. STATS (INCOME / EXPENSE)
                  const Text(
                    'Finance Analysis',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkPurple),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildStatCard('Income', 2500000, Colors.green, Icons.arrow_downward)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildStatCard('Expense', 1200000, Colors.red, Icons.arrow_upward)),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // 3. LINKED METHODS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Linked Methods',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkPurple),
                      ),
                      TextButton(onPressed: () {}, child: const Text("See All", style: TextStyle(color: AppColors.primaryPink))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildLinkedCardItem("BCA", "**** 4589", "assets/images/bca_logo.png", const Color(0xFF005DAA)), // Ganti asset nanti
                  const SizedBox(height: 12),
                  _buildLinkedCardItem("Mandiri", "**** 1121", "assets/images/mandiri_logo.png", const Color(0xFF003D79)),
                  const SizedBox(height: 12),
                  _buildAddCardButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildVirtualCard() {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    
    return Container(
      width: double.infinity,
      height: 220,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient, // Gradasi Pink Khas
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPink.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pinky Pay',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, fontStyle: FontStyle.italic),
              ),
              Icon(Icons.nfc, color: Colors.white.withOpacity(0.8), size: 30),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chip Simulasi
              Container(
                width: 40, height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(6),
                ),
                margin: const EdgeInsets.only(bottom: 10),
              ),
              const Text(
                '**** **** **** 8829', // Nomor Kartu Dummy
                style: TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 2, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Card Holder', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10)),
                  Text(
                    user?.name.toUpperCase() ?? 'USER NAME',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Balance', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10)),
                  Text(
                    currencyFormat.format(user?.balance ?? 0),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, double amount, Color color, IconData icon) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(color: AppColors.greyText, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            currencyFormat.format(amount), // Nanti kita hitung real
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkPurple),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkedCardItem(String bankName, String number, String imagePath, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            width: 50, height: 35,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
            // Disini harusnya Image.asset, tapi kita pakai Text dulu sebagai placeholder jika asset belum ada
            child: Center(child: Text(bankName[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bankName, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkPurple)),
                Text(number, style: const TextStyle(color: AppColors.greyText, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.more_vert, color: AppColors.greyText),
        ],
      ),
    );
  }

  Widget _buildAddCardButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primaryPink.withOpacity(0.3), width: 1.5),
        borderRadius: BorderRadius.circular(16),
        color: AppColors.primaryPink.withOpacity(0.05),
      ),
      child: const Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_circle_outline, color: AppColors.primaryPink),
            SizedBox(width: 8),
            Text("Add New Card", style: TextStyle(color: AppColors.primaryPink, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}