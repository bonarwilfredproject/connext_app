import 'package:connext_app/constants/app_theme.dart';
import 'package:connext_app/constants/decoration_constant.dart';
import 'package:connext_app/services/check_in_controller.dart';
import 'package:connext_app/services/event_participant_controller.dart';
import 'package:connext_app/services/user_controller.dart';
import 'package:connext_app/widgets/app_list_card.dart';
import 'package:connext_app/widgets/app_section_card.dart';
import 'package:connext_app/widgets/ellipse_background.dart';
import 'package:connext_app/widgets/tombol_sementara.dart';
import 'package:connext_app/pages/scanner/scan_peserta_page.dart';
import 'package:flutter/material.dart';
import 'package:connext_app/services/event_controller.dart';
import 'package:connext_app/models/event_model.dart';
import 'package:connext_app/constants/style_text.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lottie/lottie.dart';
import 'dart:io';

class DetailEventPage extends StatefulWidget {
  final int eventId;

  const DetailEventPage({super.key, required this.eventId});

  @override
  State<DetailEventPage> createState() => _DetailEventPageState();
}

class _DetailEventPageState extends State<DetailEventPage> {
  int totalHadir = 0;
  String createdByName = "";
  String? createdByImage;
  int totalPeserta = 0;
  EventModel? event;
  List<Map<String, dynamic>> scannedPeserta = []; // <- state untuk list peserta
  DateTime? selectedDateEdit;
  TimeOfDay? selectedTimeEdit;
  String? dateTimeError;
  String? timeError;
  final GlobalKey<FormState> _editFormKey = GlobalKey<FormState>();
  final TextEditingController dateControllerEdit = TextEditingController();
  final TextEditingController timeControllerEdit = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id');
    initializeData();
  }

  Future<void> initializeData() async {
    await loadEvent();
    await loadPeserta();
  }

  @override
  void dispose() {
    titleController.dispose();
    locationController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  String? validateDateTimeEdit() {
    if (selectedDateEdit == null || selectedTimeEdit == null) {
      return "Date and time must be filled";
    }

    final nowRaw = DateTime.now();

    /// 🔥 buang detik & millisecond
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
      return "Time has passed, please pick another time";
    }

    return null;
  }

  String? requiredValidator(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return "$fieldName can't be empty";
    }
    return null;
  }

  void showEditEventDialog() {
    titleController.text = event!.title;
    locationController.text = event!.location;
    descriptionController.text = event!.description;

    selectedDateEdit = DateTime.parse(event!.eventDate!);

    final timeParts = event!.eventTime!.split(":");
    selectedTimeEdit = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

    dateControllerEdit.text = DateFormat(
      'EE, d MMMM yyyy',
    ).format(selectedDateEdit!);

    timeControllerEdit.text =
        "${selectedTimeEdit!.hour.toString().padLeft(2, '0')}:${selectedTimeEdit!.minute.toString().padLeft(2, '0')}";

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
                "Edit Event",
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
                        /// NAMA EVENT
                        TextFormField(
                          controller: titleController,
                          style: TextStyle(
                            color: AppTheme.secondary,
                            fontSize: 14,
                          ),
                          validator: (value) =>
                              requiredValidator(value, "Event name"),
                          decoration: decorationConstant(
                            hintText: "Event Name",
                            labelText: "Event Name",
                          ),
                        ),

                        const SizedBox(height: 16),

                        /// LOKASI
                        TextFormField(
                          controller: locationController,
                          style: TextStyle(
                            color: AppTheme.secondary,
                            fontSize: 14,
                          ),
                          validator: (value) =>
                              requiredValidator(value, "Location"),
                          decoration: decorationConstant(
                            hintText: "Location",
                            labelText: "Location",
                          ),
                        ),

                        const SizedBox(height: 16),

                        Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start, // 🔥 penting
                          children: [
                            /// DATE
                            Expanded(
                              child: TextFormField(
                                controller: dateControllerEdit,
                                readOnly: true,
                                style: TextStyle(
                                  color: AppTheme.secondary,
                                  fontSize: 14,
                                ),
                                decoration: decorationConstant(
                                  hintText: "Choose date",
                                  labelText: "Date",
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

                            /// TIME
                            Expanded(
                              child: TextFormField(
                                controller: timeControllerEdit,
                                readOnly: true,
                                style: TextStyle(
                                  color: AppTheme.secondary,
                                  fontSize: 14,
                                ),
                                decoration: decorationConstant(
                                  hintText: "Choose time",
                                  labelText: "Time",
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
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 11.5,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),

                        /// DESKRIPSI
                        TextFormField(
                          controller: descriptionController,
                          maxLines: 3,
                          style: TextStyle(
                            color: AppTheme.secondary,
                            fontSize: 14,
                          ),
                          validator: (value) =>
                              requiredValidator(value, "Description"),
                          decoration: decorationConstant(
                            hintText: "Description",
                            labelText: "Description",
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("Cancel", style: styleText()),
                ),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.fourth,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () async {
                    /// 🔥 VALIDASI SAAT SAVE
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
                          "${selectedTimeEdit!.hour.toString().padLeft(2, '0')}:${selectedTimeEdit!.minute.toString().padLeft(2, '0')}",
                    );

                    await EventController.updateEvent(updatedEvent);

                    Navigator.pop(context);
                    await loadEvent();
                  },
                  child: Text("Save", style: styleText()),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> loadPeserta() async {
    final data = await CheckinController.getCheckinByEvent(event!.id!);

    setState(() {
      scannedPeserta = data;
      totalHadir = data.length; // jumlah peserta yang check-in
    });
  }

  String formatTanggal(String waktu) {
    DateTime date = DateTime.tryParse(waktu) ?? DateTime.now();

    return DateFormat("EE, dd MMM yyyy, HH.mm").format(date);
  }

  String formatCreatedAt(String waktu) {
    DateTime date = DateTime.tryParse(waktu) ?? DateTime.now();
    return DateFormat("dd MMM yyyy, HH:mm").format(date);
  }

  Future<void> loadEvent() async {
    event = await EventController.getEventById(widget.eventId);

    totalPeserta = await EventParticipantController.getTotalParticipants(
      widget.eventId,
    );

    final user = await UserController.getUserById(event!.createdBy);
    createdByName = user!.nama;
    createdByImage = user.profileImage;
    setState(() {});
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
        /// =====================
        /// JIKA BELUM ADA PESERTA
        /// =====================
        if (participants.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset(
                  "assets/lottie/yawn_emoji_animation.json",
                  height: 130,
                  width: double.infinity,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 8),

                /// TEXT UTAMA
                Text(
                  "There is no attendee",
                  style: styleText().copyWith(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 6),

                /// SUBTEXT
                Text(
                  "Share this event so people can join",
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

        /// =====================
        /// JIKA ADA PESERTA
        /// =====================
        return Padding(
          padding: const EdgeInsets.all(20),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: participants.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final p = participants[i];
              bool hadir = p["isCheckedIn"];

              return AppListCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// NAMA + BADGE
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage:
                              p["profileImage"] != null &&
                                  p["profileImage"].toString().isNotEmpty
                              ? FileImage(File(p["profileImage"]))
                              : null,
                          child:
                              p["profileImage"] == null ||
                                  p["profileImage"].toString().isEmpty
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  p["name"],
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
                                  hadir ? "Present" : "Absent",
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

                    /// PHONE
                    Row(
                      children: [
                        const Icon(
                          Icons.phone,
                          size: 18,
                          color: AppTheme.secondary,
                        ),
                        const SizedBox(width: 8),
                        Text(p["phone"], style: styleText()),
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

  @override
  Widget build(BuildContext context) {
    if (event == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
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
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, true); // kirim signal refresh
          },
        ),
        actions: [
          IconButton(
            onPressed: () {
              showEditEventDialog();
            },
            icon: Icon(Icons.edit, color: Color(0XFF424874)),
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
                      /// ID EVENT
                      Row(
                        children: [
                          Icon(Icons.numbers, color: AppTheme.secondary),
                          SizedBox(width: 10),
                          Text("${event!.id}", style: styleText()),
                        ],
                      ),

                      SizedBox(height: 16),

                      /// LOKASI
                      Row(
                        children: [
                          Icon(Icons.location_pin, color: AppTheme.secondary),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(event!.location, style: styleText()),
                          ),
                        ],
                      ),

                      SizedBox(height: 16),

                      /// DESKRIPSI
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.description, color: AppTheme.secondary),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              event!.description.isEmpty
                                  ? "There is no description"
                                  : event!.description,
                              style: styleText(),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16),

                      /// PESERTA TERDAFTAR
                      InkWell(
                        onTap: () {
                          showParticipants();
                        },
                        child: Row(
                          children: [
                            Icon(Icons.people, color: AppTheme.secondary),
                            SizedBox(width: 10),
                            Text("$totalPeserta joined", style: styleText()),
                            SizedBox(width: 6),
                            Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: AppTheme.secondary,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 16),

                      /// PESERTA HADIR
                      Row(
                        children: [
                          Icon(Icons.verified, color: AppTheme.secondary),
                          SizedBox(width: 10),
                          Text("$totalHadir present", style: styleText()),
                        ],
                      ),
                      SizedBox(height: 16),

                      /// DIBUAT OLEH
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppTheme.third,
                            radius: 12,
                            backgroundImage:
                                createdByImage != null &&
                                    createdByImage!.isNotEmpty &&
                                    File(createdByImage!).existsSync()
                                ? FileImage(File(createdByImage!))
                                : null,
                            child:
                                createdByImage == null ||
                                    createdByImage!.isEmpty
                                ? const Icon(Icons.person, size: 16)
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(createdByName, style: styleText()),
                          ),
                        ],
                      ),

                      SizedBox(height: 16),

                      /// TANGGAL DIBUAT
                      Row(
                        children: [
                          Icon(
                            Icons.history,
                            color: AppTheme.secondary,
                          ), // 🔥 beda icon
                          SizedBox(width: 10),
                          Text(
                            formatCreatedAt(event!.createdAt),
                            style: styleText(),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.event_available,
                            color: AppTheme.secondary,
                          ), // 🔥 beda icon
                          SizedBox(width: 10),
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
                    ],
                  ),
                ),

                SizedBox(height: 20),
                // Tombol Scan Peserta
                TombolSementara(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ScanPesertaPage(eventId: event!.id!),
                      ),
                    );

                    if (result != null) {
                      await loadEvent(); // update jumlah peserta
                      await loadPeserta();
                    }
                  },
                  text: "Scan Attendee",
                  height: 54,
                  width: double.infinity,
                  icon: Icons.qr_code_scanner,
                ),

                SizedBox(height: 20),

                // Tampilkan list peserta yang sudah discan
                Expanded(
                  flex: 5,
                  child: AppSectionCard(
                    title: "Present Attendee",
                    icon: Icons.people,
                    child: Expanded(
                      child: scannedPeserta.isEmpty
                          ? Center(
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Lottie.asset(
                                      "assets/lottie/yawn_emoji_animation.json",
                                      height: 120,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      "There is no present attendee",
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
                                  key: Key("${p['id']}"),
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
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
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
                                          "Delete Attendee",
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
                                                text: p['namaUser'],
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
                                    await CheckinController.deleteCheckin(
                                      int.parse(p['id']!),
                                    );

                                    setState(() {
                                      scannedPeserta.removeAt(index);
                                      totalHadir--;
                                    });

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Attendee deleted succesfully",
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },

                                  child: SizedBox(
                                    width: double.infinity,
                                    child: AppListCard(
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          /// FOTO USER
                                          CircleAvatar(
                                            radius: 22,
                                            backgroundImage:
                                                p['profileImage'] != null &&
                                                    p['profileImage']
                                                        .toString()
                                                        .isNotEmpty &&
                                                    File(
                                                      p['profileImage'],
                                                    ).existsSync()
                                                ? FileImage(
                                                    File(p['profileImage']),
                                                  )
                                                : null,
                                            child:
                                                p['profileImage'] == null ||
                                                    p['profileImage']
                                                        .toString()
                                                        .isEmpty
                                                ? const Icon(Icons.person)
                                                : null,
                                          ),

                                          const SizedBox(width: 12),

                                          /// INFO PESERTA
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                /// NAMA + BADGE
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        p['namaUser'] ?? "",
                                                        style: styleText()
                                                            .copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                      ),
                                                    ),

                                                    /// BADGE CHECK-IN
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
                                                      child: const Text(
                                                        "Present",
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),

                                                const SizedBox(height: 4),

                                                /// PHONE
                                                Text(
                                                  p['phone'] ?? "",
                                                  style: styleText(),
                                                ),

                                                const SizedBox(height: 4),

                                                /// WAKTU CHECKIN
                                                Text(
                                                  formatTanggal(
                                                    p['waktu'] ?? "",
                                                  ),
                                                  style: styleText().copyWith(
                                                    fontSize: 12,
                                                    color: AppTheme.secondary,
                                                  ),
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
