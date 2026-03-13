import 'dart:io';

import 'package:connext_app/constants/app_theme.dart';
import 'package:connext_app/pages/attendee_event_page/attendee_event_page.dart';
import 'package:connext_app/pages/profile_page/profile_page.dart';
import 'package:connext_app/services/check_in_controller.dart';
import 'package:connext_app/services/event_controller.dart';
import 'package:connext_app/services/preferences_services.dart';
import 'package:connext_app/services/database_helper.dart';
import 'package:connext_app/services/user_controller.dart';
import 'package:connext_app/models/checkin_model.dart';
import 'package:connext_app/models/event_model.dart';
import 'package:connext_app/models/user_model.dart';
import 'package:connext_app/constants/style_text.dart';
import 'package:connext_app/widgets/tombol_sementara.dart';
import 'package:connext_app/pages/home_page/create_event.dart';
import 'package:connext_app/pages/home_page/detail_event_page.dart';
import 'package:connext_app/pages/landing_page/landing_page.dart';
import 'package:connext_app/widgets/ellipse_background.dart';
import 'package:connext_app/widgets/home_screen_appbar.dart';
import 'package:connext_app/widgets/positioning_inside.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.namaUser, required this.role});
  final String namaUser;
  final String role;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  UserModel? currentUser;
  QrImageView? attendeeQr; // state untuk QR code
  List<EventModel> events = [];
  bool isLoading = true;
  late List<UserModel> dataUser = [];
  @override
  void initState() {
    super.initState();
    getDataUser();
    loadEvents();
    getCurrentUser();
  }

  Future<void> getCurrentUser() async {
    final pref = PreferenceHandler();
    await pref.init();

    int? userId = pref.getUserId();

    final user = await UserController.getUserById(userId);

    if (!mounted) return;

    setState(() {
      currentUser = user;
    });
  }

  Future<void> getDataUser() async {
    await Future.delayed(Duration(seconds: 3));
    dataUser = await UserController.getAllUser();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> loadEvents() async {
    final pref = PreferenceHandler();
    await pref.init();

    int? userId = pref.getUserId();

    events = await EventController.getEventByUser(userId);
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeScreenAppbar(
        data: "Selamat datang, ${widget.namaUser} as ${widget.role}.",
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ProfilePage(userId: currentUser!.id!, role: widget.role),
            ),
          );

          getCurrentUser(); // reload foto
        },
        child: currentUser?.profileImage != null
            ? ClipOval(
                child: Image.file(
                  File(currentUser!.profileImage!),
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                ),
              )
            : const Icon(Icons.person),
      ),
      backgroundColor: AppTheme.primary,
      body: Stack(
        children: [
          EllipseBackground(),
          PositioningInside(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.role == "Committee") ...[
                    TombolSementara(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => CreateEvent()),
                        );

                        if (result == true) {
                          loadEvents();
                        }
                      },
                      height: 54,
                      width: 164,
                      icon: Icons.edit,
                      text: "Buat Event",
                    ),
                    SizedBox(height: 40),
                    Text("Events:", style: styleText()),
                    SizedBox(height: 20),

                    Expanded(
                      child: isLoading
                          ? Center(child: CircularProgressIndicator())
                          : events.isEmpty
                          ? Column(
                              children: [
                                Lottie.asset(
                                  "assets/lottie/empty_bookings.json",
                                ),

                                SizedBox(height: 12),

                                Text("Belum ada event", style: styleText()),
                              ],
                            )
                          : ListView.separated(
                              separatorBuilder: (context, index) =>
                                  SizedBox(height: 20),
                              itemCount: events.length,
                              itemBuilder: (context, index) {
                                final event = events[index];

                                return Dismissible(
                                  key: Key(event.id.toString()),
                                  direction: DismissDirection.endToStart,

                                  movementDuration: Duration(milliseconds: 250),
                                  resizeDuration: Duration(milliseconds: 200),

                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: const [
                                        Icon(
                                          Icons.delete_outline,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          "Hapus",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  confirmDismiss: (direction) async {
                                    return await showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        backgroundColor: AppTheme.third,
                                        title: Text(
                                          "Hapus Event",
                                          style: styleText(),
                                        ),
                                        content: Text(
                                          "Yakin ingin menghapus event ini?",
                                          style: styleText(),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: Text(
                                              "Batal",
                                              style: styleText(),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
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
                                    await EventController.deleteEvent(
                                      event.id!,
                                    );

                                    setState(() {
                                      events.removeAt(index);
                                    });

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Event berhasil dihapus"),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },

                                  child: InkWell(
                                    onTap: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => DetailEventPage(
                                            eventId: event.id!,
                                          ),
                                        ),
                                      );

                                      if (result == true) {
                                        loadEvents();
                                      }
                                    },

                                    child: Container(
                                      padding: const EdgeInsets.all(16),

                                      decoration: BoxDecoration(
                                        color: AppTheme.third,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 8,
                                            offset: Offset(0, 4),
                                          ),
                                        ],
                                      ),

                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          /// HEADER EVENT
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.event,
                                                    color: AppTheme.secondary,
                                                  ),
                                                  const SizedBox(width: 8),

                                                  Text(
                                                    event.title,
                                                    style: styleText().copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Icon(
                                                Icons.info_outline,
                                                color: AppTheme.secondary,
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 6),

                                          /// LOKASI
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.location_pin,
                                                color: AppTheme.secondary,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),

                                              Expanded(
                                                child: Text(
                                                  event.location,
                                                  style: styleText(),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 6),

                                          /// JUMLAH PESERTA
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.people,
                                                color: AppTheme.secondary,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),

                                              Text(
                                                "${event.totalPeserta} Peserta",
                                                style: styleText(),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ] else if (widget.role == "Attendee") ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        children: [
                          TombolSementara(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AttendeeEventPage(
                                    userId: currentUser!.id!,
                                  ),
                                ),
                              );
                            },
                            text: "Lihat Event",
                            height: 54,
                            width: 164,
                            icon: Icons.event,
                          ),

                          SizedBox(height: 20),
                          Center(
                            child: currentUser == null
                                ? CircularProgressIndicator()
                                : QrImageView(
                                    data: jsonEncode({
                                      "userId": currentUser!.id,
                                      "namaUser": currentUser!.nama,
                                      "phone": currentUser!.phone,
                                    }),
                                    version: QrVersions.auto,
                                    size: 200,
                                    backgroundColor: Colors.white,
                                  ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            textAlign: TextAlign.center,
                            "Berikan QR ini ke panitia saat datang ke acara",
                            style: styleText(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
