import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connext_app/constants/app_theme.dart';
import 'package:connext_app/pages/attendee_event_page/attendee_event_page.dart';
import 'package:connext_app/pages/profile_page/profile_page.dart';
import 'package:connext_app/services/check_in_controller.dart';
import 'package:connext_app/services/event_controller.dart';
import 'package:connext_app/services/event_participant_controller.dart';
import 'package:connext_app/services/firebase_services.dart';
import 'package:connext_app/services/preferences_services.dart';
import 'package:connext_app/services/user_controller.dart';
import 'package:connext_app/models/event_model.dart';
import 'package:connext_app/models/user_model.dart';
import 'package:connext_app/constants/style_text.dart';
import 'package:connext_app/widgets/app_list_card.dart';
import 'package:connext_app/widgets/app_section_card.dart';
import 'package:connext_app/widgets/profile_avatar.dart';
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
  Timer? _realtimeDebounceTimer;
  StreamSubscription<UserModel?>? _profileRealtimeSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _eventsRealtimeSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _participantsRealtimeSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _usersRealtimeSub;
  String? _boundRealtimeRole;
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
  Set<int> checkedInEventIds = <int>{};
  final Set<int> _joiningEventIds = <int>{};
  bool isLoadingAttendee = true;
  int _attendeeLoadVersion = 0;
  late List<UserModel> dataUser = [];

  @override
  void initState() {
    super.initState();
    _bootstrap();
    _bindProfileRealtimeListener();

    /// 🔥 AUTO REFRESH TIAP DETIK
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _bootstrap() async {
    await getCurrentUser();
    await loadSession();
  }

  @override
  void dispose() {
    timer?.cancel();
    _realtimeDebounceTimer?.cancel();
    _profileRealtimeSub?.cancel();
    _eventsRealtimeSub?.cancel();
    _participantsRealtimeSub?.cancel();
    _usersRealtimeSub?.cancel();
    super.dispose();
  }

  void _bindProfileRealtimeListener() {
    _profileRealtimeSub?.cancel();
    _profileRealtimeSub = FirebaseServices.currentUserProfileStream().listen((
      user,
    ) {
      if (!mounted || user == null) return;

      setState(() {
        currentUser = user;
        if (user.nama.isNotEmpty) {
          namaUser = user.nama;
        }
        if (user.role.isNotEmpty) {
          role = user.role;
        }
      });

      _bindRealtimeListeners();
    });
  }

  void _scheduleRealtimeSync() {
    if (!mounted) return;

    _realtimeDebounceTimer?.cancel();
    _realtimeDebounceTimer = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;

      if (role == "Committee") {
        await loadCommitteeEvents();
      } else {
        await loadAttendeeEvents();
      }
    });
  }

  void _bindRealtimeListeners() {
    final currentRole = role;
    if (currentRole == null || currentRole.isEmpty) return;

    if (_boundRealtimeRole == currentRole &&
        _eventsRealtimeSub != null &&
        _participantsRealtimeSub != null &&
        _usersRealtimeSub != null) {
      return;
    }

    _eventsRealtimeSub?.cancel();
    _participantsRealtimeSub?.cancel();
    _usersRealtimeSub?.cancel();
    _boundRealtimeRole = currentRole;

    _eventsRealtimeSub = FirebaseFirestore.instance
        .collection('events')
        .snapshots()
        .listen((_) => _scheduleRealtimeSync());

    _participantsRealtimeSub = FirebaseFirestore.instance
        .collectionGroup('participants')
        .snapshots()
        .listen((_) => _scheduleRealtimeSync());

    _usersRealtimeSub = FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .listen((_) => _scheduleRealtimeSync());
  }

  bool isEventPassed(EventModel event) {
    final eventDateTime = _resolveEventDateTime(event);
    if (eventDateTime == null) return false;

    final nowRaw = DateTime.now();
    final now = DateTime(
      nowRaw.year,
      nowRaw.month,
      nowRaw.day,
      nowRaw.hour,
      nowRaw.minute,
    );

    return now.isAfter(eventDateTime);
  }

  DateTime? _resolveEventDateTime(EventModel event) {
    if (event.eventDate == null || event.eventTime == null) return null;

    try {
      final date = DateTime.parse(event.eventDate!);
      final timeText = event.eventTime!.trim();

      int hour;
      int minute;

      // Primary format: HH:mm
      final hhmmParts = timeText.split(':');
      if (hhmmParts.length == 2) {
        final parsedHour = int.tryParse(hhmmParts[0]);
        final parsedMinute = int.tryParse(hhmmParts[1]);
        if (parsedHour != null && parsedMinute != null) {
          hour = parsedHour;
          minute = parsedMinute;
        } else {
          final parsed = DateFormat('h:mm a').parseStrict(timeText);
          hour = parsed.hour;
          minute = parsed.minute;
        }
      } else {
        final parsed = DateFormat('h:mm a').parseStrict(timeText);
        hour = parsed.hour;
        minute = parsed.minute;
      }

      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  DateTime _eventSortKey(EventModel event) {
    return _resolveEventDateTime(event) ??
        DateTime.tryParse(event.createdAt) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  int? _extractLeftEventId(dynamic result) {
    if (result is! Map) return null;

    final raw = result['leftEventId'];
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '');
  }

  Future<void> _openAttendeeEventPage({
    required int userId,
    required int eventId,
  }) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AttendeeEventPage(userId: userId, eventId: eventId),
      ),
    );

    if (!mounted) return;

    final leftEventId = _extractLeftEventId(result);
    if (leftEventId != null) {
      setState(() {
        joinedEventIds.remove(leftEventId);
        checkedInEventIds.remove(leftEventId);

        final currentCount = eventParticipantCount[leftEventId] ?? 0;
        eventParticipantCount[leftEventId] = currentCount > 0
            ? currentCount - 1
            : 0;
      });

      unawaited(loadAttendeeEvents());
      return;
    }

    if (result == true) {
      unawaited(loadAttendeeEvents());
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

    _bindRealtimeListeners();

    setState(() {});
  }

  Future<void> getCurrentUser() async {
    final user = await FirebaseServices.getCurrentUserProfile();

    if (!mounted) return;

    setState(() {
      currentUser = user;
    });
  }

  Future<int?> _resolveCurrentUserId() async {
    final inMemoryId = currentUser?.id;
    if (inMemoryId != null && inMemoryId > 0) return inMemoryId;

    final pref = PreferenceHandler();
    await pref.init();
    final prefId = pref.getUserId();
    if (prefId > 0) return prefId;

    final firebaseUser = await FirebaseServices.getCurrentUserProfile();
    final firebaseId = firebaseUser?.id;
    if (firebaseId != null && firebaseId > 0) {
      final pref = PreferenceHandler();
      await pref.init();
      await pref.saveUser(firebaseId, firebaseUser!.nama, firebaseUser.role);

      if (mounted) {
        setState(() {
          currentUser = firebaseUser;
        });
      }
      return firebaseId;
    }

    return null;
  }

  Future<void> loadCommitteeEvents() async {
    if (!mounted) return;

    setState(() {
      isLoadingCommittee = true;
    });

    int userId = 0;
    try {
      userId = await _resolveCurrentUserId() ?? 0;
    } catch (_) {
      userId = 0;
    }

    try {
      final events = await EventController.getEventByUser(userId);
      final newParticipantCount = <int, int>{};

      for (final event in events) {
        final eventId = event.id;
        if (eventId == null) continue;

        final total = await EventParticipantController.getTotalParticipants(
          eventId,
        );
        newParticipantCount[eventId] = total;
      }

      if (!mounted) return;
      setState(() {
        committeeEvents = events;
        eventParticipantCount = newParticipantCount;
        isLoadingCommittee = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        committeeEvents = [];
        eventParticipantCount = {};
        isLoadingCommittee = false;
      });
    }
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

  Widget _buildStatusBadge({
    required String label,
    required Color color,
    FontWeight fontWeight = FontWeight.w500,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppTheme.primary,
          fontSize: 12,
          fontWeight: fontWeight,
        ),
      ),
    );
  }

  Widget _buildJoiningBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.secondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ),
          SizedBox(width: 6),
          Text(
            "JOINING...",
            style: TextStyle(
              color: AppTheme.primary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> loadAttendeeEvents() async {
    if (!mounted) return;

    final loadVersion = ++_attendeeLoadVersion;
    final shouldShowFullLoading = attendeeEvents.isEmpty;

    if (shouldShowFullLoading) {
      setState(() {
        isLoadingAttendee = true;
      });
    }

    int userId = 0;
    try {
      userId = await _resolveCurrentUserId() ?? 0;
    } catch (_) {
      userId = 0;
    }

    try {
      /// ambil semua event
      final events = await EventController.getAllEvent(userId);

      /// ambil event yang diikuti user
      final previousJoinedIds = List<int>.from(joinedEventIds);
      List<EventModel> joinedEvents = [];
      bool joinedFetchOk = false;
      try {
        // Allow UID-based fallback in Firebase layer when numeric userId is not ready yet.
        joinedEvents = await EventController.getEventByParticipant(userId);
        joinedFetchOk = true;
      } catch (_) {
        joinedEvents = [];
        joinedFetchOk = false;
      }

      /// reset state lama
      List<int> newJoinedIds;
      if (joinedFetchOk && joinedEvents.isNotEmpty) {
        newJoinedIds = joinedEvents
            .where((e) => e.id != null)
            .map((e) => e.id!)
            .toList();
      } else if (userId > 0 && events.isNotEmpty) {
        final joinedChecks = await Future.wait(
          events.map((event) async {
            final eventId = event.id;
            if (eventId == null) return null;

            try {
              final joined = await EventParticipantController.isJoined(
                userId,
                eventId,
              );
              return joined ? eventId : null;
            } catch (_) {
              return null;
            }
          }),
        );

        newJoinedIds = joinedChecks.whereType<int>().toList();
      } else {
        newJoinedIds = previousJoinedIds;
      }

      final previousCheckedInIds = Set<int>.from(checkedInEventIds);
      final newCheckedInIds = <int>{};

      if (userId > 0 && newJoinedIds.isNotEmpty) {
        final checkinChecks = await Future.wait(
          newJoinedIds.map((eventId) async {
            try {
              final participant = await CheckinController.getParticipant(
                userId,
                eventId,
              );
              final checkinTime = participant?['checkin_time']?.toString();
              final checkedIn =
                  checkinTime != null && checkinTime.trim().isNotEmpty;
              return (eventId, checkedIn, true);
            } catch (_) {
              return (eventId, false, false);
            }
          }),
        );

        for (final result in checkinChecks) {
          final eventId = result.$1;
          final checkedIn = result.$2;
          final resolved = result.$3;

          if (checkedIn) {
            newCheckedInIds.add(eventId);
            continue;
          }

          if (!resolved && previousCheckedInIds.contains(eventId)) {
            // Keep previous state if latest checkin status fails to resolve.
            newCheckedInIds.add(eventId);
          }
        }
      }

      final filteredEvents = events
          .where((event) {
            final expired = isEventPassed(event);
            if (!expired) return true;

            final eventId = event.id;
            if (eventId == null) return false;

            // Keep expired events only if attendee has joined and already checked in.
            final joined = newJoinedIds.contains(eventId);
            final checkedIn = newCheckedInIds.contains(eventId);
            return joined && checkedIn;
          })
          .toList(growable: false);

      final sortedEvents = List<EventModel>.from(filteredEvents)
        ..sort((a, b) => _eventSortKey(b).compareTo(_eventSortKey(a)));

      if (!mounted || loadVersion != _attendeeLoadVersion) return;
      setState(() {
        attendeeEvents = sortedEvents;
        joinedEventIds = newJoinedIds;
        checkedInEventIds = newCheckedInIds;
        isLoadingAttendee = false;
      });

      unawaited(_hydrateAttendeeEventMetadata(sortedEvents, loadVersion));
    } catch (_) {
      if (!mounted || loadVersion != _attendeeLoadVersion) return;
      setState(() {
        if (attendeeEvents.isEmpty) {
          joinedEventIds = [];
          checkedInEventIds = <int>{};
          eventParticipantCount = {};
          eventCreators = {};
        }
        isLoadingAttendee = false;
      });
    }
  }

  Future<void> _hydrateAttendeeEventMetadata(
    List<EventModel> events,
    int loadVersion,
  ) async {
    if (events.isEmpty) {
      if (!mounted || loadVersion != _attendeeLoadVersion) return;
      setState(() {
        eventParticipantCount = {};
        eventCreators = {};
      });
      return;
    }

    final eventIds = events
        .where((e) => e.id != null)
        .map((e) => e.id!)
        .toList();
    final creatorIds = events.map((e) => e.createdBy).toSet();

    final nextParticipantCount = <int, int>{};
    for (final eventId in eventIds) {
      final previousCount = eventParticipantCount[eventId];
      if (previousCount != null) {
        nextParticipantCount[eventId] = previousCount;
      }
    }

    final participantCountResults = await Future.wait(
      eventIds.map((eventId) async {
        try {
          final total = await EventParticipantController.getTotalParticipants(
            eventId,
          );
          return (eventId, total);
        } catch (_) {
          return (eventId, nextParticipantCount[eventId] ?? 0);
        }
      }),
      eagerError: false,
    );

    for (final result in participantCountResults) {
      nextParticipantCount[result.$1] = result.$2;
    }

    final nextEventCreators = <int, UserModel>{};

    // Always re-fetch creator profiles so avatar/name changes reflect in realtime.
    final creatorResults = await Future.wait(
      creatorIds.map((creatorId) async {
        try {
          final user = await UserController.getUserById(creatorId);
          if (user != null) return (creatorId, user);

          final fallback = eventCreators[creatorId];
          return fallback != null ? (creatorId, fallback) : null;
        } catch (_) {
          final fallback = eventCreators[creatorId];
          return fallback != null ? (creatorId, fallback) : null;
        }
      }),
      eagerError: false,
    );

    for (final result in creatorResults) {
      if (result != null) {
        nextEventCreators[result.$1] = result.$2;
      }
    }

    if (!mounted || loadVersion != _attendeeLoadVersion) return;
    setState(() {
      eventParticipantCount = nextParticipantCount;
      eventCreators = nextEventCreators;
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
                text: currentUser?.nama ?? namaUser ?? "",
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
              builder: (_) => ProfilePage(role: role ?? "Attendee"),
            ),
          );

          if (result is String) {
            role = result;
            await loadSession();
          } else if (result == true) {
            await loadSession();
          }
          getCurrentUser(); // reload foto
        },
        child: ProfileAvatar(
          imagePath: currentUser?.profileImage,
          radius: 24,
          backgroundColor: AppTheme.third,
          iconSize: 24,
        ),
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
                                        color: AppTheme.fourth,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: const [
                                          Icon(
                                            Icons.delete_outline,
                                            color: AppTheme.primary,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            "Delete",
                                            style: TextStyle(
                                              color: AppTheme.primary,
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
                                          backgroundColor: const Color(
                                            0xFF171A33,
                                          ),
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
                                                style: styleText().copyWith(
                                                  color: AppTheme.fourth,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },

                                    onDismissed: (direction) async {
                                      final removedIndex = committeeEvents
                                          .indexWhere((e) => e.id == event.id);
                                      if (removedIndex == -1) return;

                                      setState(() {
                                        committeeEvents.removeAt(removedIndex);
                                        eventParticipantCount.remove(event.id!);
                                      });

                                      try {
                                        await EventController.deleteEvent(
                                          event.id!,
                                        ).timeout(const Duration(seconds: 10));

                                        if (mounted) {
                                          try {
                                            ScaffoldMessenger.of(
                                              this.context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "Event deleted succesfully",
                                                ),
                                                behavior:
                                                    SnackBarBehavior.floating,
                                              ),
                                            );
                                          } catch (_) {}
                                        }
                                      } catch (_) {
                                        if (mounted) {
                                          try {
                                            ScaffoldMessenger.of(
                                              this.context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "Failed to delete event. Check connection and try again",
                                                ),
                                                behavior:
                                                    SnackBarBehavior.floating,
                                              ),
                                            );
                                          } catch (_) {}
                                        }
                                      }

                                      if (mounted) {
                                        await loadCommitteeEvents();
                                      }
                                    },

                                    child: InkWell(
                                      onTap: () async {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => DetailEventPage(
                                              eventId: event.id!,
                                              initialEvent: event,
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
                                              "${eventParticipantCount[event.id] ?? 0} joined",
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
                      child: isLoadingAttendee && attendeeEvents.isEmpty
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
                                  final eventId = event.id;
                                  final creator =
                                      eventCreators[event.createdBy];
                                  final joined =
                                      eventId != null &&
                                      joinedEventIds.contains(eventId);
                                  final checkedIn =
                                      eventId != null &&
                                      checkedInEventIds.contains(eventId);
                                  final isJoiningEvent =
                                      eventId != null &&
                                      _joiningEventIds.contains(eventId);
                                  final isExpired = isEventPassed(event);
                                  final showJoinedBadge =
                                      joined && !checkedIn && !isJoiningEvent;
                                  final statusBadges = <Widget>[
                                    if (isJoiningEvent) _buildJoiningBadge(),
                                    if (showJoinedBadge)
                                      _buildStatusBadge(
                                        label: "JOINED",
                                        color: const Color(0xFF73E8D7),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    if (checkedIn)
                                      _buildStatusBadge(
                                        label: "CHECKED IN",
                                        color: const Color(0xFF8BE39A),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    if (isExpired)
                                      _buildStatusBadge(
                                        label: "EXPIRED",
                                        color: AppTheme.fourth.withOpacity(
                                          0.75,
                                        ),
                                      ),
                                  ];
                                  final hasAnyBadge = statusBadges.isNotEmpty;

                                  return AppListCard(
                                    child: InkWell(
                                      onTap: isJoiningEvent
                                          ? null
                                          : () async {
                                              try {
                                                final activeUserId =
                                                    await _resolveCurrentUserId();
                                                if (activeUserId == null ||
                                                    activeUserId <= 0) {
                                                  if (!mounted) return;
                                                  try {
                                                    ScaffoldMessenger.of(
                                                      this.context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          "User session is not ready. Please login again.",
                                                        ),
                                                      ),
                                                    );
                                                  } catch (_) {}
                                                  return;
                                                }

                                                if (eventId == null) return;
                                                if (_joiningEventIds.contains(
                                                  eventId,
                                                )) {
                                                  return;
                                                }

                                                // Use local joined state first so joined events open directly.
                                                if (joined) {
                                                  await _openAttendeeEventPage(
                                                    userId: activeUserId,
                                                    eventId: eventId,
                                                  );
                                                  return;
                                                }

                                                /// ❌ JIKA BELUM JOIN & EVENT SUDAH LEWAT → BLOCK
                                                if (isEventPassed(event)) {
                                                  bool serverJoined = false;
                                                  try {
                                                    serverJoined =
                                                        await EventParticipantController.isJoined(
                                                          activeUserId,
                                                          eventId,
                                                        );
                                                  } catch (_) {
                                                    serverJoined = false;
                                                  }

                                                  if (serverJoined) {
                                                    if (mounted &&
                                                        !joinedEventIds
                                                            .contains(
                                                              eventId,
                                                            )) {
                                                      setState(() {
                                                        joinedEventIds.add(
                                                          eventId,
                                                        );
                                                      });
                                                    }

                                                    await _openAttendeeEventPage(
                                                      userId: activeUserId,
                                                      eventId: eventId,
                                                    );
                                                    return;
                                                  }

                                                  await showDialog(
                                                    context: context,
                                                    builder: (_) => AlertDialog(
                                                      backgroundColor:
                                                          const Color(
                                                            0xFF171A33,
                                                          ),
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
                                                              Navigator.pop(
                                                                context,
                                                              ),
                                                          child: Text(
                                                            "OK",
                                                            style: styleText()
                                                                .copyWith(
                                                                  color: AppTheme
                                                                      .third,
                                                                ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                  if (mounted) setState(() {});
                                                  return;
                                                }

                                                /// ✅ JIKA BELUM JOIN & MASIH AKTIF → BISA JOIN
                                                final confirm = await showDialog(
                                                  context: context,
                                                  builder: (_) => AlertDialog(
                                                    backgroundColor:
                                                        const Color(0xFF171A33),
                                                    title: Text(
                                                      "Join Event",
                                                      style: styleText(),
                                                    ),
                                                    content: Text.rich(
                                                      style: styleText(),
                                                      TextSpan(
                                                        children: [
                                                          TextSpan(
                                                            text: "Join to ",
                                                          ),
                                                          TextSpan(
                                                            text: event.title,
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                          TextSpan(text: "?"),
                                                        ],
                                                      ),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                              context,
                                                              false,
                                                            ),
                                                        child: Text(
                                                          "Cancel",
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
                                                          style: styleText()
                                                              .copyWith(
                                                                color: AppTheme
                                                                    .third,
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );

                                                if (confirm == true) {
                                                  if (mounted) {
                                                    setState(() {
                                                      _joiningEventIds.add(
                                                        eventId,
                                                      );
                                                    });
                                                  }

                                                  try {
                                                    await EventParticipantController.joinEvent(
                                                      activeUserId,
                                                      eventId,
                                                    );

                                                    if (mounted) {
                                                      setState(() {
                                                        if (!joinedEventIds
                                                            .contains(
                                                              eventId,
                                                            )) {
                                                          joinedEventIds.add(
                                                            eventId,
                                                          );
                                                        }

                                                        final currentCount =
                                                            eventParticipantCount[eventId] ??
                                                            0;
                                                        eventParticipantCount[eventId] =
                                                            currentCount + 1;
                                                      });
                                                    }

                                                    await _openAttendeeEventPage(
                                                      userId: activeUserId,
                                                      eventId: eventId,
                                                    );
                                                  } catch (e) {
                                                    bool serverJoined = false;
                                                    try {
                                                      serverJoined =
                                                          await EventParticipantController.isJoined(
                                                            activeUserId,
                                                            eventId,
                                                          );
                                                    } catch (_) {
                                                      serverJoined = false;
                                                    }

                                                    if (serverJoined) {
                                                      if (mounted &&
                                                          !joinedEventIds
                                                              .contains(
                                                                eventId,
                                                              )) {
                                                        setState(() {
                                                          joinedEventIds.add(
                                                            eventId,
                                                          );
                                                        });
                                                      }

                                                      await _openAttendeeEventPage(
                                                        userId: activeUserId,
                                                        eventId: eventId,
                                                      );
                                                      return;
                                                    }

                                                    if (mounted) {
                                                      try {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                              'Error: $e',
                                                            ),
                                                          ),
                                                        );
                                                      } catch (_) {}
                                                    }
                                                  } finally {
                                                    if (mounted) {
                                                      setState(() {
                                                        _joiningEventIds.remove(
                                                          eventId,
                                                        );
                                                      });
                                                    }
                                                  }
                                                }
                                              } catch (_) {
                                                // Silently handle top-level errors
                                              }
                                            },
                                      child: AnimatedOpacity(
                                        opacity: isJoiningEvent ? 0.55 : 1,
                                        duration: const Duration(
                                          milliseconds: 150,
                                        ),
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
                                                  child: Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          event.title,
                                                          style: styleText()
                                                              .copyWith(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          maxLines: 2,
                                                        ),
                                                      ),
                                                      if (hasAnyBadge) ...[
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Flexible(
                                                          child: Align(
                                                            alignment: Alignment
                                                                .topRight,
                                                            child: SingleChildScrollView(
                                                              scrollDirection:
                                                                  Axis.horizontal,
                                                              reverse: true,
                                                              child: Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  for (
                                                                    int i = 0;
                                                                    i <
                                                                        statusBadges
                                                                            .length;
                                                                    i++
                                                                  ) ...[
                                                                    statusBadges[i],
                                                                    if (i !=
                                                                        statusBadges.length -
                                                                            1)
                                                                      const SizedBox(
                                                                        width:
                                                                            8,
                                                                      ),
                                                                  ],
                                                                ],
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

                                            const SizedBox(height: 10),

                                            /// LOCATION
                                            buildRow(
                                              Icons.location_pin,
                                              event.location,
                                            ),

                                            const SizedBox(height: 8),

                                            /// TOTAL PESERTA
                                            buildRow(
                                              Icons.people,
                                              "${eventParticipantCount[event.id] ?? 0} joined",
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
                                                    child: ProfileAvatar(
                                                      imagePath:
                                                          creator.profileImage,
                                                      radius: 12,
                                                      backgroundColor:
                                                          AppTheme.third,
                                                      iconSize: 16,
                                                    ),
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
