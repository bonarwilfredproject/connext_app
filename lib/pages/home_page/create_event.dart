import 'package:connext_app/constants/app_theme.dart';
import 'package:connext_app/services/event_controller.dart';
import 'package:connext_app/models/event_model.dart';
import 'package:connext_app/models/user_model.dart';
import 'package:connext_app/constants/decoration_constant.dart';
import 'package:connext_app/services/google_maps_service.dart';
import 'package:connext_app/services/firebase_services.dart';
import 'package:connext_app/services/preferences_services.dart';
import 'package:connext_app/widgets/app_section_card.dart';
import 'package:connext_app/widgets/connext_app_bar.dart';
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
  static const String _eventTermsVersion = 'event_tnc_v1_2026-04';

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
  bool hasAcceptedTerms = false;

  Future<void> _showTermsAndConditions() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.78,
          decoration: const BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.third.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Terms and Conditions - Event Organizer',
                    style: styleText().copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        '1. Committee members must ensure that all event content and activities comply with applicable laws and regulations.\n\n'
                        '2. Connext, as the application provider, is not liable for any legal violations committed by committee members through events they create.\n\n'
                        '3. Attendee phone numbers are confidential personal data and may only be used for event operational purposes.\n\n'
                        '4. Committee members are strictly prohibited from sharing attendee phone numbers with third parties for any purpose outside the event.\n\n'
                        '5. If any phone number disclosure or misuse of attendee data occurs, full responsibility rests with the respective committee member.\n\n'
                        '6. Connext reserves the right to impose sanctions, including restricting or banning committee access, if a violation of these terms is proven.',
                        style: styleText().copyWith(height: 1.5, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.third,
                        foregroundColor: AppTheme.primary,
                      ),
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.check),
                      label: const Text('I Understand'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

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
    if (!hasAcceptedTerms) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must agree to Terms and Conditions first.'),
        ),
      );
      return;
    }

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
        termsAccepted: true,
        termsAcceptedAt: DateTime.now().toIso8601String(),
        termsVersion: _eventTermsVersion,
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
      backgroundColor: AppTheme.primary,
      appBar: ConnextAppBar(
        variant: ConnextAppBarVariant.hero,
        title: Text(
          "Create Event",
          style: styleText().copyWith(
            color: AppTheme.secondary,
            fontWeight: FontWeight.w800,
          ),
        ),
        onLeadingPressed: () => Navigator.pop(context),
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

                      const SizedBox(height: 18),

                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF171A33), Color(0xFF22254A)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: hasAcceptedTerms
                                ? AppTheme.third
                                : AppTheme.third.withOpacity(0.18),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Checkbox(
                                    value: hasAcceptedTerms,
                                    activeColor: AppTheme.third,
                                    onChanged: (value) {
                                      setState(() {
                                        hasAcceptedTerms = value ?? false;
                                      });
                                    },
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 10),
                                      child: Text(
                                        'I agree that event content must comply with applicable laws, and attendee phone numbers are confidential and cannot be shared.',
                                        style: styleText().copyWith(
                                          fontSize: 12,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  onPressed: _showTermsAndConditions,
                                  icon: const Icon(Icons.gavel_outlined),
                                  label: const Text(
                                    'View full Terms and Conditions',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      /// BUTTON
                      Center(
                        child: IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.third,
                          ),
                          onPressed: isCreatingEvent ? null : createEvent,
                          icon: isCreatingEvent
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.primary,
                                  ),
                                )
                              : const Icon(Icons.add, color: AppTheme.primary),
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
