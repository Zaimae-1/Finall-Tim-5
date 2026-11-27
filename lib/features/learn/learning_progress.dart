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
    this.dailyClaims = const {},
    this.milestoneClaims = const {},
    this.freezes = 0,
    this.displayName,
    this.dailyGoal,
    this.motion = true,
    this.ownedAvatars = const {},
    this.avatarId = -1,
    this.ownedSkins = const {},
    this.skinId = -1,
    this.boosters = const {},
    this.activeBoost = 0,
    this.boostUntil,
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
      dailyClaims: Set<String>.from(data['dailyClaims'] as List? ?? []),
      milestoneClaims: Set<int>.from(data['milestoneClaims'] as List? ?? []),
      freezes: data['freezes'] as int? ?? 0,
      displayName: data['displayName'] as String?,
      dailyGoal: data['dailyGoal'] as int?,
      motion: data['motion'] as bool? ?? true,
      ownedAvatars: Set<int>.from(data['ownedAvatars'] as List? ?? []),
      avatarId: data['avatarId'] as int? ?? -1,
      ownedSkins: Set<int>.from(data['ownedSkins'] as List? ?? []),
      skinId: data['skinId'] as int? ?? -1,
      boosters: (data['boosters'] as Map? ?? {}).map(
        (key, value) => MapEntry(int.parse(key.toString()), value as int),
      ),
      activeBoost: data['activeBoost'] as int? ?? 0,
      boostUntil: data['boostUntil'] as int?,
    );
  }

  final Set<String> completed;
  final int xp;
  final int gems;
  final int streak;
  final int? lastDay;
  final int lessonsToday;
  final int? claimDay;
  final Set<String> dailyClaims;
  final Set<int> milestoneClaims;
  final int freezes;
  final String? displayName;
  final int? dailyGoal;
  final bool motion;
  final Set<int> ownedAvatars;
  final int avatarId;
  final Set<int> ownedSkins;
  final int skinId;
  final Map<int, int> boosters;
  final int activeBoost;

  /// Epoch milliseconds when the running XP booster expires.
  final int? boostUntil;

  static const boostDuration = Duration(minutes: 5);

  Map<String, dynamic> toJson() => {
    'completed': completed.toList(),
    'xp': xp,
    'gems': gems,
    'streak': streak,
    'lastDay': lastDay,
    'lessonsToday': lessonsToday,
    'claimDay': claimDay,
    'dailyClaims': dailyClaims.toList(),
    'milestoneClaims': milestoneClaims.toList(),
    'freezes': freezes,
    'displayName': displayName,
    'dailyGoal': dailyGoal,
    'motion': motion,
    'ownedAvatars': ownedAvatars.toList(),
    'avatarId': avatarId,
    'ownedSkins': ownedSkins.toList(),
    'skinId': skinId,
    'boosters': boosters.map((key, value) => MapEntry('$key', value)),
    'activeBoost': activeBoost,
    'boostUntil': boostUntil,
  };

  int lessonsOn(int day) => lastDay == day ? lessonsToday : 0;

  bool dailyClaimed(String id, int day) =>
      (claimDay == day && id == 'goal') || dailyClaims.contains('$day:$id');

  LearningProgress claimDaily(String id, int day, int target, int reward) {
    if (target < 1 ||
        reward < 1 ||
        dailyClaimed(id, day) ||
        lessonsOn(day) < target) {
      return this;
    }
    return copyWith(
      gems: gems + reward,
      dailyClaims: {
        for (final key in dailyClaims)
          if (key.startsWith('$day:')) key,
        '$day:$id',
      },
      claimDay: id == 'goal' ? day : claimDay,
    );
  }

  LearningProgress claimMilestone(int target, int reward) {
    if (target < 1 ||
        reward < 1 ||
        completed.length < target ||
        milestoneClaims.contains(target)) {
      return this;
    }
    return copyWith(
      gems: gems + reward,
      milestoneClaims: {...milestoneClaims, target},
    );
  }

  int activeStreak(int day) {
    if (lastDay == null) return 0;
    final gap = day - lastDay!;
    return gap <= 1 || (gap == 2 && freezes > 0) ? streak : 0;
  }

  int boostRemainingMs(int nowMs) {
    final until = boostUntil;
    if (until == null || activeBoost == 0) return 0;
    return until > nowMs ? until - nowMs : 0;
  }

  int boostPercentAt(int nowMs) =>
      boostRemainingMs(nowMs) > 0 ? activeBoost : 0;

  int rewardXp(String lessonId, bool perfect, {int? level, int? nowMs}) {
    if (completed.contains(lessonId)) return 0;
    final actualLevel = _levelOf(lessonId, level);
    final base = isTreasureLevel(actualLevel) ? 250 : 25;
    final percent = boostPercentAt(nowMs ?? _now());
    return base + (percent > 0 ? (base * percent / 100).round() : 0);
  }

  static int _now() => DateTime.now().millisecondsSinceEpoch;

  int _levelOf(String lessonId, int? fallback) {
    final knownIndex = lessons.indexWhere((lesson) => lesson.id == lessonId);
    return knownIndex < 0 ? fallback ?? 0 : knownIndex + 1;
  }

  LearningProgress buyAvatar(int id) {
    if (id < 0 || id >= 5 || gems < 15 || ownedAvatars.contains(id)) {
      return this;
    }
    return copyWith(
      gems: gems - 15,
      ownedAvatars: {...ownedAvatars, id},
      avatarId: id,
    );
  }

  LearningProgress equipAvatar(int id) =>
      ownedAvatars.contains(id) ? copyWith(avatarId: id) : this;

  LearningProgress buySkin(int id) {
    if (id < 0 || id >= 5 || gems < 25 || ownedSkins.contains(id)) return this;
    return copyWith(
      gems: gems - 25,
      ownedSkins: {...ownedSkins, id},
      skinId: id,
    );
  }

  LearningProgress equipSkin(int id) =>
      ownedSkins.contains(id) ? copyWith(skinId: id) : this;

  static int boostPrice(int percent) => switch (percent) {
    5 => 10,
    7 => 15,
    10 => 20,
    _ => 0,
  };

  LearningProgress buyBoost(int percent) {
    final price = boostPrice(percent);
    if (price == 0 || gems < price) return this;
    return copyWith(
      gems: gems - price,
      boosters: {...boosters, percent: (boosters[percent] ?? 0) + 1},
    );
  }

  /// Starts a 5-minute booster from stock. Only one can run at a time.
  LearningProgress activateBoost(int percent, {int? nowMs}) {
    final now = nowMs ?? _now();
    if ((boosters[percent] ?? 0) < 1 || boostRemainingMs(now) > 0) return this;
    return copyWith(
      boosters: {...boosters, percent: boosters[percent]! - 1},
      activeBoost: percent,
      boostUntil: now + boostDuration.inMilliseconds,
    );
  }

  LearningProgress finish(
    String lessonId,
    bool perfect,
    int day, {
    int? level,
    int? nowMs,
  }) {
    final first = !completed.contains(lessonId);
    final usedFreeze = lastDay == day - 2 && freezes > 0;
    return copyWith(
      completed: {...completed, lessonId},
      xp: xp + rewardXp(lessonId, perfect, level: level, nowMs: nowMs),
      gems:
          gems +
          (first ? (isTreasureLevel(_levelOf(lessonId, level)) ? 15 : 5) : 0),
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
    Set<String>? dailyClaims,
    Set<int>? milestoneClaims,
    int? freezes,
    String? displayName,
    int? dailyGoal,
    bool? motion,
    Set<int>? ownedAvatars,
    int? avatarId,
    Set<int>? ownedSkins,
    int? skinId,
    Map<int, int>? boosters,
    int? activeBoost,
    int? boostUntil,
  }) {
    return LearningProgress(
      completed: completed ?? this.completed,
      xp: xp ?? this.xp,
      gems: gems ?? this.gems,
      streak: streak ?? this.streak,
      lastDay: lastDay ?? this.lastDay,
      lessonsToday: lessonsToday ?? this.lessonsToday,
      claimDay: claimDay ?? this.claimDay,
      dailyClaims: dailyClaims ?? this.dailyClaims,
      milestoneClaims: milestoneClaims ?? this.milestoneClaims,
      freezes: freezes ?? this.freezes,
      displayName: displayName ?? this.displayName,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      motion: motion ?? this.motion,
      ownedAvatars: ownedAvatars ?? this.ownedAvatars,
      avatarId: avatarId ?? this.avatarId,
      ownedSkins: ownedSkins ?? this.ownedSkins,
      skinId: skinId ?? this.skinId,
      boosters: boosters ?? this.boosters,
      activeBoost: activeBoost ?? this.activeBoost,
      boostUntil: boostUntil ?? this.boostUntil,
    );
  }
}
