import 'dart:convert';

import '../pack/region_pack.dart';
import 'battle_engine.dart';
import 'difficulty.dart';
import 'grid.dart';
import 'stage_generator.dart';

/// 操作1つ。[tick] はその操作をしたときの `BattleState.tickCount`（その刻みの前に適用する）。
class ReplayOp {
  static const place = 'place', exclusive = 'exclusive', upgrade = 'upgrade', remove = 'remove', repair = 'repair';
  static const repairQuiz = 'repairQuiz', startWave = 'startWave', skillQuiz = 'skillQuiz', skill = 'skill';

  final int tick;
  final String kind;
  final GridPos? pos;
  final String? arg; // place=施設の種類、exclusive=限定施設の id（省略可）、skill=スキル id
  final bool? correct; // repairQuiz・skillQuiz
  const ReplayOp(this.tick, this.kind, {this.pos, this.arg, this.correct});

  List<dynamic> toJson() => [tick, kind, pos?.col, pos?.row, arg, correct];

  factory ReplayOp.fromJson(List<dynamic> j) =>
      ReplayOp(j[0] as int, j[1] as String, pos: j[2] == null ? null : GridPos(j[2] as int, j[3] as int), arg: j[4] as String?, correct: j[5] as bool?);

  /// 操作を [s] に適用する。できなければ null（記録どおりなら起きない）。
  BattleState? apply(BattleEngine e, BattleState s) {
    switch (kind) {
      case place:
        return e.place(s, FacilityType.values.byName(arg!), pos!);
      case exclusive:
        return e.placeExclusive(s, pos!, id: arg);
      case upgrade:
        return e.upgrade(s, pos!);
      case remove:
        return e.remove(s, pos!);
      case repair:
        return e.repair(s, pos!);
      case repairQuiz:
        return e.repairByQuiz(s, pos!, correct: correct!);
      case startWave:
        return e.startWave(s).state;
      case skillQuiz:
        return e.resolveSkillQuiz(s, correct: correct!);
      case skill:
        return e.chooseSkill(s, arg!);
    }
    return null;
  }
}

/// 操作を記録しながらエンジンを呼ぶ窓口。成功した操作（結果が null でないもの）だけ記録する。
/// 画面（[BattleSession]）と自動対戦（[BattleBot]）が使う。
class ReplayRecorder {
  final BattleEngine engine;
  final List<ReplayOp> ops = [];
  ReplayRecorder(this.engine);

  BattleState? _rec(BattleState? result, ReplayOp op) {
    if (result != null) ops.add(op);
    return result;
  }

  BattleState? place(BattleState s, FacilityType t, GridPos p) => _rec(engine.place(s, t, p), ReplayOp(s.tickCount, ReplayOp.place, pos: p, arg: t.name));
  BattleState? placeExclusive(BattleState s, GridPos p, {String? id}) =>
      _rec(engine.placeExclusive(s, p, id: id), ReplayOp(s.tickCount, ReplayOp.exclusive, pos: p, arg: id));
  BattleState? upgrade(BattleState s, GridPos p) => _rec(engine.upgrade(s, p), ReplayOp(s.tickCount, ReplayOp.upgrade, pos: p));
  BattleState? remove(BattleState s, GridPos p) => _rec(engine.remove(s, p), ReplayOp(s.tickCount, ReplayOp.remove, pos: p));
  BattleState? repair(BattleState s, GridPos p) => _rec(engine.repair(s, p), ReplayOp(s.tickCount, ReplayOp.repair, pos: p));
  BattleState? repairByQuiz(BattleState s, GridPos p, {required bool correct}) =>
      _rec(engine.repairByQuiz(s, p, correct: correct), ReplayOp(s.tickCount, ReplayOp.repairQuiz, pos: p, correct: correct));
  BattleState? chooseSkill(BattleState s, String id) => _rec(engine.chooseSkill(s, id), ReplayOp(s.tickCount, ReplayOp.skill, arg: id));
  BattleState resolveSkillQuiz(BattleState s, {required bool correct}) {
    ops.add(ReplayOp(s.tickCount, ReplayOp.skillQuiz, correct: correct));
    return engine.resolveSkillQuiz(s, correct: correct);
  }

  TickResult startWave(BattleState s) {
    final r = engine.startWave(s);
    ops.add(ReplayOp(s.tickCount, ReplayOp.startWave));
    return r;
  }

  /// 記録から [Replay] を作る。結果は、記録を再生して求める（保存される結果と、再生の結果が必ず同じになる）。
  Replay toReplay({required String packId, required StageKind kind, required String stageId, required Difficulty difficulty}) {
    final r = Replay(
        packId: packId, kind: kind, stageId: stageId, difficulty: difficulty, quizAssist: engine.quizAssist, ops: List.of(ops), result: const ReplayResult(false, 0, 0, 0, []), rules: engine.rules);
    return r.withResult(r.play(engine));
  }
}

/// 結果の要約。再生して一致するかを確かめるのに使う。[breaches] は波ごとの拠点への被害（0=無傷）。
class ReplayResult {
  final bool won;
  final int wave, baseHp, score;
  final List<int> breaches;
  const ReplayResult(this.won, this.wave, this.baseHp, this.score, this.breaches);

  factory ReplayResult.of(BattleState s, List<int> breaches) => ReplayResult(s.phase == BattlePhase.victory, s.wave, s.baseHp, s.score, breaches);

  Map<String, dynamic> toJson() => {'won': won, 'wave': wave, 'baseHp': baseHp, 'score': score, 'breaches': breaches};

