import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connext_app/models/user_model.dart';
import 'package:connext_app/services/user_controller.dart';
import 'package:connext_app/constants/app_theme.dart';
import 'package:connext_app/constants/style_text.dart';
import 'package:connext_app/models/event_model.dart';
import 'package:connext_app/services/check_in_controller.dart';
import 'package:connext_app/services/event_controller.dart';
import 'package:connext_app/services/event_participant_controller.dart';
import 'package:connext_app/services/google_maps_service.dart';
import 'package:connext_app/widgets/app_list_card.dart';
import 'package:connext_app/widgets/app_section_card.dart';
import 'package:connext_app/widgets/ellipse_background.dart';
import 'package:connext_app/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

class AttendeeEventPage extends StatefulWidget {
  final int userId;
  final int eventId;

  const AttendeeEventPage({
    super.key,
    required this.userId,
    required this.eventId,
  });

  @override
  State<AttendeeEventPage> createState() => _AttendeeEventPageState();
}

class _AttendeeEventPageState extends State<AttendeeEventPage>
    with WidgetsBindingObserver {
  Timer? _checkinRefreshTimer;
  Timer? _eventPassTicker;
  Timer? _realtimeDebounceTimer;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _eventRealtimeSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _participantsRealtimeSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _creatorRealtimeSub;
  int? _boundCreatorId;
  UserModel? creator;
  EventModel? event;
  String? qrToken;
  bool isCheckedIn = false;
  bool isLoading = true;
  int totalPeserta = 0;
  String? waktuCheckin;
  bool? _lastEventPassed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bindRealtimeListeners();
    loadEvent();
    _startCheckinAutoRefresh();
    _startEventPassTicker();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _checkinRefreshTimer?.cancel();
    _eventPassTicker?.cancel();
    _realtimeDebounceTimer?.cancel();
    _eventRealtimeSub?.cancel();
    _participantsRealtimeSub?.cancel();
    _creatorRealtimeSub?.cancel();
    super.dispose();
  }

  void _startEventPassTicker() {
    _eventPassTicker?.cancel();
    _eventPassTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || event == null) return;

      final nowPassed = isEventPassed();
      if (_lastEventPassed == null) {
        _lastEventPassed = nowPassed;
        return;
      }

      if (_lastEventPassed != nowPassed) {
        setState(() {
          _lastEventPassed = nowPassed;
        });
      }
    });
  }

  void _bindCreatorRealtimeListener(int creatorId) {
    if (_boundCreatorId == creatorId && _creatorRealtimeSub != null) {
      return;
    }

    _boundCreatorId = creatorId;
    _creatorRealtimeSub?.cancel();

    _creatorRealtimeSub = FirebaseFirestore.instance
        .collection('users')
        .where('id', whereIn: [creatorId, creatorId.toString()])
        .limit(1)
        .snapshots()
        .listen((snapshot) {
          if (!mounted || snapshot.docs.isEmpty) return;

          final latestUser = UserModel.fromMap(snapshot.docs.first.data());
          setState(() {
            creator = latestUser;
          });
        });
  }

  void _bindRealtimeListeners() {
    final eventDocRef = FirebaseFirestore.instance
        .collection('events')
        .doc(widget.eventId.toString());

    _eventRealtimeSub = eventDocRef.snapshots().listen(
      (_) => _scheduleRealtimeRefresh(),
    );

    _participantsRealtimeSub = eventDocRef
        .collection('participants')
        .snapshots()
        .listen((_) => _scheduleRealtimeRefresh());
  }

  void _scheduleRealtimeRefresh() {
    if (!mounted) return;

    _realtimeDebounceTimer?.cancel();
    _realtimeDebounceTimer = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;

      await loadEvent();
      await _refreshCheckinStatus();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshCheckinStatus();
    }
  }

  void _startCheckinAutoRefresh() {
    _checkinRefreshTimer?.cancel();
    _checkinRefreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      _refreshCheckinStatus();
    });
  }

  Future<void> _refreshCheckinStatus() async {
    try {
      final participant = await CheckinController.getParticipant(
        widget.userId,
        widget.eventId,
      );

      if (participant == null) {
        String? latestQrToken = qrToken;
        if (latestQrToken == null || latestQrToken.isEmpty) {
          latestQrToken = await EventParticipantController.getQrToken(
            widget.userId,
            widget.eventId,
          );
        }

        if (!mounted) return;

        final shouldUpdateWhenMissing =
            isCheckedIn || waktuCheckin != null || latestQrToken != qrToken;
        if (shouldUpdateWhenMissing) {
          setState(() {
            isCheckedIn = false;
            waktuCheckin = null;
            qrToken = latestQrToken;
          });
        }
        return;
      }

      final checkinTime = participant['checkin_time']?.toString();
      final checkedIn = checkinTime != null && checkinTime.isNotEmpty;

      String? latestQrToken = qrToken;
      if (!checkedIn && (latestQrToken == null || latestQrToken.isEmpty)) {
        latestQrToken = await EventParticipantController.getQrToken(
          widget.userId,
          widget.eventId,
        );
      }

      if (!mounted) return;

      final shouldUpdate =
          checkedIn != isCheckedIn ||
          waktuCheckin != checkinTime ||
          latestQrToken != qrToken;

      if (shouldUpdate) {
        setState(() {
          isCheckedIn = checkedIn;
          waktuCheckin = checkedIn ? checkinTime : null;
          qrToken = latestQrToken;
        });
      }
    } catch (_) {
      // Keep UI stable if network or parsing fails.
    }
  }

  bool isEventPassed() {
    if (event?.eventDate == null || event?.eventTime == null) return false;

    try {
      final date = DateTime.parse(event!.eventDate!);
      final normalized = event!.eventTime!
          .trim()
          .replaceAll('.', ':')
          .replaceAll(RegExp(r'\s+'), ' ')
          .toUpperCase();

      int? hour;
      int? minute;

      final hmMatch = RegExp(
        r'^(\d{1,2}):(\d{1,2})(?:\s*([AP]M))?$',
      ).firstMatch(normalized);
      if (hmMatch != null) {
        var parsedHour = int.tryParse(hmMatch.group(1)!);
        final parsedMinute = int.tryParse(hmMatch.group(2)!);
        final ampm = hmMatch.group(3);

        if (parsedHour != null && parsedMinute != null) {
          if (ampm != null) {
            if (parsedHour == 12) parsedHour = 0;
            if (ampm == 'PM') parsedHour += 12;
          }

          if (parsedHour >= 0 &&
              parsedHour <= 23 &&
              parsedMinute >= 0 &&
              parsedMinute <= 59) {
            hour = parsedHour;
            minute = parsedMinute;
          }
        }
      }

      if (hour == null || minute == null) {
        for (final pattern in ['H:mm', 'HH:mm', 'h:mm a', 'hh:mm a']) {
          try {
            final parsed = DateFormat(pattern).parseStrict(normalized);
            hour = parsed.hour;
            minute = parsed.minute;
            break;
          } catch (_) {
            // Try next pattern.
          }
        }
      }

      if (hour == null || minute == null) return false;

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

      // Consider event passed only after the next minute bucket.
      return now.isAfter(eventDateTime);
    } catch (e) {
      return false;
    }
  }

  String formatTanggal(String waktu) {
    DateTime date = DateTime.tryParse(waktu) ?? DateTime.now();

    return DateFormat("EEEE, dd MMM yyyy, HH.mm").format(date);
  }

  Future<void> loadEvent() async {
    try {
      /// ambil detail event
      event = await EventController.getEventById(widget.eventId);

      /// ambil data panitia
      if (event != null) {
        creator = await UserController.getUserById(event!.createdBy);
        _bindCreatorRealtimeListener(event!.createdBy);
        _lastEventPassed = isEventPassed();
      }

      totalPeserta = await EventParticipantController.getTotalParticipants(
        widget.eventId,
      );

      /// ambil token QR
      qrToken = await EventParticipantController.getQrToken(
        widget.userId,
        widget.eventId,
      );

      final participant = await CheckinController.getParticipant(
        widget.userId,
        widget.eventId,
      );
      if (participant != null) {
        final checkinTime = participant["checkin_time"]?.toString();
        isCheckedIn = checkinTime != null && checkinTime.isNotEmpty;

        /// ambil waktu check-in
        waktuCheckin = checkinTime;
      } else {
        isCheckedIn = false;
        waktuCheckin = null;
      }
    } catch (_) {
      // Keep page responsive even if one of the requests fails.
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _openEventLocation() async {
    if (event == null) return;

    final opened = await openGoogleMapsLocation(
      location: event!.location,
      locationUrl: event!.resolvedLocationUrl,
      placeId: event!.locationPlaceId,
    );

    if (!opened && mounted) {
      try {
        ScaffoldMessenger.of(this.context).showSnackBar(
          const SnackBar(content: Text('Google Maps could not be opened')),
        );
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: Text("Event Detail", style: styleText()),
      ),
      body: Stack(
        children: [
          EllipseBackground(),
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : event == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Event details can not be loaded",
                      textAlign: TextAlign.center,
                      style: styleText(),
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      /// =====================
                      /// SECTION INFO EVENT
                      /// =====================
                      AppSectionCard(
                        title: "Event",
                        icon: Icons.event,
                        child: AppListCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event!.title,
                                style: styleText().copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 8),

                              /// LOCATION
                              InkWell(
                                onTap: _openEventLocation,
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.location_pin,
                                        size: 18,
                                        color: AppTheme.secondary,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if ((event!.locationName
                                                    ?.trim()
                                                    .isNotEmpty ??
                                                false))
                                              Text(
                                                event!.locationName!.trim(),
                                                style: styleText().copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            if ((event!.locationName
                                                        ?.trim()
                                                        .isEmpty ??
                                                    true) ||
                                                event!.locationName!.trim() !=
                                                    event!.location.trim())
                                              Text(
                                                event!.location,
                                                style: styleText().copyWith(
                                                  decoration:
                                                      TextDecoration.underline,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 2,
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.open_in_new,
                                        size: 16,
                                        color: AppTheme.secondary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 8),

                              /// DESCRIPTION
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.description,
                                    size: 18,
                                    color: AppTheme.secondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      event!.description.isEmpty
                                          ? 'There is no description'
                                          : event!.description,
                                      style: styleText(),
                                      maxLines: 4,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              /// TOTAL PESERTA
                              Row(
                                children: [
                                  const Icon(
                                    Icons.people,
                                    size: 18,
                                    color: AppTheme.secondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "$totalPeserta joined",
                                    style: styleText(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              /// TANGGAL & WAKTU EVENT
                              Row(
                                children: [
                                  const Icon(
                                    Icons.event_available,
                                    size: 18,
                                    color: AppTheme.secondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      event!.eventDate != null
                                          ? "${DateFormat('EEEE, d MMMM yyyy').format(DateTime.parse(event!.eventDate!))} • ${event!.eventTime ?? '-'}"
                                          : "-",
                                      style: styleText(),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              /// PANITIA PEMBUAT EVENT
                              if (creator != null)
                                Row(
                                  children: [
                                    ProfileAvatar(
                                      imagePath: creator!.profileImage,
                                      radius: 12,
                                      backgroundColor: AppTheme.third,
                                      iconSize: 16,
                                    ),

                                    const SizedBox(width: 8),

                                    Expanded(
                                      child: Text(
                                        "by ${creator!.nama}",
                                        style: styleText(),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      /// =====================
                      /// SECTION QR CHECKIN
                      /// =====================
                      AppSectionCard(
                        title: "Check-In QR",
                        icon: Icons.qr_code,
                        child: Center(
                          child: Column(
                            children: [
                              if (isCheckedIn)
                                /// SUDAH CHECKIN
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    waktuCheckin != null
                                        ? "You have checked-in on\n${formatTanggal(waktuCheckin!)}"
                                        : "You have checked-in",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              else if (qrToken != null && !isEventPassed())
                                /// QR CODE
                                QrImageView(
                                  data: qrToken!,
                                  version: QrVersions.auto,
                                  size: 200,
                                  backgroundColor: Colors.white,
                                )
                              else if (isEventPassed())
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    "QR is not available",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 12),

                              Text(
                                isCheckedIn
                                    ? "Thank you for attending this event"
                                    : isEventPassed()
                                    ? "Event has passed"
                                    : "Show this QR to the Committee at the event",
                                textAlign: TextAlign.center,
                                style: styleText(),
                              ),
                              const SizedBox(height: 24),

                              /// CANCEL JOIN BUTTON
                              if (!isCheckedIn && !isEventPassed()) ...[
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.exit_to_app,
                                      color: AppTheme.white,
                                    ),
                                    label: const Text(
                                      "Leave Event",
                                      style: TextStyle(color: AppTheme.white),
                                    ),
                                    onPressed: () async {
                                      final confirm = await showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          backgroundColor: AppTheme.third,
                                          title: Text(
                                            "Leave Event",
                                            style: styleText(),
                                          ),
                                          content: Text.rich(
                                            style: styleText(),
                                            TextSpan(
                                              children: [
                                                TextSpan(
                                                  text:
                                                      "Are you sure want to leave ",
                                                ),
                                                TextSpan(
                                                  text: event!.title,
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
                                                "Leave",
                                                style: styleText(),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm == true) {
                                        await EventParticipantController.cancelJoin(
                                          widget.userId,
                                          widget.eventId,
                                        );

                                        Navigator.pop(context, {
                                          'leftEventId': widget.eventId,
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
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
