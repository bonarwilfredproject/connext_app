import 'package:connext_app/constants/app_theme.dart';
import 'package:connext_app/services/event_controller.dart';
import 'package:connext_app/models/event_model.dart';
import 'package:connext_app/constants/decoration_constant.dart';
import 'package:connext_app/services/preferences_services.dart';
import 'package:connext_app/widgets/ellipse_background.dart';
import 'package:connext_app/widgets/positioning_inside.dart';
import 'package:connext_app/constants/style_text.dart';
import 'package:flutter/material.dart';

class CreateEvent extends StatefulWidget {
  const CreateEvent({super.key});

  @override
  State<CreateEvent> createState() => _CreateEventState();
}

class _CreateEventState extends State<CreateEvent> {
  GlobalKey<FormState> _formKey = GlobalKey();
  TextEditingController namaEventController = TextEditingController();
  TextEditingController lokasiController = TextEditingController();
  int? userId;
  String? namaUser;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final pref = PreferenceHandler();
    await pref.init();
    userId = pref.getUserId();
    namaUser = pref.getNamaUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF4EEFF),
      appBar: AppBar(
        backgroundColor: Color(0xFFF4EEFF),
        title: Text("Buat Event", style: styleText()),
      ),
      body: Stack(
        children: [
          EllipseBackground(),
          PositioningInside(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Nama Event", style: styleText()),
                    TextFormField(
                      style: TextStyle(color: AppTheme.primary, fontSize: 12),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Nama event tidak boleh kosong";
                        }
                        return null;
                      },
                      controller: namaEventController,
                      decoration: decorationConstant(
                        hintText: "Masukkan nama event",
                      ),
                    ),
                    SizedBox(height: 20),
                    Text("Lokasi", style: styleText()),
                    TextFormField(
                      style: TextStyle(color: AppTheme.primary, fontSize: 12),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Lokasi tidak boleh kosong";
                        }
                        return null;
                      },
                      controller: lokasiController,
                      decoration: decorationConstant(
                        hintText: "Masukkan lokasi event",
                      ),
                    ),
                    SizedBox(height: 20),
                    Center(
                      child: IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Color(0XFF424874),
                        ),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            await EventController.insertEvent(
                              EventModel(
                                userId: userId!,
                                title: namaEventController.text.trim(),
                                location: lokasiController.text.trim(),
                                totalPeserta: 0,
                                createdBy:
                                    namaUser ??
                                    "Unknown", // sementara, nanti bisa pakai nama user login
                              ),
                            );

                            Navigator.pop(context, true);
                            // kirim sinyal ke HomePage bahwa event berhasil dibuat
                          }
                        },
                        icon: Icon(Icons.add, color: Color(0xFFF4EEFF)),
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
