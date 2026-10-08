import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Guest identity restored from the 30-day device session at startup.
final guestNameProvider = StateProvider<String?>((ref) => null);

final guestAgeProvider = StateProvider<int?>((ref) => null);
final guestGenderProvider = StateProvider<String?>((ref) => null);
