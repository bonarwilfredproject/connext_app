import 'dart:convert';
import 'package:animate_do/animate_do.dart';
import 'package:connext_app/constants/app_theme.dart';
import 'package:connext_app/pages/scanner/corner_painter.dart';
import 'package:connext_app/services/check_in_controller.dart';
import 'package:connext_app/widgets/ellipse_background.dart';
import 'package:connext_app/constants/style_text.dart';
import 'package:connext_app/widgets/tombol_sementara.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vibration/vibration.dart';
import 'package:vibration/vibration_presets.dart';
import 'package:image_picker/image_picker.dart';

class ScanPesertaPage extends StatefulWidget {
  final int eventId;

  const ScanPesertaPage({super.key, required this.eventId});

  @override
  State<ScanPesertaPage> createState() => _ScanPesertaPageState();
}

class _ScanPesertaPageState extends State<ScanPesertaPage>
    with SingleTickerProviderStateMixin {
  final MobileScannerController controller = MobileScannerController();

  late AnimationController scanAnimation;
  late Animation<double> scanPosition;

  bool isProcessing = false;
  String processingMessage = 'Processing QR code...';

  void _setProcessing(bool value, {String? message}) {
    if (!mounted) return;

    setState(() {
      isProcessing = value;
      if (message != null && message.trim().isNotEmpty) {
        processingMessage = message;
      }
    });
  }

  Widget buildCorner() {
    return SizedBox(
      width: 40,
      height: 40,
      child: CustomPaint(painter: CornerPainter()),
    );
  }

  @override
  void initState() {
    super.initState();

    scanAnimation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    scanPosition = Tween<double>(
      begin: -120,
      end: 120,
    ).animate(CurvedAnimation(parent: scanAnimation, curve: Curves.easeInOut));

    scanAnimation.repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    scanAnimation.dispose();
    super.dispose();
  }

  void restartScanner() {
    if (!mounted) return;

    _setProcessing(false);
    controller.start();
  }

  Future<void> _safeVibrate() async {
    try {
      final hasVibrator = await Vibration.hasVibrator() ?? false;
      if (!hasVibrator) return;

      await Vibration.vibrate(preset: VibrationPreset.quickSuccessAlert);
    } catch (_) {
      // Ignore vibration failures; scanning/check-in should still proceed.
    }
  }

  Future<void> scanFromGallery() async {
    final ImagePicker picker = ImagePicker();

    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    /// hentikan kamera supaya tidak bentrok
    controller.stop();

    try {
      bool success = await controller.analyzeImage(image.path);

      /// jika tidak ada QR di gambar
      if (!success) {
        showErrorDialog("QR Code can't be found in picture");
        restartScanner();
        await _safeVibrate();
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pop(context, "error");
        });
      }

      /// jika success → onDetect() akan terpanggil otomatis
      /// dan _handleQrScan() akan berjalan
    } catch (e) {
      showErrorDialog("QR Code can't be read");
      restartScanner();
      await _safeVibrate();
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pop(context, "error");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        title: Text("Scan Attendee", style: styleText()),
        backgroundColor: AppTheme.primary,
        elevation: 0,
      ),
      body: Stack(
        children: [
          EllipseBackground(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              children: [
                Text(
                  "Direct the attendee QR Code\ninside the box",
                  textAlign: TextAlign.center,
                  style: styleText(),
                ),
                const SizedBox(height: 20),

                /// SCANNER
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 270,
                        width: 270,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          color: Colors.black,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: MobileScanner(
                            controller: controller,
                            onDetect: (capture) {
                              if (isProcessing) return;

                              final Barcode barcode = capture.barcodes.first;
                              final String code = barcode.rawValue ?? "";

                              if (code.isNotEmpty) {
                                _handleQrScan(code);
                              }
                            },
                          ),
                        ),
                      ),

                      /// FRAME
                      Container(
                        height: 270,
                        width: 270,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: AppTheme.secondary,
                            width: 1.5,
                          ),
                        ),
                      ),

                      /// CORNERS
                      SizedBox(
                        height: 270,
                        width: 270,
                        child: Stack(
                          children: [
                            Positioned(top: 0, left: 0, child: buildCorner()),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Transform.rotate(
                                angle: 90 * 3.1416 / 180,
                                child: buildCorner(),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              child: Transform.rotate(
                                angle: -90 * 3.1416 / 180,
                                child: buildCorner(),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Transform.rotate(
                                angle: 180 * 3.1416 / 180,
                                child: buildCorner(),
                              ),
                            ),
                          ],
                        ),
                      ),

                      /// SCAN LASER
                      AnimatedBuilder(
                        animation: scanPosition,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, scanPosition.value),
                            child: Container(
                              width: 220,
                              height: 4,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    AppTheme.secondary,
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                Text("QR will be read automatically", style: styleText()),

                const SizedBox(height: 12),

                TombolSementara(
                  onPressed: isProcessing ? null : scanFromGallery,
                  icon: Icons.photo_library,
                  text: "Upload from Gallery",
                  width: 220,
                  height: 45,
                  isLoading: isProcessing,
                ),
              ],
            ),
          ),
          if (isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.45),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.third,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Processing...',
                          style: styleText().copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          processingMessage,
                          style: styleText().copyWith(fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// ERROR
  void showErrorDialog(String pesan) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShakeX(child: Icon(Icons.cancel, color: Colors.red, size: 80)),
            const SizedBox(height: 16),
            const Text(
              "Scan Failed",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(pesan, textAlign: TextAlign.center),
          ],
        ),
      ),
    );

    controller.stop();

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) Navigator.pop(context);
      restartScanner();
    });
  }

  /// SUCCESS
  void showSuccessDialog(String nama) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tada(
              child: Icon(Icons.check_circle, color: Colors.green, size: 80),
            ),
            const SizedBox(height: 16),
            const Text(
              "Check-in Successful!",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(nama),
          ],
        ),
      ),
    );

    controller.stop();

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) Navigator.pop(context);
      restartScanner();
    });
  }

  /// HANDLE SCAN
  String? _extractToken(String code) {
    final raw = code.trim();
    if (raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final token = decoded['token']?.toString().trim();
        if (token != null && token.isNotEmpty) return token;
      }
    } catch (_) {
      // Ignore JSON parse errors and fall back to plain payload handling.
    }

    return raw;
  }

  int? _toIntFlexible(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();

    final text = value.toString().trim();
    if (text.isEmpty) return null;

    return int.tryParse(text);
  }

  Future<void> _handleQrScan(String code) async {
    if (isProcessing) return;

    _setProcessing(true, message: 'Validating attendee QR...');
    controller.stop();

    try {
      final token = _extractToken(code);
      if (token == null || token.isEmpty) {
        showErrorDialog("Invalid QR code");
        await _safeVibrate();
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pop(context, "invalid");
        });
        return;
      }

      int eventId = widget.eventId;

      /// cari participant berdasarkan token
      _setProcessing(true, message: 'Checking attendee data...');
      final participant = await CheckinController.getParticipantByToken(
        token,
        eventId,
      );

      if (participant == null) {
        showErrorDialog("Participant is not registered for this event");
        await _safeVibrate();
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pop(context, "error");
        });
        return;
      }

      final participantId = _toIntFlexible(participant["id"]);
      final nama = participant["nama"]?.toString() ?? "Peserta";
      final participantDocId = participant["doc_id"]?.toString().trim();
      final alreadyCheckedIn = participant["checkin_time"] != null;

      if (participantId == null || participantId <= 0) {
        showErrorDialog("Participant data is invalid");
        await _safeVibrate();
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pop(context, "error");
        });
        return;
      }

      /// cek sudah checkin
      if (alreadyCheckedIn) {
        showErrorDialog("Participant has already checked in");
        await _safeVibrate();
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pop(context, "already checked in");
        });
        return;
      }

      /// update checkin
      _setProcessing(true, message: 'Saving attendee check-in...');
      if (participantDocId != null && participantDocId.isNotEmpty) {
        await CheckinController.checkinParticipantByDocId(
          eventId,
          participantDocId,
        );
      } else {
        await CheckinController.checkinParticipant(participantId);
      }

      await _safeVibrate();

      showSuccessDialog(nama);
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pop(context, "success");
      });
    } catch (e) {
      showErrorDialog("Failed to process QR, please try again");
      await _safeVibrate();
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pop(context, "error");
      });
    }
  }
}
