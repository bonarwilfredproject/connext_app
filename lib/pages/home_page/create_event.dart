import 'package:connext_app/constants/app_theme.dart';
import 'package:connext_app/services/event_controller.dart';
import 'package:connext_app/models/event_model.dart';
import 'package:connext_app/models/user_model.dart';
import 'package:connext_app/constants/decoration_constant.dart';
import 'package:connext_app/services/google_maps_service.dart';
import 'package:connext_app/services/firebase_services.dart';
import 'package:connext_app/services/preferences_services.dart';
import 'package:connext_app/widgets/app_section_card.dart';
import 'package:connext_app/widgets/ellipse_background.dart';
import 'package:connext_app/widgets/google_places_autocomplete_field.dart';
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
  String? selectedLocationPlaceId;
  String? selectedLocationName;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String? timeError;
  int? userId;
  bool isCreatingEvent = false;
  void validateTime() {
    if (selectedDate == null || selectedTime == null) return;

    final nowRaw = DateTime.now();

    final now = DateTime(
      nowRaw.year,
      nowRaw.month,
      nowRaw.day,
      nowRaw.hour,
      nowRaw.minute,
    );

    final pickedDateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    if (pickedDateTime.isBefore(now)) {
      timeError = "Can't pick the passed time";
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
    dateController.text = DateFormat('EE, d MMMM yyyy').format(selectedDate!);
    timeController.text =
        "${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}";
  }

  Future<void> loadUser() async {
    final pref = PreferenceHandler();
    await pref.init();
    userId = pref.getUserId();
  }

  Future<void> createEvent() async {
    if (isCreatingEvent) return;

    validateTime();
    if (!_formKey.currentState!.validate()) return;
    if (timeError != null) return;

    setState(() {
      isCreatingEvent = true;
    });

    try {
      UserModel? profile;

      int? creatorId = userId;
      if (creatorId == null || creatorId <= 0) {
        final pref = PreferenceHandler();
        await pref.init();
        final prefId = pref.getUserId();
        if (prefId > 0) {
          creatorId = prefId;
        }
      }

      if (creatorId == null || creatorId <= 0) {
        profile = await FirebaseServices.getCurrentUserProfile();
        final profileId = profile?.id;
        if (profileId != null && profileId > 0) {
          creatorId = profileId;

          final pref = PreferenceHandler();
          await pref.init();
          await pref.saveUser(profileId, profile!.nama, profile.role);
        }
      }

      if (creatorId == null || creatorId <= 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to determine event creator. Please relogin.'),
          ),
        );
        return;
      }

      profile ??= await FirebaseServices.getCurrentUserProfile();

      final pref = PreferenceHandler();
      await pref.init();
      final fallbackName = pref.getNamaUser();
      final creatorName = (profile?.nama.trim().isNotEmpty ?? false)
          ? profile!.nama.trim()
          : fallbackName;

      final currentUid = FirebaseServices.currentUid;

      final event = EventModel(
        title: namaEventController.text.trim(),
        location: lokasiController.text.trim(),
        locationName: selectedLocationName,
        locationUrl: buildGoogleMapsSearchUrl(
          lokasiController.text,
          placeId: selectedLocationPlaceId,
        ),
        locationPlaceId: selectedLocationPlaceId,
        description: descriptionController.text.trim(),
        createdBy: creatorId,
        createdByName: creatorName,
        createdByUid: currentUid,
        createdAt: DateTime.now().toIso8601String(),
        eventDate: selectedDate!.toIso8601String(),
        eventTime:
            '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}',
      );

      await EventController.insertEvent(event);

      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) {
        setState(() {
          isCreatingEvent = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF4EEFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4EEFF),
        title: Text("Create Event", style: styleText()),
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
                  title: "Event Form",
                  icon: Icons.event_note,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// NAMA EVENT
                      Text("Event Name", style: styleText()),
                      TextFormField(
                        style: TextStyle(
                          color: AppTheme.secondary,
                          fontSize: 12,
                        ),
                        controller: namaEventController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Event name can't be empty";
                          }
                          return null;
                        },
                        decoration: decorationConstant(
                          hintText: "Please input event name",
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// LOKASI
                      GooglePlacesAutocompleteField(
                        controller: lokasiController,
                        labelText: 'Location',
                        hintText: 'Search event location on Google Maps',
                        showKeySourceInfo: false,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Location can't be empty";
                          }
                          return null;
                        },
                        onSelected: (details) {
                          setState(() {
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
                                Text("Date", style: styleText()),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: dateController,
                                  readOnly: true,
                                  style: TextStyle(
                                    color: AppTheme.secondary,
                                    fontSize: 12,
                                  ),
                                  decoration: decorationConstant(
                                    hintText: "Choose date",
                                  ).copyWith(helperText: ' '),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Date must be filled";
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
                                          'EE, d MMMM yyyy',
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
                                Text("Time", style: styleText()),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: timeController,
                                  readOnly: true,
                                  style: TextStyle(
                                    color: AppTheme.secondary,
                                    fontSize: 12,
                                  ),
                                  decoration: decorationConstant(
                                    hintText: "Choose time",
                                  ).copyWith(helperText: ' '),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Time must be filled";
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
                      Text("Description", style: styleText()),
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
                            return "Description can't be empty";
                          }
                          return null;
                        },
                        decoration:
                            decorationConstant(
                              hintText: "Please input event description",
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
                          onPressed: isCreatingEvent ? null : createEvent,
                          icon: isCreatingEvent
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFFF4EEFF),
                                  ),
                                )
                              : const Icon(Icons.add, color: Color(0xFFF4EEFF)),
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
