import 'dart:convert';
import 'package:animate_do/animate_do.dart';
import 'package:connext_app/constants/app_theme.dart';
import 'package:connext_app/services/attendee_controller.dart';
import 'package:connext_app/services/event_controller.dart';
import 'package:connext_app/widgets/ellipse_background.dart';
import 'package:connext_app/constants/style_text.dart';
import 'package:connext_app/widgets/tombol_sementara.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:connext_app/services/check_in_controller.dart';
import 'package:connext_app/models/checkin_model.dart';
import 'package:vibration/vibration.dart';
import 'package:vibration/vibration_presets.dart';

class ScanPesertaPage extends StatefulWidget {
  final int eventId;

  const ScanPesertaPage({super.key, required this.eventId});

  @override
  State<ScanPesertaPage> createState() => _ScanPesertaPageState();
}

class _ScanPesertaPageState extends State<ScanPesertaPage> {
  MobileScannerController controller = MobileScannerController();
  bool isProcessing = false;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        title: Text("Scan Peserta", style: styleText()),
        backgroundColor: AppTheme.primary,
      ),
      body: Stack(
        children: [
          EllipseBackground(),
          Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              children: [
                // Scanner area
                Expanded(
                  flex: 5,
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  void showErrorDialog(String pesan) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShakeX(child: Icon(Icons.cancel, color: Colors.red, size: 80)),

            SizedBox(height: 16),

            Text(
              "Scan Gagal",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 8),

            Text(
              pesan,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
    controller.stop();
    Future.delayed(Duration(seconds: 1), () {
      Navigator.pop(context, true);
    });
  }

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

            SizedBox(height: 16),

            Text(
              "Check-in Berhasil!",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 8),

            Text(nama, style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
    controller.stop();
    Future.delayed(Duration(seconds: 1), () {
      Navigator.pop(context, true);
    });
  }

  Future<void> _handleQrScan(String code) async {
    if (isProcessing) return;

    isProcessing = true;

    try {
      Map<String, dynamic> data = jsonDecode(code);

      int userId = data['userId'];
      String namaUser = data['namaUser'];
      String phone = data['phone'];

      int eventId = widget.eventId;

      bool already = await CheckinController.isAlreadyCheckin(userId, eventId);

      if (already) {
        showErrorDialog("Peserta sudah melakukan check-in");

        if (await Vibration.hasVibrator()) {
          Vibration.vibrate();
        }

        await Future.delayed(Duration(seconds: 1));
        controller.stop();
        Navigator.pop(context, true); // kembali ke Detail Event
        return;
      }

      String waktuScan = DateTime.now().toString();

      await CheckinController.insertCheckin(
        CheckinModel(
          userId: userId,
          eventId: eventId,
          namaUser: namaUser,
          phone: phone,
          waktu: waktuScan,
        ),
      );
      await EventController.incrementPeserta(eventId);

      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(preset: VibrationPreset.quickSuccessAlert);
      }
      showSuccessDialog(data["namaUser"]);
      await Future.delayed(Duration(seconds: 1));
      controller.stop();
      Navigator.pop(context, true);
    } catch (e) {
      isProcessing = false;
      controller.stop();
      showErrorDialog("QR Code tidak valid");
    }
  }
}
