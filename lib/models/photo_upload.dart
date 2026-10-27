import 'dart:typed_data';

/// Model: a photo picked on the device, waiting to be uploaded with a new
/// Give Away post. Bytes rather than a file path so it works on Web too.
class PhotoUpload {
  final Uint8List bytes;

  /// e.g. image/jpeg; null when the picker couldn't tell.
  final String? mimeType;

  /// Original file name or path, kept for mock data and the file extension.
  final String name;

  const PhotoUpload({required this.bytes, this.mimeType, required this.name});
}
