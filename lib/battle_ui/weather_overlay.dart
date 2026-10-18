import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// 天候の見た目（盤面の上に重ねる粒と色）。素材は使わず、時刻 [t]（秒）から決まる動きだけで描く。
/// 種類は `WeatherEffect` の天候: hurricane / tornado / blizzard / heatwave / wildfire / flood / earthquake / storm。
/// 知らない種類は何も描かない。
void paintWeather(Canvas canvas, Size size, String type, double t) {
  switch (type) {
    case 'storm':
      _tint(canvas, size, const Color(0x2237474F));
      _rain(canvas, size, t, count: 70, slant: 0.25, speed: 1.1);
    case 'hurricane':
      _tint(canvas, size, const Color(0x3337474F));
      _rain(canvas, size, t, count: 110, slant: 0.7, speed: 1.5);
    case 'blizzard':
      _tint(canvas, size, const Color(0x33E3F2FD));
      _snow(canvas, size, t);
    case 'heatwave':
      _heat(canvas, size, t);
    case 'wildfire':
      _tint(canvas, size, const Color(0x22FF7043));
      _embers(canvas, size, t);
    case 'flood':
      _flood(canvas, size, t);
    case 'tornado':
      _tornado(canvas, size, t);
    case 'earthquake':
      _dust(canvas, size, t);
  }
}

/// 地震のゆれ（盤面全体の位置のずれ）。ほかの天候は 0。
Offset weatherShake(String? type, double t) {
  if (type != 'earthquake') return Offset.zero;
  return Offset(math.sin(t * 47) * 2.0, math.cos(t * 61) * 1.5);
}

// 0〜1 の決まった乱数（粒の番号 i と用途 k から）。
double _r(int i, int k) {
  final x = math.sin(i * 12.9898 + k * 78.233) * 43758.5453;
  return x - x.floorToDouble();
}

void _tint(Canvas canvas, Size size, Color c) => canvas.drawRect(Offset.zero & size, Paint()..color = c);

void _rain(Canvas canvas, Size size, double t, {required int count, required double slant, required double speed}) {
  final p = Paint()
    ..color = const Color(0xDD64B5F6)
    ..strokeWidth = 2.0
    ..strokeCap = StrokeCap.round;
  final len = size.height * 0.035;
  for (var i = 0; i < count; i++) {
    final fall = (_r(i, 1) * 0.6 + 0.7) * speed;
    final y = ((_r(i, 2) + t * fall * 0.9) % 1.0) * (size.height + len) - len;
    final x = ((_r(i, 3) + y / size.height * slant * 0.3) % 1.0) * size.width;
    canvas.drawLine(Offset(x, y), Offset(x - len * slant, y + len), p);
  }
}

void _snow(Canvas canvas, Size size, double t) {
  final p = Paint()..color = const Color(0xDDFFFFFF);
  for (var i = 0; i < 80; i++) {
    final r = 1.5 + _r(i, 1) * 2.5;
    final y = ((_r(i, 2) + t * (0.08 + _r(i, 4) * 0.1)) % 1.0) * size.height;
    final x = (_r(i, 3) * size.width + math.sin(t * 1.3 + i) * 12) % size.width;
    canvas.drawCircle(Offset(x, y), r, p);
  }
}

void _heat(Canvas canvas, Size size, double t) {
  final pulse = 0.5 + 0.5 * math.sin(t * 1.5);
  _tint(canvas, size, Color.fromRGBO(255, 183, 77, 0.10 + 0.08 * pulse));
  final p = Paint()
    ..color = const Color(0x33FFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  for (var i = 0; i < 6; i++) {
    final x = (_r(i, 1) * 0.9 + 0.05) * size.width;
    final base = size.height * (0.9 - ((t * 0.1 + _r(i, 2)) % 1.0) * 0.5);
    final path = Path()..moveTo(x, base);
    for (var k = 1; k <= 4; k++) {
      path.quadraticBezierTo(x + (k.isOdd ? 8 : -8), base - k * 14 + 7, x, base - k * 14);
    }
    canvas.drawPath(path, p);
  }
}

void _embers(Canvas canvas, Size size, double t) {
  for (var i = 0; i < 40; i++) {
    final rise = (_r(i, 1) + t * (0.12 + _r(i, 2) * 0.12)) % 1.0;
    final y = size.height * (1 - rise);
    final x = (_r(i, 3) * size.width + math.sin(t * 2 + i) * 10) % size.width;
    final a = (1 - rise).clamp(0.0, 1.0);
    canvas.drawCircle(Offset(x, y), 1.5 + _r(i, 4) * 2, Paint()..color = Color.fromRGBO(255, 138, 61, 0.35 + 0.5 * a));
  }
}

void _flood(Canvas canvas, Size size, double t) {
  final level = size.height * (0.88 - 0.05 * (0.5 + 0.5 * math.sin(t * 0.6)));
  final path = Path()..moveTo(0, size.height)..lineTo(0, level);
  for (var x = 0.0; x <= size.width; x += 8) {
    path.lineTo(x, level + math.sin(x * 0.05 + t * 2) * 3);
  }
  path..lineTo(size.width, size.height)..close();
  canvas.drawPath(path, Paint()..color = const Color(0x554FC3F7));
}

void _tornado(Canvas canvas, Size size, double t) {
  _tint(canvas, size, const Color(0x1A455A64));
  final cx = size.width * (0.5 + 0.3 * math.sin(t * 0.4));
  final p = Paint()..color = const Color(0x88B0BEC5);
  for (var i = 0; i < 36; i++) {
    final h = i / 36.0;
    final ang = t * 3 + i * 0.9;
    final rad = 10 + h * size.width * 0.12;
    canvas.drawCircle(Offset(cx + math.cos(ang) * rad, size.height * (0.25 + h * 0.6)), 2.5 + h * 2, p);
  }
}

void _dust(Canvas canvas, Size size, double t) {
  _tint(canvas, size, const Color(0x118D6E63));
  final p = Paint()..color = const Color(0x668D6E63);
  for (var i = 0; i < 30; i++) {
    final x = _r(i, 1) * size.width;
    final y = (_r(i, 2) * size.height + math.sin(t * 9 + i) * 6) % size.height;
    canvas.drawCircle(Offset(x, y), 1.2 + _r(i, 3) * 1.8, p);
  }
}
