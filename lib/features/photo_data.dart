import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../session.dart';
import '../ui.dart';

class Photo {
  const Photo.asset(this.source) : local = false;
  const Photo.file(this.source) : local = true;
  final String source;
  final bool local;

  ImageProvider get provider =>
      local ? FileImage(File(source)) : AssetImage(art(source));

  Future<Uint8List> bytes() async => local
      ? File(source).readAsBytes()
      : (await rootBundle.load(art(source))).buffer.asUint8List();

  Widget view({BoxFit fit = BoxFit.cover, ColorFilter? filter}) {
    final image = Image(
      image: provider,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, _, _) =>
          const Center(child: Icon(Icons.broken_image_outlined, size: 44)),
    );
    return filter == null
        ? image
        : ColorFiltered(colorFilter: filter, child: image);
  }
}

Future<List<Photo>> pickPhotos(
  BuildContext context, {
  bool multiple = false,
}) async {
  try {
    final paths = await Session.channel.invokeListMethod<String>(
      'pick',
      multiple,
    );
    return paths?.map(Photo.file).toList() ?? [];
  } on PlatformException {
    if (context.mounted) {
      notice(context, 'The selected photos could not be opened.');
    }
    return [];
  }
}

Future<String> writePhoto(
  Photo photo, {
  int? width,
  int? height,
  double? crop,
  ColorFilter? filter,
  bool share = false,
}) async {
  final codec = await ui.instantiateImageCodec(await photo.bytes());
  final frame = await codec.getNextFrame();
  final image = frame.image;
  try {
    var src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    if (crop != null || (width != null && height != null)) {
      final ratio = crop ?? width! / height!;
      final size = src.size;
      src = Rect.fromCenter(
        center: src.center,
        width: size.aspectRatio > ratio ? size.height * ratio : size.width,
        height: size.aspectRatio > ratio ? size.height : size.width / ratio,
      );
    }
    final outW = width ?? src.width.round().clamp(1, 4096);
    final outH = height ?? src.height.round().clamp(1, 4096);
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawImageRect(
      image,
      src,
      Rect.fromLTWH(0, 0, outW.toDouble(), outH.toDouble()),
      Paint()
        ..colorFilter = filter
        ..filterQuality = FilterQuality.high,
    );
    final picture = recorder.endRecording();
    try {
      final rendered = await picture.toImage(outW, outH);
      try {
        final bytes = (await rendered.toByteData(
          format: ui.ImageByteFormat.png,
        ))!.buffer.asUint8List();
        final uri = (await Session.channel.invokeMethod<String>(
          'save',
          bytes,
        ))!;
        if (share) await Session.channel.invokeMethod<void>('share', uri);
        return uri;
      } finally {
        rendered.dispose();
      }
    } finally {
      picture.dispose();
    }
  } finally {
    image.dispose();
    codec.dispose();
  }
}

Future<void> download(
  BuildContext context,
  Photo photo, {
  int? width,
  int? height,
  double? crop,
  ColorFilter? filter,
  bool share = false,
}) async {
  try {
    final uri = await writePhoto(
      photo,
      width: width,
      height: height,
      crop: crop,
      filter: filter,
      share: share,
    );
    if (context.mounted && !share) {
      notice(
        context,
        uri.startsWith('content:')
            ? 'Saved to gallery'
            : 'Saved to app pictures',
      );
    }
  } on Exception {
    if (context.mounted) notice(context, 'Unable to save this photo.');
  }
}

class PhotoBox extends StatelessWidget {
  const PhotoBox(
    this.photo, {
    this.ratio = 2 / 3,
    this.filter,
    this.radius = 8,
    this.fit = BoxFit.cover,
    super.key,
  });
  final Photo photo;
  final double ratio;
  final double radius;
  final ColorFilter? filter;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: ratio,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: photo.view(fit: fit, filter: filter),
    ),
  );
}
