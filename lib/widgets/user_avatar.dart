import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import 'item_photo.dart';

/// Round profile photo with a mint ring, or a person icon when there is no
/// photo. [previewBytes] shows a just-picked photo before it is saved.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.url,
    this.previewBytes,
    this.size = 96,
    this.ringWidth = 3,
  });

  final String? url;
  final Uint8List? previewBytes;
  final double size;
  final double ringWidth;

  @override
  Widget build(BuildContext context) {
    final placeholder = Icon(
      Icons.person_outline,
      size: size * 0.46,
      color: AppColors.deepGreen,
    );
    final Widget content;
    if (previewBytes case final bytes?) {
      content = Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true);
    } else if (url case final url? when url.isNotEmpty) {
      content = ItemPhoto(url: url, placeholder: Center(child: placeholder));
    } else {
      content = Center(child: placeholder);
    }
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.paleMint,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.softMint, width: ringWidth),
      ),
      child: ExcludeSemantics(child: content),
    );
  }
}
