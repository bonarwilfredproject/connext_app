import 'package:connext_app/constants/app_theme.dart';
import 'package:connext_app/services/event_controller.dart';
import 'package:connext_app/models/event_model.dart';
import 'package:connext_app/constants/decoration_constant.dart';
import 'package:connext_app/services/preferences_services.dart';
import 'package:connext_app/widgets/ellipse_background.dart';
import 'package:connext_app/constants/style_text.dart';
import 'package:flutter/material.dart';

class CreateEvent extends StatefulWidget {
  const CreateEvent({super.key});

  @override
  State<CreateEvent> createState() => _CreateEventState();
}

class _CreateEventState extends State<CreateEvent> {
  final GlobalKey<FormState> _formKey = GlobalKey();

  TextEditingController namaEventController = TextEditingController();
  TextEditingController lokasiController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  int? userId;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final pref = PreferenceHandler();
    await pref.init();
    userId = pref.getUserId();
  }

  Future<void> createEvent() async {
    if (!_formKey.currentState!.validate()) return;

    final event = EventModel(
      title: namaEventController.text.trim(),
      location: lokasiController.text.trim(),
      description: descriptionController.text.trim(),
      createdBy: userId!,
      createdAt: DateTime.now().toIso8601String(),
    );

    await EventController.insertEvent(event);

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF4EEFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4EEFF),
        title: Text("Buat Event", style: styleText()),
      ),
      body: Stack(
        children: [
          EllipseBackground(),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// NAMA EVENT
                    Text("Nama Event", style: styleText()),
                    TextFormField(
                      style: TextStyle(color: AppTheme.secondary, fontSize: 12),
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
                      style: TextStyle(color: AppTheme.secondary, fontSize: 12),
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

                    /// DESKRIPSI
                    Text("Deskripsi", style: styleText()),
                    TextFormField(
                      style: TextStyle(color: AppTheme.secondary, fontSize: 12),
                      controller: descriptionController,
                      minLines: 4,
                      maxLines: 6,
                      textAlignVertical: TextAlignVertical.top,
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
        ],
      ),
    );
  }
}
