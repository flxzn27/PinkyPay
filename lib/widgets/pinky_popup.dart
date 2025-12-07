import 'package:flutter/material.dart';
import '../config/colors.dart';

// Tambahkan tipe baru sesuai jumlah maskot
enum PopUpType { 
  success, error, warning, info, 
  confused, rich, love, waiting 
}

class PinkyPopUp {
  
  static void show(
    BuildContext context, {
    required PopUpType type,
    required String title,
    required String message,
    String? btnText,
    VoidCallback? onPressed,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _PinkyDialog(
        type: type,
        title: title,
        message: message,
        btnText: btnText,
        onPressed: onPressed,
      ),
    );
  }
}

class _PinkyDialog extends StatelessWidget {
  final PopUpType type;
  final String title;
  final String message;
  final String? btnText;
  final VoidCallback? onPressed;

  const _PinkyDialog({
    required this.type,
    required this.title,
    required this.message,
    this.btnText,
    this.onPressed,
  });

  // LOGIKA PEMILIHAN GAMBAR (Sesuai 9 file tadi)
  String get _getMascotImage {
    switch (type) {
      case PopUpType.success:
        return 'assets/images/mascot_success.png';
      case PopUpType.error:
        return 'assets/images/mascot_error.png';
      case PopUpType.warning:
        return 'assets/images/mascot_shocked.png'; // Pakai yang kaget
      case PopUpType.confused:
        return 'assets/images/mascot_confused.png';
      case PopUpType.rich:
        return 'assets/images/mascot_rich.png';
      case PopUpType.love:
        return 'assets/images/mascot_love.png';
      case PopUpType.waiting:
        return 'assets/images/mascot_waiting.png';
      case PopUpType.info:
      default:
        return 'assets/images/mascot_info.png';
    }
  }

  // LOGIKA WARNA
  Color get _getColor {
    switch (type) {
      case PopUpType.success:
      case PopUpType.rich:
      case PopUpType.love:
        return Colors.green;
      
      case PopUpType.error:
        return Colors.redAccent;
      
      case PopUpType.warning:
      case PopUpType.confused:
        return Colors.orange;
      
      case PopUpType.info:
      case PopUpType.waiting:
      default:
        return AppColors.primaryPink;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 60),
            padding: const EdgeInsets.fromLTRB(20, 70, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _getColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.greyText,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      if (onPressed != null) onPressed!();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    child: Text(
                      btnText ?? "Okay",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            child: Image.asset(
              _getMascotImage,
              width: 130, // Ukuran agak besar biar ekspresinya kelihatan
              height: 130,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Fallback kalau gambar belum ada
                return CircleAvatar(
                  radius: 60,
                  backgroundColor: AppColors.lightPeach,
                  child: Icon(Icons.sentiment_satisfied_alt, size: 50, color: _getColor),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}