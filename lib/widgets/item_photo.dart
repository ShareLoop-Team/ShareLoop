import 'dart:typed_data';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// Shows one item photo. Supabase posts carry signed network URLs; the mock
/// data uses bundled `assets/` paths so the feed has real pictures offline.
class ItemPhoto extends StatelessWidget {
  const ItemPhoto({
    super.key,
    required this.url,
    required this.placeholder,
    this.fit = BoxFit.cover,
  });

  final String url;

  /// Shown while nothing can be displayed (e.g. a broken link).
  final Widget placeholder;
  final BoxFit fit;

  /// Decoded `data:` URLs, so rebuilding doesn't decode (and flicker) again.
  static final Map<String, Uint8List> _dataBytes = {};

  @override
  Widget build(BuildContext context) {
    if (url.startsWith('data:')) {
      // Photos kept in memory by the mock backend (e.g. profile photos).
      final bytes = _dataBytes.putIfAbsent(
        url,
        () => UriData.parse(url).contentAsBytes(),
      );
      return Image.memory(
        bytes,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => placeholder,
      );
    }
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: fit,
        errorBuilder: (_, _, _) => placeholder,
      );
    }
    return Image.network(
      url,
      fit: fit,
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}

/// Shows the whole photo, uncropped, over a blurred copy of itself that
/// fills the rest of the frame (so wide or tall photos get no plain bars).
class ItemPhotoFull extends StatelessWidget {
  const ItemPhotoFull({
    super.key,
    required this.url,
    required this.placeholder,
  });

  final String url;
  final Widget placeholder;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRect(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: ItemPhoto(url: url, placeholder: const SizedBox.shrink()),
          ),
        ),
        ItemPhoto(url: url, placeholder: placeholder, fit: BoxFit.contain),
      ],
    );
  }
}
