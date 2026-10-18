import '../pack/region_pack.dart';
import 'difficulty.dart';
import 'grid.dart';
import 'replay.dart';

/// 友だちへの招待。ステージと難易度（と、自分の結果）を短い文字列にして、メッセージに貼って送る。
/// ステージは、種別・id・難易度から同じものが作られるので、リプレイを送らなくても同じ条件で挑戦できる。
/// 形: `TMI1.<packId>.<種別>.<id>.<難易度>` ＋ 結果があれば `.w12`（勝ち・拠点HP12）／`.l0`（負け）。
class Invite {
  final String packId;
  final StageKind kind;
  final String stageId;
  final Difficulty difficulty;
  final bool? won; // 送り主の結果（なければ null）
  final int? baseHp;
  const Invite({required this.packId, required this.kind, required this.stageId, required this.difficulty, this.won, this.baseHp});

  /// 終えた戦いから作る（自分の結果つき）。
  factory Invite.fromReplay(Replay r) =>
      Invite(packId: r.packId, kind: r.kind, stageId: r.stageId, difficulty: r.difficulty, won: r.result.won, baseHp: r.result.baseHp);

  bool get hasResult => won != null && baseHp != null;

  String toCode() => 'TMI1.$packId.${kind.name}.$stageId.${difficulty.name}${hasResult ? '.${won! ? 'w' : 'l'}${baseHp!.clamp(0, 99999)}' : ''}';

  static final _re = RegExp(r'TMI1\.([a-z0-9_]+)\.(normal|regional|extra)\.([A-Za-z0-9_\-]+)\.(easy|normal|hard)(?:\.([wl])(\d{1,5}))?(?![A-Za-z0-9_\-])');

  /// 貼られた文章のどこかにある招待コードを読む。なければ null（前後の文章があってもよい）。
  static Invite? parse(String? text) {
    if (text == null) return null;
    final m = _re.firstMatch(text);
    if (m == null) return null;
    return Invite(
      packId: m.group(1)!,
      kind: StageKind.values.byName(m.group(2)!),
      stageId: m.group(3)!,
      difficulty: Difficulty.values.byName(m.group(4)!),
      won: m.group(5) == null ? null : m.group(5) == 'w',
      baseHp: m.group(6) == null ? null : int.parse(m.group(6)!),
    );
  }

  /// この国のデータに、そのステージがあるか（別の国のコード・存在しない id・壊れたコードを弾く）。
  bool isValidFor(RegionPack pack) {
    if (pack.packId != packId) return false;
    switch (kind) {
      case StageKind.normal:
        return pack.regions.any((r) => r.id == stageId);
      case StageKind.regional:
        return pack.profile?.groups.containsKey(stageId) ?? false;
      case StageKind.extra:
        return pack.profile?.extras.any((e) => e.id == stageId) ?? false;
    }
  }

  /// 送る文面。[headline] は「○○に勝てるかな？」のような一文、[result] は自分の結果の一文（なければ空）。
  String shareText({required String headline, String result = ''}) => [headline, if (result.isNotEmpty) result, toCode()].join('\n');
}
