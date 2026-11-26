import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'course.dart';

int localDay(DateTime time) =>
    DateTime.utc(time.year, time.month, time.day).millisecondsSinceEpoch ~/
    Duration.millisecondsPerDay;

class ProgressStore {
  ProgressStore(String email) : _key = 'lingoshark.progress.v1.$email';

  final _preferences = SharedPreferencesAsync();
  final String _key;

  Future<LearningProgress> load() async {
    final raw = await _preferences.getString(_key);
    return raw == null
        ? const LearningProgress()
        : LearningProgress.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(LearningProgress progress) =>
      _preferences.setString(_key, jsonEncode(progress.toJson()));
}

class LearningProgress {
  const LearningProgress({
    this.completed = const {},
    this.xp = 0,
    this.gems = 0,
    this.streak = 0,
    this.lastDay,
    this.lessonsToday = 0,
    this.claimDay,
    this.freezes = 0,
    this.displayName,
    this.dailyGoal,
    this.motion = true,
  });

  factory LearningProgress.fromJson(Map<String, dynamic> data) {
    return LearningProgress(
      completed: Set<String>.from(data['completed'] as List? ?? []),
      xp: data['xp'] as int? ?? 0,
      gems: data['gems'] as int? ?? 0,
      streak: data['streak'] as int? ?? 0,
      lastDay: data['lastDay'] as int?,
      lessonsToday: data['lessonsToday'] as int? ?? 0,
      claimDay: data['claimDay'] as int?,
      freezes: data['freezes'] as int? ?? 0,
      displayName: data['displayName'] as String?,
      dailyGoal: data['dailyGoal'] as int?,
      motion: data['motion'] as bool? ?? true,
    );
  }

  final Set<String> completed;
  final int xp;
  final int gems;
  final int streak;
  final int? lastDay;
  final int lessonsToday;
  final int? claimDay;
  final int freezes;
  final String? displayName;
  final int? dailyGoal;
  final bool motion;

  Map<String, dynamic> toJson() => {
    'completed': completed.toList(),
    'xp': xp,
    'gems': gems,
    'streak': streak,
    'lastDay': lastDay,
    'lessonsToday': lessonsToday,
    'claimDay': claimDay,
    'freezes': freezes,
    'displayName': displayName,
    'dailyGoal': dailyGoal,
    'motion': motion,
  };

  int lessonsOn(int day) => lastDay == day ? lessonsToday : 0;

  int activeStreak(int day) {
    if (lastDay == null) return 0;
    final gap = day - lastDay!;
    return gap <= 1 || (gap == 2 && freezes > 0) ? streak : 0;
  }

  int rewardXp(String lessonId, bool perfect, {int? level}) {
    if (completed.contains(lessonId)) return 0;
    final knownIndex = lessons.indexWhere((lesson) => lesson.id == lessonId);
    final actualLevel = knownIndex < 0 ? level ?? 0 : knownIndex + 1;
    return isTreasureLevel(actualLevel) ? 250 : 25;
  }

  LearningProgress finish(
    String lessonId,
    bool perfect,
    int day, {
    int? level,
  }) {
    final first = !completed.contains(lessonId);
    final usedFreeze = lastDay == day - 2 && freezes > 0;
    return copyWith(
      completed: {...completed, lessonId},
      xp: xp + rewardXp(lessonId, perfect, level: level),
      gems: gems + (first ? 10 : 0),
      streak: lastDay == day ? streak : activeStreak(day) + 1,
      lastDay: day,
      lessonsToday: lessonsOn(day) + 1,
      freezes: freezes - (usedFreeze ? 1 : 0),
    );
  }

  LearningProgress copyWith({
    Set<String>? completed,
    int? xp,
    int? gems,
    int? streak,
    int? lastDay,
    int? lessonsToday,
    int? claimDay,
    int? freezes,
    String? displayName,
    int? dailyGoal,
    bool? motion,
  }) {
    return LearningProgress(
      completed: completed ?? this.completed,
      xp: xp ?? this.xp,
      gems: gems ?? this.gems,
      streak: streak ?? this.streak,
      lastDay: lastDay ?? this.lastDay,
      lessonsToday: lessonsToday ?? this.lessonsToday,
      claimDay: claimDay ?? this.claimDay,
      freezes: freezes ?? this.freezes,
      displayName: displayName ?? this.displayName,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      motion: motion ?? this.motion,
    );
  }
}