  factory ReplayResult.fromJson(Map<String, dynamic> j) =>
      ReplayResult(j['won'] as bool, j['wave'] as int, j['baseHp'] as int, j['score'] as int, [for (final b in (j['breaches'] as List)) b as int]);

  @override
  bool operator ==(Object o) => o is ReplayResult && o.won == won && o.wave == wave && o.baseHp == baseHp && o.score == score && _same(o.breaches, breaches);
  @override
  int get hashCode => Object.hash(won, wave, baseHp, score, Object.hashAll(breaches));
  static bool _same(List<int> a, List<int> b) => a.length == b.length && [for (var i = 0; i < a.length; i++) a[i] == b[i]].every((x) => x);
  @override
  String toString() => 'ReplayResult(${won ? 'win' : 'lose'} wave$wave hp$baseHp score$score breaches$breaches)';
}

/// バトル1回の記録（設計書 §6.13）。ステージの指定と操作の列だけ。計算が決定的なので、再生すると同じ結果になる。
class Replay {
  static const version = 2; // 2: ルールの版（'r'）を持つ。1（'r' なし）はルール1として読める
  final String packId;
  final StageKind kind;
  final String stageId; // 種別に応じた id（州・地方・エクストラ）
  final Difficulty difficulty;
  final bool quizAssist;
  final List<ReplayOp> ops;
  final ReplayResult result;

  /// 記録したときのルールの版（[BattleEngine.rules]）。再生は、この版のルールで行う。
  final int rules;
  const Replay({required this.packId, required this.kind, required this.stageId, required this.difficulty, required this.quizAssist, required this.ops, required this.result, this.rules = BattleEngine.currentRules});

  /// この記録を再生するエンジン。pack が違えば [ArgumentError]。
  BattleEngine buildEngine(RegionPack pack) {
    if (pack.packId != packId) throw ArgumentError('packId が違います: ${pack.packId} != $packId');
    return BattleEngine(StageGenerator(pack).generate(stageId, difficulty, kind: kind), profile: pack.profile, pack: pack, quizAssist: quizAssist, rules: rules);
  }

  /// 再生して、終わった状態と波ごとの被害を返す。操作が適用できなければ [StateError]（改ざん・版違い）。
  /// 操作を使い切ったあとは、勝敗が決まる（または [maxSeconds]）まで進める。
  ReplayResult play(BattleEngine engine, {double maxSeconds = 3600}) {
    var s = engine.start();
    final breaches = <int>[];
    var i = 0, t = 0.0;
    void note(List<BattleEvent> events) {
      for (final e in events) {
        if (e.type == BattleEventType.waveStart) {
          while (breaches.length < (e.value ?? 0)) {
            breaches.add(0);
          }
        } else if (e.type == BattleEventType.breach && breaches.isNotEmpty) {
          breaches[breaches.length - 1] += e.value ?? 0;
        }
      }
    }

    while (!s.isOver && t < maxSeconds) {
      while (i < ops.length && ops[i].tick <= s.tickCount) {
        final op = ops[i++];
        if (op.kind == ReplayOp.startWave) {
          final r = engine.startWave(s);
          s = r.state;
          note(r.events);
          continue;
        }
        final n = op.apply(engine, s);
        if (n == null) throw StateError('操作を適用できません: ${op.toJson()}');
        s = n;
      }
      final r = engine.tick(s, BattleEngine.step);
      s = r.state;
      note(r.events);
      t += BattleEngine.step;
    }
    while (breaches.length < s.wave.clamp(0, 1 << 20)) {
      breaches.add(0);
    }
    return ReplayResult.of(s, breaches);
  }

  Replay withResult(ReplayResult r) =>
      Replay(packId: packId, kind: kind, stageId: stageId, difficulty: difficulty, quizAssist: quizAssist, ops: ops, result: r, rules: rules);

  /// 再生した結果が、保存された結果と一致するか。
  bool verify(RegionPack pack) {
    try {
      return play(buildEngine(pack)) == result;
    } on StateError {
      return false;
    }
  }

  Map<String, dynamic> toJson() => {
        'v': version,
        'pack': packId,
        'kind': kind.name,
        'id': stageId,
        'diff': difficulty.name,
        'assist': quizAssist,
        'r': rules,
        'ops': [for (final o in ops) o.toJson()],
        'result': result.toJson(),
      };

  String toJsonString() => jsonEncode(toJson());

  factory Replay.fromJson(Map<String, dynamic> j) {
    if (j['v'] != 1 && j['v'] != version) throw FormatException('未対応の版: ${j['v']}');
    return Replay(
      packId: j['pack'] as String,
      kind: StageKind.values.byName(j['kind'] as String),
      stageId: j['id'] as String,
      difficulty: Difficulty.values.byName(j['diff'] as String),
      quizAssist: j['assist'] as bool,
      rules: j['v'] == 1 ? 1 : (j['r'] as int? ?? 1),
      ops: [for (final o in (j['ops'] as List)) ReplayOp.fromJson(o as List)],
      result: ReplayResult.fromJson(j['result'] as Map<String, dynamic>),
    );
  }

  /// 挑戦リンク用の短い文字列（URL に載せられる base64url）。
  String toShareCode() => base64Url.encode(utf8.encode(toJsonString()));

  /// 共有の文字列から読む。壊れていれば null。
  static Replay? fromShareCode(String? code) {
    if (code == null || code.isEmpty) return null;
    try {
      return tryParse(utf8.decode(base64Url.decode(base64Url.normalize(code))));
    } catch (_) {
      return null;
    }
  }

  /// 壊れた文字列は null。
  static Replay? tryParse(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      return Replay.fromJson(jsonDecode(s) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
