import 'package:flutter/material.dart';

import '../ui.dart';
import 'photo_data.dart';
import 'tools.dart';

Future<Photo?> choosePhoto(BuildContext context, Photo sample) async {
  final useSample = await sheet<bool>(
    context,
    Builder(
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Heading('Select Photo', align: TextAlign.center),
          gap,
          Pill(
            'Choose from Gallery',
            () => Navigator.pop(context, false),
            icon: Icons.photo_library_outlined,
          ),
          gap,
          Pill('Use Sample', () => Navigator.pop(context, true), soft: true),
        ],
      ),
    ),
  );
  if (useSample == null || !context.mounted) return null;
  if (useSample) return sample;
  final photos = await pickPhotos(context);
  return photos.firstOrNull;
}

class ToolFlow extends StatefulWidget {
  const ToolFlow(this.tool, {this.initial, super.key});
  final PhotoTool tool;
  final Photo? initial;

  @override
  State<ToolFlow> createState() => _ToolFlowState();
}

enum _Stage { upload, mask, configure, generating, result, avatar }

class _ToolFlowState extends State<ToolFlow> {
  _Stage stage = _Stage.upload;
  PhotoTool get tool => widget.tool;
  late Photo? photo = widget.initial;
  final photos = <Photo>[];
  final strokes = <List<Offset>>[];
  double brush = 24;
  double split = .5;
  int choice = 0;
  int secondary = 0;
  int variant = 0;
  int avatar = 0;
  bool male = false;
  bool busy = false;
  bool demo = false;
  final transform = TransformationController();

  @override
  void dispose() {
    transform.dispose();
    super.dispose();
  }

  Future<void> select() async {
    final selected = await choosePhoto(context, Photo.asset(tool.sample));
    if (mounted && selected != null) setState(() => photo = selected);
  }

  Future<void> start() async {
    if (tool.step == ToolStep.configure) {
      setState(() => stage = _Stage.configure);
    } else if (tool.step == ToolStep.mask) {
      setState(() => stage = _Stage.mask);
    } else {
      await generate();
    }
  }

  Future<void> generate() async {
    demo = tool == PhotoTool.avatar
        ? photos.every((photo) => !photo.local)
        : photo?.local == false;
    setState(() => stage = _Stage.generating);
    await Future<void>.delayed(
      Duration(milliseconds: tool == PhotoTool.avatar ? 1400 : 480),
    );
    if (!mounted || stage != _Stage.generating) return;
    setState(() {
      variant = 0;
      split = .5;
      transform.value = Matrix4.identity();
      stage = _Stage.result;
    });
  }

