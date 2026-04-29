import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connext_app/constants/app_theme.dart';
import 'package:connext_app/constants/decoration_constant.dart';
import 'package:connext_app/constants/style_text.dart';
import 'package:connext_app/models/event_model.dart';
import 'package:connext_app/pages/scanner/scan_peserta_page.dart';
import 'package:connext_app/services/check_in_controller.dart';
import 'package:connext_app/services/event_controller.dart';
import 'package:connext_app/services/event_invite_link_service.dart';
import 'package:connext_app/services/event_participant_controller.dart';
import 'package:connext_app/services/google_maps_service.dart';
import 'package:connext_app/services/user_controller.dart';
import 'package:connext_app/widgets/app_list_card.dart';
import 'package:connext_app/widgets/app_section_card.dart';
import 'package:connext_app/widgets/connext_app_bar.dart';
import 'package:connext_app/widgets/ellipse_background.dart';
import 'package:connext_app/widgets/profile_avatar.dart';
import 'package:connext_app/widgets/tombol_sementara.dart';
import 'package:flutter/material.dart';
import 'package:connext_app/widgets/google_places_autocomplete_field.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:simple_file_saver/simple_file_saver.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

class DetailEventPage extends StatefulWidget {
  final int eventId;
  final EventModel? initialEvent;

  const DetailEventPage({super.key, required this.eventId, this.initialEvent});

  @override
  State<DetailEventPage> createState() => _DetailEventPageState();
}

