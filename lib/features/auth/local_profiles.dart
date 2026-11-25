import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LearnerProfile {
  const LearnerProfile({
    required this.name,
    required this.email,
    this.level = 'Pemula',
    this.dailyGoal = 1,
  });

  final String name;
  final String email;
  final String level;
  final int dailyGoal;
}

class LocalProfiles {
  final _preferences = SharedPreferencesAsync();

  Future<LearnerProfile?> register({
    required String name,
    required String email,
    required String password,
    String level = 'Pemula',
    int dailyGoal = 1,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final key = _key(normalizedEmail);
    if (await _preferences.getString(key) != null) return null;

    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256));
    final verifier = await compute(_deriveVerifier, (password, salt));
    final profile = LearnerProfile(
      name: name.trim(),
      email: normalizedEmail,
      level: level,
      dailyGoal: dailyGoal,
    );

    await _preferences.setString(
      key,
      jsonEncode({
        'name': profile.name,
        'salt': base64Encode(salt),
        'verifier': base64Encode(verifier),
        'level': level,
        'dailyGoal': dailyGoal,
      }),
    );
    return profile;
  }

  Future<LearnerProfile?> signIn({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final stored = await _preferences.getString(_key(normalizedEmail));
    if (stored == null) return null;

    final data = jsonDecode(stored) as Map<String, dynamic>;
    final salt = base64Decode(data['salt'] as String);
    final expected = base64Decode(data['verifier'] as String);
    final actual = await compute(_deriveVerifier, (password, salt));
    if (actual.length != expected.length) return null;
    var difference = 0;
    for (var i = 0; i < expected.length; i++) {
      difference |= expected[i] ^ actual[i];
    }
    if (difference != 0) return null;

    return LearnerProfile(
      name: data['name'] as String,
      email: normalizedEmail,
      level: data['level'] as String? ?? 'Pemula',
      dailyGoal: data['dailyGoal'] as int? ?? 1,
    );
  }

  String _key(String email) => 'lingoshark.demoProfile.v1.$email';
}

Future<List<int>> _deriveVerifier((String, List<int>) input) async {
  final (password, salt) = input;
  final algorithm = Pbkdf2.hmacSha256(iterations: 120000, bits: 256);
  final key = await algorithm.deriveKeyFromPassword(
    password: password,
    nonce: salt,
  );
  return key.extractBytes();
}
