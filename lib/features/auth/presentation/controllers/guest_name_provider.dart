import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Temporary identity entered at the start of the guest flow.
final guestNameProvider = StateProvider<String?>((ref) => null);

final guestAgeProvider = StateProvider<int?>((ref) => null);
final guestGenderProvider = StateProvider<String?>((ref) => null);
