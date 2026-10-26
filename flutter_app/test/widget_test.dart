import 'package:flutter_app/data/exercise_database.dart';
import 'package:flutter_app/models/log_entries.dart';
import 'package:flutter_app/models/user_profile.dart';
import 'package:flutter_app/services/app_state.dart';
import 'package:flutter_app/services/recommendation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const profile = UserProfile(
    gender: Gender.male,
    age: 30,
    heightCm: 175,
    weightKg: 70,
    activityLevel: ActivityLevel.moderate,
    goal: Goal.lose,
  );

  test('BMR, TDEE and target use Mifflin-St Jeor', () {
    // 10*70 + 6.25*175 - 5*30 + 5 = 1648.75
    expect(profile.bmr, closeTo(1648.75, 0.01));
    expect(profile.tdee, closeTo(1648.75 * 1.55, 0.01));
    expect(profile.targetCalories, (1648.75 * 1.55 - 500).round());
    expect(profile.bmi, closeTo(22.86, 0.01));
  });

  test('target never drops below the safe minimum', () {
    const small = UserProfile(
      gender: Gender.female,
      age: 60,
      heightCm: 150,
      weightKg: 45,
      activityLevel: ActivityLevel.sedentary,
      goal: Goal.lose,
    );
    expect(small.targetCalories, 1200);
  });

  test('exercise calories follow MET formula', () {
    final run = exerciseDatabase.firstWhere((e) => e.name == 'Chạy bộ');
    // 8 MET * 3.5 * 70 / 200 = 9.8 kcal/min
    expect(run.caloriesFor(30, 70), 294);
    expect(run.minutesToBurn(294, 70), 30);
  });

  test('surplus drives burn target; high BMI gets low-impact only', () {
    const heavy = UserProfile(
      gender: Gender.male,
      age: 35,
      heightCm: 170,
      weightKg: 95,
      activityLevel: ActivityLevel.sedentary,
      goal: Goal.lose,
    );
    final log = DayLog(foods: [
      FoodEntry(
        id: '1',
        name: 'Big meal',
        calories: heavy.targetCalories + 600,
        servings: 1,
        time: DateTime(2026),
      ),
    ]);
    final rec = buildRecommendation(heavy, log);
    expect(rec.burnTarget, 600);
    expect(rec.suggestions, isNotEmpty);
    expect(rec.suggestions.every((s) => s.exercise.lowImpact), isTrue);
  });
}
