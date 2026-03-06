import 'package:connext_app/utils/ellipse_background.dart';
import 'package:connext_app/utils/positioning_inside.dart';
import 'package:connext_app/utils/tombol_sementara.dart';
import 'package:connext_app/view/scanner/scan_peserta_page.dart';
import 'package:flutter/material.dart';
import 'package:connext_app/database/event_controller.dart';
import 'package:connext_app/model/event_model.dart';
import 'package:connext_app/utils/style_text.dart';

class DetailEventPage extends StatefulWidget {
  final int eventId;

  const DetailEventPage({super.key, required this.eventId});

  @override
  State<DetailEventPage> createState() => _DetailEventPageState();
}

class _DetailEventPageState extends State<DetailEventPage> {
  EventModel? event;
  List<Map<String, String>> scannedPeserta = []; // <- state untuk list peserta

  @override
  void initState() {
    super.initState();
    loadEvent();
  }

  Future<void> loadEvent() async {
    final allEvents = await EventController.getAllEvent();
    event = allEvents.firstWhere((e) => e.id == widget.eventId);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (event == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(event!.title, style: styleText())),
      body: Stack(
        children: [
          EllipseBackground(),
          PositioningInside(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.numbers),
                      SizedBox(width: 10),
                      Text("${event!.id}", style: styleText()),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.location_pin),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(event!.location, style: styleText()),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.people),
                      SizedBox(width: 10),
                      Text(
                        "${event!.totalPeserta} Peserta",
                        style: styleText(),
                      ),
                    ],
                  ),
                  SizedBox(height: 40),
                  // Tombol Scan Peserta
                  TombolSementara(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ScanPesertaPage(eventId: event!.id!),
                        ),
                      );

                      // Ambil data scannedPeserta dari ScanPesertaPage
                      if (result != null &&
                          result is List<Map<String, String>>) {
                        setState(() {
                          scannedPeserta = result;
                        });
                      }
                    },
                    text: "Scan Peserta",
                    height: 54,
                    width: double.infinity,
                    icon: Icons.qr_code_scanner,
                  ),

                  SizedBox(height: 20),
                  // Tampilkan list peserta yang sudah discan
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Peserta yang sudah discan:",
                            style: styleText(),
                          ),
                          SizedBox(height: 10),
                          Expanded(
                            child: scannedPeserta.isEmpty
                                ? Center(
                                    child: Text("Belum ada peserta discan"),
                                  )
                                : ListView.builder(
                                    itemCount: scannedPeserta.length,
                                    itemBuilder: (context, index) {
                                      final p = scannedPeserta[index];
                                      return Card(
                                        child: ListTile(
                                          title: Text(p['namaUser'] ?? ""),
                                          subtitle: Text(
                                            "Phone: ${p['phone'] ?? ""}\nWaktu: ${p['waktu'] ?? ""}",
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
