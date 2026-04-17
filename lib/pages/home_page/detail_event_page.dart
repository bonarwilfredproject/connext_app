import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:connext_app/constants/app_theme.dart';
import 'package:connext_app/constants/decoration_constant.dart';
import 'package:connext_app/constants/style_text.dart';
import 'package:connext_app/models/event_model.dart';
import 'package:connext_app/pages/scanner/scan_peserta_page.dart';
import 'package:connext_app/services/check_in_controller.dart';
import 'package:connext_app/services/event_controller.dart';
import 'package:connext_app/services/event_participant_controller.dart';
import 'package:connext_app/services/google_maps_service.dart';
import 'package:connext_app/services/user_controller.dart';
import 'package:connext_app/widgets/app_list_card.dart';
import 'package:connext_app/widgets/app_section_card.dart';
import 'package:connext_app/widgets/ellipse_background.dart';
import 'package:connext_app/widgets/profile_avatar.dart';
import 'package:connext_app/widgets/tombol_sementara.dart';
import 'package:flutter/material.dart';
import 'package:connext_app/widgets/google_places_autocomplete_field.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lottie/lottie.dart';

class DetailEventPage extends StatefulWidget {
  final int eventId;
  final EventModel? initialEvent;

  const DetailEventPage({super.key, required this.eventId, this.initialEvent});

  @override
  State<DetailEventPage> createState() => _DetailEventPageState();
}

class _DetailEventPageState extends State<DetailEventPage> {
  static const Duration _requestTimeout = Duration(seconds: 8);
  Timer? _realtimeDebounceTimer;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _eventRealtimeSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _participantsRealtimeSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _usersRealtimeSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _creatorRealtimeSub;
  int? _boundCreatorId;

  EventModel? event;
  String createdByName = 'Unknown user';
  String? createdByImage;
  String? loadError;
  bool isLoading = true;
  int totalPeserta = 0;
  int totalHadir = 0;
  List<Map<String, dynamic>> scannedPeserta = [];

  final GlobalKey<FormState> _editFormKey = GlobalKey<FormState>();
  final TextEditingController dateControllerEdit = TextEditingController();
  final TextEditingController timeControllerEdit = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  DateTime? selectedDateEdit;
  TimeOfDay? selectedTimeEdit;
  String? timeError;

  @override
  void initState() {
    super.initState();
    event = widget.initialEvent;
    initializeDateFormatting('id');
    _bindRealtimeListeners();
    initializeData();
  }

