import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import '../battle/battle_model.dart';
import '../quiz/rng.dart';

/// バトル画面に出す画像のまとまり。画像が無い要素は null を返し、呼び出し側が図形の描画にフォールバックする。
///
/// 画像は各アプリの assets に `<prefix><種類>/<id>.png` で置く（種類: backdrops / facilities / exclusive / enemies / bosses / landmarks）。
/// 一覧と命名は `tools/art_manifest.py` を参照。
class ArtSet {
  /// `backdrops/alps` のようなキー → 画像。
  final Map<String, ui.Image> images;

  /// 施設の種類名(`FacilityType.name`) → skin id（profile.json の facilities.*.skin）。
  final Map<String, String> facilitySkins;

  /// 敵の種類 → skin id（profile.json の enemySkins.*.skin）。
  final Map<String, String> enemySkins;

  /// 敵の種類 → この州・地方で出る見た目違いの skin id（`CountryProfile.enemySkinIds` の2番目以降）。基本の見た目と合わせて、敵ごとに決まった1つが出る。
  final Map<String, List<String>> enemyVariants;

  /// ボスの画像 id（エクストラの id。ボスのいないステージは null）。
  final String? bossId;

  /// ミニボスの画像のid（`bosses/<id>`）。州・地方で決まる（[CountryProfile.miniBossFor]）。
  final String? miniBossId;
  const ArtSet({this.miniBossId, this.images = const {}, this.facilitySkins = const {}, this.enemySkins = const {}, this.enemyVariants = const {}, this.bossId});

  bool get isEmpty => images.isEmpty;

  ui.Image? backdrop(String? id) => id == null ? null : images['backdrops/$id'];

  /// 図鑑カードの名所の画像（`landmarks/<名所id>`。facts.json の id）。無ければ null で、呼び出し側が代わりのアイコンを出す。
  ui.Image? landmark(String id) => images['landmarks/$id'];

  /// 天候の重ね画像（`weather/<天候>`。hurricane / tornado / blizzard / heatwave / wildfire / flood / earthquake / storm。国共通・縦長9:16（768x1344）の透過）。
  /// 無ければ null で、盤面は図形の演出（`paintWeather`）で描く。
  ui.Image? weather(String type) => images['weather/$type'];

  ui.Image? facility(Facility f) {
    final ex = f.exclusive;
    if (ex != null) return images['exclusive/$ex'];
    final skin = facilitySkins[f.type.name];
    return skin == null ? null : images['facilities/$skin'];
  }

  ui.Image? enemy(Enemy e) {
    if (e.isMini) {
      final id = miniBossId;
      return id == null ? null : images['bosses/$id'];
    }
    if (e.isBoss) {
      final id = bossId;
      return id == null ? null : images['bosses/$id'];
    }
    final base = enemySkins[e.kind];
    final variants = enemyVariants[e.kind];
    if (variants != null && variants.isNotEmpty) {
      // 敵のid から決まる(同じ敵はいつも同じ見た目)。画像がない見た目違いは、基本の見た目で出す。
      final all = [if (base != null) base, ...variants];
      final img = images['enemies/${all[fnv1a(e.id) % all.length]}'];
      if (img != null) return img;
    }
    return base == null ? null : images['enemies/$base'];
  }

  /// [bundle] の assets のうち [prefix]（例 `assets/art/`）の下にある PNG を読み込む。
  /// 画像が1枚も無い・壊れている場合も例外にせず、読めたものだけの ArtSet を返す。
  static Future<ArtSet> load(
    AssetBundle bundle, {
    String prefix = 'assets/art/',
    Map<String, String> facilitySkins = const {},
    Map<String, String> enemySkins = const {},
    Map<String, List<String>> enemyVariants = const {},
    String? bossId,
    String? miniBossId,
  }) async {
    final images = <String, ui.Image>{};
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(bundle);
      for (final key in manifest.listAssets()) {
        if (!key.startsWith(prefix) || !key.endsWith('.png')) continue;
        try {
          final bytes = (await bundle.load(key)).buffer.asUint8List();
          final codec = await ui.instantiateImageCodec(bytes);
          images[key.substring(prefix.length, key.length - 4)] = (await codec.getNextFrame()).image;
        } catch (_) {
          // 1枚が壊れていても他は使う
        }
      }
    } catch (_) {
      // manifest が読めない場合は画像なし
    }
    return ArtSet(images: images, facilitySkins: facilitySkins, enemySkins: enemySkins, enemyVariants: enemyVariants, bossId: bossId, miniBossId: miniBossId);
  }
}
