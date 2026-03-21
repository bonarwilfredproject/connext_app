import 'dart:io';
import 'package:connext_app/models/user_model.dart';
import 'package:connext_app/services/user_controller.dart';
import 'package:connext_app/constants/app_theme.dart';
import 'package:connext_app/constants/style_text.dart';
import 'package:connext_app/models/event_model.dart';
import 'package:connext_app/services/check_in_controller.dart';
import 'package:connext_app/services/event_controller.dart';
import 'package:connext_app/services/event_participant_controller.dart';
import 'package:connext_app/widgets/app_list_card.dart';
import 'package:connext_app/widgets/app_section_card.dart';
import 'package:connext_app/widgets/ellipse_background.dart';
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

class _AttendeeEventPageState extends State<AttendeeEventPage> {
  UserModel? creator;
  EventModel? event;
  String? qrToken;
  bool isCheckedIn = false;
  bool isLoading = true;
  int totalPeserta = 0;
  String? waktuCheckin;

  @override
  void initState() {
    super.initState();
    loadEvent();
  }

  bool isEventPassed() {
    if (event?.eventDate == null || event?.eventTime == null) return false;

    try {
      final date = DateTime.parse(event!.eventDate!);

      final timeParts = event!.eventTime!.split(":");

      final eventDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
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

  String formatTanggal(String waktu) {
    DateTime date = DateTime.tryParse(waktu) ?? DateTime.now();

    return DateFormat("EEEE, dd MMM yyyy, HH.mm").format(date);
  }

  Future<void> loadEvent() async {
    /// ambil detail event
    event = await EventController.getEventById(widget.eventId);

    /// ambil data panitia
    if (event != null) {
      creator = await UserController.getUserById(event!.createdBy);
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
    print(participant);
    if (participant != null) {
      isCheckedIn = await CheckinController.isAlreadyCheckin(participant["id"]);

      /// ambil waktu check-in
      waktuCheckin = participant["checkin_time"];
    }

    setState(() {
      isLoading = false;
    });
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
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_pin,
                                    size: 18,
                                    color: AppTheme.secondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      event!.location,
                                      style: styleText(),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
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
                                    "$totalPeserta Attendee",
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
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor: AppTheme.third,
                                      backgroundImage:
                                          creator!.profileImage != null &&
                                              creator!
                                                  .profileImage!
                                                  .isNotEmpty &&
                                              File(
                                                creator!.profileImage!,
                                              ).existsSync()
                                          ? FileImage(
                                              File(creator!.profileImage!),
                                            )
                                          : null,
                                      child:
                                          creator!.profileImage == null ||
                                              creator!.profileImage!.isEmpty
                                          ? const Icon(Icons.person, size: 16)
                                          : null,
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
                                  data: '{"token":"$qrToken"}',
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
                                      "Leave",
                                      style: TextStyle(color: AppTheme.white),
                                    ),
                                    onPressed: () async {
                                      final confirm = await showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          backgroundColor: AppTheme.third,
                                          title: Text(
                                            "Leave",
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

                                        Navigator.pop(context, true);
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
