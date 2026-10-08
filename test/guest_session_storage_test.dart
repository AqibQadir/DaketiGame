import 'package:daketi_phase1_modular/features/auth/data/guest_session_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('name persists across instances for 30 days then expires', () async {
    final start = DateTime.utc(2026, 10, 8);
    await GuestSessionStorage().save(' Ali ', now: start);
    expect(await GuestSessionStorage().read(now: start.add(const Duration(days: 7))), 'Ali');
    expect(await GuestSessionStorage().read(now: start.add(const Duration(days: 29))), 'Ali');
    expect(await GuestSessionStorage().read(now: start.add(const Duration(days: 30))), isNull);
    expect((await SharedPreferences.getInstance()).containsKey(GuestSessionStorage.key), isFalse);
  });
  test('invalid session is safely removed', () async {
    SharedPreferences.setMockInitialValues({GuestSessionStorage.key: 'broken'});
    expect(await GuestSessionStorage().read(), isNull);
  });
}
