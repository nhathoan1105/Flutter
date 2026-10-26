import '../data/exercise_database.dart';
import '../models/user_profile.dart';
import 'app_state.dart';

class ExerciseSuggestion {
  final Exercise exercise;
  final int minutes;
  final int calories;

  const ExerciseSuggestion(this.exercise, this.minutes, this.calories);
}

class Recommendation {
  /// Calories the suggested session should burn.
  final int burnTarget;
  final String headline;
  final List<String> notes;
  final List<ExerciseSuggestion> suggestions;
  final List<String> weeklyPlan;

  const Recommendation({
    required this.burnTarget,
    required this.headline,
    required this.notes,
    required this.suggestions,
    required this.weeklyPlan,
  });
}

Recommendation buildRecommendation(UserProfile profile, DayLog log) {
  final net = log.consumed - log.burned;
  final surplus = net - profile.targetCalories;
  final notes = <String>[];

  final baseline = switch (profile.goal) {
    Goal.lose => 300,
    Goal.maintain => 200,
    Goal.gain => 150,
  };

  final int burnTarget;
  final String headline;
  if (surplus > 0) {
    burnTarget = surplus < baseline ? baseline : surplus;
    headline = 'Bạn đã vượt $surplus kcal so với mục tiêu. '
        'Hãy vận động để đốt khoảng $burnTarget kcal.';
  } else if (log.burned >= baseline) {
    burnTarget = 0;
    headline = 'Tuyệt vời! Hôm nay bạn đã đốt ${log.burned} kcal. '
        'Có thể nghỉ ngơi hoặc giãn cơ nhẹ.';
  } else {
    burnTarget = baseline - log.burned;
    headline = switch (profile.goal) {
      Goal.lose =>
        'Đốt thêm $burnTarget kcal hôm nay để giảm cân hiệu quả hơn.',
      Goal.maintain =>
        'Vận động khoảng $burnTarget kcal để giữ dáng và khỏe mạnh.',
      Goal.gain =>
        'Ưu tiên tập sức mạnh để tăng cơ — nhớ ăn đủ ${profile.targetCalories} kcal.',
    };
  }

  final protectJoints = profile.bmi >= 30 || profile.age >= 60;
  final avoidHighIntensity = profile.age >= 60;
  if (profile.bmi >= 30) {
    notes.add('BMI ${profile.bmi.toStringAsFixed(1)}: ưu tiên bài ít tác động '
        'lên khớp như đi bộ, đạp xe, bơi.');
  }
  if (profile.age >= 60) {
    notes.add('Trên 60 tuổi: nên tập cường độ nhẹ–vừa và hỏi ý kiến bác sĩ.');
  }
  if (profile.goal == Goal.gain) {
    notes.add('Tăng cân: hạn chế cardio dài, tập tạ 3–4 buổi/tuần.');
  }
  if (profile.goal == Goal.lose && profile.bmi < 18.5) {
    notes.add('BMI của bạn đang thấp — cân nhắc mục tiêu giữ cân thay vì giảm.');
  }

  final candidates = exerciseDatabase.where((e) {
    if (protectJoints && !e.lowImpact) return false;
    if (avoidHighIntensity && e.intensity == Intensity.high) return false;
    return true;
  }).toList();

  int score(Exercise e) {
    var s = switch ((profile.goal, e.type)) {
      (Goal.lose, ExerciseType.cardio) => 4,
      (Goal.lose, ExerciseType.strength) => 2,
      (Goal.lose, ExerciseType.sport) => 2,
      (Goal.gain, ExerciseType.strength) => 5,
      (Goal.gain, ExerciseType.flexibility) => 2,
      (Goal.maintain, ExerciseType.sport) => 3,
      (Goal.maintain, _) => 2,
      _ => 0,
    };
    // Beginners (sedentary) do better with easier options.
    if (profile.activityLevel == ActivityLevel.sedentary) {
      if (e.intensity == Intensity.low) s += 2;
      if (e.intensity == Intensity.high) s -= 2;
    }
    return s;
  }

  candidates.sort((a, b) => score(b).compareTo(score(a)));

  final sessionTarget = burnTarget > 0 ? burnTarget : 100;
  final suggestions = candidates.take(6).map((e) {
    final minutes = e.minutesToBurn(sessionTarget, profile.weightKg).clamp(10, 90);
    return ExerciseSuggestion(
        e, minutes, e.caloriesFor(minutes, profile.weightKg));
  }).toList();

  return Recommendation(
    burnTarget: burnTarget,
    headline: headline,
    notes: notes,
    suggestions: suggestions,
    weeklyPlan: _weeklyPlan(profile.goal, protectJoints),
  );
}

List<String> _weeklyPlan(Goal goal, bool protectJoints) {
  final cardio = protectJoints ? 'Đi bộ nhanh / bơi' : 'Chạy bộ / HIIT';
  return switch (goal) {
    Goal.lose => [
        'T2: $cardio 30–40 phút',
        'T3: Bodyweight toàn thân 30 phút',
        'T4: Đạp xe 40 phút',
        'T5: Tập tạ 40 phút',
        'T6: $cardio 30 phút',
        'T7: Thể thao / đi bộ dài 60 phút',
        'CN: Nghỉ hoặc yoga nhẹ',
      ],
    Goal.maintain => [
        'T2: $cardio 30 phút',
        'T3: Tập tạ 40 phút',
        'T4: Yoga 30 phút',
        'T5: Đạp xe / bơi 30 phút',
        'T6: Tập tạ 40 phút',
        'T7: Thể thao yêu thích',
        'CN: Nghỉ',
      ],
    Goal.gain => [
        'T2: Tập tạ — ngực, vai, tay sau',
        'T3: Đi bộ nhẹ 20 phút + giãn cơ',
        'T4: Tập tạ — lưng, tay trước',
        'T5: Nghỉ',
        'T6: Tập tạ — chân, mông',
        'T7: Yoga / pilates 30 phút',
        'CN: Nghỉ',
      ],
  };
}