  @override
  void dispose() {
    _realtimeDebounceTimer?.cancel();
    _eventRealtimeSub?.cancel();
    _participantsRealtimeSub?.cancel();
    _usersRealtimeSub?.cancel();
    _creatorRealtimeSub?.cancel();
    dateControllerEdit.dispose();
    timeControllerEdit.dispose();
    titleController.dispose();
    locationController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void _scheduleRealtimeRefresh() {
    if (!mounted) return;

    _realtimeDebounceTimer?.cancel();
    _realtimeDebounceTimer = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;

      await Future.wait([loadEvent(), loadPeserta()], eagerError: false);
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

    _usersRealtimeSub = FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .listen((_) => _scheduleRealtimeRefresh());
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

          final data = snapshot.docs.first.data();
          final latestName = (data['nama'] ?? '').toString().trim();
          final latestImage = (data['profile_image'] ?? data['profileImage'])
              ?.toString();

          setState(() {
            if (latestName.isNotEmpty) {
              createdByName = latestName;
            }
            createdByImage = latestImage;
          });
        });
  }

  String? requiredValidator(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return "$label can't be empty";
    }
    return null;
  }

  String? validateDateTimeEdit() {
    if (selectedDateEdit == null || selectedTimeEdit == null) {
      return 'Date and time must be filled';
    }

    final nowRaw = DateTime.now();
    final now = DateTime(
      nowRaw.year,
      nowRaw.month,
      nowRaw.day,
      nowRaw.hour,
      nowRaw.minute,
    );

    final selectedDateTime = DateTime(
      selectedDateEdit!.year,
      selectedDateEdit!.month,
      selectedDateEdit!.day,
      selectedTimeEdit!.hour,
      selectedTimeEdit!.minute,
    );

    if (selectedDateTime.isBefore(now)) {
      return 'Time has passed, please pick another time';
    }

    return null;
  }

  String formatCreatedAt(String waktu) {
    final date = DateTime.tryParse(waktu) ?? DateTime.now();
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }

  DateTime? _parseCheckinDateTime(dynamic waktuRaw) {
    if (waktuRaw is Timestamp) {
      return waktuRaw.toDate();
    }

    if (waktuRaw is DateTime) {
      return waktuRaw;
    }

    return DateTime.tryParse(waktuRaw?.toString() ?? '');
  }

  String formatCheckinDateTime(dynamic waktuRaw) {
    final dateTime = _parseCheckinDateTime(waktuRaw);

    if (dateTime == null) return '-';

    return DateFormat('EEEE, dd MMM yyyy, HH:mm', 'id').format(dateTime);
  }

  Future<void> initializeData() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      loadError = null;
    });

    await Future.wait([loadEvent(), loadPeserta()], eagerError: false);

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> loadEvent() async {
    if (widget.initialEvent != null) {
      event = widget.initialEvent;
    }

    try {
      final loadedEvent = await EventController.getEventById(
        widget.eventId,
      ).timeout(_requestTimeout, onTimeout: () => null);

      if (loadedEvent != null) {
        event = loadedEvent;
        _bindCreatorRealtimeListener(loadedEvent.createdBy);
      } else if (event == null) {
        loadError = 'Event data could not be loaded';
        return;
      }

      try {
        totalPeserta = await EventParticipantController.getTotalParticipants(
          widget.eventId,
        ).timeout(_requestTimeout, onTimeout: () => 0);
      } catch (_) {
        totalPeserta = 0;
      }

      final inlineCreatorName = event?.createdByName?.trim();
      if (inlineCreatorName != null && inlineCreatorName.isNotEmpty) {
        createdByName = inlineCreatorName;
      }

      try {
        final user = await UserController.getUserById(
          event!.createdBy,
        ).timeout(_requestTimeout, onTimeout: () => null);
        createdByName = user?.nama ?? createdByName;
        createdByImage = user?.profileImage;
      } catch (_) {
        createdByName = createdByName.isEmpty ? 'Unknown user' : createdByName;
        createdByImage = null;
      }

      if (mounted) setState(() {});
    } catch (_) {
      if (event == null) {
        loadError = 'Event data could not be loaded';
      }
    }
  }

  Future<void> loadPeserta() async {
    final targetEventId = event?.id ?? widget.eventId;

    try {
      final data = await CheckinController.getCheckinByEvent(
        targetEventId,
      ).timeout(_requestTimeout, onTimeout: () => []);

      final sortedData = List<Map<String, dynamic>>.from(data)
        ..sort((a, b) {
          final aTime = _parseCheckinDateTime(a['waktu']);
          final bTime = _parseCheckinDateTime(b['waktu']);

          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;

          // Latest check-in should appear first.
          return bTime.compareTo(aTime);
        });

      if (!mounted) return;

      setState(() {
        scannedPeserta = sortedData;
        totalHadir = sortedData.length;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        scannedPeserta = [];
        totalHadir = 0;
      });
    }
  }

  Future<void> _openEventLocation() async {
    if (event == null) return;

    final opened = await openGoogleMapsLocation(
      location: event!.location,
      locationUrl: event!.locationUrl,
      placeId: event!.locationPlaceId,
    );

    if (!opened && mounted) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open location in Google Maps'),
          ),
        );
      } catch (_) {}
    }
  }

  void showEditEventDialog() {
    if (event == null) return;

    titleController.text = event!.title;
    locationController.text = event!.location;
    descriptionController.text = event!.description;
    String? selectedLocationPlaceId = event!.locationPlaceId;
    String? selectedLocationName = event!.locationName;

    selectedDateEdit = DateTime.tryParse(event!.eventDate ?? event!.createdAt);
    selectedDateEdit ??= DateTime.now();

    final timeValue = event!.eventTime ?? '00:00';
    final timeParts = timeValue.split(':');
    selectedTimeEdit = TimeOfDay(
      hour: int.tryParse(timeParts[0]) ?? 0,
      minute: int.tryParse(timeParts.length > 1 ? timeParts[1] : '0') ?? 0,
    );

    dateControllerEdit.text = DateFormat(
      'EE, d MMMM yyyy',
    ).format(selectedDateEdit!);
    timeControllerEdit.text =
        '${selectedTimeEdit!.hour.toString().padLeft(2, '0')}:${selectedTimeEdit!.minute.toString().padLeft(2, '0')}';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: AppTheme.third,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'Edit Event',
                style: styleText().copyWith(fontWeight: FontWeight.bold),
              ),
              content: Form(
                key: _editFormKey,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: titleController,
                          style: TextStyle(
                            color: AppTheme.secondary,
                            fontSize: 14,
                          ),
                          validator: (value) =>
                              requiredValidator(value, 'Event name'),
                          decoration: decorationConstant(
                            hintText: 'Event Name',
                            labelText: 'Event Name',
                          ),
                        ),
                        const SizedBox(height: 16),
                        GooglePlacesAutocompleteField(
                          controller: locationController,
                          labelText: 'Location',
                          hintText: 'Search event location on Google Maps',
                          showKeySourceInfo: false,
                          validator: (value) =>
                              requiredValidator(value, 'Location'),
                          onSelected: (details) {
                            setStateDialog(() {
                              selectedLocationPlaceId = details.placeId;
                              selectedLocationName =
                                  details.name?.trim().isNotEmpty ?? false
                                  ? details.name!.trim()
                                  : details.description.trim();
                            });
                          },
                          onTextChanged: (value) {
                            if (selectedLocationPlaceId != null ||
                                selectedLocationName != null) {
                              selectedLocationPlaceId = null;
                              selectedLocationName = null;
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: dateControllerEdit,
                                readOnly: true,
                                style: TextStyle(
                                  color: AppTheme.secondary,
                                  fontSize: 14,
                                ),
                                decoration: decorationConstant(
                                  hintText: 'Choose date',
                                  labelText: 'Date',
                                ),
                                onTap: () async {
                                  final now = DateTime.now();
                                  final safeInitialDate =
                                      (selectedDateEdit != null &&
                                          selectedDateEdit!.isBefore(now))
                                      ? now
                                      : selectedDateEdit ?? now;

                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: safeInitialDate,
                                    firstDate: now,
                                    lastDate: DateTime(2100),
                                  );

                                  if (picked != null) {
                                    selectedDateEdit = picked;
                                    dateControllerEdit.text = DateFormat(
                                      'EE, d MMMM yyyy',
                                    ).format(picked);
                                    timeError = validateDateTimeEdit();
                                    setStateDialog(() {});
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: timeControllerEdit,
                                readOnly: true,
                                style: TextStyle(
                                  color: AppTheme.secondary,
                                  fontSize: 14,
                                ),
                                decoration: decorationConstant(
                                  hintText: 'Choose time',
                                  labelText: 'Time',
                                ).copyWith(errorMaxLines: 1),
                                onTap: () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime:
                                        selectedTimeEdit ?? TimeOfDay.now(),
                                  );

                                  if (picked != null) {
                                    selectedTimeEdit = picked;
                                    timeControllerEdit.text = picked.format(
                                      context,
                                    );
                                    timeError = validateDateTimeEdit();
                                    setStateDialog(() {});
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (timeError != null)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text(
                                timeError!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 11.5,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: descriptionController,
                          maxLines: 3,
                          style: TextStyle(
                            color: AppTheme.secondary,
                            fontSize: 14,
                          ),
                          validator: (value) =>
                              requiredValidator(value, 'Description'),
                          decoration: decorationConstant(
                            hintText: 'Description',
                            labelText: 'Description',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: styleText()),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.fourth,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () async {
                    final isValid = _editFormKey.currentState!.validate();
                    timeError = validateDateTimeEdit();
                    setStateDialog(() {});

                    if (!isValid || timeError != null) return;

                    final updatedEvent = EventModel(
                      id: event!.id,
                      title: titleController.text,
                      location: locationController.text,
                      locationName: selectedLocationName,
                      locationUrl: buildGoogleMapsSearchUrl(
                        locationController.text,
                        placeId: selectedLocationPlaceId,
                      ),
                      locationPlaceId: selectedLocationPlaceId,
                      description: descriptionController.text,
                      createdBy: event!.createdBy,
                      createdAt: event!.createdAt,
                      eventDate: selectedDateEdit!.toIso8601String(),
                      eventTime:
                          '${selectedTimeEdit!.hour.toString().padLeft(2, '0')}:${selectedTimeEdit!.minute.toString().padLeft(2, '0')}',
                    );

                    await EventController.updateEvent(updatedEvent);
                    if (context.mounted) Navigator.pop(context);
                    await loadEvent();
                    await loadPeserta();
                  },
                  child: Text('Save', style: styleText()),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> showParticipants() async {
    final participants = await EventParticipantController.getParticipants(
      widget.eventId,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.primary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        if (participants.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset(
                  'assets/lottie/yawn_emoji_animation.json',
                  height: 130,
                  width: double.infinity,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 8),
                Text(
                  'There is no attendee',
                  style: styleText().copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Share this event so people can join',
                  textAlign: TextAlign.center,
                  style: styleText().copyWith(
                    fontSize: 13,
                    color: AppTheme.secondary,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(20),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: participants.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, index) {
              final p = participants[index];
              final hadir = p['isCheckedIn'];

              return AppListCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ProfileAvatar(
                          imagePath: p['profileImage']?.toString(),
                          radius: 20,
                          backgroundColor: AppTheme.third,
                          iconSize: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  p['name'] ?? '',
                                  style: styleText().copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: hadir ? Colors.green : Colors.red,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  hadir ? 'Present' : 'Absent',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.phone,
                          size: 18,
                          color: AppTheme.secondary,
                        ),
                        const SizedBox(width: 8),
                        Text(p['phone'] ?? '', style: styleText()),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Event Detail', style: styleText()),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.event_busy, size: 56, color: AppTheme.secondary),
              const SizedBox(height: 12),
              Text(loadError ?? 'Failed to load event', style: styleText()),
              const SizedBox(height: 12),
              TextButton(
                onPressed: initializeData,
                child: Text('Retry', style: styleText()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (event == null) {
      return _buildErrorState();
    }

    final eventInfoSection = AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.numbers, color: AppTheme.secondary),
              const SizedBox(width: 10),
              Text('${event!.id}', style: styleText()),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _openEventLocation,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.location_pin, color: AppTheme.secondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event!.location,
                          style: styleText().copyWith(
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.open_in_new, size: 16, color: AppTheme.secondary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.description, color: AppTheme.secondary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  event!.description.isEmpty
                      ? 'There is no description'
                      : event!.description,
                  style: styleText(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: showParticipants,
            child: Row(
              children: [
                Icon(Icons.people, color: AppTheme.secondary),
                const SizedBox(width: 10),
                Text('$totalPeserta joined', style: styleText()),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right, size: 18, color: AppTheme.secondary),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.verified, color: AppTheme.secondary),
              const SizedBox(width: 10),
              Text('$totalHadir present', style: styleText()),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ProfileAvatar(
                imagePath: createdByImage,
                radius: 12,
                backgroundColor: AppTheme.third,
                iconSize: 16,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text('By $createdByName', style: styleText())),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.history, color: AppTheme.secondary),
              const SizedBox(width: 10),
              Text(formatCreatedAt(event!.createdAt), style: styleText()),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.event_available, color: AppTheme.secondary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  event!.eventDate != null
                      ? "${DateFormat('EEEE, d MMMM yyyy').format(DateTime.parse(event!.eventDate!))} • ${event!.eventTime ?? '-'}"
                      : '-',
                  style: styleText(),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final scanButton = TombolSementara(
      onPressed: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ScanPesertaPage(eventId: event?.id ?? widget.eventId),
          ),
        );

        if (result != null) {
          await loadEvent();
          await loadPeserta();
        }
      },
      text: 'Scan Attendee',
      height: 54,
      width: double.infinity,
      icon: Icons.qr_code_scanner,
    );

    final presentAttendeeEmptySection = AppSectionCard(
      title: 'Present Attendee',
      icon: Icons.people,
      child: Expanded(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/lottie/yawn_emoji_animation.json',
                height: 80,
                width: double.infinity,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 8),
              Text(
                'There is no present attendee',
                style: styleText(),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    final presentAttendeeListSection = AppSectionCard(
      title: 'Present Attendee',
      icon: Icons.people,
      child: Column(
        children: [
          for (int index = 0; index < scannedPeserta.length; index++) ...[
            if (index > 0) const SizedBox(height: 20),
            Builder(
              builder: (context) {
                final p = scannedPeserta[index];
                return Dismissible(
                  key: Key('${p['doc_id'] ?? p['id']}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(Icons.delete_outline, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'Delete',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  confirmDismiss: (_) async {
                    return await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: AppTheme.third,
                            title: Text('Delete Attendee', style: styleText()),
                            content: Text(
                              'Are you sure want to delete ${p['namaUser']}?',
                              style: styleText(),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text('Cancel', style: styleText()),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text('Delete', style: styleText()),
                              ),
                            ],
                          ),
                        ) ??
                        false;
                  },
                  onDismissed: (_) async {
                    final participantDocId = p['doc_id']?.toString().trim();
                    final participantId = int.tryParse(p['id'].toString());
                    final participantIdText = p['id'].toString();

                    Map<String, dynamic>? removedItem;
                    int removedIndex = -1;

                    if (mounted) {
                      setState(() {
                        removedIndex = scannedPeserta.indexWhere((item) {
                          final itemDocId = item['doc_id']?.toString().trim();
                          if (participantDocId != null &&
                              participantDocId.isNotEmpty &&
                              itemDocId == participantDocId) {
                            return true;
                          }

                          return item['id'].toString() == participantIdText;
                        });

                        if (removedIndex != -1) {
                          removedItem = Map<String, dynamic>.from(
                            scannedPeserta.removeAt(removedIndex),
                          );
                        }

                        totalHadir = scannedPeserta.length;
                      });
                    }

                    try {
                      if (participantDocId != null &&
                          participantDocId.isNotEmpty) {
                        await CheckinController.deleteCheckinByDocId(
                          event?.id ?? widget.eventId,
                          participantDocId,
                        );
                      } else if (participantId != null) {
                        await CheckinController.deleteCheckin(participantId);
                      }
                    } catch (_) {
                      if (!mounted) return;

                      if (removedItem != null) {
                        setState(() {
                          var safeInsertIndex = removedIndex;
                          if (safeInsertIndex < 0 ||
                              safeInsertIndex > scannedPeserta.length) {
                            safeInsertIndex = scannedPeserta.length;
                          }

                          scannedPeserta.insert(safeInsertIndex, removedItem!);
                          totalHadir = scannedPeserta.length;
                        });
                      }

                      try {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to delete attendee'),
                          ),
                        );
                      } catch (_) {}
                    }
                  },
                  child: SizedBox(
                    width: double.infinity,
                    child: AppListCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ProfileAvatar(
                            imagePath: p['profileImage']?.toString(),
                            radius: 22,
                            backgroundColor: AppTheme.third,
                            iconSize: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        p['namaUser'] ?? '',
                                        style: styleText().copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Present',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.phone,
                                      size: 18,
                                      color: AppTheme.secondary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        p['phone'] ?? '',
                                        style: styleText(),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.access_time,
                                      size: 18,
                                      color: AppTheme.secondary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Check in: ${formatCheckinDateTime(p['waktu'])}',
                                        style: styleText().copyWith(
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: Text(
          event!.title,
          style: styleText().copyWith(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, true),
        ),
        actions: [
          IconButton(
            onPressed: showEditEventDialog,
            icon: const Icon(Icons.edit, color: Color(0XFF424874)),
          ),
        ],
      ),
      body: Stack(
        children: [
          EllipseBackground(),
          CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      eventInfoSection,
                      const SizedBox(height: 20),
                      scanButton,
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                sliver: scannedPeserta.isEmpty
                    ? SliverFillRemaining(
                        hasScrollBody: false,
                        child: presentAttendeeEmptySection,
                      )
                    : SliverToBoxAdapter(child: presentAttendeeListSection),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
