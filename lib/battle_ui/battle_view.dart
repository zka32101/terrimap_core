import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../battle/battle_engine.dart';
import '../battle/grid.dart';
import '../battle/stage.dart';
import 'art_set.dart';

/// 季節ごとの地面の色。
const seasonGround = <Season, Color>{
  Season.spring: Color(0xFFA5D6A7),
  Season.summer: Color(0xFF81C784),
  Season.autumn: Color(0xFFE6C877),
  Season.winter: Color(0xFFCFD8DC),
};

const facilityColors = <FacilityType, Color>{
  FacilityType.farm: Color(0xFF7CB342),
  FacilityType.fishery: Color(0xFF29B6F6),
  FacilityType.factory: Color(0xFF8D6E63),
  FacilityType.mine: Color(0xFF616161),
  FacilityType.castle: Color(0xFFAB47BC),
  FacilityType.shrine: Color(0xFFFFB300),
};

const enemyColors = <String, Color>{
  'normal': Color(0xFFE53935),
  'speedy': Color(0xFFFF7043),
  'armored': Color(0xFF5E35B1),
  'healer': Color(0xFF26A69A),
};

/// ステージの盤面（陸・進路・設置枠・拠点・施設・敵）を描く。[art] に画像があればそれを使い、無い要素は色と図形で描く。
/// マスをタップすると [onCellTap] が呼ばれる。
class BattleView extends StatelessWidget {
  final Stage stage;
  final BattleState state;
  final GridPos? selected;

  /// 選択中の施設の射程を円で出す（null なら出さない）。
  final double? selectedRange;
  final void Function(GridPos cell)? onCellTap;

  /// 施設の最大耐久（耐久バーの割合に使う。`engine.maxHpOf`）。省略すると耐久バーは出さない。
  final int Function(Facility f)? facilityMaxHp;

  /// 背景・施設・敵・ボスの画像（省略または画像なしなら図形のみ）。
  final ArtSet? art;

  const BattleView(
      {super.key,
      required this.stage,
      required this.state,
      this.selected,
      this.selectedRange,
      this.onCellTap,
      this.facilityMaxHp,
      this.art});

  /// 盤面を表示サイズに収めたときのマスの一辺と、左上の余白。
  static ({double cell, double dx, double dy}) layout(Size size, int cols, int rows) {
    final cell = math.min(size.width / cols, size.height / rows);
    return (cell: cell, dx: (size.width - cell * cols) / 2, dy: (size.height - cell * rows) / 2);
  }

  /// 表示上の位置からマスを引く（盤面の外は null）。
  static GridPos? cellAt(Offset p, Size size, int cols, int rows) {
    final l = layout(size, cols, rows);
    final c = ((p.dx - l.dx) / l.cell).floor(), r = ((p.dy - l.dy) / l.cell).floor();
    if (c < 0 || r < 0 || c >= cols || r >= rows) return null;
    return GridPos(c, r);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final size = Size(box.maxWidth, box.maxHeight);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) {
          final c = cellAt(d.localPosition, size, stage.cols, stage.rows);
          if (c != null) onCellTap?.call(c);
        },
        child: CustomPaint(
          size: size,
          painter: _BattlePainter(stage, state, selected, selectedRange, facilityMaxHp, art),
        ),
      );
    });
  }
}

class _BattlePainter extends CustomPainter {
  final Stage stage;
  final BattleState state;
  final GridPos? selected;
  final double? range;
  final int Function(Facility f)? maxHp;
  final ArtSet? art;
  _BattlePainter(this.stage, this.state, this.selected, this.range, this.maxHp, this.art);

  /// [img] を [dst] に収まる最大の大きさで（縦横比を保って）描く。
  static void _sprite(Canvas canvas, ui.Image img, Rect dst, {double opacity = 1}) {
    final src = Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
    final k = math.min(dst.width / src.width, dst.height / src.height);
    final out = Rect.fromCenter(center: dst.center, width: src.width * k, height: src.height * k);
    canvas.drawImageRect(img, src, out, Paint()..filterQuality = FilterQuality.medium..color = Color.fromRGBO(0, 0, 0, opacity));
  }

