import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/colors.dart';
import 'main_screen.dart';
import '../auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Animasi Fade In
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    // Animasi Scale (Membesar sedikit biar dinamis)
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
      ),
    );

    // Animasi Slide Teks (Naik ke atas)
    _slideAnimation = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();

    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            session != null ? const MainScreen() : const LoginScreen(),
        transitionsBuilder: (_, a, __, c) =>
            FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Responsive sizing berdasarkan screen height
    final screenHeight = MediaQuery.of(context).size.height;
    final logoSize = screenHeight * 0.18; // ~18% dari screen height
    final mainFontSize = screenHeight * 0.045; // ~4.5% dari screen height
    final subFontSize = screenHeight * 0.02; // ~2% dari screen height

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryPink,
              Color(0xFFFF4DC4),
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- LOGO (Optimized untuk layar besar) ---
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: logoSize,
                        height: logoSize,
                        fit: BoxFit.contain,
                        color: Colors.white,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.account_balance_wallet_rounded,
                            size: logoSize * 0.8,
                            color: Colors.white,
                          );
                        },
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.04), // Responsive spacing

                  // --- TEKS JUDUL ---
                  Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          Text(
                            'Pinky Pay',
                            style: TextStyle(
                              fontSize: mainFontSize,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.5,
                              fontFamily: 'Poppins',
                              shadows: [
                                Shadow(
                                  offset: const Offset(0, 4),
                                  blurRadius: 10.0,
                                  color: Colors.black.withOpacity(0.2),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.015),
                          Text(
                            'Smart Way to Pay',
                            style: TextStyle(
                              fontSize: subFontSize,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.85),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
