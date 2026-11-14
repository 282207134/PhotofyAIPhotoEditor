import 'package:flutter/material.dart';

import '../session.dart';
import '../ui.dart';
import 'photo_data.dart';
import 'tool_flow.dart';
import 'tools.dart';

class Editor extends StatefulWidget {
  const Editor(this.photo, {super.key});
  final Photo photo;

  @override
  State<Editor> createState() => _EditorState();
}

class _EditorState extends State<Editor> {
  int filter = 0;
  double brightness = 0;
  double? crop;
  bool saving = false;

  ColorFilter? get adjustment => photoFilter(filter, brightness: brightness);

  Future<void> save() async {
    final pro = Session.of(context).pro;
    final size = await sheet<(int, int)>(
      context,
      Builder(
        builder: (context) => Column(
          children: [
            const Heading('Save Results'),
            gap,
            for (final height in [640, 854, 1280, 1920, 2560, 3840, 7680])
              menuRow(
                context,
                '${(height * 9 / 16).round()} × $height',
                trailing: height >= 2560
                    ? const Text('PRO', style: TextStyle(color: brand))
                    : const Icon(Icons.file_download_outlined, size: 19),
                onTap: () {
                  if (height >= 2560 && !pro) {
                    notice(context, 'Upgrade to PRO to unlock this size.');
                  } else {
                    Navigator.pop(context, ((height * 9 / 16).round(), height));
                  }
                },
              ),
          ],
        ),
      ),
    );
    if (!mounted || size == null) return;
    setState(() => saving = true);
    if (crop == null) {
      await download(
        context,
        widget.photo,
        width: size.$1,
        height: size.$2,
        filter: adjustment,
      );
    } else {
      // Fit the selected crop within the export limit so its shape is preserved.
      final width = (size.$2 * crop!).round().clamp(1, size.$1);
      final height = (width / crop!).round();
      await download(
        context,
        widget.photo,
        width: width,
        height: height,
        crop: crop,
        filter: adjustment,
      );
    }
    if (mounted) setState(() => saving = false);
  }

  Future<void> chooseAdjustment(String label) async {
    await sheet<void>(
      context,
      StatefulBuilder(
        builder: (context, refresh) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Heading(label, align: TextAlign.center),
            gap,
            if (label == 'Adjust') ...[
              Center(child: Text('Brightness ${brightness.round()}')),
              Slider(
                min: -70,
                max: 70,
                value: brightness,
                onChanged: (value) {
                  setState(() => brightness = value);
                  refresh(() {});
                },
              ),
            ],
            if (label == 'Crop')
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                children: [
                  for (final (name, ratio) in const [
                    ('Original', null),
                    ('1:1', 1.0),
                    ('4:5', .8),
                    ('9:16', 9 / 16),
                  ])
                    ChoiceChip(
                      label: Text(name),
                      selected: crop == ratio,
                      onSelected: (_) {
                        setState(() => crop = ratio);
                        refresh(() {});
                      },
                    ),
                ],
              ),
            if (label == 'Filters')
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: [
                  for (final (i, name) in const [
                    'Original',
                    'Sepia',
                    'Mono',
                    'Warm',
                    'Cool',
                  ].indexed)
                    ChoiceChip(
                      label: Text(name),
                      selected: filter == i,
                      onSelected: (_) {
                        setState(() => filter = i);
                        refresh(() {});
                      },
                    ),
                ],
              ),
            gap,
            Pill('Done', () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Screen(
    title: 'Edit Photo',
    actions: [
      IconButton(
        tooltip: 'Save Results',
        onPressed: saving ? null : save,
        icon: const Icon(Icons.file_download_outlined),
      ),
    ],
    scroll: false,
    padding: const EdgeInsets.fromLTRB(side, 16, side, 10),
    body: Center(
      child: PhotoBox(
        widget.photo,
        ratio: crop ?? 9 / 16,
        radius: 2,
        fit: crop == null && widget.photo.local ? BoxFit.contain : BoxFit.cover,
        filter: adjustment,
      ),
    ),
    bottom: DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 88,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            children: [
              for (final (label, tool) in const [
                ('Scenes', PhotoTool.scene),
                ('Transform', PhotoTool.transform),
                ('Cartoonize', PhotoTool.cartoon),
                ('Anime', PhotoTool.anime),
                ('Enhance', PhotoTool.enhance),
                ('Eraser', PhotoTool.erase),
                ('Background', PhotoTool.background),
                ('Sky Rep.', PhotoTool.sky),
                ('Colorizer', PhotoTool.color),
              ])
                _EditorAction(
                  label,
                  tool.icon,
                  () => open(context, ToolFlow(tool, initial: widget.photo)),
                ),
              for (final (label, icon) in const [
                ('Adjust', Icons.tune_outlined),
                ('Crop', Icons.crop_outlined),
                ('Filters', Icons.filter_vintage_outlined),
              ])
                _EditorAction(label, icon, () => chooseAdjustment(label)),
            ],
          ),
        ),
      ),
    ),
  );
}

class _EditorAction extends StatelessWidget {
  const _EditorAction(this.label, this.icon, this.onTap);
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: SizedBox(
      width: 65,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    ),
  );
}
