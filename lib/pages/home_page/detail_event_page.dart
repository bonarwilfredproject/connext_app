import 'package:connext_app/constants/app_theme.dart';
import 'package:connext_app/constants/decoration_constant.dart';
import 'package:connext_app/services/check_in_controller.dart';
import 'package:connext_app/services/user_controller.dart';
import 'package:connext_app/widgets/ellipse_background.dart';
import 'package:connext_app/widgets/positioning_inside.dart';
import 'package:connext_app/widgets/tombol_sementara.dart';
import 'package:connext_app/pages/scanner/scan_peserta_page.dart';
import 'package:flutter/material.dart';
import 'package:connext_app/services/event_controller.dart';
import 'package:connext_app/models/event_model.dart';
import 'package:connext_app/constants/style_text.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lottie/lottie.dart';

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
          backgroundColor: AppTheme.third,
          title: Text("Edit Event", style: styleText()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                style: TextStyle(color: AppTheme.primary, fontSize: 12),
                controller: titleController,
                decoration: decorationConstant(hintText: "Nama Event"),
              ),
              SizedBox(height: 10),
              TextField(
                style: TextStyle(color: AppTheme.primary, fontSize: 12),
                controller: locationController,
                decoration: decorationConstant(hintText: "Lokasi"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Batal", style: styleText()),
            ),
            ElevatedButton(
              onPressed: () async {
                final updatedEvent = EventModel(
                  userId: event!.userId,
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
              child: Text("Simpan", style: styleText()),
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
      peserta.add({
        "userId": c.userId.toString(),
        "namaUser": c.namaUser,
        "phone": c.phone,
        "waktu": c.waktu,
      });
    }

    setState(() {
      scannedPeserta = peserta;
    });
  }

  String formatTanggal(String waktu) {
    DateTime date = DateTime.tryParse(waktu) ?? DateTime.now();

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
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
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
                      await loadPeserta();
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
                        Text("Peserta yang hadir: ", style: styleText()),
                        SizedBox(height: 10),
                        Expanded(
                          child: scannedPeserta.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Lottie.asset(
                                        "assets/lottie/yawn_emoji_animation.json",
                                        height: 200,
                                      ),

                                      SizedBox(height: 12),

                                      Text(
                                        "Belum ada peserta yang hadir",
                                        style: styleText(),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: scannedPeserta.length,
                                  itemBuilder: (context, index) {
                                    final p = scannedPeserta[index];
                                    return Dismissible(
                                      key: Key(p['userId']! + index.toString()),
                                      direction: DismissDirection.endToStart,

                                      background: Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                        ),
                                        alignment: Alignment.centerRight,
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.delete,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),

                                      confirmDismiss: (direction) async {
                                        return await showDialog(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            backgroundColor: AppTheme.third,
                                            title: Text(
                                              "Hapus Peserta",
                                              style: styleText(),
                                            ),
                                            content: Text(
                                              "Yakin ingin menghapus peserta ini?",
                                              style: styleText(),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                                child: Text(
                                                  "Batal",
                                                  style: styleText(),
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                                child: Text(
                                                  "Hapus",
                                                  style: styleText(),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },

                                      onDismissed: (direction) async {
                                        await CheckinController.deleteCheckin(
                                          int.parse(p['userId']!),
                                          widget.eventId,
                                        );

                                        setState(() {
                                          scannedPeserta.removeAt(index);
                                        });
                                        await EventController.decrementPeserta(
                                          widget.eventId,
                                        );
                                        await loadEvent();

                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Peserta berhasil dihapus",
                                            ),
                                          ),
                                        );
                                      },

                                      child: SizedBox(
                                        width: double.infinity,
                                        child: Material(
                                          color: AppTheme.third,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: Container(
                                            margin: EdgeInsets.only(bottom: 12),
                                            padding: EdgeInsets.symmetric(
                                              vertical: 16,
                                              horizontal: 16,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primary,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Text(
                                                  p['namaUser'] ?? "",
                                                  style: styleText(),
                                                ),
                                                SizedBox(height: 4),

                                                Text(
                                                  p['phone'] ?? "",
                                                  style: styleText(),
                                                ),

                                                SizedBox(height: 4),

                                                Text(
                                                  formatTanggal(
                                                    p['waktu'] ?? "",
                                                  ),
                                                  style: styleText(),
                                                ),
                                              ],
                                            ),
                                          ),
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
        ],
      ),
    );
  }
}
