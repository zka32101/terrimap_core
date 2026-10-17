# region_core 最小仕様 v0.2（暫定）
v0.2: 都市州の対策（ズーム＋最小タップ領域）とリポジトリ名（region_core）を決定として反映

作成日: 2026-10-17 / 関連: state-master-spec.md v0.5
前提: 既存コードは構造確認のみ（ビルド・実行は未確認）。数値・性能目標は未測定の目標値。

## 1. 目的とスコープ
「地域（州・県・国）の地図を描き、タップ・出題・進捗・デイリーを回す」部分だけを共通化する Flutter パッケージ。

**含める（v0）**
- 地図の描画とタップ判定（自前描画、タイル・ネット接続なし）
- 国データ `country_pack` の読み込みと検証
- 出題エンジン（種類・選択肢生成・採点）
- 進捗の状態モデルと保存インターフェース
- デイリーチャレンジ（日付シード）と共有文の生成

**含めない（アプリ側の責務）**
- 課金・広告・同意・設定画面（app_common_kit を使う）
- Firebase、ランキング、通知
- タワーディフェンスのゲームロジック（地理パズル王側）
- 画面デザイン・文言・キャラクター

## 2. パッケージ構成と依存
- 置き場所: 新規リポジトリ `region_core`（他の `*_core` と同じく git dependency で参照）。公開リポジトリなら、匿名化・セキュリティの確認（app-privacy-security）を通す
- 依存: `flutter` のみ。状態管理・保存・課金は持たない（アプリ側の Riverpod / Hive から使えるよう、インターフェースだけ定義）
- 既存の `shared_core`（小学コレ専用）とは依存させない

```
region_core/
  lib/
    pack/        # RegionPack, Region, PackLoader, PackValidator
    map/         # RegionMapView, RegionProjection, RegionPainter
    quiz/        # QuizEngine, QuestionType, QuizSession
    progress/    # RegionState, ProgressStore（interface）
    daily/       # DailyChallenge, ShareTextBuilder
  tools/build_pack.py   # GeoJSON → country_pack（簡略化・検証）
  packs_sample/         # テスト用の小さなpack
  test/
```

## 3. country_pack の形式
国ごとに1ディレクトリ（アプリの assets に同梱）。

```
packs/de/
  pack.json        # メタ情報
  regions.json     # 地域一覧
  geo.geojson      # 簡略化済みポリゴン（properties.id が regions の id と一致）
  strings/de.json  # 言語別の名称（id → 文字列）
  strings/en.json
  media/flags/<id>.png  （任意）
```

**pack.json（必須項目）**
| 項目 | 内容 |
|---|---|
| packId / country | `de` など |
| regionKind | `state` / `prefecture` など（UI文言用） |
| languages | 同梱する言語コード |
| projection | `equirect_cos`（既存方式）／将来 `albers` |
| insets | 離島・飛び地を別枠で表示する設定（例: 日本=沖縄、米国=アラスカ・ハワイ）。空でもよい |
| attribution | 出典表示の文字列（必須。画面に出す） |
| license | データのライセンス名とURL（必須） |

**regions.json（1地域あたり）**
| 項目 | 必須 | 内容 |
|---|---|---|
| id | ◎ | 安定した英数字ID（例: `de-by`）。文言や進捗のキー |
| capitalId | ○ | 首都・県庁所在地の文言ID |
| flagAsset | 任意 | 旗の画像パス |
| neighbors | 任意 | 隣接地域のid（出題の難易度調整用） |
| tags | 任意 | 地方区分など |
| facts | 任意 | 産業・特産・雑学のid配列（地理パズル王・社会コレが使う。国別アプリでは未使用でもよい） |
| learning | 任意 | 学習要点（日本の学習指導要領など。国共通にしない） |

文言は **IDで引く**（日本語の文字列を直接キーにしない）。現状の `tr('日本語…')` 方式は pack では使わない。

**検証（PackValidator）**
- regions の全idが geo に存在し、逆も成立
- 宣言した全言語に、全地域の名称がある
- attribution / license が空でない
- ポリゴンの頂点数が上限以内（上限は計測して決める。暫定: 1地域あたり数千点）

