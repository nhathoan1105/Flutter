import 'package:flutter_app/models/user_profile.dart';
import 'package:flutter_app/services/app_state.dart';
import 'package:flutter_app/services/weight_stats.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('startOfWeek returns Monday at midnight', () {
    // 2026-10-24 is a Saturday.
    expect(startOfWeek(DateTime(2026, 10, 24, 15)), DateTime(2026, 10, 19));
    expect(startOfWeek(DateTime(2026, 10, 19)), DateTime(2026, 10, 19));
  });

  test('weeklyAverages groups by week and drops old weeks', () {
    final history = [
      (date: DateTime(2026, 8, 1), kg: 80.0), // outside 4-week window
      (date: DateTime(2026, 10, 6), kg: 72.0),
      (date: DateTime(2026, 10, 8), kg: 71.0),
      (date: DateTime(2026, 10, 20), kg: 70.0),
    ];
    final weekly =
        weeklyAverages(history, weeks: 4, now: DateTime(2026, 10, 24));
    expect(weekly.map((w) => w.weekStart),
        [DateTime(2026, 10, 5), DateTime(2026, 10, 19)]);
    expect(weekly.first.average, 71.5);
    expect(weekly.first.count, 2);
    expect(weekly.last.average, 70.0);
  });

  test('logging a past weigh-in does not create a fake entry for today',
      () async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState();
    await state.load();
    await state.saveProfile(const UserProfile(
      gender: Gender.female,
      age: 28,
      heightCm: 160,
      weightKg: 60,
      activityLevel: ActivityLevel.light,
      goal: Goal.lose,
    ));
    await state.removeWeight(DateTime.now());
    final past = DateTime.now().subtract(const Duration(days: 10));
    await state.logWeight(past, 62);

    expect(state.weightHistory.length, 1);
    expect(state.profile!.weightKg, 62);
  });
}
