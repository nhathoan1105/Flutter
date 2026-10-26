import 'package:flutter_app/models/user_profile.dart';
import 'package:flutter_app/models/water.dart';
import 'package:flutter_app/services/app_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const profile = UserProfile(
    gender: Gender.male,
    age: 30,
    heightCm: 175,
    weightKg: 70,
    activityLevel: ActivityLevel.moderate,
    goal: Goal.maintain,
  );

  test('water goal scales with weight and exercise', () {
    expect(waterGoalMl(profile, 0), 2450); // 70 * 35
    expect(waterGoalMl(profile, 30), 2800); // + 360, rounded to 50
  });

  test('reminder hours span the active window', () {
    const s = WaterSettings(startHour: 8, endHour: 21, intervalHours: 3);
    expect(s.reminderHours, [8, 11, 14, 17, 20]);
  });

  test('overdue only inside active hours and after an interval', () {
    const s = WaterSettings(startHour: 8, endHour: 21, intervalHours: 2);
    final day = DateTime(2026, 10, 24);
    DateTime at(int h, [int m = 0]) => day.add(Duration(hours: h, minutes: m));

    expect(isWaterOverdue(s, at(6), null), isFalse); // before start
    expect(isWaterOverdue(s, at(9), null), isFalse); // 1h into the day
    expect(isWaterOverdue(s, at(10), null), isTrue); // 2h, nothing drunk
    expect(isWaterOverdue(s, at(14), at(13)), isFalse);
    expect(isWaterOverdue(s, at(15, 30), at(13)), isTrue);
    expect(isWaterOverdue(s, at(22, 30), at(13)), isFalse); // after end
  });

  test('logs saved before water tracking still load', () {
    final log = DayLog.fromJson({'foods': [], 'exercises': []});
    expect(log.waterMl, 0);
    expect(log.isEmpty, isTrue);
  });
}
