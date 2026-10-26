enum Gender {
  male('Nam'),
  female('Nữ');

  const Gender(this.label);
  final String label;
}

enum ActivityLevel {
  sedentary('Ít vận động', 'Ngồi nhiều, hầu như không tập', 1.2),
  light('Vận động nhẹ', 'Tập 1–3 buổi/tuần', 1.375),
  moderate('Vận động vừa', 'Tập 3–5 buổi/tuần', 1.55),
  active('Năng động', 'Tập 6–7 buổi/tuần', 1.725),
  veryActive('Rất năng động', 'Lao động nặng hoặc tập 2 lần/ngày', 1.9);

  const ActivityLevel(this.label, this.description, this.factor);
  final String label;
  final String description;
  final double factor;
}

enum Goal {
  lose('Giảm cân', -500),
  maintain('Giữ cân', 0),
  gain('Tăng cân', 300);

  const Goal(this.label, this.calorieAdjustment);
  final String label;
  final int calorieAdjustment;
}

class UserProfile {
  final Gender gender;
  final int age;
  final double heightCm;
  final double weightKg;
  final ActivityLevel activityLevel;
  final Goal goal;
  final double? targetWeightKg;

  const UserProfile({
    required this.gender,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.activityLevel,
    required this.goal,
    this.targetWeightKg,
  });

  UserProfile copyWith({double? weightKg}) => UserProfile(
        gender: gender,
        age: age,
        heightCm: heightCm,
        weightKg: weightKg ?? this.weightKg,
        activityLevel: activityLevel,
        goal: goal,
        targetWeightKg: targetWeightKg,
      );

  /// Basal metabolic rate (Mifflin-St Jeor).
  double get bmr {
    final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
    return gender == Gender.male ? base + 5 : base - 161;
  }

  /// Total daily energy expenditure.
  double get tdee => bmr * activityLevel.factor;

  /// Daily calorie target, never below a safe minimum.
  int get targetCalories {
    final minimum = gender == Gender.male ? 1500 : 1200;
    final target = tdee + goal.calorieAdjustment;
    return target < minimum ? minimum : target.round();
  }

  double get bmi => weightKg / ((heightCm / 100) * (heightCm / 100));

  String get bmiCategory {
    // Asian cut-offs (WHO Western Pacific).
    if (bmi < 18.5) return 'Thiếu cân';
    if (bmi < 23) return 'Bình thường';
    if (bmi < 25) return 'Thừa cân';
    if (bmi < 30) return 'Béo phì độ I';
    return 'Béo phì độ II';
  }

  /// Macro targets in grams: protein / carbs / fat.
  ({int protein, int carbs, int fat}) get macros {
    final proteinPerKg = switch (goal) {
      Goal.lose => 1.8,
      Goal.maintain => 1.4,
      Goal.gain => 1.8,
    };
    final protein = weightKg * proteinPerKg;
    final fat = targetCalories * 0.25 / 9;
    final carbs = (targetCalories - protein * 4 - fat * 9) / 4;
    return (
      protein: protein.round(),
      carbs: carbs < 0 ? 0 : carbs.round(),
      fat: fat.round(),
    );
  }

  Map<String, dynamic> toJson() => {
        'gender': gender.name,
        'age': age,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'activityLevel': activityLevel.name,
        'goal': goal.name,
        'targetWeightKg': targetWeightKg,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        gender: Gender.values.byName(json['gender'] as String),
        age: json['age'] as int,
        heightCm: (json['heightCm'] as num).toDouble(),
        weightKg: (json['weightKg'] as num).toDouble(),
        activityLevel:
            ActivityLevel.values.byName(json['activityLevel'] as String),
        goal: Goal.values.byName(json['goal'] as String),
        targetWeightKg: (json['targetWeightKg'] as num?)?.toDouble(),
      );
}
