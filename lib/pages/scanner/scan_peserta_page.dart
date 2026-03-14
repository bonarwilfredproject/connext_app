import 'dart:convert';
import 'package:animate_do/animate_do.dart';
import 'package:connext_app/constants/app_theme.dart';
import 'package:connext_app/pages/scanner/corner_painter.dart';
import 'package:connext_app/services/check_in_controller.dart';
import 'package:connext_app/widgets/ellipse_background.dart';
import 'package:connext_app/constants/style_text.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vibration/vibration.dart';
import 'package:vibration/vibration_presets.dart';

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

    isProcessing = false;
    controller.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        title: Text("Scan Peserta", style: styleText()),
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
                  "Arahkan QR Code peserta\nke dalam kotak",
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
                Text("QR akan terbaca otomatis", style: styleText()),
              ],
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
              "Scan Gagal",
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
              "Check-in Berhasil!",
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
  Future<void> _handleQrScan(String code) async {
    if (isProcessing) return;

    isProcessing = true;
    controller.stop();

    try {
      final data = jsonDecode(code.trim());

      /// ✅ ambil token dari QR
      String token = data["token"];

      int eventId = widget.eventId;

      /// cari participant berdasarkan token
      final participant = await CheckinController.getParticipantByToken(
        token,
        eventId,
      );

      if (participant == null) {
        showErrorDialog("Peserta tidak terdaftar di event ini");
        if (await Vibration.hasVibrator()) {
          Vibration.vibrate(preset: VibrationPreset.quickSuccessAlert);
        }
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pop(context, "error");
        });
        return;
      }

      int participantId = participant["id"];
      String nama = participant["nama"];

      /// cek sudah checkin
      bool already = await CheckinController.isAlreadyCheckin(participantId);

      if (already) {
        showErrorDialog("Peserta sudah melakukan check-in");
        if (await Vibration.hasVibrator()) {
          Vibration.vibrate(preset: VibrationPreset.quickSuccessAlert);
        }
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pop(context, "sudah check-in");
        });
        return;
      }

      /// update checkin
      await CheckinController.checkinParticipant(participantId);

      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(preset: VibrationPreset.quickSuccessAlert);
      }

      showSuccessDialog(nama);
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pop(context, "success");
      });
    } catch (e) {
      showErrorDialog("QR Code tidak valid");
      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(preset: VibrationPreset.quickSuccessAlert);
      }
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pop(context, "tidak valid");
      });
    }
  }
}
