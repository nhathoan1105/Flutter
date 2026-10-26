import 'user_profile.dart';

class WaterSettings {
  final bool remindersEnabled;
  final int startHour;
  final int endHour;
  final int intervalHours;
  final int glassMl;

  const WaterSettings({
    this.remindersEnabled = false,
    this.startHour = 8,
    this.endHour = 21,
    this.intervalHours = 2,
    this.glassMl = 250,
  });

  /// Daily reminder times as hours of the day, e.g. [8, 10, 12, ...].
  List<int> get reminderHours => [
        for (var h = startHour; h <= endHour; h += intervalHours) h,
      ];

  WaterSettings copyWith({
    bool? remindersEnabled,
    int? startHour,
    int? endHour,
    int? intervalHours,
    int? glassMl,
  }) =>
      WaterSettings(
        remindersEnabled: remindersEnabled ?? this.remindersEnabled,
        startHour: startHour ?? this.startHour,
        endHour: endHour ?? this.endHour,
        intervalHours: intervalHours ?? this.intervalHours,
        glassMl: glassMl ?? this.glassMl,
      );

  Map<String, dynamic> toJson() => {
        'remindersEnabled': remindersEnabled,
        'startHour': startHour,
        'endHour': endHour,
        'intervalHours': intervalHours,
        'glassMl': glassMl,
      };

  factory WaterSettings.fromJson(Map<String, dynamic> json) => WaterSettings(
        remindersEnabled: json['remindersEnabled'] as bool,
        startHour: json['startHour'] as int,
        endHour: json['endHour'] as int,
        intervalHours: json['intervalHours'] as int,
        glassMl: json['glassMl'] as int,
      );
}

/// ~35 ml per kg body weight, plus ~350 ml for every 30 minutes of exercise.
/// Rounded to the nearest 50 ml.
int waterGoalMl(UserProfile profile, int exerciseMinutes) {
  final ml = profile.weightKg * 35 + exerciseMinutes * 12;
  return (ml / 50).round() * 50;
}

/// Whether to nudge the user in-app: within active hours and it's been at
/// least one reminder interval since the last drink (or since the day began).
bool isWaterOverdue(WaterSettings s, DateTime now, DateTime? lastDrink) {
  if (now.hour < s.startHour || now.hour > s.endHour) return false;
  final since =
      lastDrink ?? DateTime(now.year, now.month, now.day, s.startHour);
  return now.difference(since) >= Duration(hours: s.intervalHours);
}
