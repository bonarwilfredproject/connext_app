import 'package:connext_app/constants/style_text.dart';
import 'package:connext_app/models/event_model.dart';
import 'package:connext_app/services/event_controller.dart';
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
      appBar: AppBar(title: Text("Event Saya", style: styleText())),
      body: ListView.builder(
        itemCount: events.length,
        itemBuilder: (context, index) {
          final e = events[index];

          return ListTile(
            title: Text(e.title, style: styleText()),
            subtitle: Text(e.location, style: styleText()),
            trailing: Text("${e.totalPeserta} Peserta", style: styleText()),
          );
        },
      ),
    );
  }
}
