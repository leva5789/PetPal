import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'app_theme.dart';

import 'dart:html' as html if (dart.library.io) 'dart:io';

class PetQRCodeDialog extends StatefulWidget {
  final String petId;
  final String petName;
  final String? petImageUrl;

  const PetQRCodeDialog({
    super.key,
    required this.petId,
    required this.petName,
    this.petImageUrl,
  });

  String get petProfileUrl {
    return 'https://petpal-9e193.web.app/#/pet/$petId';
  }

  static void show(
    BuildContext context, {
    required String petId,
    required String petName,
    String? petImageUrl,
  }) {
    showDialog(
      context: context,
      builder: (context) => PetQRCodeDialog(
        petId: petId,
        petName: petName,
        petImageUrl: petImageUrl,
      ),
    );
  }

  @override
  State<PetQRCodeDialog> createState() => _PetQRCodeDialogState();
}

class _PetQRCodeDialogState extends State<PetQRCodeDialog> {
  final GlobalKey _qrKey = GlobalKey();
  bool _isSaving = false;

  Future<void> _saveQRCode() async {
    setState(() => _isSaving = true);

    try {
      final qrPainter = QrPainter(
        data: widget.petProfileUrl,
        version: QrVersions.auto,
        gapless: true,
        color: const Color(0xFF000000),
        emptyColor: Colors.white,
      );

      final imageSize = 400.0;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      canvas.drawRect(
        Rect.fromLTWH(0, 0, imageSize, imageSize),
        Paint()..color = Colors.white,
      );

      qrPainter.paint(canvas, Size(imageSize, imageSize));

      final picture = recorder.endRecording();
      final img = await picture.toImage(imageSize.toInt(), imageSize.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Failed to generate image');
      }

      final pngBytes = byteData.buffer.asUint8List();

      if (kIsWeb) {
        _downloadOnWeb(pngBytes);
      } else {
        _showSuccessMessage('QR code ready for download');
      }
    } catch (e) {
      debugPrint('Error saving QR code: $e');
      _showErrorMessage('Failed to save QR code');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _downloadOnWeb(Uint8List bytes) {
    final blob = html.Blob([bytes], 'image/png');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', '${widget.petName}_qr_code.png')
      ..click();
    html.Url.revokeObjectUrl(url);
    _showSuccessMessage('QR code downloaded!');
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: AppTheme.mint,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppTheme.mintGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.qr_code_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Digital Tag',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.darkText,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.close,
                      color: isDark ? Colors.grey : Colors.black54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (widget.petImageUrl != null && widget.petImageUrl!.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.mintGradient,
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
                  backgroundImage: NetworkImage(widget.petImageUrl!),
                ),
              ).animate().scale(duration: 300.ms),
            const SizedBox(height: 12),
            Text(
              widget.petName,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.darkText,
              ),
            ),
            const SizedBox(height: 24),
            RepaintBoundary(
              key: _qrKey,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.mint.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: QrImageView(
                  data: widget.petProfileUrl,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
              ),
            )
                .animate()
                .fadeIn(delay: 200.ms)
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveQRCode,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.download_rounded, color: Colors.white),
                label: Text(
                  _isSaving ? 'Saving...' : 'Save QR Code',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.mint,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.mint.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: AppTheme.mint, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Print this QR code and attach it to your pet\'s collar!',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }
}
