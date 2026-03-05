import 'package:connext_app/database/event_controller.dart';
import 'package:connext_app/model/event_model.dart';
import 'package:connext_app/utils/decoration_constant.dart';
import 'package:connext_app/utils/ellipse_background.dart';
import 'package:connext_app/utils/positioning_inside.dart';
import 'package:connext_app/utils/style_text.dart';
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
                                title: namaEventController.text.trim(),
                                location: lokasiController.text.trim(),
                                totalPeserta: 0,
                                createdBy:
                                    "Admin", // sementara, nanti bisa pakai nama user login
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
