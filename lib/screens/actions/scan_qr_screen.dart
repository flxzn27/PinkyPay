import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart'; // Tambahkan image_picker
import '../../config/colors.dart';
import 'payment_screen.dart'; // Pastikan import ini ada

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
  final ImagePicker _picker = ImagePicker(); // Instance ImagePicker

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
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 24),
                    ),
                  ),
                  
                  const Text(
                    "Scan QR",
                    style: TextStyle(
                      color: Colors.white, 
                      fontWeight: FontWeight.bold, 
                      fontSize: 18,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                    ),
                  ),

                  // Tombol Flash
                  IconButton(
                    onPressed: () {
                      _controller.toggleTorch();
                      setState(() => _isFlashOn = !_isFlashOn);
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isFlashOn ? Icons.flash_on : Icons.flash_off,
                        color: _isFlashOn ? Colors.yellow : Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. TOMBOL GALERI (Floating Button di Bawah)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: GestureDetector(
                onTap: _scanFromGallery,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withOpacity(0.5)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.image_rounded, color: Colors.white),
                      SizedBox(width: 8),
                      Text("Scan from Gallery", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 5. TEKS PETUNJUK (Di Atas Tombol Galeri)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.only(bottom: 120), // Geser ke atas tombol galeri
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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

  // LOGIC AKSES GALERI
  Future<void> _scanFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final BarcodeCapture? capture = await _controller.analyzeImage(image.path);
    
    if (capture != null && capture.barcodes.isNotEmpty) {
      final String? code = capture.barcodes.first.rawValue;
      _handleQrCode(code);
    } else {
      _showError("No QR code found in image");
    }
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
      
      // Navigasi ke PaymentScreen
      // Kita perlu cara untuk mengirim data ke PaymentScreen. 
      // Jika PaymentScreen belum di-update untuk menerima argumen,
      // kita bisa passing data lewat constructor (yang sudah kita update sebelumnya).
      
      // Asumsi PaymentScreen sudah diupdate untuk menerima initialRecipientEmail
      // Tetapi karena PaymentScreen butuh callback onPayment dan onAddTransaction,
      // idealnya navigasi ini dilakukan dari MainScreen atau kita pass dummy callback 
      // (yang mana kurang ideal).
      
      // SOLUSI: Tampilkan dialog konfirmasi dulu, lalu pop dengan result.
      // Atau jika PaymentScreen bisa diakses langsung, kita push.
      
      // Di sini saya akan menggunakan pendekatan Dialog -> Pop with Result 
      // ATAU Push Replacement jika PaymentScreen mandiri.
      // Mengingat struktur navigasi, kita akan coba Push MaterialPageRoute.
      // Namun PaymentScreen butuh callback. 
      
      // SEMENTARA: Tampilkan SnackBar dan Dialog Konfirmasi.
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text("QR Detected"),
          content: Text("Transfer to $email?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _controller.start(); // Resume scanning
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx); // Close dialog
                Navigator.pop(context); // Close Scanner
                
                // TODO: Idealnya di sini kita kirim data balik ke halaman sebelumnya
                // atau gunakan State Management untuk menavigasi ke PaymentScreen.
                // Untuk sekarang, kita beri info ke user.
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Please go to 'Send' menu and enter: $email")),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPink),
              child: const Text("OK", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

    } else {
      // Jika QR salah, resume kamera lagi setelah 2 detik
      _showError("Invalid PinkyPay QR Code");
    }
  }
  
  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _controller.start();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}