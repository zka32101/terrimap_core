import 'dart:convert';

import '../battle/battle_progress.dart';
import '../battle/grid.dart';
import '../pack/region_pack.dart';

/// 言語ごとの文。足りない言語は英語、英語もなければ空にする。
class LocalizedText {
  final Map<String, String> _m;
  const LocalizedText(this._m);

  factory LocalizedText.fromJson(Object? j) {
    if (j is! Map) return const LocalizedText({});
    return LocalizedText({for (final e in j.entries) if (e.value is String) '${e.key}': e.value as String});
  }

  String of(String lang) => _m[lang] ?? _m['en'] ?? '';
  bool get hasEnglish => (_m['en'] ?? '').trim().isNotEmpty;
  Iterable<String> get languages => _m.keys;
}

/// 物語の語り手。note は「何が実在で何が伝説か」の注記（伝説を元にした章には必ず入れる）。
/// hero は、その国の案内役の主人公（`story.json` の `hero` で定義する）。知らない語り手の文は読み飛ばす。
enum Speaker { narrator, boss, note, hero }

/// その国の主人公。名前は言語によらず同じでよい（訳がなければ英語）。role は一言の紹介。
class Hero {
  final String id;
  final LocalizedText name;
  final LocalizedText role;
  const Hero({required this.id, required this.name, required this.role});

  static Hero? fromJson(Object? j) {
    if (j is! Map || j['id'] is! String) return null;
    return Hero(id: j['id'] as String, name: LocalizedText.fromJson(j['name']), role: LocalizedText.fromJson(j['role']));
  }
}

class DialogueLine {
  final Speaker speaker;
  final LocalizedText text;
  const DialogueLine(this.speaker, this.text);

  static DialogueLine? fromJson(Object? j) {
    if (j is! Map) return null;
    final name = j['speaker'];
    final s = Speaker.values.where((e) => e.name == name);
    if (s.isEmpty) return null;
    return DialogueLine(s.first, LocalizedText.fromJson(j['text']));
  }
}

/// 物語の1章。1つのステージ（通常・地方決戦・エクストラ）に結びつく。
class StoryChapter {
  final String id;
  final StageKind kind;
  final String stageId;

  /// 先に終えておく章の id（なければ最初から読める）。
  final String? requires;
  final LocalizedText title;
  final List<DialogueLine> intro; // 戦いの前
  final List<DialogueLine> beforeBoss; // ボスの登場の直前
  final List<DialogueLine> outro; // 勝ったあと
  const StoryChapter({
    required this.id,
    required this.kind,
    required this.stageId,
    this.requires,
    required this.title,
    this.intro = const [],
    this.beforeBoss = const [],
    this.outro = const [],
  });

  static List<DialogueLine> _lines(Object? j) => [for (final l in (j as List? ?? const [])) DialogueLine.fromJson(l)].whereType<DialogueLine>().toList();

  static StoryChapter? fromJson(Object? j) {
    if (j is! Map) return null;
    final kind = StageKind.values.where((k) => k.name == j['kind']);
    if (kind.isEmpty || j['id'] is! String || j['stageId'] is! String) return null;
    return StoryChapter(
      id: j['id'] as String,
      kind: kind.first,
      stageId: j['stageId'] as String,
      requires: j['requires'] as String?,
      title: LocalizedText.fromJson(j['title']),
      intro: _lines(j['intro']),
      beforeBoss: _lines(j['beforeBoss']),
      outro: _lines(j['outro']),
    );
  }
}

/// その国の物語（`packs/<国>/story.json`）。章の並びと、各章の文。画面にも保存先にも依存しない。
class Story {
  final List<StoryChapter> chapters;

  /// 主人公（なければ null。その国の物語に主人公の文は入れられない）。
  final Hero? hero;
  const Story(this.chapters, {this.hero});

  factory Story.parse(String json) {
    final m = jsonDecode(json) as Map;
    return Story(
      [for (final c in (m['chapters'] as List? ?? const [])) StoryChapter.fromJson(c)].whereType<StoryChapter>().toList(),
      hero: Hero.fromJson(m['hero']),
    );
  }

  StoryChapter? chapter(String id) {
    for (final c in chapters) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// そのステージの章（なければ null）。
  StoryChapter? forStage(StageKind kind, String stageId) {
    for (final c in chapters) {
      if (c.kind == kind && c.stageId == stageId) return c;
    }
    return null;
  }

  /// データの問題の一覧（空なら問題なし）。章の id の重複・未知のステージ・前提の章・英語の文・伝説の章の注記を調べる。
  List<String> validate(RegionPack pack) {
    final errs = <String>[];
    final ids = <String>{};
    final profile = pack.profile;
    final h = hero;
    if (h != null && !h.name.hasEnglish) errs.add('hero: 名前の英語がない');
    for (final c in chapters) {
      if (!ids.add(c.id)) errs.add('${c.id}: 章の id が重複');
      if (!c.title.hasEnglish) errs.add('${c.id}: 題名の英語がない');
      for (final l in [...c.intro, ...c.beforeBoss, ...c.outro]) {
        if (!l.text.hasEnglish) errs.add('${c.id}: 英語のない文がある');
        if (l.speaker == Speaker.hero && h == null) errs.add('${c.id}: 主人公の文があるが、hero が定義されていない');
      }
      switch (c.kind) {
        case StageKind.normal:
          if (!pack.regions.any((r) => r.id == c.stageId)) errs.add('${c.id}: 未知の州 ${c.stageId}');
        case StageKind.regional:
          if (!(profile?.groups.containsKey(c.stageId) ?? false)) errs.add('${c.id}: 未知の地方 ${c.stageId}');
        case StageKind.extra:
          final e = profile?.extras.where((x) => x.id == c.stageId);
          if (e == null || e.isEmpty) {
            errs.add('${c.id}: 未知のエクストラ ${c.stageId}');
          } else if (e.first.basis == 'legend' && !c.outro.any((l) => l.speaker == Speaker.note)) {
            errs.add('${c.id}: 伝説の章には、実在と伝説を分ける注記（note）が要る');
          }
      }
    }
    final seen = <String>{};
    for (final c in chapters) {
      final r = c.requires;
      if (r != null && !seen.contains(r)) errs.add('${c.id}: 前提の章 $r が、先にない（未知か、順番が逆）');
      seen.add(c.id);
    }
    return errs;
  }
}

/// 物語の進み具合。クリアの記録から毎回計算する（保存しない）。
class StoryProgress {
  final Story story;
  final BattleProgress progress;
  const StoryProgress(this.story, this.progress);

  /// その章を終えたか（結びつくステージを、どの難易度でもクリアした）。
  bool completed(StoryChapter c) => progress.isCleared(c.kind, c.stageId);

  /// その章を読めるか（前提の章を終えている）。
  bool unlocked(StoryChapter c) {
    final r = c.requires;
    if (r == null) return true;
    final p = story.chapter(r);
    return p != null && completed(p);
  }

  int get completedCount => story.chapters.where(completed).length;

  /// 次に進める章（読めて、まだ終えていない最初の章）。全部終えたら null。
  StoryChapter? get next {
    for (final c in story.chapters) {
      if (unlocked(c) && !completed(c)) return c;
    }
    return null;
  }
}
