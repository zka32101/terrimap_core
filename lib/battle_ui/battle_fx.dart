import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../battle/battle_engine.dart';
import '../battle/stage.dart';

/// バトルの演出（弾・命中の火花・撃破の爆発・ダメージ数字・拠点被弾・画面の揺れ・波とボスの表示）。
/// エンジンのイベントから作る表示だけの層で、ゲームの結果には影響しない（リプレイ・バランスは変わらない）。
/// 時間はバトルの時間（`state.time`）で進むので、一時停止・倍速・リプレイに合う。
enum FxKind { shot, spark, burst, damage, coin, baseFlash, banner, ring, combo, confetti }

class FxItem {
  final FxKind kind;
  final double t0;
  final double life; // 秒
  final ({double x, double y}) at; // 盤面の座標（列・行。マスの中心が +0.5 ではなく、敵の位置と同じ座標系）
  final ({double x, double y})? from; // shot の撃ち出し位置
  final String? text;
  final Color color;
  final double size; // 1.0 = ふつう
  final bool crit;
  const FxItem(this.kind, this.t0, this.life, this.at, {this.from, this.text, this.color = Colors.white, this.size = 1.0, this.crit = false});
  double age(double now) => ((now - t0) / life).clamp(0.0, 1.0);
}

class BattleFx {
  /// 演出を出すか（「演出をへらす」設定や、低スペック向け）。
  bool enabled;
  static const maxItems = 160;
  final List<FxItem> items = [];
  final List<({double t0, double amp})> _shakes = [];
  Map<String, ({double x, double y})> _pos = {};

  /// 連続撃破(コンボ): 直前の撃破からこの秒数以内に倒すと続く。
  static const comboWindow = 1.2;
  double _lastKill = -100;
  int _combo = 0;

  /// いまのコンボ数(表示用・テスト用)。
  int get combo => _combo;

  BattleFx({this.enabled = true});

  /// 画面を動かす強さ（0〜1）。時間とともに減る。
  Offset shake(double now) {
    if (!enabled) return Offset.zero;
    var dx = 0.0, dy = 0.0;
    for (final s in _shakes) {
      final dt = now - s.t0;
      if (dt < 0 || dt > 0.6) continue;
      final k = s.amp * math.exp(-dt * 6);
      dx += math.sin(now * 85) * 6 * k;
      dy += math.cos(now * 70) * 5 * k;
    }
    return Offset(dx, dy);
  }

  void _addShake(double now, double amp) {
    _shakes.add((t0: now, amp: amp));
    if (_shakes.length > 6) _shakes.removeAt(0);
  }

  void _add(FxItem i) {
    items.add(i);
    if (items.length > maxItems) items.removeRange(0, items.length - maxItems);
  }