class _DetailEventPageState extends State<DetailEventPage>
    with WidgetsBindingObserver {
  static const Duration _requestTimeout = Duration(seconds: 8);
  Timer? _realtimeDebounceTimer;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _eventRealtimeSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _participantsRealtimeSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _usersRealtimeSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _creatorRealtimeSub;
  int? _boundCreatorId;
  bool _isAppInForeground = true;

  EventModel? event;
  String createdByName = 'Unknown user';
  String? createdByImage;
  String? loadError;
  bool isLoading = true;
  int totalPeserta = 0;
  int totalHadir = 0;
  List<Map<String, dynamic>> scannedPeserta = [];
  bool _isSharingEvent = false;
  bool _isExportingCsv = false;
  bool _isExportingExcel = false;

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
    WidgetsBinding.instance.addObserver(this);
    event = widget.initialEvent;
    initializeDateFormatting('id');
    _bindRealtimeListeners();
    initializeData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isAppInForeground = state == AppLifecycleState.resumed;
  }

  void _scheduleRealtimeRefresh() {
    if (!mounted || !_isAppInForeground) return;

    _realtimeDebounceTimer?.cancel();
    _realtimeDebounceTimer = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;

      await Future.wait([loadEvent(), loadPeserta()], eagerError: false);
    });
  }

  void _handleRealtimeError(Object error, StackTrace stackTrace) {
    debugPrint('Realtime listener error: $error');
  }

  void _bindRealtimeListeners() {
    final eventDocRef = FirebaseFirestore.instance
        .collection('events')
        .doc(widget.eventId.toString());

    _eventRealtimeSub = eventDocRef.snapshots().listen(
      (_) => _scheduleRealtimeRefresh(),
      onError: _handleRealtimeError,
    );

    _participantsRealtimeSub = eventDocRef
        .collection('participants')
        .snapshots()
        .listen(
          (_) => _scheduleRealtimeRefresh(),
          onError: _handleRealtimeError,
        );

    _usersRealtimeSub = FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .listen(
          (_) => _scheduleRealtimeRefresh(),
          onError: _handleRealtimeError,
        );
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
        }, onError: _handleRealtimeError);
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

    return DateFormat('EEEE, dd MMM yyyy, HH:mm', 'en_US').format(dateTime);
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

  String _buildInviteLink() {
    final eventId = event?.id ?? widget.eventId;
    return EventInviteLinkService.buildJoinEventUri(eventId).toString();
  }

  String _sanitizeFileName(String value) {
    final sanitized = value
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9\-_]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    return sanitized.isEmpty ? 'present_attendees' : sanitized;
  }

  List<List<String>> _buildPresentAttendeeTable() {
    final rows = <List<String>>[
      ['No', 'Name', 'Phone', 'Check In Time'],
    ];

    for (var index = 0; index < scannedPeserta.length; index++) {
      final attendee = scannedPeserta[index];
      rows.add([
        '${index + 1}',
        attendee['namaUser']?.toString() ?? '',
        attendee['phone']?.toString() ?? '',
        formatCheckinDateTime(attendee['waktu']),
      ]);
    }

    return rows;
  }

  String _toCsv(List<List<String>> rows) {
    String escapeCell(String value) {
      final needsQuotes =
          value.contains(',') ||
          value.contains('"') ||
          value.contains('\n') ||
          value.contains('\r');
      final escaped = value.replaceAll('"', '""');
      return needsQuotes ? '"$escaped"' : escaped;
    }

    return rows.map((row) => row.map(escapeCell).join(',')).join('\n');
  }

  Future<void> _shareInviteLink() async {
    if (_isSharingEvent || event == null) return;

    setState(() {
      _isSharingEvent = true;
    });

    try {
      final inviteLink = _buildInviteLink();
      final installLink = EventInviteLinkService.buildPlayStoreUri(
        eventId: event?.id ?? widget.eventId,
      ).toString();
      final directAppLink = EventInviteLinkService.buildDirectAppUri(
        event?.id ?? widget.eventId,
      ).toString();
      try {
        await Share.shareUri(Uri.parse(inviteLink));
      } catch (_) {
        await Share.share(
          'Join event "${event!.title}" in Connext\n\n'
          'Open invite link:\n$inviteLink\n\n'
          'Open directly in app:\n$directAppLink\n\n'
          'If Connext is not installed yet:\n$installLink',
          subject: 'Invite to ${event!.title}',
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event link shared successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      final inviteLink = _buildInviteLink();
      await Clipboard.setData(ClipboardData(text: inviteLink));
      final errorMsg = e.toString().contains('MissingPluginException')
          ? 'Share unavailable, link copied to clipboard'
          : 'Error sharing, link copied to clipboard';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMsg)));
    } finally {
      if (mounted) {
        setState(() {
          _isSharingEvent = false;
        });
      }
    }
  }

  Future<void> _exportPresentAttendeesAsCsv() async {
    if (_isExportingCsv || scannedPeserta.isEmpty || event == null) return;

    setState(() {
      _isExportingCsv = true;
    });

    try {
      final rows = _buildPresentAttendeeTable();
      final csvText = _toCsv(rows);
      final fileName =
          'present_attendees_${_sanitizeFileName(event!.title)}.csv';

      final saved = await SimpleFileSaver.saveFile(
        dataBytes: Uint8List.fromList(utf8.encode(csvText)),
        fileName: fileName,
        mimeType: 'text/csv',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            saved ? 'CSV saved to Downloads: $fileName' : 'CSV save cancelled',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error exporting CSV: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isExportingCsv = false;
        });
      }
    }
  }

  Future<void> _exportPresentAttendeesAsExcel() async {
    if (_isExportingExcel || scannedPeserta.isEmpty || event == null) return;

    setState(() {
      _isExportingExcel = true;
    });

    try {
      final workbook = xlsio.Workbook();
      final sheet = workbook.worksheets[0];
      sheet.name = 'Present Attendee';

      final rows = _buildPresentAttendeeTable();
      for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
        final row = rows[rowIndex];
        for (var columnIndex = 0; columnIndex < row.length; columnIndex++) {
          sheet
              .getRangeByIndex(rowIndex + 1, columnIndex + 1)
              .setText(row[columnIndex]);
        }
      }

      sheet.autoFitColumn(1);
      sheet.autoFitColumn(2);
      sheet.autoFitColumn(3);
      sheet.autoFitColumn(4);

      final fileBytes = Uint8List.fromList(workbook.saveAsStream());
      workbook.dispose();

      final fileName =
          'present_attendees_${_sanitizeFileName(event!.title)}.xlsx';

      final saved = await SimpleFileSaver.saveFile(
        dataBytes: fileBytes,
        fileName: fileName,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            saved
                ? 'Excel saved to Downloads: $fileName'
                : 'Excel save cancelled',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error exporting Excel: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isExportingExcel = false;
        });
      }
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
              backgroundColor: const Color(0xFF171A33),
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
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF22254A),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppTheme.third.withOpacity(0.16),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.third.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.edit_calendar,
                                  size: 18,
                                  color: AppTheme.third,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Update event details below. Date and time cannot be in the past.',
                                  style: styleText().copyWith(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Event Form',
                            style: styleText().copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.third,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1D3A),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppTheme.third.withOpacity(0.16),
                            ),
                          ),
                          child: TextFormField(
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
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1D3A),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppTheme.third.withOpacity(0.16),
                            ),
                          ),
                          child: GooglePlacesAutocompleteField(
                            controller: locationController,
                            labelText: 'Location',
                            hintText: 'Search location',
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
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF22254A),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppTheme.third.withOpacity(0.12),
                            ),
                          ),
                          child: Row(
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
                                  color: AppTheme.fourth,
                                  fontSize: 11.5,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1D3A),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppTheme.third.withOpacity(0.16),
                            ),
                          ),
                          child: TextFormField(
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
                    backgroundColor: AppTheme.third,
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
                  child: Text(
                    'Save',
                    style: styleText().copyWith(color: AppTheme.primary),
                  ),
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
        return SafeArea(
          top: false,
          child: participants.isEmpty
              ? Padding(
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
                        style: styleText().copyWith(
                          fontWeight: FontWeight.bold,
                        ),
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
                )
              : Padding(
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
                                  iconColor: AppTheme.primary,
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
                                          color: hadir
                                              ? const Color(0xFF78D98B)
                                              : AppTheme.fourth,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          hadir ? 'Present' : 'Absent',
                                          style: const TextStyle(
                                            color: AppTheme.primary,
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
                                  color: Color(0xFF00C2FF),
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
                ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: ConnextAppBar(
        variant: ConnextAppBarVariant.minimal,
        title: Text('Event Detail', style: styleText()),
        onLeadingPressed: () => Navigator.pop(context),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.event_busy, size: 56, color: AppTheme.fourth),
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
        backgroundColor: AppTheme.primary,
      );
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
              Icon(Icons.numbers, color: AppTheme.third),
              const SizedBox(width: 10),
              Text('${event!.id}', style: styleText()),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.description, color: const Color(0xFF73E8D7)),
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
          Row(
            children: [
              Icon(Icons.verified, color: const Color(0xFF73E8D7)),
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
                iconColor: AppTheme.primary,
                iconSize: 16,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text('By $createdByName', style: styleText())),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.history, color: AppTheme.third),
              const SizedBox(width: 10),
              Text(formatCreatedAt(event!.createdAt), style: styleText()),
            ],
          ),
        ],
      ),
    );

    final heroBanner = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.third.withOpacity(0.95),
            AppTheme.fourth.withOpacity(0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
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
                child: const Icon(Icons.event, color: AppTheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
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
                    const SizedBox(height: 4),
                    Text(
                      'Event detail & attendee check-in',
                      style: styleText().copyWith(
                        color: AppTheme.primary.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildHeroActionTag(
                icon: Icons.location_pin,
                label: event!.location,
                onTap: _openEventLocation,
              ),
              _buildHeroActionTag(
                icon: Icons.people,
                label: '$totalPeserta joined',
                onTap: showParticipants,
                accentColor: const Color(0xFF73E8D7),
              ),
              _buildHeroTag(
                Icons.event_available,
                event!.eventDate != null
                    ? "${DateFormat('EEE, d MMM yyyy').format(DateTime.parse(event!.eventDate!))} • ${event!.eventTime ?? '-'}"
                    : '-',
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
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isExportingCsv
                      ? null
                      : _exportPresentAttendeesAsCsv,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF73E8D7),
                    foregroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isExportingCsv
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.file_download_outlined),
                  label: const Text('CSV'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isExportingExcel
                      ? null
                      : _exportPresentAttendeesAsExcel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.third,
                    foregroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isExportingExcel
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.grid_on_outlined),
                  label: const Text('Excel'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                      color: AppTheme.fourth,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(Icons.delete_outline, color: AppTheme.primary),
                        SizedBox(width: 6),
                        Text(
                          'Delete',
                          style: TextStyle(
                            color: AppTheme.primary,
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
                            backgroundColor: const Color(0xFF171A33),
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
                                child: Text(
                                  'Delete',
                                  style: styleText().copyWith(
                                    color: AppTheme.fourth,
                                  ),
                                ),
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
                            iconColor: AppTheme.primary,
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
                                        color: const Color(0xFF78D98B),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Present',
                                        style: TextStyle(
                                          color: AppTheme.primary,
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
                                      color: Color(0xFF00C2FF),
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
                                      color: Color(0xFF73E8D7),
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
      appBar: ConnextAppBar(
        variant: ConnextAppBarVariant.hero,
        title: Text(
          event!.title,
          style: styleText().copyWith(
            fontWeight: FontWeight.w800,
            color: AppTheme.secondary,
          ),
        ),
        onLeadingPressed: () => Navigator.pop(context, true),
        actions: [
          IconButton(
            onPressed: _isSharingEvent ? null : _shareInviteLink,
            icon: _isSharingEvent
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.share_outlined, color: AppTheme.third),
            tooltip: 'Share event link',
          ),
          IconButton(
            onPressed: showEditEventDialog,
            icon: const Icon(Icons.edit, color: AppTheme.third),
          ),
        ],
      ),
      body: Stack(
        children: [
          EllipseBackground(),
          SafeArea(
            top: false,
            bottom: true,
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        heroBanner,
                        const SizedBox(height: 20),
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
          ),
        ],
      ),
    );
  }

  Widget _buildHeroTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.18),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.primary),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: styleText().copyWith(
                color: AppTheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroActionTag({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color accentColor = AppTheme.third,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.18),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accentColor.withOpacity(0.45)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: accentColor),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: styleText().copyWith(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
