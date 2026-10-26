class FoodEntry {
  final String id;
  final String name;
  final int calories;
  final double servings;
  final DateTime time;

  const FoodEntry({
    required this.id,
    required this.name,
    required this.calories,
    required this.servings,
    required this.time,
  });

  int get totalCalories => (calories * servings).round();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'calories': calories,
        'servings': servings,
        'time': time.toIso8601String(),
      };

  factory FoodEntry.fromJson(Map<String, dynamic> json) => FoodEntry(
        id: json['id'] as String,
        name: json['name'] as String,
        calories: json['calories'] as int,
        servings: (json['servings'] as num).toDouble(),
        time: DateTime.parse(json['time'] as String),
      );
}

class ExerciseEntry {
  final String id;
  final String name;
  final int minutes;
  final int caloriesBurned;
  final DateTime time;

  const ExerciseEntry({
    required this.id,
    required this.name,
    required this.minutes,
    required this.caloriesBurned,
    required this.time,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'minutes': minutes,
        'caloriesBurned': caloriesBurned,
        'time': time.toIso8601String(),
      };

  factory ExerciseEntry.fromJson(Map<String, dynamic> json) => ExerciseEntry(
        id: json['id'] as String,
        name: json['name'] as String,
        minutes: json['minutes'] as int,
        caloriesBurned: json['caloriesBurned'] as int,
        time: DateTime.parse(json['time'] as String),
      );
}

class WaterEntry {
  final int ml;
  final DateTime time;

  const WaterEntry({required this.ml, required this.time});

  Map<String, dynamic> toJson() => {'ml': ml, 'time': time.toIso8601String()};

  factory WaterEntry.fromJson(Map<String, dynamic> json) => WaterEntry(
        ml: json['ml'] as int,
        time: DateTime.parse(json['time'] as String),
      );
}