## 4. 公開インターフェース（Dart・概要）
```dart
class RegionPack { /* load(assetPath), regions, geometry, strings(lang) */ }

class RegionMapView extends StatefulWidget {
  final RegionPack pack;
  final Map<String, RegionState> states; // id → 未/正解/ミス/ハイライト
  final void Function(String regionId) onRegionTap;
  final RegionMapStyle style;            // 色・線・ラベル表示
  final bool zoomable;                   // 小さい地域用（後述）
}

enum QuestionType { locateOnMap, nameFromMap, capitalFromName,
                    nameFromCapital, flagFromName, silhouette }

class QuizEngine {
  QuizEngine(RegionPack pack, {int? seed});
  Question next(QuestionType type, {Difficulty difficulty});
  AnswerResult check(Question q, Object answer);
}

abstract class ProgressStore {              // 保存先はアプリ側（Hive等）が実装
  Future<RegionState> get(String regionId);
  Future<void> put(String regionId, RegionState state);
}

class DailyChallenge {
  DailyChallenge(RegionPack pack, DateTime date);
  List<Question> questions;                 // 日付＋packIdで決定（全員同じ）
  String shareText(List<AnswerResult> r);   // 絵文字グリッド（🟩🟥）
}
```
- MVP の Must 5個との対応: 地図タップ=RegionMapView／4択=QuizEngine／形当て=silhouette／進捗・称号=ProgressStore＋地図の塗り／デイリー=DailyChallenge。課金はアプリ側（app_common_kit の entitlement）

## 5. 地図描画の仕様
- 自前描画（`CustomPainter`）。タイル・ネット接続なし（社会コレの `flutter_map` 版は日本の国土地理院タイルを使うため、海外に流用不可）
- 投影: 既存方式（経度を cos(中心緯度) で補正した等角図法）を既定とする。米国は離島の別枠表示が必要
- タップ判定: 描画時のパスを保持し、`Path.contains` で判定（既存と同じ）
- **小さい地域への対策（ドイツ版の最初の課題）**: ベルリン・ブレーメン・ハンブルクなどの都市州は、そのままだとタップできない。**決定（v0.2）: 1＋2を採用**
  1. ピンチズーム＋パン（`InteractiveViewer`）
  2. 最小タップ領域（描画サイズが閾値より小さい地域には、重心を中心に円形のヒット領域を追加。閾値は実機で決める）
  - 3（小地域の拡大インセット）は v0 では採用しない。米国のアラスカ・ハワイの別枠表示だけ、pack.json の insets で対応する
  - 2のヒット領域が隣接地域と重なる場合は、面積が小さいほうを優先してタップ判定する
- 既存コードからの一般化: 沖縄の別枠が直書きされている部分を insets 設定へ、`PrefectureRecord` 依存を `RegionState` へ、`AppLocalizations` 依存を外す

## 6. 既存コードからの切り出し計画
| 移すもの | 元 | 変更点 |
|---|---|---|
| 地図描画・タップ判定 | 地理パズル王 `japan_map_widget.dart`（約400行） | 沖縄直書き→insets、依存の除去、GeoJSON読み込みへ |
| 境界データの形式 | `japan_prefecture_boundaries.dart`（Dart定数） | GeoJSON assetsへ変換（`generate_prefecture_boundaries.py` を流用） |
| GeoJSON読み込みの考え方 | 社会コレ `world_map_widget.dart`（GeoJSONをassetsから解析） | pack形式に合わせて整理 |
| 4択出題の型 | 地理パズル王 `prefecture_quiz_data.dart` | 直書き→pack＋生成（首都・旗など） |

移さないもの: TD（`td_model` ほか）、ランキング、HQ・実績、Firebase、広告（アプリ側）

## 7. 受け入れ条件（テスト）
- **回帰**: 日本の pack（既存データから変換）で、地理パズル王の現行の地図と見た目が一致する（ゴールデン画像テスト）
- **新規**: ドイツ pack（16州）で、全州がタップ可能（都市州を含む）
- **出題**: 同じ seed で同じ問題列（デイリーの再現性）。選択肢は重複せず、正解を必ず含む
- **検証**: PackValidator が、欠けた翻訳・idの不一致を検出する
- **性能**: 中程度の端末で、地図の表示・タップ応答がもたつかない（数値目標は実測してから決める）

