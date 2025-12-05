import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../config/colors.dart';
// import 'payment_screen.dart'; // Opsional: Uncomment jika logika navigasi sudah siap

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  // Controller kamera
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
    torchEnabled: false,
  );
  
  bool _isFlashOn = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. KAMERA SCANNER (Full Screen)
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                _handleQrCode(barcode.rawValue);
              }
            },
          ),

          // 2. OVERLAY BINGKAI
          _buildScanOverlay(),

          // 3. TOMBOL KONTROL (Close & Flash)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Tombol Close
                  // Karena halaman ini di-PUSH, Navigator.pop() akan menutupnya dan KEMBALI ke MainScreen
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  ),
                  
                  // Tombol Flash
                  IconButton(
                    onPressed: () {
                      _controller.toggleTorch();
                      setState(() => _isFlashOn = !_isFlashOn);
                    },
                    icon: Icon(
                      _isFlashOn ? Icons.flash_on : Icons.flash_off,
                      color: _isFlashOn ? Colors.yellow : Colors.white,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. TEKS PETUNJUK (Di Bawah)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.only(bottom: 100),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Scan QR Code to Pay",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Align the QR code within the frame",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      shadows: [const Shadow(blurRadius: 10, color: Colors.black)],
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildScanOverlay() {
    return Center(
      child: Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primaryPink, width: 2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            Positioned(top: 0, left: 0, child: _corner(0)),
            Positioned(top: 0, right: 0, child: _corner(90)),
            Positioned(bottom: 0, right: 0, child: _corner(180)),
            Positioned(bottom: 0, left: 0, child: _corner(270)),
          ],
        ),
      ),
    );
  }

  Widget _corner(double angle) {
    return RotationTransition(
      turns: AlwaysStoppedAnimation(angle / 360),
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.primaryPink, width: 6),
            left: BorderSide(color: AppColors.primaryPink, width: 6),
          ),
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20)),
        ),
      ),
    );
  }

  void _handleQrCode(String? code) {
    if (code == null) return;

    // Cegah scan berulang kali dengan pause kamera
    _controller.stop(); 

    if (code.startsWith('pinkypay:transfer_to:')) {
      final email = code.split(':')[2];
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("QR Detected: Kirim ke $email")),
      );

      // TODO: Arahkan ke PaymentScreen dengan membawa parameter email
      // Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentScreen(...)));

    } else {
      // Jika QR salah, resume kamera lagi setelah 2 detik
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid PinkyPay QR Code")),
      );
      Future.delayed(const Duration(seconds: 2), () {
        _controller.start();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}