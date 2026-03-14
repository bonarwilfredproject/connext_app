import 'dart:io';

import 'package:connext_app/constants/app_theme.dart';
import 'package:connext_app/pages/attendee_event_page/attendee_event_page.dart';
import 'package:connext_app/pages/profile_page/profile_page.dart';
import 'package:connext_app/services/event_controller.dart';
import 'package:connext_app/services/event_participant_controller.dart';
import 'package:connext_app/services/preferences_services.dart';
import 'package:connext_app/services/user_controller.dart';
import 'package:connext_app/models/event_model.dart';
import 'package:connext_app/models/user_model.dart';
import 'package:connext_app/constants/style_text.dart';
import 'package:connext_app/widgets/app_list_card.dart';
import 'package:connext_app/widgets/app_section_card.dart';
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
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? role;
  String? namaUser;
  UserModel? currentUser;
  Map<int, int> eventParticipantCount = {};
  Map<int, UserModel> eventCreators = {};

  /// EVENT PANITIA
  List<EventModel> committeeEvents = [];
  bool isLoadingCommittee = true;

  /// EVENT ATTENDEE
  List<EventModel> attendeeEvents = [];
  List<int> joinedEventIds = [];
  bool isLoadingAttendee = true;
  late List<UserModel> dataUser = [];
  @override
  void initState() {
    super.initState();
    getCurrentUser();
    loadSession();
  }

  Future<void> loadSession() async {
    final pref = PreferenceHandler();
    await pref.init();

    namaUser = pref.getNamaUser();
    role = pref.getRole();

    if (role == "Committee") {
      await loadCommitteeEvents();
    } else {
      await loadAttendeeEvents();
    }

    setState(() {});
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

  Future<void> loadCommitteeEvents() async {
    final pref = PreferenceHandler();
    await pref.init();

    int? userId = pref.getUserId();

    committeeEvents = await EventController.getEventByUser(userId);

    for (var event in committeeEvents) {
      int total = await EventParticipantController.getTotalParticipants(
        event.id!,
      );
      eventParticipantCount[event.id!] = total;
    }

    setState(() {
      isLoadingCommittee = false;
    });
  }

  Future<void> loadRole() async {
    final pref = PreferenceHandler();
    await pref.init();

    setState(() {
      role = pref.getRole();
    });
  }

  Future<void> loadAttendeeEvents() async {
    setState(() {
      isLoadingAttendee = true;
    });

    final pref = PreferenceHandler();
    await pref.init();

    int? userId = pref.getUserId();

    /// ambil semua event
    final events = await EventController.getAllEvent(userId);

    /// ambil event yang diikuti user
    final joinedEvents = await EventController.getEventByParticipant(userId);

    /// reset state lama
    List<int> newJoinedIds = joinedEvents.map((e) => e.id!).toList();
    Map<int, int> newParticipantCount = {};

    /// hitung jumlah peserta tiap event

    for (var event in events) {
      int total = await EventParticipantController.getTotalParticipants(
        event.id!,
      );
      newParticipantCount[event.id!] = total;

      /// ambil data panitia
      if (!eventCreators.containsKey(event.createdBy)) {
        final user = await UserController.getUserById(event.createdBy);
        if (user != null) {
          eventCreators[event.createdBy] = user;
        }
      }
    }
    setState(() {
      attendeeEvents = events;
      joinedEventIds = newJoinedIds;
      eventParticipantCount = newParticipantCount;
      isLoadingAttendee = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeScreenAppbar(
        data: "Selamat datang, ${namaUser ?? ""} as ${role ?? ""}.",
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ProfilePage(userId: currentUser!.id!, role: role!),
            ),
          );

          if (result == true) {
            await loadSession();
          }
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (role == "Committee") ...[
                  TombolSementara(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CreateEvent()),
                      );

                      if (result == true) {
                        loadCommitteeEvents();
                      }
                    },
                    height: 54,
                    width: 164,
                    icon: Icons.edit,
                    text: "Buat Event",
                  ),
                  SizedBox(height: 20),

                  Expanded(
                    child: AppSectionCard(
                      icon: Icons.event_note,
                      title: "Events",
                      child: Expanded(
                        child: isLoadingCommittee
                            ? const Center(child: CircularProgressIndicator())
                            : committeeEvents.isEmpty
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Lottie.asset(
                                    "assets/lottie/empty_bookings.json",
                                  ),
                                  const SizedBox(height: 12),
                                  Text("Belum ada event", style: styleText()),
                                ],
                              )
                            : ListView.separated(
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 20),
                                itemCount: committeeEvents.length,
                                itemBuilder: (context, index) {
                                  final event = committeeEvents[index];

                                  return Dismissible(
                                    key: Key(event.id.toString()),
                                    direction: DismissDirection.endToStart,
                                    movementDuration: const Duration(
                                      milliseconds: 250,
                                    ),
                                    resizeDuration: const Duration(
                                      milliseconds: 200,
                                    ),

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
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
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
                                        committeeEvents.removeAt(index);
                                      });

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Event berhasil dihapus",
                                          ),
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
                                          loadCommitteeEvents();
                                        }
                                      },
                                      child: AppListCard(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            /// HEADER EVENT
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Icon(
                                                  Icons.event,
                                                  color: AppTheme.secondary,
                                                ),

                                                const SizedBox(width: 8),

                                                Expanded(
                                                  child: Text(
                                                    event.title,
                                                    style: styleText().copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),

                                                const SizedBox(width: 8),

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
                                                  "${eventParticipantCount[event.id] ?? 0} Peserta",
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
                    ),
                  ),
                ] else if (role == "Attendee") ...[
                  Expanded(
                    child: AppSectionCard(
                      title: "Event Tersedia",
                      icon: Icons.event,
                      child: isLoadingAttendee
                          ? const Center(child: CircularProgressIndicator())
                          : attendeeEvents.isEmpty
                          ? Column(
                              children: [
                                Lottie.asset(
                                  "assets/lottie/empty_bookings.json",
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "Belum ada event tersedia",
                                  style: styleText(),
                                ),
                              ],
                            )
                          : Expanded(
                              child: ListView.separated(
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 16),
                                itemCount: attendeeEvents.length,
                                itemBuilder: (context, index) {
                                  final event = attendeeEvents[index];
                                  final creator =
                                      eventCreators[event.createdBy];
                                  bool joined = joinedEventIds.contains(
                                    event.id,
                                  );

                                  return AppListCard(
                                    child: InkWell(
                                      onTap: () async {
                                        /// cek ulang status join dari database
                                        final joinedEvents =
                                            await EventController.getEventByParticipant(
                                              currentUser!.id!,
                                            );

                                        bool isJoined = joinedEvents.any(
                                          (e) => e.id == event.id,
                                        );

                                        if (isJoined) {
                                          /// jika masih join → buka detail
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => AttendeeEventPage(
                                                userId: currentUser!.id!,
                                                eventId: event.id!,
                                              ),
                                            ),
                                          );

                                          if (result == true) {
                                            await loadAttendeeEvents();
                                          }
                                        } else {
                                          /// jika tidak join → dialog join
                                          final confirm = await showDialog(
                                            context: context,
                                            builder: (_) => AlertDialog(
                                              backgroundColor: AppTheme.third,
                                              title: Text(
                                                "Join Event",
                                                style: styleText(),
                                              ),
                                              content: Text(
                                                "Bergabung ke event ${event.title}?",
                                                style: styleText(),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        false,
                                                      ),
                                                  child: Text(
                                                    "Batal",
                                                    style: styleText(),
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        true,
                                                      ),
                                                  child: Text(
                                                    "Join",
                                                    style: styleText(),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (confirm == true) {
                                            await EventParticipantController.joinEvent(
                                              currentUser!.id!,
                                              event.id!,
                                            );

                                            /// langsung buka halaman QR event
                                            final result = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    AttendeeEventPage(
                                                      userId: currentUser!.id!,
                                                      eventId: event.id!,
                                                    ),
                                              ),
                                            );

                                            /// setelah kembali ke homepage baru refresh
                                            await loadAttendeeEvents();
                                          }
                                        }
                                      },
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          /// TITLE
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Icon(
                                                Icons.event,
                                                color: AppTheme.secondary,
                                                size: 20,
                                              ),

                                              const SizedBox(width: 8),

                                              /// TITLE EVENT
                                              Expanded(
                                                child: Text(
                                                  event.title,
                                                  style: styleText().copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 2,
                                                ),
                                              ),

                                              /// STATUS JOIN
                                              if (joined) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: const Text(
                                                    "JOINED",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),

                                          const SizedBox(height: 8),

                                          /// LOCATION
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

                                          const SizedBox(height: 8),

                                          /// TOTAL PESERTA
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.people,
                                                color: AppTheme.secondary,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                "${eventParticipantCount[event.id] ?? 0} Peserta",
                                                style: styleText(),
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 8),

                                          /// PANITIA PEMBUAT EVENT
                                          if (creator != null)
                                            Row(
                                              children: [
                                                /// FOTO PANITIA
                                                CircleAvatar(
                                                  radius: 12,
                                                  backgroundColor:
                                                      Colors.grey.shade300,
                                                  backgroundImage:
                                                      creator.profileImage !=
                                                              null &&
                                                          creator
                                                              .profileImage!
                                                              .isNotEmpty &&
                                                          File(
                                                            creator
                                                                .profileImage!,
                                                          ).existsSync()
                                                      ? FileImage(
                                                          File(
                                                            creator
                                                                .profileImage!,
                                                          ),
                                                        )
                                                      : null,
                                                ),

                                                const SizedBox(width: 8),

                                                /// NAMA PANITIA
                                                Expanded(
                                                  child: Text(
                                                    "by ${creator.nama}",
                                                    style: styleText(),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
