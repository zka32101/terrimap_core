import 'dart:convert';
import 'package:flutter/painting.dart' show Color;
import 'progress_store.dart';

/// 地図の塗り分け用の状態。
enum RegionState { unseen, mastered, missed }

/// 称号(習得率で決まる)。表示名・文言はアプリ側で持つ。
enum RegionTitle { beginner, explorer, expert, master }

RegionTitle regionTitleFor(int mastered, int total) => switch (titleFor(mastered, total)) {
      'master' => RegionTitle.master,
      'expert' => RegionTitle.expert,
      'explorer' => RegionTitle.explorer,
      _ => RegionTitle.beginner,
    };

/// 進捗の読み出し結果。地図の色・称号・達成率をまとめて返す。
class RegionProgress {
  final Map<String, RegionState> states;
  const RegionProgress(this.states);

  int get total => states.length;
  int get masteredCount => states.values.where((s) => s == RegionState.mastered).length;
  double get ratio => total == 0 ? 0 : masteredCount / total;
  RegionTitle get title => regionTitleFor(masteredCount, total);
  RegionState stateOf(String id) => states[id] ?? RegionState.unseen;

  /// 正解済み=mastered、ミスがあって未習得=missed、それ以外=unseen。
  static Future<RegionProgress> load(ProgressStore store, String packId, Iterable<String> regionIds) async {
    final done = await store.mastered(packId);
    final miss = await store.misses(packId);
    return RegionProgress({
      for (final id in regionIds)
        id: done.contains(id)
            ? RegionState.mastered
            : (miss[id] ?? 0) > 0
                ? RegionState.missed
                : RegionState.unseen,
    });
  }
}

/// RegionMapView.colorOf に渡す既定の配色。
Color defaultRegionColor(RegionState s) => switch (s) {
      RegionState.mastered => const Color(0xFF66BB6A),
      RegionState.missed => const Color(0xFFEF9A9A),
      RegionState.unseen => const Color(0xFFECEFF1),
    };

/// 色覚に配慮した配色（赤と緑を使わない）。習得=青、ミス=オレンジ、未出題=グレー。
Color colorBlindRegionColor(RegionState s) => switch (s) {
      RegionState.mastered => const Color(0xFF1E88E5),
      RegionState.missed => const Color(0xFFFB8C00),
      RegionState.unseen => const Color(0xFFECEFF1),
    };

/// クイズの「正解」「不正解」の強調色。[colorBlind] なら青とオレンジ（赤と緑を使わない）。
Color answerCorrectColor({bool colorBlind = false}) => colorBlind ? const Color(0xFF1E88E5) : const Color(0xFF66BB6A);
Color answerWrongColor({bool colorBlind = false}) => colorBlind ? const Color(0xFFFB8C00) : const Color(0xFFEF9A9A);

/// JSONで保存・復元できる進捗ストア。保存先(Hive/SharedPreferences等)はアプリ側が選ぶ。
class JsonProgressStore implements ProgressStore {
  final _mastered = <String, Set<String>>{};
  final _misses = <String, Map<String, int>>{};

  JsonProgressStore();

  factory JsonProgressStore.fromJson(String src) {
    final s = JsonProgressStore();
    final m = jsonDecode(src) as Map<String, dynamic>;
    (m['mastered'] as Map<String, dynamic>? ?? {}).forEach((p, l) => s._mastered[p] = {...(l as List).cast<String>()});
    (m['misses'] as Map<String, dynamic>? ?? {}).forEach(
        (p, v) => s._misses[p] = (v as Map<String, dynamic>).map((k, n) => MapEntry(k, n as int)));
    return s;
  }

  String toJson() => jsonEncode({
        'mastered': {for (final e in _mastered.entries) e.key: e.value.toList()..sort()},
        'misses': _misses,
      });

  @override
  Future<Set<String>> mastered(String packId) async => {...?_mastered[packId]};
  @override
  Future<void> markMastered(String packId, String regionId) async => (_mastered[packId] ??= {}).add(regionId);
  @override
  Future<void> recordMiss(String packId, String regionId) async {
    final m = _misses[packId] ??= {};
    m[regionId] = (m[regionId] ?? 0) + 1;
  }
  @override
  Future<Map<String, int>> misses(String packId) async => {...?_misses[packId]};
}
