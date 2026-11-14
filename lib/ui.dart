import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const brand = Color(0xff9610ff);
const side = 24.0;
const gap = SizedBox(height: 16);
const largeGap = SizedBox(height: 24);

extension PhotofyTheme on BuildContext {
  Color get surface => Theme.of(this).scaffoldBackgroundColor;
  Color get ink => Theme.of(this).colorScheme.onSurface;
  Color get muted => Theme.of(this).colorScheme.onSurfaceVariant;
  Color get panel => Theme.of(this).colorScheme.surfaceContainerLow;
  Color get line => Theme.of(this).colorScheme.outlineVariant;
  Color get tint => Theme.of(this).colorScheme.secondaryContainer;
  bool get dark => Theme.of(this).brightness == Brightness.dark;
}

ThemeData photofyTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(seedColor: brand, brightness: brightness)
      .copyWith(
        primary: brand,
        onPrimary: Colors.white,
        surface: dark ? const Color(0xff181a20) : Colors.white,
        surfaceContainerLow: dark
            ? const Color(0xff1f222a)
            : const Color(0xfffafafa),
        onSurface: dark ? Colors.white : const Color(0xff212121),
        onSurfaceVariant: dark
            ? const Color(0xffd5d5df)
            : const Color(0xff616161),
        outlineVariant: dark
            ? const Color(0xff35383f)
            : const Color(0xffeeeeee),
        secondaryContainer: dark
            ? const Color(0xff322047)
            : const Color(0xfff3e5ff),
      );
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    fontFamily: 'Urbanist',
    dividerColor: scheme.outlineVariant,
    splashFactory: InkRipple.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      systemOverlayStyle:
          (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
              .copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: scheme.surface,
              ),
      titleTextStyle: TextStyle(
        fontFamily: 'Urbanist',
        fontSize: 21,
        color: scheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(fontSize: 16, height: 1.45),
      titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

String art(String name) => 'assets/photofy/$name';

void open(BuildContext context, Widget page) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

Future<T?> sheet<T>(BuildContext context, Widget content) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(side, 0, side, 24),
            child: content,
          ),
        ),
      ),
    );

void notice(BuildContext context, String text) => ScaffoldMessenger.of(context)
  ..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(content: Text(text)));

class Heading extends StatelessWidget {
  const Heading(this.text, {this.size = 22, this.align, super.key});
  final String text;
  final double size;
  final TextAlign? align;
  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: align,
    style: TextStyle(fontSize: size, fontWeight: FontWeight.w700, height: 1.18),
  );
}

class Pill extends StatelessWidget {
  const Pill(
    this.label,
    this.onTap, {
    this.soft = false,
    this.outline = false,
    this.icon,
    super.key,
  });
  final String label;
  final VoidCallback? onTap;
  final bool soft;
  final bool outline;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final foreground = outline
        ? context.ink
        : soft
        ? brand
        : Colors.white;
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 56),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        foregroundColor: foreground,
        backgroundColor: outline
            ? Colors.transparent
            : soft
            ? context.tint
            : brand,
        disabledBackgroundColor: context.tint,
        disabledForegroundColor: brand.withValues(alpha: .55),
        side: outline ? BorderSide(color: context.line) : null,
        textStyle: const TextStyle(
          fontFamily: 'Urbanist',
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[Icon(icon, size: 19), const SizedBox(width: 9)],
          Flexible(child: Text(label, textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}

class BottomActions extends StatelessWidget {
  const BottomActions(this.children, {super.key});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.surface,
      border: Border(top: BorderSide(color: context.line)),
    ),
    child: SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(side, 16, side, 19),
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(child: children[i]),
          ],
        ],
      ),
    ),
  );
}

class Screen extends StatelessWidget {
  const Screen({
    this.title,
    required this.body,
    this.bottom,
    this.actions,
    this.padding = const EdgeInsets.fromLTRB(side, 12, side, 20),
    this.scroll = true,
    super.key,
  });
  final String? title;
  final Widget body;
  final Widget? bottom;
  final List<Widget>? actions;
  final EdgeInsetsGeometry padding;
  final bool scroll;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: Theme.of(context).appBarTheme.systemOverlayStyle!,
    child: Scaffold(
      appBar: title == null
          ? null
          : AppBar(
              title: Text(title!, maxLines: 1, overflow: TextOverflow.ellipsis),
              actions: actions,
            ),
      body: SafeArea(
        bottom: bottom == null,
        child: scroll
            ? SingleChildScrollView(padding: padding, child: body)
            : Padding(padding: padding, child: body),
      ),
      bottomNavigationBar: bottom,
    ),
  );
}

class Field extends StatelessWidget {
  const Field(
    this.label, {
    this.hint,
    this.initial,
    this.controller,
    this.icon,
    this.trailing,
    this.secret = false,
    this.keyboard,
    this.onChanged,
    super.key,
  });
  final String label;
  final String? hint;
  final String? initial;
  final TextEditingController? controller;
  final IconData? icon;
  final Widget? trailing;
  final bool secret;
  final TextInputType? keyboard;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 17),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        TextFormField(
          initialValue: controller == null ? initial : null,
          controller: controller,
          obscureText: secret,
          keyboardType: keyboard,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint ?? label,
            prefixIcon: icon == null ? null : Icon(icon, size: 20),
            suffixIcon: trailing,
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xffc490ed)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: brand, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 13),
          ),
        ),
      ],
    ),
  );
}

class Mark extends StatelessWidget {
  const Mark({this.size = 78, super.key});
  final double size;
  @override
  Widget build(BuildContext context) =>
      Image.asset(art('logo.webp'), width: size, height: size);
}

class ChoiceGrid extends StatelessWidget {
  const ChoiceGrid({
    required this.labels,
    required this.images,
    required this.selected,
    required this.onSelect,
    this.columns = 3,
    super.key,
  });

  final List<String> labels;
  final List<String> images;
  final int selected;
  final ValueChanged<int> onSelect;
  final int columns;
  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: columns,
      crossAxisSpacing: 9,
      mainAxisSpacing: 12,
      childAspectRatio: .88,
    ),
    itemCount: labels.length,
    itemBuilder: (context, i) {
      final active = selected == i;
      return InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: () => onSelect(i),
        child: Column(
          children: [
            Expanded(
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  border: active ? Border.all(color: brand, width: 2) : null,
                ),
                width: double.infinity,
                child: Image.asset(art(images[i]), fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              labels[i],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: active ? brand : context.ink,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget menuRow(
  BuildContext context,
  String label, {
  IconData? icon,
  Widget? trailing,
  VoidCallback? onTap,
}) => ListTile(
  contentPadding: EdgeInsets.zero,
  minTileHeight: 49,
  leading: icon == null ? null : Icon(icon, size: 21),
  title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
  trailing:
      trailing ??
      (onTap == null ? null : const Icon(Icons.chevron_right, size: 19)),
  onTap: onTap,
);
