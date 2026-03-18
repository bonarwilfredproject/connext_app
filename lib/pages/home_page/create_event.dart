import 'package:connext_app/constants/app_theme.dart';
import 'package:connext_app/services/event_controller.dart';
import 'package:connext_app/models/event_model.dart';
import 'package:connext_app/constants/decoration_constant.dart';
import 'package:connext_app/services/preferences_services.dart';
import 'package:connext_app/widgets/app_section_card.dart';
import 'package:connext_app/widgets/ellipse_background.dart';
import 'package:connext_app/constants/style_text.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CreateEvent extends StatefulWidget {
  const CreateEvent({super.key});

  @override
  State<CreateEvent> createState() => _CreateEventState();
}

class _CreateEventState extends State<CreateEvent> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController timeController = TextEditingController();
  TextEditingController namaEventController = TextEditingController();
  TextEditingController lokasiController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String? timeError;
  int? userId;
  void validateTime() {
    if (selectedDate == null || selectedTime == null) return;

    final now = DateTime.now();

    final pickedDateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    if (selectedDate!.year == now.year &&
        selectedDate!.month == now.month &&
        selectedDate!.day == now.day &&
        pickedDateTime.isBefore(now)) {
      timeError = "Tidak bisa pilih waktu yang sudah lewat";
    } else {
      timeError = null;
    }
  }

  @override
  void initState() {
    super.initState();
    loadUser();

    selectedDate = DateTime.now();
    selectedTime = TimeOfDay.now();
    dateController.text = DateFormat(
      'EEEE, d MMMM yyyy',
      'id_ID',
    ).format(selectedDate!);
    timeController.text =
        "${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}";
  }

  Future<void> loadUser() async {
    final pref = PreferenceHandler();
    await pref.init();
    userId = pref.getUserId();
  }

  Future<void> createEvent() async {
    if (!_formKey.currentState!.validate()) return;
    if (timeError != null) return;
    final event = EventModel(
      title: namaEventController.text.trim(),
      location: lokasiController.text.trim(),
      description: descriptionController.text.trim(),
      createdBy: userId!,
      createdAt: DateTime.now().toIso8601String(),
      eventDate: selectedDate!.toIso8601String(),
      eventTime: selectedTime!.format(context),
    );

    await EventController.insertEvent(event);

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF4EEFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4EEFF),
        title: Text("Buat Event", style: styleText()),
      ),
      body: Stack(
        children: [
          EllipseBackground(),

          SizedBox(
            height: MediaQuery.of(context).size.height,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: AppSectionCard(
                  title: "Form Event",
                  icon: Icons.event_note,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// NAMA EVENT
                      Text("Nama Event", style: styleText()),
                      TextFormField(
                        style: TextStyle(
                          color: AppTheme.secondary,
                          fontSize: 12,
                        ),
                        controller: namaEventController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Nama event tidak boleh kosong";
                          }
                          return null;
                        },
                        decoration: decorationConstant(
                          hintText: "Masukkan nama event",
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// LOKASI
                      Text("Lokasi", style: styleText()),
                      TextFormField(
                        style: TextStyle(
                          color: AppTheme.secondary,
                          fontSize: 12,
                        ),
                        controller: lokasiController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Lokasi tidak boleh kosong";
                          }
                          return null;
                        },
                        decoration: decorationConstant(
                          hintText: "Masukkan lokasi event",
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// DATE & TIME
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// DATE
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Tanggal", style: styleText()),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: dateController,
                                  readOnly: true,
                                  style: TextStyle(
                                    color: AppTheme.secondary,
                                    fontSize: 12,
                                  ),
                                  decoration: decorationConstant(
                                    hintText: "Pilih tanggal",
                                  ).copyWith(helperText: ' '),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Tanggal wajib diisi";
                                    }
                                    return null;
                                  },
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate:
                                          selectedDate ?? DateTime.now(),
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime(2100),
                                    );

                                    if (picked != null) {
                                      setState(() {
                                        selectedDate = picked;
                                        dateController.text = DateFormat(
                                          'EEEE, d MMMM yyyy',
                                          'id_ID',
                                        ).format(picked);
                                      });
                                    }

                                    validateTime();
                                    _formKey.currentState!.validate();
                                  },
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 12),

                          /// TIME
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Waktu", style: styleText()),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: timeController,
                                  readOnly: true,
                                  style: TextStyle(
                                    color: AppTheme.secondary,
                                    fontSize: 12,
                                  ),
                                  decoration: decorationConstant(
                                    hintText: "Pilih waktu",
                                  ).copyWith(helperText: ' '),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Waktu wajib diisi";
                                    }
                                    if (timeError != null) {
                                      return timeError;
                                    }
                                    return null;
                                  },
                                  onTap: () async {
                                    final picked = await showTimePicker(
                                      context: context,
                                      initialTime:
                                          selectedTime ?? TimeOfDay.now(),
                                    );

                                    if (picked != null) {
                                      setState(() {
                                        selectedTime = picked;
                                        timeController.text = picked.format(
                                          context,
                                        );
                                        timeError = null;
                                      });

                                      validateTime();
                                      _formKey.currentState!.validate();
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      /// DESKRIPSI
                      Text("Deskripsi", style: styleText()),
                      TextFormField(
                        controller: descriptionController,
                        minLines: 4,
                        maxLines: 6,
                        style: TextStyle(
                          color: AppTheme.secondary,
                          fontSize: 12,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Deskripsi tidak boleh kosong";
                          }
                          return null;
                        },
                        decoration:
                            decorationConstant(
                              hintText: "Masukkan deskripsi event",
                            ).copyWith(
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 8,
                              ),
                            ),
                      ),

                      const SizedBox(height: 30),

                      /// BUTTON
                      Center(
                        child: IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0XFF424874),
                          ),
                          onPressed: createEvent,
                          icon: const Icon(Icons.add, color: Color(0xFFF4EEFF)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
