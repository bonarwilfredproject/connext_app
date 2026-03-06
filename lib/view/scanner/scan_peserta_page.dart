import 'dart:convert';
import 'package:connext_app/utils/ellipse_background.dart';
import 'package:connext_app/utils/style_text.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:connext_app/database/check_in_controller.dart';
import 'package:connext_app/model/checkin_model.dart';

class ScanPesertaPage extends StatefulWidget {
  final int eventId;

  const ScanPesertaPage({super.key, required this.eventId});

  @override
  State<ScanPesertaPage> createState() => _ScanPesertaPageState();
}

class _ScanPesertaPageState extends State<ScanPesertaPage> {
  List<Map<String, String>> scannedPeserta = [];

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
                    onDetect: (capture) {
                      final List<Barcode> barcodes = capture.barcodes;
                      for (final barcode in barcodes) {
                        final code = barcode.rawValue ?? "";
                        _handleQrScan(code);
                      }
                    },
                  ),
                ),

                SizedBox(height: 16),
                // Tombol selesai / kembali ke DetailEventPage
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, scannedPeserta);
                  },
                  child: Text("Selesai"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleQrScan(String code) async {
    try {
      Map<String, dynamic> data = jsonDecode(code);

      int userId = data['userId'];
      int eventId = data['eventId'];
      String namaUser = data['namaUser'];
      String phone = data['phone'];
      String waktuScan = DateTime.now().toString();

      bool already = await CheckinController.isAlreadyCheckin(userId, eventId);

      if (!already) {
        await CheckinController.insertCheckin(
          CheckinModel(userId: userId, eventId: eventId, waktu: waktuScan),
        );
      }

      setState(() {
        scannedPeserta.insert(0, {
          'namaUser': namaUser,
          'phone': phone,
          'waktu': waktuScan,
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Peserta $namaUser berhasil discan!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('QR Code tidak valid!')));
    }
  }
}
