import 'dart:convert';
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
      appBar: AppBar(title: Text("Scan Peserta", style: styleText())),
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
        if (await Vibration.hasVibrator()) {
          Vibration.vibrate();
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("$namaUser sudah check-in")));

        await Future.delayed(Duration(milliseconds: 500));
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Peserta $namaUser berhasil check-in")),
      );

      await Future.delayed(Duration(milliseconds: 800));
      controller.stop();
      Navigator.pop(context, {
        "namaUser": namaUser,
        "phone": phone,
        "waktu": waktuScan,
      });
    } catch (e) {
      isProcessing = false;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("QR Code tidak valid")));
    }
  }
}
