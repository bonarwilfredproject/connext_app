import 'package:connext_app/constants/app_theme.dart';
import 'package:connext_app/constants/style_text.dart';
import 'package:connext_app/models/event_model.dart';
import 'package:connext_app/services/event_controller.dart';
import 'package:connext_app/widgets/ellipse_background.dart';
import 'package:connext_app/widgets/positioning_inside.dart';
import 'package:flutter/material.dart';

class AttendeeEventPage extends StatefulWidget {
  final int userId;

  const AttendeeEventPage({super.key, required this.userId});

  @override
  State<AttendeeEventPage> createState() => _AttendeeEventPageState();
}

class _AttendeeEventPageState extends State<AttendeeEventPage> {
  List<EventModel> events = [];

  @override
  void initState() {
    super.initState();
    loadEvents();
  }

  void loadEvents() async {
    events = await EventController.getEventByAttendee(widget.userId);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        title: Text("Event Saya", style: styleText()),
        backgroundColor: AppTheme.primary,
      ),
      body: Stack(
        children: [
          EllipseBackground(),
          PositioningInside(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final e = events[index];

                  return ListTile(
                    title: Text(e.title, style: styleText()),
                    subtitle: Text(e.location, style: styleText()),
                    trailing: Text(
                      "${e.totalPeserta} Peserta",
                      style: styleText(),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
