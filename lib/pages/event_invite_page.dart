import 'package:connext_app/constants/app_theme.dart';
import 'package:connext_app/constants/style_text.dart';
import 'package:connext_app/models/event_model.dart';
import 'package:connext_app/models/user_model.dart';
import 'package:connext_app/pages/attendee_event_page/attendee_event_page.dart';
import 'package:connext_app/pages/auth/daftar_page.dart';
import 'package:connext_app/pages/auth/log_in_page.dart';
import 'package:connext_app/pages/home_page/home_page.dart';
import 'package:connext_app/pages/landing_page/landing_page.dart';
import 'package:connext_app/services/event_controller.dart';
import 'package:connext_app/services/event_participant_controller.dart';
import 'package:connext_app/services/google_maps_service.dart';
import 'package:connext_app/services/preferences_services.dart';
import 'package:connext_app/services/user_controller.dart';
import 'package:connext_app/widgets/app_section_card.dart';
import 'package:connext_app/widgets/connext_app_bar.dart';
import 'package:connext_app/widgets/ellipse_background.dart';
import 'package:connext_app/widgets/profile_avatar.dart';
import 'package:connext_app/widgets/tombol_sementara.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventInvitePage extends StatefulWidget {
  const EventInvitePage({super.key, required this.eventId});

  final int eventId;

  @override
  State<EventInvitePage> createState() => _EventInvitePageState();
}

class _EventInvitePageState extends State<EventInvitePage> {
  EventModel? event;
  bool isLoading = true;
  bool isJoining = false;
  bool isAlreadyJoined = false;
  int userId = 0;
  String userRole = 'Attendee';
  String? creatorProfileImage;

  bool get isOwner {
    if (event == null) return false;
    return userId > 0 && event!.createdBy == userId;
  }

  DateTime? get _eventDateTime {
    if (event == null) return null;

    final rawDate = event!.eventDate?.trim() ?? '';
    if (rawDate.isEmpty) return null;

    final datePart = DateTime.tryParse(rawDate);
    if (datePart == null) return null;

    final rawTime = event!.eventTime?.trim() ?? '';
    if (rawTime.isEmpty) {
      return DateTime(datePart.year, datePart.month, datePart.day);
    }

    final timeSegments = rawTime.split(':');
    final hour = int.tryParse(timeSegments.first) ?? 0;
    final minute = timeSegments.length > 1
        ? int.tryParse(timeSegments[1]) ?? 0
        : 0;

    return DateTime(datePart.year, datePart.month, datePart.day, hour, minute);
  }

  bool get isEventExpired {
    final eventDateTime = _eventDateTime;
    if (eventDateTime == null) return false;
    return eventDateTime.isBefore(DateTime.now());
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _refreshSessionState() async {
    final pref = PreferenceHandler();
    await pref.init();
    userId = pref.getUserId();
    userRole = pref.getRole() ?? 'Attendee';
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      isAlreadyJoined = false;
      creatorProfileImage = null;
    });

    await _refreshSessionState();

