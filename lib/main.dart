import 'package:flutter/material.dart';

import 'features/access.dart';
import 'features/home.dart';
import 'session.dart';
import 'ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dark = await Session.channel.invokeMethod<bool>('readTheme') ?? false;
  runApp(PhotofyApp(session: Session(dark)));
}

class PhotofyApp extends StatelessWidget {
  const PhotofyApp({required this.session, super.key});
  final Session session;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: session,
    builder: (context, _) => SessionScope(
      session: session,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Photofy',
        theme: photofyTheme(Brightness.light),
        darkTheme: photofyTheme(Brightness.dark),
        themeMode: session.dark ? ThemeMode.dark : ThemeMode.light,
        home: const Intro(),
        routes: {
          '/welcome': (_) => const Welcome(),
          '/home': (_) => const Home(),
        },
      ),
    ),
  );
}