  Future<void> addAvatars() async {
    final useSample = await sheet<bool>(
      context,
      Builder(
        builder: (context) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Heading('Upload 5 - 10 Photos', align: TextAlign.center),
            gap,
            Pill('Choose from Gallery', () => Navigator.pop(context, false)),
            gap,
            Pill(
              'Use Sample Photos',
              () => Navigator.pop(context, true),
              soft: true,
            ),
          ],
        ),
      ),
    );
    if (!mounted || useSample == null) return;
    final added = useSample
        ? List.generate(7, (i) => Photo.asset('guide${i % 6}.webp'))
        : await pickPhotos(context, multiple: true);
    if (!mounted || added.isEmpty) return;
    setState(() {
      for (final item in added) {
        if (photos.length == 10) break;
        photos.add(item);
      }
    });
  }

  Photo avatarPhoto(int i) =>
      demo ? Photo.asset('avatar$i.webp') : photos[i % photos.length];

  bool hasSampleVariant(int index) =>
      index > 0 &&
      (tool == PhotoTool.color ||
          (index < 4 &&
              [
                PhotoTool.scene,
                PhotoTool.anime,
                PhotoTool.cartoon,
                PhotoTool.transform,
                PhotoTool.room,
              ].contains(tool)));

  Photo get result {
    if (!demo || tool == PhotoTool.enhance) return photo!;
    if (hasSampleVariant(variant)) {
      return Photo.asset('variant${tool.index}_$variant.webp');
    }
    return Photo.asset(tool.result);
  }

  ColorFilter? get resultFilter {
    if (tool == PhotoTool.enhance) {
      return photoFilter(variant == 0 ? 3 : variant);
    }
    if (tool == PhotoTool.color && !demo) {
      return photoFilter(variant);
    }
    return null;
  }

  Future<void> saveResult(
    Photo value, {
    bool share = false,
    bool filter = false,
  }) async {
    if (busy) return;
    setState(() => busy = true);
    await download(
      context,
      value,
      share: share,
      filter: filter ? resultFilter : null,
    );
    if (mounted) setState(() => busy = false);
  }

  Future<void> saveAll() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      for (var i = 0; i < (demo ? 8 : photos.length); i++) {
        await writePhoto(avatarPhoto(i));
      }
      if (mounted) notice(context, 'Photos saved');
    } on Exception {
      if (mounted) notice(context, 'Some photos could not be saved.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void back() {
    switch (stage) {
      case _Stage.upload:
        Navigator.pop(context);
      case _Stage.configure:
      case _Stage.mask:
      case _Stage.generating:
      case _Stage.result:
        setState(() => stage = _Stage.upload);
      case _Stage.avatar:
        setState(() => stage = _Stage.result);
    }
  }

  Future<void> masked() async {
    if (strokes.isEmpty) {
      notice(context, 'Brush over an area to continue.');
      return;
    }
    if (tool == PhotoTool.transform) {
      final prompt = TextEditingController();
      final confirmed = await sheet<bool>(
        context,
        StatefulBuilder(
          builder: (context, refresh) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Heading('Transform', align: TextAlign.center),
              gap,
              TextField(
                controller: prompt,
                maxLines: 4,
                onChanged: (_) => refresh(() {}),
                decoration: const InputDecoration(
                  hintText: 'Describe the transformation you want to make...',
                  border: OutlineInputBorder(),
                ),
              ),
              gap,
              Row(
                children: [
                  Expanded(
                    child: Pill(
                      'Cancel',
                      () => Navigator.pop(context, false),
                      soft: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Pill(
                      'Transform',
                      prompt.text.trim().isEmpty
                          ? null
                          : () => Navigator.pop(context, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      // Allow the sheet's exit animation to release the field before disposing it.
      Future<void>.delayed(const Duration(milliseconds: 400), prompt.dispose);
      if (!mounted || confirmed != true) return;
    }
    await generate();
  }

  Widget upload() {
    if (tool == PhotoTool.avatar) return avatarUpload();
    final selected = photo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Heading('Upload your photo'),
        if (selected == null) ...[
          const SizedBox(height: 9),
          Text(
            'Upload your photo, and we’ll ${tool.purpose}.',
            style: TextStyle(color: context.muted),
          ),
        ],
        largeGap,
        if (selected == null)
          Semantics(
            button: true,
            child: InkWell(
              onTap: select,
              borderRadius: BorderRadius.circular(10),
              child: AspectRatio(
                aspectRatio: 1,
                child: ColoredBox(
                  color: context.tint,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.ios_share, color: brand, size: 42),
                      gap,
                      Text(
                        'Upload',
                        style: TextStyle(
                          color: context.dark ? Colors.white : brand,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        else
          Stack(
            children: [
              PhotoBox(selected),
              Positioned(
                top: 5,
                right: 5,
                child: IconButton.filled(
                  tooltip: 'Remove photo',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xffff5157),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => setState(() {
                    photo = null;
                    strokes.clear();
                  }),
                  icon: const Icon(Icons.close, size: 18),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget avatarUpload() {
    if (photos.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Heading('${photos.length} photos have been uploaded'),
          gap,
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: photos.length,
            itemBuilder: (context, i) => Stack(
              fit: StackFit.expand,
              children: [
                PhotoBox(photos[i], ratio: 1),
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    tooltip: 'Remove photo ${i + 1}',
                    onPressed: () => setState(() => photos.removeAt(i)),
                    icon: const Icon(Icons.cancel, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Heading('Pick 5 - 10 photos of yourself'),
        for (final good in [true, false]) ...[
          gap,
          Row(
            children: [
              Icon(
                good ? Icons.check_box : Icons.disabled_by_default,
                color: good ? const Color(0xff0bc58b) : const Color(0xffff5157),
              ),
              const SizedBox(width: 10),
              Heading(good ? 'Good Photos' : 'Bad Photos', size: 18),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            good
                ? 'Close-up selfies, one and same person, variety of expressions and face angles.'
                : 'Group pics and different person, face not visible, wearing glasses, animals.',
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(
                  child: PhotoBox(
                    Photo.asset('guide${i + (good ? 0 : 3)}.webp'),
                    ratio: 1,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget mask() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Mask the area you want to ${tool == PhotoTool.erase ? 'erase' : 'transform'}.',
        textAlign: TextAlign.center,
      ),
      gap,
      LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxWidth * 1.5);
          Offset normalized(Offset point) => Offset(
            (point.dx / size.width).clamp(0, 1),
            (point.dy / size.height).clamp(0, 1),
          );
          return GestureDetector(
            onPanStart: (event) =>
                setState(() => strokes.add([normalized(event.localPosition)])),
            onPanUpdate: (event) => setState(
              () => strokes.last.add(normalized(event.localPosition)),
            ),
            child: CustomPaint(
              foregroundPainter: _MaskPainter(strokes, brush),
              child: PhotoBox(photo!, radius: 2),
            ),
          );
        },
      ),
      Row(
        children: [
          const Icon(Icons.brush_outlined, color: brand, size: 19),
          Expanded(
            child: Slider(
              min: 8,
              max: 60,
              value: brush,
              label: '${brush.round()} px',
              onChanged: (value) => setState(() => brush = value),
            ),
          ),
          IconButton(
            tooltip: 'Undo brush stroke',
            onPressed: strokes.isEmpty
                ? null
                : () => setState(() => strokes.removeLast()),
            icon: const Icon(Icons.undo),
          ),
        ],
      ),
    ],
  );

  Widget configure() {
    final (firstTitle, labels, prefix, nextLabels) = switch (tool) {
      PhotoTool.room => (
        'Select Room Type',
        const [
          'Living Room',
          'Bedroom',
          'Kitchen',
          'Bathroom',
          'Dining Room',
          'Office',
        ],
        'room',
        const [
          'Contemporary',
          'Minimalist',
          'Modern',
          'Industrial',
          'Vintage',
          'Tropical',
        ],
      ),
      PhotoTool.background => (
        'Select Filters',
        const [
          'Auto',
          'Person',
          'Nature',
          'Food & Drink',
          'Animal',
          'Miscellaneous',
        ],
        'back',
        const ['Home', 'Beach', 'Bokeh Effect', 'Forest', 'Autumn', 'Winter'],
      ),
      PhotoTool.expression => (
        'Select Expression',
        const ['Big Smile', 'Frown', 'Angry', 'Unhappy'],
        'expression',
        const <String>[],
      ),
      PhotoTool.hair => (
        'Select Hairstyle',
        const ['Long Bangs Hair', 'Straight Hair', 'Curly Hair', 'Short Hair'],
        'hair',
        const <String>[],
      ),
      _ => (
        'Select Sky',
        const ['Clear', 'Sunset', 'Cloudy'],
        '',
        const <String>[],
      ),
    };
    final gender = tool == PhotoTool.expression || tool == PhotoTool.hair;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Heading(firstTitle),
        gap,
        if (gender) ...[
          Row(
            children: [
              for (final value in [true, false])
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() {
                      male = value;
                      choice = 0;
                    }),
                    child: Container(
                      padding: const EdgeInsets.only(bottom: 9),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            width: 2,
                            color: value == male ? brand : context.line,
                          ),
                        ),
                      ),
                      child: Text(
                        value ? 'Male' : 'Female',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: value == male ? brand : context.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          gap,
        ],
        ChoiceGrid(
          labels: labels,
          images: List.generate(
            labels.length,
            (i) => prefix.isEmpty
                ? ['result12.webp', 'back10.webp', 'sample12.webp'][i]
                : '$prefix$i.webp',
          ),
          selected: choice,
          columns: gender ? 2 : 3,
          onSelect: (value) => setState(() => choice = value),
        ),
        if (nextLabels.isNotEmpty) ...[
          largeGap,
          const Heading('Select Design Style'),
          gap,
          ChoiceGrid(
            labels: nextLabels,
            images: List.generate(
              nextLabels.length,
              (i) => '$prefix${i + labels.length}.webp',
            ),
            selected: secondary,
            onSelect: (value) => setState(() => secondary = value),
          ),
        ],
      ],
    );
  }

  Widget preview() {
    final output = result;
    if (tool != PhotoTool.enhance) {
      return PhotoBox(output, radius: 2, filter: resultFilter);
    }
    return AspectRatio(
      aspectRatio: 2 / 3,
      child: LayoutBuilder(
        builder: (context, constraints) => ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              InteractiveViewer(
                transformationController: transform,
                maxScale: 4,
                child: output.view(filter: resultFilter),
              ),
              IgnorePointer(
                child: ClipRect(
                  clipper: _Split(split),
                  child: ListenableBuilder(
                    listenable: transform,
                    builder: (context, child) =>
                        Transform(transform: transform.value, child: child),
                    child: photo!.view(),
                  ),
                ),
              ),
              Positioned(top: 10, left: 10, child: _CompareLabel('Before')),
              Positioned(top: 10, right: 10, child: _CompareLabel('After')),
              Positioned(
                top: 0,
                bottom: 0,
                left: constraints.maxWidth * split - 1,
                child: IgnorePointer(
                  child: Container(width: 2, color: Colors.white),
                ),
              ),
              Positioned(
                left: (constraints.maxWidth * split - 24).clamp(
                  0,
                  constraints.maxWidth - 48,
                ),
                top: constraints.maxHeight * .75,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragUpdate: (event) => setState(() {
                    split = (split + event.delta.dx / constraints.maxWidth)
                        .clamp(0, 1);
                  }),
                  child: Semantics(
                    label: 'Drag to compare before and after',
                    child: const SizedBox.square(
                      dimension: 48,
                      child: Center(
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 14,
                          child: Icon(
                            Icons.compare_arrows,
                            size: 18,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget results() {
    if (tool == PhotoTool.avatar) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: demo ? 8 : photos.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemBuilder: (context, i) => Stack(
          fit: StackFit.expand,
          children: [
            InkWell(
              onTap: () => setState(() {
                avatar = i;
                stage = _Stage.avatar;
              }),
              child: PhotoBox(avatarPhoto(i), ratio: 1),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              child: IconButton.filled(
                tooltip: 'Download avatar ${i + 1}',
                onPressed: busy ? null : () => saveResult(avatarPhoto(i)),
                style: IconButton.styleFrom(
                  minimumSize: const Size(30, 30),
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.arrow_downward, size: 16),
              ),
            ),
          ],
        ),
      );
    }
    final names = tool.variants;
    return Column(
      children: [
        if (!demo && tool != PhotoTool.enhance) ...[
          Text(
            'AI preview · showing your original photo',
            style: TextStyle(color: context.muted),
          ),
          const SizedBox(height: 10),
        ],
        preview(),
        if (names.isNotEmpty) ...[
          gap,
          SizedBox(
            height: 145,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: names.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final thumbnail = demo && hasSampleVariant(i)
                    ? Photo.asset('variant${tool.index}_$i.webp')
                    : demo && tool != PhotoTool.enhance
                    ? Photo.asset(tool.result)
                    : photo!;
                return InkWell(
                  onTap: () => setState(() => variant = i),
                  child: SizedBox(
                    width: 78,
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(
                                color: i == variant
                                    ? brand
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: PhotoBox(
                              thumbnail,
                              radius: 5,
                              filter: tool == PhotoTool.enhance
                                  ? photoFilter(i == 0 ? 3 : i)
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          names[i],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: i == variant ? brand : context.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Future<void> shareAvatar() async {
    await sheet<void>(
      context,
      Builder(
        builder: (context) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Heading('Share', align: TextAlign.center),
            gap,
            Text(
              'Share this avatar using an app installed on your device.',
              textAlign: TextAlign.center,
            ),
            gap,
            Pill('Open Share Menu', () {
              Navigator.pop(context);
              saveResult(avatarPhoto(avatar), share: true);
            }, icon: Icons.ios_share),
          ],
        ),
      ),
    );
  }

  List<Widget> get actions => switch (stage) {
    _Stage.upload when tool == PhotoTool.avatar && photos.isEmpty => [
      Pill('Upload 5 - 10 Photos', addAvatars, icon: Icons.ios_share),
    ],
    _Stage.upload when tool == PhotoTool.avatar => [
      Pill('Upload more', photos.length < 10 ? addAvatars : null, soft: true),
      Pill('Generate', photos.length >= 5 ? generate : null),
    ],
    _Stage.upload => [Pill(tool.uploadAction, photo == null ? null : start)],
    _Stage.mask => [
      Pill(tool == PhotoTool.erase ? 'Erase' : 'Transform', masked),
    ],
    _Stage.configure => [Pill('Generate', generate)],
    _Stage.generating when tool == PhotoTool.avatar => [
      Pill(
        'Notify Me When It’s Done',
        () => notice(context, 'Keep this preview open to view your avatars.'),
      ),
    ],
    _Stage.result when tool == PhotoTool.avatar => [
      Pill('Generate More', back, soft: true),
      Pill('Download All', busy ? null : saveAll),
    ],
    _Stage.result when tool.repeat != null => [
      Pill(
        tool.repeat!,
        () => setState(
          () => stage = tool.step == ToolStep.mask
              ? _Stage.mask
              : _Stage.configure,
        ),
        soft: true,
      ),
    ],
    _Stage.avatar => [
      Pill('Share', busy ? null : shareAvatar, soft: true),
      Pill('Download', busy ? null : () => saveResult(avatarPhoto(avatar))),
    ],
    _ => [],
  };

  @override
  Widget build(BuildContext context) {
    final buttons = actions;
    final centered = stage == _Stage.generating || stage == _Stage.avatar;
    return PopScope(
      canPop: stage == _Stage.upload,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) back();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: back),
          title: Text(
            stage == _Stage.avatar ? '' : tool.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            if (stage == _Stage.result && tool != PhotoTool.avatar)
              IconButton(
                tooltip: 'Download',
                onPressed: busy ? null : () => saveResult(result, filter: true),
                icon: const Icon(Icons.file_download_outlined),
              ),
            if (stage == _Stage.result && tool == PhotoTool.enhance)
              IconButton(
                tooltip: 'Zoom preview',
                onPressed: () {
                  transform.value = transform.value.getMaxScaleOnAxis() > 1
                      ? Matrix4.identity()
                      : Matrix4.diagonal3Values(1.6, 1.6, 1);
                },
                icon: const Icon(Icons.zoom_in),
              ),
          ],
        ),
        body: SafeArea(
          bottom: buttons.isEmpty,
          child: centered
              ? Padding(
                  padding: const EdgeInsets.all(side),
                  child: Center(
                    child: stage == _Stage.avatar
                        ? PhotoBox(avatarPhoto(avatar), ratio: 1)
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Mark(),
                              largeGap,
                              const CircularProgressIndicator(color: brand),
                              largeGap,
                              Heading(
                                tool == PhotoTool.avatar
                                    ? 'Generating Avatar...'
                                    : 'Preparing preview...',
                              ),
                              if (tool == PhotoTool.avatar) ...[
                                gap,
                                const Text(
                                  'Your avatar previews will appear here.',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(side, 16, side, 14),
                  child: switch (stage) {
                    _Stage.upload => upload(),
                    _Stage.mask => mask(),
                    _Stage.configure => configure(),
                    _Stage.result => results(),
                    _ => const SizedBox.shrink(),
                  },
                ),
        ),
        bottomNavigationBar: buttons.isEmpty ? null : BottomActions(buttons),
      ),
    );
  }
}

class _MaskPainter extends CustomPainter {
  const _MaskPainter(this.strokes, this.brush);
  final List<List<Offset>> strokes;
  final double brush;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .6)
      ..strokeWidth = brush
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    Offset position(Offset point) =>
        Offset(point.dx * size.width, point.dy * size.height);
    for (final stroke in strokes) {
      final start = position(stroke.first);
      if (stroke.length == 1) canvas.drawCircle(start, brush / 4, paint);
      final path = Path()..moveTo(start.dx, start.dy);
      for (final point in stroke.skip(1)) {
        final p = position(point);
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_MaskPainter oldDelegate) => true;
}

class _Split extends CustomClipper<Rect> {
  const _Split(this.value);
  final double value;
  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * value, size.height);
  @override
  bool shouldReclip(_Split oldClipper) => value != oldClipper.value;
}

class _CompareLabel extends StatelessWidget {
  const _CompareLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    ),
  );
}
