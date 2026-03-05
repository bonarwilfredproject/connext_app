import 'package:flutter/material.dart';

class ScanPesertaPage extends StatelessWidget {
  final int eventId;

  const ScanPesertaPage({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Peserta")),
      body: const Center(child: Text("Scanner belum diaktifkan")),
    );
  }
}