  /// [events] から演出を作る。[state] は events を出した直後の状態（敵・施設の位置を引く）。
  void consume(BattleState state, List<BattleEvent> events, Stage stage) {
    final cur = <String, ({double x, double y})>{
      for (final e in state.enemies) e.id: Enemy.positionAt(e.flying, e.progress, stage.paths[e.pathIndex]),
    };
    if (enabled) {
      final now = state.time;
      for (final ev in events) {
        final at = ev.enemyId == null ? null : (cur[ev.enemyId] ?? _pos[ev.enemyId]);
        switch (ev.type) {
          case BattleEventType.hit:
            final fp = ev.facilityPos;
            if (at == null || fp == null) break;
            final f = state.facilities[fp];
            final col = ev.crit ? const Color(0xFFFFB300) : (f == null ? Colors.white : _towerColor(f.type));
            _add(FxItem(FxKind.shot, now, 0.16, at, from: (x: fp.col.toDouble(), y: fp.row.toDouble()), color: col, crit: ev.crit));
            _add(FxItem(FxKind.spark, now + 0.1, 0.2, at, color: col, crit: ev.crit));
            if (ev.crit) _addShake(now + 0.1, 0.25);
            if (ev.value != null) _add(FxItem(FxKind.damage, now + 0.1, 0.7, at, text: '${ev.value}', color: col, crit: ev.crit, size: ev.crit ? 1.5 : 1.0));
            break;
          case BattleEventType.kill:
            // コンボ: 続けて倒すほど大きく。3連続から表示し、5の倍数で画面も揺らす。
            _combo = now - _lastKill <= comboWindow ? _combo + 1 : 1;
            _lastKill = now;
            if (_combo >= 3) {
              _add(FxItem(FxKind.combo, now, 1.0, (x: 0, y: 0), text: '×$_combo', color: const Color(0xFFFFD54F), size: math.min(1.0 + 0.08 * _combo, 2.2)));
              if (_combo % 5 == 0) _addShake(now, 0.4);
            }
            if (at == null) break;
            final big = ev.isBoss;
            _add(FxItem(FxKind.burst, now, big ? 0.9 : 0.45, at, color: big ? const Color(0xFFFFD54F) : const Color(0xFFFF8A65), size: big ? 2.6 : 1.0));
            if (ev.value != null && ev.value! > 0) _add(FxItem(FxKind.coin, now, 0.9, at, text: '+${ev.value}', color: const Color(0xFFFFD54F), size: big ? 1.4 : 1.0));
            if (big) _addShake(now, 1.2);
            break;
          case BattleEventType.spawn:
            if (!ev.isBoss) break;
            // ボスの登場: 赤い縁取り・大きな表示・揺れ
            _add(FxItem(FxKind.baseFlash, now, 0.9, (x: 0, y: 0), color: const Color(0xFFB71C1C), size: 1.3));
            _add(FxItem(FxKind.banner, now, 1.8, (x: 0, y: 0), text: 'BOSS', color: const Color(0xFFFF5252), size: 1.5));
            if (at != null) _add(FxItem(FxKind.ring, now, 0.9, at, color: const Color(0xFFFF5252), size: 2.8));
            _addShake(now, 1.0);
            break;
          case BattleEventType.waveClear:
            _add(FxItem(FxKind.banner, now, 1.2, (x: 0, y: 0), text: 'WAVE ${ev.value ?? ''} CLEAR', color: const Color(0xFFB9F6CA)));
            break;
          case BattleEventType.victory:
            // 勝利: 盤面のあちこちで、色とりどりの花火
            const cols = [Color(0xFFFFD54F), Color(0xFF4FC3F7), Color(0xFFF48FB1), Color(0xFFAED581), Color(0xFFCE93D8), Color(0xFFFFB74D)];
            for (var k = 0; k < 6; k++) {
              final fx = (stage.cols * (0.15 + 0.14 * k)) % stage.cols, fy = stage.rows * (k.isEven ? 0.3 : 0.65);
              _add(FxItem(FxKind.confetti, now + 0.12 * k, 1.1, (x: fx, y: fy), color: cols[k], size: 2.2));
            }
            _add(FxItem(FxKind.banner, now, 2.0, (x: 0, y: 0), text: 'VICTORY!', color: const Color(0xFFFFD54F), size: 1.4));
            _addShake(now, 0.6);
            break;
          case BattleEventType.defeat:
            _add(FxItem(FxKind.baseFlash, now, 1.2, (x: 0, y: 0), color: const Color(0xFFB71C1C), size: 1.6));
            _add(FxItem(FxKind.banner, now, 2.0, (x: 0, y: 0), text: 'DEFEAT', color: const Color(0xFFEF9A9A), size: 1.4));
            _addShake(now, 1.4);
            break;
          case BattleEventType.breach:
            _add(FxItem(FxKind.baseFlash, now, 0.5, (x: 0, y: 0), color: const Color(0xFFD32F2F), size: ev.isBoss ? 1.6 : 1.0));
            _addShake(now, ev.isBoss ? 1.6 : 0.9);
            break;
          case BattleEventType.bossSkill:
            if (at != null) _add(FxItem(FxKind.ring, now, 0.8, at, color: const Color(0xFFAB47BC), size: 2.4));
            _addShake(now, 0.7);
            break;
          case BattleEventType.facilityDestroyed:
            final fp = ev.facilityPos;
            if (fp != null) _add(FxItem(FxKind.burst, now, 0.6, (x: fp.col.toDouble(), y: fp.row.toDouble()), color: const Color(0xFF9E9E9E), size: 1.5));
            _addShake(now, 0.5);
            break;
          case BattleEventType.waveStart:
            _add(FxItem(FxKind.banner, now, 1.4, (x: 0, y: 0), text: 'WAVE ${ev.value ?? ''}', color: Colors.white));
            break;
          default:
            break;
        }
      }
      // 古いものを捨てる
      final now2 = state.time;
      items.removeWhere((i) => now2 - i.t0 > i.life + 0.05);
      _shakes.removeWhere((s) => now2 - s.t0 > 0.7);
    }
    _pos = cur;
  }

