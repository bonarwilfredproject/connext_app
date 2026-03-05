import 'package:connext_app/database/event_controller.dart';
import 'package:connext_app/database/preferences.dart';
import 'package:connext_app/database/sqflite.dart';
import 'package:connext_app/database/user_controller.dart';
import 'package:connext_app/model/event_model.dart';
import 'package:connext_app/model/user_model.dart';
import 'package:connext_app/utils/style_text.dart';
import 'package:connext_app/utils/tombol_sementara.dart';
import 'package:connext_app/view/home_page/create_event.dart';
import 'package:connext_app/view/home_page/detail_event_page.dart';
import 'package:connext_app/view/landing_page/landing_page.dart';
import 'package:connext_app/utils/ellipse_background.dart';
import 'package:connext_app/utils/home_screen_appbar.dart';
import 'package:connext_app/utils/positioning_inside.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.namaUser, required this.role});
  final String namaUser;
  final String role;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<EventModel> events = [];
  bool isLoading = true;
  late List<UserModel> dataUser = [];
  @override
  void initState() {
    super.initState();
    getDataUser();
    loadEvents();
  }

  Future<void> getDataUser() async {
    await Future.delayed(Duration(seconds: 3));
    dataUser = await UserController.getAllUser();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> loadEvents() async {
    events = await EventController.getAllEvent();
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
          final confirm = await showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text("Logout"),
              content: Text("Apakah kamu yakin ingin logout?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text("Batal"),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text("Ya"),
                ),
              ],
            ),
          );

          if (confirm == true) {
            final pref = PreferenceHandler();
            await pref.init();
            await pref.logout();

            if (!mounted) return;

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => LandingPage()),
              (route) => false,
            );
          }
        },
      ),
      backgroundColor: Color(0xFFF4EEFF),
      body: Stack(
        children: [
          EllipseBackground(),
          PositioningInside(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.role == "Committee")
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
                        ? Center(
                            child: Text("Belum ada event", style: styleText()),
                          )
                        : ListView.separated(
                            separatorBuilder: (context, index) =>
                                SizedBox(height: 20),
                            itemCount: events.length,
                            itemBuilder: (context, index) {
                              final event = events[index];

                              return Dismissible(
                                key: Key(event.id.toString()),
                                direction: DismissDirection
                                    .endToStart, // swipe dari kanan ke kiri
                                background: Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  alignment: Alignment.centerRight,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ), // 🔥 wajib unik
                                confirmDismiss: (direction) async {
                                  return await showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text("Hapus Event"),
                                      content: const Text(
                                        "Yakin ingin menghapus event ini?",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text("Batal"),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text("Hapus"),
                                        ),
                                      ],
                                    ),
                                  );
                                },

                                onDismissed: (direction) async {
                                  await EventController.deleteEvent(event.id!);

                                  setState(() {
                                    events.removeAt(index);
                                  });

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Event berhasil dihapus"),
                                    ),
                                  );
                                },
                                child: InkWell(
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            DetailEventPage(eventId: event.id!),
                                      ),
                                    );

                                    if (result == true) {
                                      loadEvents(); // reload setelah delete
                                    }
                                  },
                                  child: Material(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      margin: EdgeInsets.only(bottom: 16),
                                      padding: EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Color(0xffF4EEFF),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        children: [
                                          // 🔥 HEADER + ICON INFO
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(Icons.event),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    event.title,
                                                    style: styleText(),
                                                  ),
                                                ],
                                              ),

                                              IconButton(
                                                icon: Icon(Icons.info_outline),
                                                onPressed: () async {
                                                  final result =
                                                      await Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (_) =>
                                                              DetailEventPage(
                                                                eventId:
                                                                    event.id!,
                                                              ),
                                                        ),
                                                      );

                                                  if (result == true) {
                                                    loadEvents();
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Icon(Icons.location_pin),
                                              SizedBox(width: 8),
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
                                          Row(
                                            children: [
                                              Icon(Icons.people),
                                              SizedBox(width: 8),
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
                                ),
                              );
                            },
                          ),
                  ),

                  if (widget.role == "Attendee")
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: TombolSementara(
                        onPressed: () {},
                        text: "Lihat Event",
                        height: 54,
                        width: 164,
                        icon: Icons.event,
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