## 8. マイルストーン
| M | 内容 | 完了の目安 |
|---|---|---|
| M0 | pack形式の確定、日本packの変換、PackValidator | 日本packが検証を通る |
| M1 | RegionMapView（日本packで既存と一致） | ゴールデンテスト合格 |
| M2 | QuizEngine、ProgressStore、DailyChallenge | 単体テスト合格 |
| M3 | ドイツpack＋ドイツ版アプリ（最小） | 実機で全州タップ・1ゲーム完走 |
| M4 | 米国pack（インセット含む）＋米国版 | 同上 |

## 9. 未決・要確認
1. **データのライセンス**: ドイツ・米国は調査済み（10章）。日本（国土地理院）は現行規約の本文が取得できず**未確認**。自分でページを開いて確認するか、国土地理院に問い合わせる
2. 社会コレの `world_map` のデータ（国境ポリゴン）の出典とライセンス
3. ~~小さい地域の対策~~ → **決定**: ズーム＋最小タップ領域（5章）。最小タップ領域の閾値は実機で決める
4. 米国の投影方式（アラスカ・ハワイを別枠にするか）
5. 新規リポジトリ名は **`region_core` に決定**。公開範囲は未決（公開にする場合は app-privacy-security で匿名化・セキュリティを確認してから）
6. 地理パズル王の現状（リリース済みか）。既存アプリへの `region_core` 導入は後回しの方針
7. 日本版の学習用（ふりがな・学習指導要領）をどこまで pack に持たせるか。国共通にせず、`learning` を任意項目にする

## 10. 境界データの出典とライセンス（2026-10-17調査）
法的判断ではない。公式ページの記載を読んだ範囲で、読めなかったものは「未確認」と明記。公開前に原文で再確認する。

| 出典 | 条件（確認できた内容） | 義務 | 未確認 |
|---|---|---|---|
| **Natural Earth**（世界の州・省の層） | パブリックドメイン。商用利用可。出典表示は不要（任意で「Made with Natural Earth」） | なし | 一部の第三者データは「世界の基本地図の作成」用途のみ許可とある。ドイツ・米国の州の層が、使う縮尺で必要な地域（都市州など）を含むかは**実データで要確認** |
| **ドイツ BKG VG250**（行政区域） | データライセンス・ドイツ・表示2.0（dl-de/by-2-0）。無償。加工可 | 出典表示（画面に見える形）。**加工した場合は変更の表示**。表記の雛形: 「© BKG（最終データ取得年）dl-de/by-2-0、データ出典: （規定のURL）」 | 商用利用への言及は取得ページになし。ライセンス本文は取得できず（アクセス拒否）。**本文を読んで確認** |
| **米国 Census Bureau**（州の境界ファイル） | 連邦政府の著作物として扱われる記載。製品への利用は無償 | 出典として U.S. Census Bureau を明記 | ライセンス欄は空。1:500,000 の州別ファイルは2025年版で確認。1:5,000,000 / 1:20,000,000 は全国ファイルのみ確認（州の抽出可否は未確認） |
| **日本 地球地図日本（国土地理院）** | 公式ページに「国土地理院コンテンツ利用規約が適用される」とのみ記載 | 規約本体は取得不可（アクセス拒否）のため**未確認** | 現行規約で、出典表示以外に「利用報告」が必要か。**要確認** |
| 日本の現行データ（`dataofjapan/land` 経由） | リポジトリは独自ライセンスを明記せず、元の配布元の条件に従うとする。READMEは旧条件として「出典の明記」「商用は著作権者への利用報告」を記載 | 同左（旧条件のまま） | 非公式ミラーであること自体のリスク。一次配布元から取り直すか検討 |

**制約・注意**
- 米国 Census の境界ファイルは、掲載の縮尺より拡大して表示しない、面積・周長の計算など地理分析には使わない、とされる。クイズ表示には問題なさそうだが、**ズームの上限は決めておく**（拡大しすぎない）
- ドイツ BKG を加工（頂点の簡略化）して使う場合は、変更した旨の表示が必要
- 日本版は、規約の確認が済むまで公開しない。既存の2ファイルの記載の食い違い（「対応済み/予定」と「別途対応要」）の理由は不明

**推奨（暫定）**
1. ドイツ版・米国版の初版は、**Natural Earth** を第一候補にする（義務が最小）。実データで都市州などの欠落や形の粗さを確認し、足りなければ BKG / Census に切り替える
2. 切り替えた場合に備え、pack.json の attribution / license 欄を必須にしてあるので、出典表示は pack から自動で出せるようにする
3. 日本版は、国土地理院の現行規約を確認してから公開判断