    try {
      event = await EventController.getEventById(widget.eventId);

      if (event != null && event!.createdBy > 0) {
        final UserModel? creator = await UserController.getUserById(
          event!.createdBy,
        );
        creatorProfileImage = creator?.profileImage;
      }

      if (event != null && userId > 0) {
        isAlreadyJoined = await EventParticipantController.isJoined(
          userId,
          widget.eventId,
        );
      }
    } catch (_) {
      event = null;
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _openMaps() async {
    if (event == null) return;
    await openGoogleMapsLocation(
      location: event!.location,
      locationUrl: event!.resolvedLocationUrl,
      placeId: event!.locationPlaceId,
    );
  }

  String _buildEventScheduleLabel() {
    final eventDateTime = _eventDateTime;
    if (eventDateTime == null) return '-';
    return DateFormat('EEE, d MMM yyyy • HH:mm').format(eventDateTime);
  }

  String _buildCreatorLabel() {
    if (event == null) return '-';

    final createdByName = event!.createdByName?.trim() ?? '';
    if (createdByName.isNotEmpty) return createdByName;

    if (event!.createdBy > 0) {
      return 'Committee #${event!.createdBy}';
    }

    return 'Committee';
  }

  Future<void> _joinEvent() async {
    if (event == null || isJoining) return;

    await _refreshSessionState();

    if (isOwner) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot join your own event as attendee'),
        ),
      );
      return;
    }

    if (isEventExpired) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This event has already ended')),
      );
      return;
    }

    if (userId <= 0) {
      final pref = PreferenceHandler();
      await pref.init();
      await pref.savePendingJoinEventId(widget.eventId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in or register first')),
      );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LandingPage()),
      );
      return;
    }

    final alreadyJoined = await EventParticipantController.isJoined(
      userId,
      widget.eventId,
    );

    if (alreadyJoined) {
      final pref = PreferenceHandler();
      await pref.init();
      await pref.clearPendingJoinEventId();

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) =>
              AttendeeEventPage(userId: userId, eventId: widget.eventId),
        ),
        (route) => false,
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF171A33),
        title: Text('Join Event', style: styleText()),
        content: Text.rich(
          style: styleText(),
          TextSpan(
            children: [
              const TextSpan(text: 'Join to '),
              TextSpan(
                text: event!.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: '?'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: styleText()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Join',
              style: styleText().copyWith(color: AppTheme.third),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      isJoining = true;
    });

    try {
      await EventParticipantController.joinEvent(userId, widget.eventId);

      final pref = PreferenceHandler();
      await pref.init();
      await pref.clearPendingJoinEventId();

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) =>
              AttendeeEventPage(userId: userId, eventId: widget.eventId),
        ),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to join event')));
    } finally {
      if (mounted) {
        setState(() {
          isJoining = false;
        });
      }
    }
  }

  Future<void> _goBackSafely() async {
    final pref = PreferenceHandler();
    await pref.init();

    if (!mounted) return;
    final target = pref.getIsLogin() ? const HomePage() : const LandingPage();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => target),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: ConnextAppBar(
        variant: ConnextAppBarVariant.hero,
        title: Text('Event Invitation', style: styleText()),
        onLeadingPressed: _goBackSafely,
      ),
      body: Stack(
        children: [
          EllipseBackground(),
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : event == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Event not found or link is invalid.',
                      textAlign: TextAlign.center,
                      style: styleText(),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: AppSectionCard(
                    title: 'Do you want to join event?',
                    icon: Icons.how_to_reg,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppTheme.third.withOpacity(0.95),
                                AppTheme.fourth.withOpacity(0.95),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.third.withOpacity(0.18),
                                blurRadius: 24,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.event,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      event!.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: styleText().copyWith(
                                        color: AppTheme.primary,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        height: 1.1,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Event invitation',
                                style: styleText().copyWith(
                                  color: AppTheme.primary.withOpacity(0.8),
                                  fontSize: 12,
                                ),
                              ),
                              if (isEventExpired) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'Event has ended',
                                    style: styleText().copyWith(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_pin,
                              color: Color(0xFF73E8D7),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                event!.locationName?.trim().isNotEmpty == true
                                    ? event!.locationName!.trim()
                                    : event!.location,
                                style: styleText().copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.third,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _openMaps,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: const Color(0xFF171A33),
                              border: Border.all(
                                color: AppTheme.third.withOpacity(0.24),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.location_pin,
                                  color: AppTheme.third,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Open in Google Maps',
                                    style: styleText().copyWith(
                                      color: AppTheme.secondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.open_in_new,
                                  color: AppTheme.third,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: const Color(0xFF171A33),
                            border: Border.all(
                              color: AppTheme.third.withOpacity(0.14),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Event Time',
                                style: styleText().copyWith(
                                  fontSize: 12,
                                  color: AppTheme.third,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _buildEventScheduleLabel(),
                                style: styleText().copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Created by',
                                style: styleText().copyWith(
                                  fontSize: 12,
                                  color: AppTheme.third,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  ProfileAvatar(
                                    imagePath: creatorProfileImage,
                                    radius: 12,
                                    backgroundColor: AppTheme.third,
                                    iconColor: AppTheme.primary,
                                    iconSize: 14,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _buildCreatorLabel(),
                                      style: styleText().copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.description,
                              color: Color(0xFF73E8D7),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                event!.description.isEmpty
                                    ? 'No description'
                                    : event!.description,
                                style: styleText(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        if (userId <= 0) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF171A33),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: AppTheme.third.withOpacity(0.18),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'You need an account before joining this event.',
                                  style: styleText().copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TombolSementara(
                                        icon: Icons.login,
                                        text: 'Log In',
                                        width: double.infinity,
                                        height: 48,
                                        onPressed: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => const LogInPage(),
                                            ),
                                          );
                                          await _loadData();
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TombolSementara(
                                        icon: Icons.app_registration,
                                        text: 'Register',
                                        width: double.infinity,
                                        height: 48,
                                        onPressed: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const DaftarPage(),
                                            ),
                                          );
                                          await _loadData();
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],
                        TombolSementara(
                          icon: isOwner
                              ? Icons.person_off
                              : isEventExpired
                              ? Icons.event_busy
                              : Icons.person_add_alt_1,
                          text: isOwner
                              ? 'Your Event'
                              : isEventExpired
                              ? 'Event Ended'
                              : 'Join Event',
                          width: double.infinity,
                          height: 52,
                          isLoading: isJoining,
                          onPressed: isEventExpired || isOwner
                              ? null
                              : _joinEvent,
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