  /// [img] で [dst] を隙間なく覆う（はみ出しは切る）。
  static void _cover(Canvas canvas, ui.Image img, Rect dst) {
    final k = math.max(dst.width / img.width, dst.height / img.height);
    final sw = dst.width / k, sh = dst.height / k;
    final src = Rect.fromLTWH((img.width - sw) / 2, (img.height - sh) / 2, sw, sh);
    canvas.drawImageRect(img, src, dst, Paint()..filterQuality = FilterQuality.medium);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final l = BattleView.layout(size, stage.cols, stage.rows);
    final cell = l.cell;
    Rect rect(GridPos p) => Rect.fromLTWH(l.dx + p.col * cell, l.dy + p.row * cell, cell, cell);
    Offset center(double col, double row) => Offset(l.dx + (col + 0.5) * cell, l.dy + (row + 0.5) * cell);

    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFB3E5FC)); // 海
    final ground = Paint()..color = seasonGround[stage.season]!;
    final pathPaint = Paint()..color = const Color(0xFFD7CCC8);
    final slotPaint = Paint()
      ..color = const Color(0x55FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final onPath = {for (final p in stage.paths) ...p};

    // 背景画像があれば全面に敷き、陸の地面は塗らず進路だけ重ねる（道はゲーム側で描く）
    final backdrop = art?.backdrop(stage.backdrop);
    if (backdrop != null) _cover(canvas, backdrop, Offset.zero & size);
    for (final p in stage.land) {
      final onP = onPath.contains(p);
      if (backdrop != null && !onP) continue;
      canvas.drawRect(rect(p).deflate(0.4), onP ? pathPaint : ground);
    }
    for (final s in stage.slots) {
      canvas.drawRRect(RRect.fromRectAndRadius(rect(s).deflate(cell * 0.12), Radius.circular(cell * 0.12)), slotPaint);
    }
    // 入口と拠点
    for (final e in stage.entrances) {
      canvas.drawCircle(center(e.cell.col.toDouble(), e.cell.row.toDouble()), cell * 0.18, Paint()..color = const Color(0xFFD32F2F));
    }
    final b = rect(stage.base).deflate(cell * 0.1);
    canvas.drawRRect(RRect.fromRectAndRadius(b, Radius.circular(cell * 0.2)), Paint()..color = const Color(0xFF1565C0));
    canvas.drawRRect(
        RRect.fromRectAndRadius(b.deflate(cell * 0.18), Radius.circular(cell * 0.1)), Paint()..color = const Color(0xFFFFD54F));

    // 選択
    if (selected != null) {
      canvas.drawRect(rect(selected!), Paint()..color = const Color(0x44FFEB3B));
      canvas.drawRect(
          rect(selected!),
          Paint()
            ..color = const Color(0xFFF9A825)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
      if (range != null) {
        final c = center(selected!.col.toDouble(), selected!.row.toDouble());
        canvas.drawCircle(
            c,
            range! * cell,
            Paint()
              ..color = const Color(0x22000000)
              ..style = PaintingStyle.fill);
      }
    }

    // 施設
    for (final f in state.facilities.values) {
      final r = rect(f.pos).deflate(cell * 0.14);
      final base = f.exclusive != null ? const Color(0xFFD4AF37) : facilityColors[f.type]!;
      final stopped = f.disabledUntil > state.time;
      final img = art?.facility(f);
      if (img != null) {
        _sprite(canvas, img, rect(f.pos).deflate(cell * 0.04), opacity: stopped ? 0.4 : 1);
      } else {
        canvas.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(cell * 0.18)), Paint()..color = stopped ? base.withValues(alpha: 0.4) : base);
      }
      // レベル（点）
      for (var i = 0; i < f.level; i++) {
        canvas.drawCircle(Offset(r.left + cell * 0.14 + i * cell * 0.15, r.bottom - cell * 0.12), cell * 0.045, Paint()..color = Colors.white);
      }
      if (f.exclusive != null && img == null) {
        final tp = TextPainter(text: TextSpan(text: '★', style: TextStyle(color: Colors.white, fontSize: cell * 0.4)), textDirection: TextDirection.ltr)..layout();
        tp.paint(canvas, r.center - Offset(tp.width / 2, tp.height / 2));
      }
      _hpBar(canvas, Rect.fromLTWH(r.left, r.top - cell * 0.08, r.width, cell * 0.06), f.hp, maxHp?.call(f) ?? 0);
    }

    // 敵
    for (final e in state.enemies) {
      final pos = Enemy.positionAt(e.flying, e.progress, stage.paths[e.pathIndex]);
      final c = center(pos.x, pos.y);
      final img = art?.enemy(e);
      // 画像は図形より大きく見せる（絵の余白ぶん）
      final rad = cell * (img != null ? (e.isBoss ? 0.5 : 0.32) : (e.isBoss ? 0.34 : 0.2));
      if (img != null) {
        _sprite(canvas, img, Rect.fromCircle(center: c, radius: rad));
      } else {
        canvas.drawCircle(c, rad, Paint()..color = enemyColors[e.kind] ?? Colors.red);
        canvas.drawCircle(
            c,
            rad,
            Paint()
              ..color = e.isBoss ? const Color(0xFFFFD54F) : Colors.white
              ..style = PaintingStyle.stroke
              ..strokeWidth = e.isBoss ? 2.5 : 1.2);
      }
      _hpBar(canvas, Rect.fromLTWH(c.dx - rad, c.dy - rad - cell * 0.1, rad * 2, cell * 0.06), e.hp, e.maxHp);
    }
  }

  void _hpBar(Canvas canvas, Rect r, int hp, int max) {
    if (max <= 0 || hp >= max) return;
    canvas.drawRect(r, Paint()..color = const Color(0x88000000));
    canvas.drawRect(Rect.fromLTWH(r.left, r.top, r.width * (hp / max).clamp(0.0, 1.0), r.height), Paint()..color = const Color(0xFF66BB6A));
  }

  @override
  bool shouldRepaint(covariant _BattlePainter old) => old.state != state || old.selected != selected || old.range != range || old.stage != stage || old.art != art;
}
