import 'dart:async';

import 'package:connext_app/constants/app_theme.dart';
import 'package:connext_app/constants/decoration_constant.dart';
import 'package:connext_app/constants/style_text.dart';
import 'package:connext_app/models/event_model.dart';
import 'package:connext_app/pages/scanner/scan_peserta_page.dart';
import 'package:connext_app/services/check_in_controller.dart';
import 'package:connext_app/services/event_controller.dart';
import 'package:connext_app/services/event_participant_controller.dart';
import 'package:connext_app/services/user_controller.dart';
import 'package:connext_app/widgets/app_list_card.dart';
import 'package:connext_app/widgets/app_section_card.dart';
import 'package:connext_app/widgets/ellipse_background.dart';
import 'package:connext_app/widgets/profile_avatar.dart';
import 'package:connext_app/widgets/tombol_sementara.dart';
import 'package:flutter/material.dart';
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
    initializeData();
  }

  @override
  void dispose() {
    dateControllerEdit.dispose();
    timeControllerEdit.dispose();
    titleController.dispose();
    locationController.dispose();
    descriptionController.dispose();
    super.dispose();
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

  Future<void> initializeData() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      loadError = null;
    });

    await loadEvent();

    if (event != null) {
      unawaited(loadPeserta());
    }

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
    if (event?.id == null) return;

    try {
      final data = await CheckinController.getCheckinByEvent(
        event!.id!,
      ).timeout(_requestTimeout, onTimeout: () => []);

      if (!mounted) return;

      setState(() {
        scannedPeserta = data;
        totalHadir = data.length;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        scannedPeserta = [];
        totalHadir = 0;
      });
    }
  }

  void showEditEventDialog() {
    if (event == null) return;

    titleController.text = event!.title;
    locationController.text = event!.location;
    descriptionController.text = event!.description;

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
                        TextFormField(
                          controller: locationController,
                          style: TextStyle(
                            color: AppTheme.secondary,
                            fontSize: 14,
                          ),
                          validator: (value) =>
                              requiredValidator(value, 'Location'),
                          decoration: decorationConstant(
                            hintText: 'Location',
                            labelText: 'Location',
                          ),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSectionCard(
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
                      Row(
                        children: [
                          Icon(Icons.location_pin, color: AppTheme.secondary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(event!.location, style: styleText()),
                          ),
                        ],
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
                            Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: AppTheme.secondary,
                            ),
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
                          Expanded(
                            child: Text(
                              'By $createdByName',
                              style: styleText(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.history, color: AppTheme.secondary),
                          const SizedBox(width: 10),
                          Text(
                            formatCreatedAt(event!.createdAt),
                            style: styleText(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.event_available,
                            color: AppTheme.secondary,
                          ),
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
                ),
                const SizedBox(height: 20),
                TombolSementara(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ScanPesertaPage(eventId: event!.id!),
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
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: AppSectionCard(
                    title: 'Present Attendee',
                    icon: Icons.people,
                    child: scannedPeserta.isEmpty
                        ? Center(
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Lottie.asset(
                                    'assets/lottie/yawn_emoji_animation.json',
                                    height: 120,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'There is no present attendee',
                                    style: styleText(),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 20),
                            itemCount: scannedPeserta.length,
                            itemBuilder: (context, index) {
                              final p = scannedPeserta[index];
                              return Dismissible(
                                key: Key('${p['id']}'),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Icon(
                                        Icons.delete_outline,
                                        color: Colors.white,
                                      ),
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
                                          title: Text(
                                            'Delete Attendee',
                                            style: styleText(),
                                          ),
                                          content: Text(
                                            'Are you sure want to delete ${p['namaUser']}?',
                                            style: styleText(),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: Text(
                                                'Cancel',
                                                style: styleText(),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: Text(
                                                'Delete',
                                                style: styleText(),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ) ??
                                      false;
                                },
                                onDismissed: (_) async {
                                  await CheckinController.deleteCheckin(
                                    int.parse(p['id'].toString()),
                                  );
                                  if (!mounted) return;
                                  setState(() {
                                    scannedPeserta.removeWhere(
                                      (item) =>
                                          item['id'].toString() ==
                                          p['id'].toString(),
                                    );
                                    totalHadir = scannedPeserta.length;
                                  });
                                },
                                child: SizedBox(
                                  width: double.infinity,
                                  child: AppListCard(
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ProfileAvatar(
                                          imagePath: p['profileImage']
                                              ?.toString(),
                                          radius: 22,
                                          backgroundColor: AppTheme.third,
                                          iconSize: 22,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      p['namaUser'] ?? '',
                                                      style: styleText()
                                                          .copyWith(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 3,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      'Present',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.bold,
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
                                                  Text(
                                                    p['phone'] ?? '',
                                                    style: styleText(),
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
