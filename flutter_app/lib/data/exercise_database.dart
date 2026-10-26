import 'package:flutter/material.dart';

enum ExerciseType {
  cardio('Cardio'),
  strength('Sức mạnh'),
  flexibility('Dẻo dai'),
  sport('Thể thao');

  const ExerciseType(this.label);
  final String label;
}

enum Intensity {
  low('Nhẹ'),
  moderate('Vừa'),
  high('Cao');

  const Intensity(this.label);
  final String label;
}

class Exercise {
  final String name;

  /// Metabolic equivalent (Compendium of Physical Activities).
  final double met;
  final ExerciseType type;
  final Intensity intensity;

  /// Gentle on joints — suitable for high BMI or older users.
  final bool lowImpact;
  final IconData icon;
  final String tip;

  const Exercise({
    required this.name,
    required this.met,
    required this.type,
    required this.intensity,
    required this.lowImpact,
    required this.icon,
    required this.tip,
  });

  double caloriesPerMinute(double weightKg) => met * 3.5 * weightKg / 200;

  int caloriesFor(int minutes, double weightKg) =>
      (caloriesPerMinute(weightKg) * minutes).round();

  int minutesToBurn(int calories, double weightKg) =>
      (calories / caloriesPerMinute(weightKg)).ceil();
}

const exerciseDatabase = <Exercise>[
  Exercise(
    name: 'Đi bộ nhanh',
    met: 4.3,
    type: ExerciseType.cardio,
    intensity: Intensity.low,
    lowImpact: true,
    icon: Icons.directions_walk,
    tip: 'Giữ tốc độ ~6 km/h, vừa đủ để thở nhanh nhưng vẫn nói chuyện được.',
  ),
  Exercise(
    name: 'Chạy bộ',
    met: 8.0,
    type: ExerciseType.cardio,
    intensity: Intensity.high,
    lowImpact: false,
    icon: Icons.directions_run,
    tip: 'Khởi động 5 phút, chạy ~8 km/h. Mang giày có đệm tốt.',
  ),
  Exercise(
    name: 'Đạp xe',
    met: 6.8,
    type: ExerciseType.cardio,
    intensity: Intensity.moderate,
    lowImpact: true,
    icon: Icons.directions_bike,
    tip: 'Tốc độ 16–19 km/h. Chỉnh yên vừa chiều cao để bảo vệ đầu gối.',
  ),
  Exercise(
    name: 'Bơi lội',
    met: 6.0,
    type: ExerciseType.cardio,
    intensity: Intensity.moderate,
    lowImpact: true,
    icon: Icons.pool,
    tip: 'Rất tốt cho khớp. Bắt đầu với bơi ếch nhẹ nhàng.',
  ),
  Exercise(
    name: 'Nhảy dây',
    met: 11.0,
    type: ExerciseType.cardio,
    intensity: Intensity.high,
    lowImpact: false,
    icon: Icons.sports_gymnastics,
    tip: 'Chia hiệp 1 phút nhảy / 30 giây nghỉ. Đốt calo rất nhanh.',
  ),
  Exercise(
    name: 'HIIT',
    met: 8.0,
    type: ExerciseType.cardio,
    intensity: Intensity.high,
    lowImpact: false,
    icon: Icons.local_fire_department,
    tip: '30 giây hết sức / 30 giây nghỉ. Tiếp tục đốt calo sau khi tập.',
  ),
  Exercise(
    name: 'Aerobic / Zumba',
    met: 6.5,
    type: ExerciseType.cardio,
    intensity: Intensity.moderate,
    lowImpact: false,
    icon: Icons.music_note,
    tip: 'Tập theo video trên mạng tại nhà, vui và dễ duy trì.',
  ),
  Exercise(
    name: 'Tập tạ',
    met: 5.0,
    type: ExerciseType.strength,
    intensity: Intensity.moderate,
    lowImpact: true,
    icon: Icons.fitness_center,
    tip: '3 hiệp × 8–12 lần mỗi bài. Tăng tạ dần để phát triển cơ.',
  ),
  Exercise(
    name: 'Bodyweight (hít đất, squat, plank)',
    met: 3.8,
    type: ExerciseType.strength,
    intensity: Intensity.moderate,
    lowImpact: true,
    icon: Icons.accessibility_new,
    tip: 'Không cần dụng cụ. Làm vòng: 10 hít đất, 15 squat, 30 giây plank.',
  ),
  Exercise(
    name: 'Yoga',
    met: 2.5,
    type: ExerciseType.flexibility,
    intensity: Intensity.low,
    lowImpact: true,
    icon: Icons.self_improvement,
    tip: 'Giúp dẻo dai, giảm căng thẳng và ngủ ngon hơn.',
  ),
  Exercise(
    name: 'Pilates',
    met: 3.0,
    type: ExerciseType.flexibility,
    intensity: Intensity.low,
    lowImpact: true,
    icon: Icons.airline_seat_flat,
    tip: 'Tăng sức mạnh cơ lõi và cải thiện tư thế.',
  ),
  Exercise(
    name: 'Leo cầu thang',
    met: 8.8,
    type: ExerciseType.cardio,
    intensity: Intensity.high,
    lowImpact: false,
    icon: Icons.stairs,
    tip: 'Tận dụng cầu thang chung cư/văn phòng, đi chậm nếu mới bắt đầu.',
  ),
  Exercise(
    name: 'Cầu lông',
    met: 5.5,
    type: ExerciseType.sport,
    intensity: Intensity.moderate,
    lowImpact: false,
    icon: Icons.sports_tennis,
    tip: 'Rủ bạn bè chơi buổi tối — vừa vận động vừa giải trí.',
  ),
  Exercise(
    name: 'Bóng đá',
    met: 7.0,
    type: ExerciseType.sport,
    intensity: Intensity.high,
    lowImpact: false,
    icon: Icons.sports_soccer,
    tip: 'Khởi động kỹ cổ chân và đầu gối trước khi đá.',
  ),
];
