import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Session extends ChangeNotifier {
  Session(this.dark);
  static const channel = MethodChannel('photofy/device');

  bool dark;
  bool pro = false;
  bool remember = true;
  String language = 'English (US)';
  static const defaultProfile = <String, String>{
    'Full Name': 'Andrew Ainsley',
    'Email': 'andrew.ainsley@yourdomain.com',
    'Phone Number': '+1 111 467 378 399',
    'Date of Birth': '12/27/1995',
    'Gender': 'Male',
    'Street Address': '3517 W. Gray Street, New York',
  };
  Map<String, String> profile = {...defaultProfile};
  static const defaultCards = ['•••• •••• •••• 5567', '•••• •••• •••• 8456'];
  final cards = [...defaultCards];
  final security = <String>{};

  void clearAccount() {
    profile = {...defaultProfile};
    cards
      ..clear()
      ..addAll(defaultCards);
    security.clear();
    remember = true;
    language = 'English (US)';
    pro = false;
    notifyListeners();
  }

  static Session of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SessionScope>()!.notifier!;

  void toggleTheme(bool value) {
    dark = value;
    notifyListeners();
    channel.invokeMethod<void>('theme', value);
  }

  void updateProfile(Map<String, String> changes) {
    profile = {...profile, ...changes};
    notifyListeners();
  }

  void setLanguage(String value) {
    language = value;
    notifyListeners();
  }

  void addCard(String ending) {
    cards.add('•••• •••• •••• $ending');
    notifyListeners();
  }

  void activatePro() {
    pro = true;
    notifyListeners();
  }
}

class SessionScope extends InheritedNotifier<Session> {
  const SessionScope({
    required Session session,
    required super.child,
    super.key,
  }) : super(notifier: session);
}
