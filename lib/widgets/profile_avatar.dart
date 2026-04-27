import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class ProfileAvatar extends StatefulWidget {
  final String? imagePath;
  final double radius;
  final Color backgroundColor;
  final IconData fallbackIcon;
  final Color iconColor;
  final double iconSize;

  const ProfileAvatar({
    super.key,
    required this.imagePath,
    required this.radius,
    required this.backgroundColor,
    this.fallbackIcon = Icons.person,
    this.iconColor = Colors.white,
    this.iconSize = 24,
  });

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  late Future<ImageProvider?> _imageFuture;

  @override
  void initState() {
    super.initState();
    _imageFuture = _resolveImage(widget.imagePath);
  }

  @override
  void didUpdateWidget(covariant ProfileAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath) {
      _imageFuture = _resolveImage(widget.imagePath);
    }
  }

  bool _isRemoteImage(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  bool _isFirebaseStorageUrl(String path) {
    return path.startsWith('gs://');
  }

  bool _looksLikeStoragePath(String path) {
    // e.g. profile_images/uid.jpg
    if (path.contains('://')) return false;
    if (path.startsWith('/') || path.startsWith('\\')) return false;
    if (path.contains('\\')) return false;
    return path.contains('/');
  }

  Future<ImageProvider?> _resolveImage(String? path) async {
    final imagePath = path?.trim();
    if (imagePath == null || imagePath.isEmpty) return null;

    if (_isRemoteImage(imagePath)) {
      return NetworkImage(imagePath);
    }

    if (File(imagePath).existsSync()) {
      return FileImage(File(imagePath));
    }

    try {
      if (_isFirebaseStorageUrl(imagePath)) {
        final url = await FirebaseStorage.instance
            .refFromURL(imagePath)
            .getDownloadURL();
        return NetworkImage(url);
      }

      if (_looksLikeStoragePath(imagePath)) {
        final url = await FirebaseStorage.instance
            .ref(imagePath)
            .getDownloadURL();
        return NetworkImage(url);
      }
    } catch (_) {
      // ignore and fall back
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ImageProvider?>(
      future: _imageFuture,
      builder: (context, snapshot) {
        final image = snapshot.data;

        return CircleAvatar(
          radius: widget.radius,
          backgroundColor: widget.backgroundColor,
          backgroundImage: image,
          child: image == null
              ? Icon(
                  widget.fallbackIcon,
                  size: widget.iconSize,
                  color: widget.iconColor,
                )
              : null,
        );
      },
    );
  }
}
