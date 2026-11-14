import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photofy/features/home.dart';
import 'package:photofy/main.dart';
import 'package:photofy/session.dart';

Future<void> goHome(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(430, 932));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(PhotofyApp(session: Session(false)));
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Skip'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Sign in with password'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField).at(0), 'demo@example.com');
  await tester.enterText(find.byType(TextFormField).at(1), 'demo1234');
  await tester.tap(find.text('Sign in'));
  await tester.pumpAndSettle();
  expect(find.text('Sign in Successful!'), findsOneWidget);
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();
  expect(find.byType(Home), findsOneWidget);
}

void main() {
  testWidgets('Sign in, choose a sample and preview an AI scene', (
    tester,
  ) async {
    await goHome(tester);
    await tester.tap(find.text('AI Scene Generator'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Upload'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use Sample'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Remove photo'), findsOneWidget);
    await tester.tap(find.text('Generate'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.text('Ancient'), findsOneWidget);
    await tester.tap(find.text('Coral'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Download'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Settings switch the theme without resetting navigation', (
    tester,
  ) async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      Session.channel,
      (MethodCall call) async => null,
    );
    addTearDown(
      () => messenger.setMockMethodCallHandler(Session.channel, null),
    );
    await goHome(tester);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('Dark Mode'))).brightness,
      Brightness.dark,
    );
    expect(find.text('Settings'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
