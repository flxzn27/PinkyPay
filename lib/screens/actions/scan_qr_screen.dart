import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/colors.dart';
import 'payment_screen.dart';
import 'friend_screen.dart';
import '../../widgets/pinky_popup.dart';

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

    try {
      // Format 1: Transfer QR Code
      if (code.startsWith('pinkypay:transfer_to:')) {
        final parts = code.split(':');
        if (parts.length < 3) {
          _showError("Invalid Transfer QR Code Format");
          return;
        }
        
        final email = parts[2];
        _navigateToPayment(email);

      // Format 2: Add Friend QR Code
      } else if (code.startsWith('pinkypay:add_friend:')) {
        final parts = code.split(':');
        if (parts.length < 3) {
          _showError("Invalid Add Friend QR Code Format");
          return;
        }
        
        final email = parts[2];
        _navigateToAddFriend(email);

      } else {
        _showError("Invalid PinkyPay QR Code");
      }
    } catch (e) {
      _showError("Error reading QR Code: ${e.toString()}");
    }
  }

  /// Navigate ke Payment Screen dengan recipient email dari QR
  void _navigateToPayment(String email) {
    // Close scanner dan navigate
    Navigator.pop(context);
    
    // Kita perlu mendapatkan current balance dari parent widget
    // Karena parent widget (root/main) memiliki state dengan balance
    // Kita bisa pass callback via Navigator result
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          currentBalance: 1000000, // Dummy value - parent harus pass yang real
          onPayment: (amount, isDebit) {
            // Dummy callback
          },
          onAddTransaction: (transaction) {
            // Dummy callback
          },
          initialRecipientEmail: email,
        ),
      ),
    ).then((_) {
      // Jika kembali dari payment, resume scanning
      _controller.start();
    });
  }

  /// Navigate ke Add Friend Screen dengan email dari QR
  void _navigateToAddFriend(String email) {
    // Tampilkan konfirmasi dialog dulu sebelum add friend
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add Friend"),
        content: Text("Add $email as a friend?"),
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
              Navigator.pop(ctx);
              _addFriendFromQr(email);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPink),
            child: const Text("Add", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Proses add friend dari QR code
  Future<void> _addFriendFromQr(String email) async {
    try {
      final supabase = Supabase.instance.client;
      final currentUserId = supabase.auth.currentUser!.id;

      // Get target user by email
      final targetUserResponse = await supabase
          .from('profiles')
          .select('id, username')
          .eq('email', email)
          .single();

      final targetUserId = targetUserResponse['id'];
      final targetUsername = targetUserResponse['username'] ?? email;

      // Check if already friends
      final existingFriend = await supabase
          .from('friends')
          .select()
          .eq('user_id', currentUserId)
          .eq('friend_id', targetUserId);

      if (existingFriend.isNotEmpty) {
        PinkyPopUp.show(
          context,
          type: PopUpType.warning,
          title: "Already Friends",
          message: "Kamu udah berteman dengan $targetUsername",
        );
        Navigator.pop(context);
        return;
      }

      // Add friend
      await supabase.from('friends').insert({
        'user_id': currentUserId,
        'friend_id': targetUserId,
        'created_at': DateTime.now().toIso8601String(),
      });

      PinkyPopUp.show(
        context,
        type: PopUpType.success,
        title: "Friend Added",
        message: "$targetUsername ditambahkan ke Pinky Circle mu!",
      );

      // Close scanner and go back
      Navigator.pop(context);
    } catch (e) {
      PinkyPopUp.show(
        context,
        type: PopUpType.error,
        title: "Error",
        message: "Gagal menambah teman: ${e.toString()}",
      );
      _controller.start();
    }
  }
  
  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
    
    // Auto resume scanning after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _controller.start();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}