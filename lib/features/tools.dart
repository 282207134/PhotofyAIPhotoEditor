import 'package:flutter/material.dart';

enum ToolStep { generate, mask, configure }

enum PhotoTool {
  avatar('AI Avatar Generator', Icons.face_retouching_natural),
  scene(
    'AI Scene Generator',
    Icons.location_city_outlined,
    'generate an AI scene for you',
  ),
  anime(
    'AI Anime Generator',
    Icons.auto_awesome_outlined,
    'create an anime version of you',
  ),
  cartoon(
    'AI Cartoonizer',
    Icons.mood_outlined,
    'create a cartoon version of you',
  ),
  transform(
    'AI Transform',
    Icons.auto_fix_high_outlined,
    'transform it as you want',
    ToolStep.mask,
  ),
  room(
    'AI Room Design',
    Icons.chair_outlined,
    'redesign your room',
    ToolStep.configure,
  ),
  enhance('AI Photo Enhancer', Icons.auto_awesome, 'enhance it for you'),
  erase(
    'AI Magic Eraser',
    Icons.cleaning_services_outlined,
    'erase the part or object you select',
    ToolStep.mask,
  ),
  expression(
    'AI Change Facial Expressions',
    Icons.sentiment_satisfied_alt,
    'change the facial expression',
    ToolStep.configure,
  ),
  hair(
    'AI Hairstyle Changer',
    Icons.face_3_outlined,
    'change the hairstyle',
    ToolStep.configure,
  ),
  remove(
    'AI Background Remover',
    Icons.layers_clear_outlined,
    'remove the background for you',
  ),
  background(
    'AI Background Changer',
    Icons.landscape_outlined,
    'change the background for you',
    ToolStep.configure,
  ),
  sky(
    'AI Sky Background Replacer',
    Icons.cloud_outlined,
    'replace the sky',
    ToolStep.configure,
  ),
  color('AI Photo Colorizer', Icons.palette_outlined, 'colorize it');

  const PhotoTool(
    this.label,
    this.icon, [
    this.purpose = '',
    this.step = ToolStep.generate,
  ]);
  final String label;
  final IconData icon;
  final String purpose;
  final ToolStep step;

  String get cover => 'tile$index.webp';
  String get sample => 'sample$index.webp';
  String get result => 'result$index.webp';

  String get uploadAction => switch (this) {
    enhance => 'Enhance',
    remove => 'Remove Background',
    color => 'Colorize',
    _ => step == ToolStep.generate ? 'Generate' : 'Continue',
  };

  String? get repeat => switch (this) {
    erase => 'Erase More',
    expression => 'Change Expression',
    hair => 'Change Hairstyle',
    background => 'Change Background',
    sky => 'Change Sky',
    _ => null,
  };

  List<String> get variants => switch (this) {
    scene => const ['Ancient', 'Coral', 'Old Times', 'Greenish'],
    color => const ['Hefe', 'Sierra', 'Walden', 'Sutro', 'Greeno'],
    remove || erase || expression || hair || background || sky => const [],
    _ => const ['Base', 'V2', 'V3', 'V4'],
  };
}

const _filterMatrices = <List<double>>[
  [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0],
  [
    .39,
    .77,
    .19,
    0,
    0,
    .35,
    .69,
    .17,
    0,
    0,
    .27,
    .53,
    .13,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ],
  [
    .21,
    .72,
    .07,
    0,
    0,
    .21,
    .72,
    .07,
    0,
    0,
    .21,
    .72,
    .07,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ],
  [1.09, 0, 0, 0, 4, 0, 1.02, 0, 0, 0, 0, 0, .94, 0, 3, 0, 0, 0, 1, 0],
  [.93, 0, 0, 0, 0, 0, 1.06, 0, 0, 6, 0, 0, 1.10, 0, 8, 0, 0, 0, 1, 0],
];

ColorFilter? photoFilter(int index, {double brightness = 0}) {
  if (index == 0 && brightness == 0) return null;
  final values = [..._filterMatrices[index]];
  for (final channel in [4, 9, 14]) {
    values[channel] += brightness;
  }
  return ColorFilter.matrix(values);
}
