import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/log_entries.dart';
import '../models/user_profile.dart';
import '../models/water.dart';
import 'notification_service.dart';

String dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class DayLog {
  final List<FoodEntry> foods;
  final List<ExerciseEntry> exercises;
  final List<WaterEntry> water;

  DayLog({
    List<FoodEntry>? foods,
    List<ExerciseEntry>? exercises,
    List<WaterEntry>? water,
  })  : foods = foods ?? [],
        exercises = exercises ?? [],
        water = water ?? [];

  bool get isEmpty => foods.isEmpty && exercises.isEmpty && water.isEmpty;

  int get consumed => foods.fold(0, (sum, f) => sum + f.totalCalories);
  int get burned => exercises.fold(0, (sum, e) => sum + e.caloriesBurned);
  int get exerciseMinutes => exercises.fold(0, (sum, e) => sum + e.minutes);
  int get waterMl => water.fold(0, (sum, w) => sum + w.ml);
  DateTime? get lastDrink => water.isEmpty ? null : water.last.time;

  Map<String, dynamic> toJson() => {
        'foods': foods.map((f) => f.toJson()).toList(),
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'water': water.map((w) => w.toJson()).toList(),
      };

  factory DayLog.fromJson(Map<String, dynamic> json) => DayLog(
        foods: (json['foods'] as List)
            .map((f) => FoodEntry.fromJson(f as Map<String, dynamic>))
            .toList(),
        exercises: (json['exercises'] as List)
            .map((e) => ExerciseEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        // Logs saved before water tracking existed have no 'water' key.
        water: ((json['water'] as List?) ?? [])
            .map((w) => WaterEntry.fromJson(w as Map<String, dynamic>))
            .toList(),
      );
}

class AppState extends ChangeNotifier {
  static const _profileKey = 'profile';
  static const _logsKey = 'logs';
  static const _weightsKey = 'weights';
  static const _waterSettingsKey = 'waterSettings';

  late SharedPreferences _prefs;
  UserProfile? profile;
  final Map<String, DayLog> _logs = {};
  final Map<String, double> _weights = {};
  WaterSettings waterSettings = const WaterSettings();
  DateTime selectedDate = DateTime.now();

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final rawProfile = _prefs.getString(_profileKey);
    if (rawProfile != null) {
      profile = UserProfile.fromJson(jsonDecode(rawProfile));
    }
    final rawLogs = _prefs.getString(_logsKey);
    if (rawLogs != null) {
      (jsonDecode(rawLogs) as Map<String, dynamic>).forEach((key, value) {
        _logs[key] = DayLog.fromJson(value as Map<String, dynamic>);
      });
    }
    final rawWeights = _prefs.getString(_weightsKey);
    if (rawWeights != null) {
      (jsonDecode(rawWeights) as Map<String, dynamic>).forEach((key, value) {
        _weights[key] = (value as num).toDouble();
      });
    } else if (profile != null) {
      _weights[dateKey(DateTime.now())] = profile!.weightKg;
    }
    final rawWater = _prefs.getString(_waterSettingsKey);
    if (rawWater != null) {
      waterSettings = WaterSettings.fromJson(jsonDecode(rawWater));
    }
  }

  int get waterGoal => waterGoalMl(profile!, today.exerciseMinutes);

  Future<void> addWater(int ml) async {
    today.water.add(WaterEntry(ml: ml, time: DateTime.now()));
    await _persistLogs();
  }

  Future<void> undoWater() async {
    if (today.water.isEmpty) return;
    today.water.removeLast();
    await _persistLogs();
  }

  Future<void> saveWaterSettings(WaterSettings s) async {
    waterSettings = s;
    await _prefs.setString(_waterSettingsKey, jsonEncode(s.toJson()));
    notifyListeners();
    await NotificationService.scheduleWaterReminders(s);
  }

  /// Weigh-ins sorted oldest first.
  List<({DateTime date, double kg})> get weightHistory {
    final entries = _weights.entries
        .map((e) => (date: DateTime.parse(e.key), kg: e.value))
        .toList();
    entries.sort((a, b) => a.date.compareTo(b.date));
    return entries;
  }

  Future<void> logWeight(DateTime date, double kg) async {
    _weights[dateKey(date)] = kg;
    await _syncProfileWeight();
    await _persistWeights();
  }

  Future<void> removeWeight(DateTime date) async {
    _weights.remove(dateKey(date));
    await _syncProfileWeight();
    await _persistWeights();
  }

  /// Keeps calorie targets based on the most recent weigh-in.
  Future<void> _syncProfileWeight() async {
    final history = weightHistory;
    if (profile == null || history.isEmpty) return;
    if (history.last.kg != profile!.weightKg) {
      await _writeProfile(profile!.copyWith(weightKg: history.last.kg));
    }
  }

  Future<void> _persistWeights() async {
    await _prefs.setString(_weightsKey, jsonEncode(_weights));
    notifyListeners();
  }

  DayLog get today => _logs.putIfAbsent(dateKey(selectedDate), DayLog.new);

  bool get isViewingToday => dateKey(selectedDate) == dateKey(DateTime.now());

  void shiftDate(int days) {
    final next = selectedDate.add(Duration(days: days));
    if (next.isAfter(DateTime.now())) return;
    selectedDate = next;
    notifyListeners();
  }

  Future<void> saveProfile(UserProfile p) async {
    final weightChanged = profile?.weightKg != p.weightKg;
    await _writeProfile(p);
    if (weightChanged) {
      // Editing weight in the profile counts as today's weigh-in.
      _weights[dateKey(DateTime.now())] = p.weightKg;
      await _persistWeights();
    }
    notifyListeners();
  }

  Future<void> _writeProfile(UserProfile p) async {
    profile = p;
    await _prefs.setString(_profileKey, jsonEncode(p.toJson()));
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  Future<void> addFood(String name, int calories, double servings) async {
    today.foods.add(FoodEntry(
      id: _newId(),
      name: name,
      calories: calories,
      servings: servings,
      time: DateTime.now(),
    ));
    await _persistLogs();
  }

  Future<void> removeFood(String id) async {
    today.foods.removeWhere((f) => f.id == id);
    await _persistLogs();
  }

  Future<void> addExercise(String name, int minutes, int calories) async {
    today.exercises.add(ExerciseEntry(
      id: _newId(),
      name: name,
      minutes: minutes,
      caloriesBurned: calories,
      time: DateTime.now(),
    ));
    await _persistLogs();
  }

  Future<void> removeExercise(String id) async {
    today.exercises.removeWhere((e) => e.id == id);
    await _persistLogs();
  }

  Future<void> _persistLogs() async {
    _logs.removeWhere((_, log) => log.isEmpty);
    await _prefs.setString(
      _logsKey,
      jsonEncode(_logs.map((k, v) => MapEntry(k, v.toJson()))),
    );
    notifyListeners();
  }
}

/// Exposes [AppState] to the widget tree and rebuilds dependents on change.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
