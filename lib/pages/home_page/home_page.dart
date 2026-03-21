import 'dart:io';
import 'dart:async';
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
import 'package:connext_app/widgets/ellipse_background.dart';
import 'package:connext_app/widgets/home_screen_appbar.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer? timer;
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

    /// 🔥 AUTO REFRESH TIAP DETIK
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  bool isEventPassed(EventModel event) {
    if (event.eventDate == null || event.eventTime == null) return false;

    try {
      final date = DateTime.parse(event.eventDate!);

      final timeParts = event.eventTime!.split(":");
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      final eventDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        hour,
        minute,
      );

      final nowRaw = DateTime.now();

      final now = DateTime(
        nowRaw.year,
        nowRaw.month,
        nowRaw.day,
        nowRaw.hour,
        nowRaw.minute,
      );

      return now.isAfter(eventDateTime);
    } catch (e) {
      return false;
    }
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

  Widget buildRow(IconData icon, String text, {Widget? trailing}) {
    return Row(
      children: [
        SizedBox(child: Icon(icon, size: 18, color: AppTheme.secondary)),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: styleText())),
        if (trailing != null) ...[const SizedBox(width: 6), trailing],
      ],
    );
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
        title: Text.rich(
          maxLines: 2,
          TextSpan(
            style: styleText().copyWith(height: 1.4),
            children: [
              const TextSpan(text: "Welcome, "),
              TextSpan(
                text: currentUser?.nama ?? "",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: " as "),
              TextSpan(
                text: role ?? "",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
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
                    text: "Create Event",
                  ),
                  SizedBox(height: 20),

                  Expanded(
                    child: AppSectionCard(
                      icon: Icons.event_note,
                      title: "Your Event",
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
                                  Text("There is no event", style: styleText()),
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
                                            "Delete",
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
                                            "Delete Event",
                                            style: styleText(),
                                          ),
                                          content: Text.rich(
                                            style: styleText(),
                                            TextSpan(
                                              children: [
                                                TextSpan(
                                                  text:
                                                      "Are you sure want to delete ",
                                                ),
                                                TextSpan(
                                                  text: event.title,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                TextSpan(text: "?"),
                                              ],
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: Text(
                                                "Cancel",
                                                style: styleText(),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: Text(
                                                "Delete",
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
                                            "Event deleted succesfully",
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
                                                  size: 20,
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
                                                  size: 20,
                                                ),
                                              ],
                                            ),

                                            const SizedBox(height: 8),

                                            buildRow(
                                              Icons.location_pin,
                                              event.location,
                                            ),

                                            const SizedBox(height: 6),

                                            buildRow(
                                              Icons
                                                  .event_available, // 🔥 icon baru
                                              event.eventDate != null
                                                  ? "${DateFormat('EE, d MMMM yyyy').format(DateTime.parse(event.eventDate!))} • ${event.eventTime}"
                                                  : "-",
                                            ),

                                            const SizedBox(height: 6),

                                            buildRow(
                                              Icons.people,
                                              "${eventParticipantCount[event.id] ?? 0} Attendee",
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
                      title: "Event Available",
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
                                  "There is no event available",
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

                                        /// ✅ JIKA SUDAH JOIN → BOLEH MASUK (walaupun expired)
                                        if (isJoined) {
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
                                          return;
                                        }

                                        /// ❌ JIKA BELUM JOIN & EVENT SUDAH LEWAT → BLOCK
                                        if (isEventPassed(event)) {
                                          await showDialog(
                                            context: context,
                                            builder: (_) => AlertDialog(
                                              backgroundColor: AppTheme.third,
                                              title: Text(
                                                "Event ended",
                                                style: styleText(),
                                              ),
                                              content: Text(
                                                "Can not join event, the event has ended",
                                                style: styleText(),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: Text(
                                                    "OK",
                                                    style: styleText(),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                          setState(() {});
                                          return;
                                        }

                                        /// ✅ JIKA BELUM JOIN & MASIH AKTIF → BISA JOIN
                                        final confirm = await showDialog(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            backgroundColor: AppTheme.third,
                                            title: Text(
                                              "Join Event",
                                              style: styleText(),
                                            ),
                                            content: Text.rich(
                                              style: styleText(),
                                              TextSpan(
                                                children: [
                                                  TextSpan(text: "Join to "),
                                                  TextSpan(
                                                    text: event.title,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  TextSpan(text: "?"),
                                                ],
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                                child: Text(
                                                  "Cancel",
                                                  style: styleText(),
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(
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

                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => AttendeeEventPage(
                                                userId: currentUser!.id!,
                                                eventId: event.id!,
                                              ),
                                            ),
                                          );

                                          await loadAttendeeEvents();
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
                                              if (isEventPassed(event)) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: const Text(
                                                    "EXPIRED",
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
                                          buildRow(
                                            Icons.location_pin,
                                            event.location,
                                          ),

                                          const SizedBox(height: 8),

                                          /// TOTAL PESERTA
                                          buildRow(
                                            Icons.people,
                                            "${eventParticipantCount[event.id] ?? 0} Attendee",
                                          ),
                                          const SizedBox(height: 8),

                                          buildRow(
                                            Icons.event_available,
                                            event.eventDate != null
                                                ? "${DateFormat('EE, d MMMM yyyy').format(DateTime.parse(event.eventDate!))} • ${event.eventTime ?? '-'}"
                                                : "-",
                                          ),
                                          const SizedBox(height: 8),

                                          /// PANITIA PEMBUAT EVENT
                                          if (creator != null)
                                            Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 12,
                                                  backgroundColor:
                                                      AppTheme.third,
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
                                                  child:
                                                      creator.profileImage ==
                                                              null ||
                                                          creator
                                                              .profileImage!
                                                              .isEmpty
                                                      ? const Icon(
                                                          Icons.person,
                                                          size: 16,
                                                        )
                                                      : null,
                                                ),
                                                const SizedBox(width: 8),
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
