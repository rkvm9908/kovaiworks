import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class UserAvatar extends StatelessWidget {
  final String? photoBase64;
  final double radius;
  const UserAvatar({super.key, this.photoBase64, this.radius = 24});

  @override
  Widget build(BuildContext context) {
    ImageProvider? img;
    if (photoBase64 != null && photoBase64!.isNotEmpty) {
      try {
        img = MemoryImage(base64Decode(photoBase64!));
      } catch (_) {}
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.blueLight,
      backgroundImage: img,
      child: img == null
          ? Icon(Icons.person, size: radius, color: AppColors.blue)
          : null,
    );
  }
}