  void clear() {
    _combo = 0;
    _lastKill = -100;
    items.clear();
    _shakes.clear();
    _pos = {};
  }

  static Color _towerColor(FacilityType t) {
    switch (t) {
      case FacilityType.farm:
        return const Color(0xFFAED581);
      case FacilityType.fishery:
        return const Color(0xFF4FC3F7);
      case FacilityType.factory:
        return const Color(0xFFBCAAA4);
      case FacilityType.mine:
        return const Color(0xFFE0E0E0);
      case FacilityType.castle:
        return const Color(0xFFCE93D8);
      case FacilityType.shrine:
        return const Color(0xFFFFD54F);
    }
  }

  /// 盤面の上に演出を描く。[center] は盤面の座標（列・行）→ 画面の位置、[cell] はマスの大きさ。
  void paint(Canvas canvas, Size size, Offset Function(double col, double row) center, double cell, double now) {
    if (!enabled) return;
    for (final i in items) {
      final dt = now - i.t0;
      if (dt < 0) continue;
      final a = i.age(now);
      if (a >= 1) continue;
      switch (i.kind) {
        case FxKind.shot:
          final p0 = center(i.from!.x, i.from!.y), p1 = center(i.at.x, i.at.y);
          final head = Offset.lerp(p0, p1, Curves.easeIn.transform(a))!;
          final tail = Offset.lerp(p0, p1, math.max(0, a - 0.35))!;
          canvas.drawLine(tail, head, Paint()..color = i.color.withValues(alpha: 0.9 * (1 - a * 0.5))..strokeWidth = cell * (i.crit ? 0.12 : 0.07)..strokeCap = StrokeCap.round);
          canvas.drawCircle(head, cell * (i.crit ? 0.14 : 0.09), Paint()..color = Colors.white.withValues(alpha: 0.95));
          break;
        case FxKind.spark:
          final c = center(i.at.x, i.at.y);
          final r = cell * (0.18 + 0.3 * a) * (i.crit ? 1.5 : 1.0);
          final p = Paint()..color = i.color.withValues(alpha: 1 - a)..strokeWidth = cell * 0.05..strokeCap = StrokeCap.round;
          for (var k = 0; k < 6; k++) {
            final ang = k * math.pi / 3 + 0.4;
            canvas.drawLine(c + Offset(math.cos(ang), math.sin(ang)) * r * 0.5, c + Offset(math.cos(ang), math.sin(ang)) * r, p);
          }
          break;
        case FxKind.burst:
          final c = center(i.at.x, i.at.y);
          final r = cell * (0.25 + 0.6 * Curves.easeOut.transform(a)) * i.size;
          canvas.drawCircle(c, r, Paint()..color = i.color.withValues(alpha: 0.35 * (1 - a)));
          canvas.drawCircle(c, r, Paint()..color = i.color.withValues(alpha: 0.9 * (1 - a))..style = PaintingStyle.stroke..strokeWidth = cell * 0.07 * (1 - a));
          final dp = Paint()..color = i.color.withValues(alpha: 1 - a);
          for (var k = 0; k < 8; k++) {
            final ang = k * math.pi / 4 + i.t0 * 7;
            canvas.drawCircle(c + Offset(math.cos(ang), math.sin(ang)) * r * 1.15, cell * 0.05 * (1 - a) * i.size, dp);
          }
          break;
        case FxKind.ring:
          final c = center(i.at.x, i.at.y);
          final r = cell * (0.3 + 1.0 * Curves.easeOut.transform(a)) * i.size;
          canvas.drawCircle(c, r, Paint()..color = i.color.withValues(alpha: 0.8 * (1 - a))..style = PaintingStyle.stroke..strokeWidth = cell * 0.1 * (1 - a));
          break;
        case FxKind.damage:
        case FxKind.coin:
          final c = center(i.at.x, i.at.y) + Offset(0, -cell * (0.3 + 0.6 * Curves.easeOut.transform(a)));
          _text(canvas, i.text ?? '', c, cell * 0.34 * i.size, i.color.withValues(alpha: a < 0.7 ? 1 : (1 - a) / 0.3), bold: i.crit || i.kind == FxKind.coin);
          break;
        case FxKind.baseFlash:
          final alpha = 0.45 * (1 - a) * i.size.clamp(0, 1.6);
          final r = Offset.zero & size;
          canvas.drawRect(r, Paint()..shader = RadialGradient(colors: [Colors.transparent, i.color.withValues(alpha: alpha.clamp(0, 0.7))], stops: const [0.5, 1.0]).createShader(r));
          break;
        case FxKind.combo:
          // 右上に、弾むように大きくなって消えるコンボ数
          final pop = a < 0.15 ? Curves.easeOut.transform(a / 0.15) : 1.0;
          final fade = a > 0.7 ? (1 - a) / 0.3 : 1.0;
          _text(canvas, '${i.text} COMBO', Offset(size.width - cell * 1.6, cell * 0.9), cell * 0.5 * i.size * (0.6 + 0.4 * pop), i.color.withValues(alpha: fade), bold: true);
          break;
        case FxKind.confetti:
          // 花火: 外へ広がる光の粒と、落ちていく紙ふぶき
          final c = center(i.at.x, i.at.y);
          final r = cell * (0.3 + 1.6 * Curves.easeOut.transform(a)) * i.size * 0.5;
          final p = Paint()..color = i.color.withValues(alpha: 1 - a);
          for (var k = 0; k < 14; k++) {
            final ang = k * math.pi * 2 / 14 + i.t0 * 3;
            final drop = cell * 0.5 * a * a;
            canvas.drawCircle(c + Offset(math.cos(ang) * r, math.sin(ang) * r + drop), cell * 0.07 * (1 - a * 0.6), p);
          }
          canvas.drawCircle(c, cell * 0.15 * (1 - a), Paint()..color = Colors.white.withValues(alpha: 1 - a));
          break;
        case FxKind.banner:
          final k = a < 0.2 ? Curves.easeOut.transform(a / 0.2) : (a > 0.75 ? (1 - a) / 0.25 : 1.0);
          final c = Offset(size.width / 2, size.height * 0.3);
          canvas.drawRect(Rect.fromCenter(center: c, width: size.width, height: cell * 1.0 * k), Paint()..color = Colors.black.withValues(alpha: 0.35 * k));
          _text(canvas, i.text ?? '', c, cell * 0.62 * i.size, i.color.withValues(alpha: k), bold: true);
          break;
      }
    }
  }

  static void _text(Canvas canvas, String s, Offset c, double px, Color color, {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(fontSize: px, color: color, fontWeight: bold ? FontWeight.w900 : FontWeight.w700, shadows: [Shadow(color: Colors.black.withValues(alpha: color.a * 0.8), blurRadius: 3, offset: const Offset(1, 1))])),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
  }
}
