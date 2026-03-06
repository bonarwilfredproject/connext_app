import 'package:connext_app/services/check_in_controller.dart';
import 'package:connext_app/services/user_controller.dart';
import 'package:connext_app/widgets/ellipse_background.dart';
import 'package:connext_app/widgets/positioning_inside.dart';
import 'package:connext_app/widgets/tombol_sementara.dart';
import 'package:connext_app/pages/scanner/scan_peserta_page.dart';
import 'package:flutter/material.dart';
import 'package:connext_app/services/event_controller.dart';
import 'package:connext_app/models/event_model.dart';
import 'package:connext_app/constant/style_text.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class DetailEventPage extends StatefulWidget {
  final int eventId;

  const DetailEventPage({super.key, required this.eventId});

  @override
  State<DetailEventPage> createState() => _DetailEventPageState();
}

class _DetailEventPageState extends State<DetailEventPage> {
  EventModel? event;
  List<Map<String, String>> scannedPeserta = []; // <- state untuk list peserta
  final TextEditingController titleController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id');
    loadEvent();
    loadPeserta();
  }

  void showEditEventDialog() {
    titleController.text = event!.title;
    locationController.text = event!.location;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Event"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: "Nama Event"),
              ),
              SizedBox(height: 10),
              TextField(
                controller: locationController,
                decoration: InputDecoration(labelText: "Lokasi Event"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () async {
                final updatedEvent = EventModel(
                  createdBy: event!.createdBy,
                  id: event!.id,
                  title: titleController.text,
                  location: locationController.text,
                  totalPeserta: event!.totalPeserta,
                );

                await EventController.updateEvent(updatedEvent);

                Navigator.pop(context, true);

                await loadEvent(); // refresh data
              },
              child: Text("Simpan"),
            ),
          ],
        );
      },
    );
  }

  Future<void> loadPeserta() async {
    final checkins = await CheckinController.getCheckinsByEvent(widget.eventId);

    List<Map<String, String>> peserta = [];

    for (var c in checkins) {
      final user = await UserController.getUserById(c.userId);

      if (user != null) {
        peserta.add({
          "namaUser": user.nama,
          "phone": user.phone,
          "waktu": c.waktu,
        });
      }
    }

    setState(() {
      scannedPeserta = peserta;
    });
  }

  String formatTanggal(String waktu) {
    DateTime date = DateTime.parse(waktu);

    return DateFormat("EEEE, dd MMM yyyy, HH.mm", "id").format(date);
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
      appBar: AppBar(
        title: Text(event!.title, style: styleText()),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, true); // kirim signal refresh
          },
        ),
        actions: [
          IconButton(
            onPressed: () {
              showEditEventDialog();
            },
            icon: Icon(Icons.edit, color: Color(0XFF424874)),
          ),
        ],
      ),
      body: Stack(
        children: [
          EllipseBackground(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 40),
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
                    Expanded(child: Text(event!.location, style: styleText())),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.people),
                    SizedBox(width: 10),
                    Text("${event!.totalPeserta} Peserta", style: styleText()),
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

                    if (result != null) {
                      await loadEvent(); // update jumlah peserta
                      await loadPeserta(); // reload list peserta dari database
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
                        Text("Peserta yang sudah discan: ", style: styleText()),
                        SizedBox(height: 10),
                        Expanded(
                          child: scannedPeserta.isEmpty
                              ? Center(
                                  child: Text(
                                    "Belum ada peserta discan",
                                    style: styleText(),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: scannedPeserta.length,
                                  itemBuilder: (context, index) {
                                    final p = scannedPeserta[index];
                                    return Container(
                                      margin: EdgeInsets.only(bottom: 12),
                                      padding: EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Color(0xffE9E3F4),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            p['namaUser'] ?? "",
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              fontStyle: FontStyle.italic,
                                              color: Color(0xff3F3D6B),
                                            ),
                                          ),
                                          SizedBox(height: 4),

                                          Text(
                                            p['phone'] ?? "",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              fontStyle: FontStyle.italic,
                                              color: Color(0xff3F3D6B),
                                            ),
                                          ),

                                          SizedBox(height: 4),

                                          Text(
                                            formatTanggal(p['waktu'] ?? ""),
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              fontStyle: FontStyle.italic,
                                              color: Color(0xff3F3D6B),
                                            ),
                                          ),
                                        ],
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
        ],
      ),
    );
  }
}
