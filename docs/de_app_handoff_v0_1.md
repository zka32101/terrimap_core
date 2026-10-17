# ドイツ版アプリ 実装引き渡し v0.1(Claude Code向け)
仮称: State Master – Germany(アプリ名・bundle IDは未確定。要決定)

## 前提
- region_core(/tmp/outputs/region_core)をgit依存で取り込む。packs/de を assets に同梱。
- 共通基盤は app_common_kit(設定・広告・RevenueCat・同意・進捗)。※再利用範囲は未確認。最初に pubspec と公開APIを読んで確認すること。
- 言語: 英語(既定)+ドイツ語。端末言語で切替。

## MVP(Must 5+デイリー)
1. 地図タップ(RegionMapView、全16州、都市州は拡大で押せること)
2. 4択(地図から州名/州名から首都)
3. 形当て(任意。M2のQuestionTypeに追加が必要)
4. 進捗: 正解済み州を塗る、称号(titleFor、閾値は仮)
5. 課金: 無料=最初の4〜5州+広告、買い切り=全州解放+広告除去(サブスクなし)
6. デイリー(DailyChallenge、5問、🟩🟥共有)

## 画面
ホーム(地図+進捗) / クイズ / デイリー / 設定(言語・購入復元・プライバシー・出典)

## 法務・ストア
- 出典表示「Made with Natural Earth」を設定画面に表示
- GDPR同意(app_common_kit の consent)。子ども向けにしない(COPPA/GDPR-K回避)
- 国旗を使う場合は別途ライセンス確認(今回は未使用)

## 検証KPI(仮)
D1/D7、課金転換率、ARPDAU、CPI。2〜4週間公開して判断。

## 未確認・要確認
- Flutter実行環境がなく、region_coreのDartコードは未実行。最初に flutter test / analyze を通すこと。
- 都市州(ベルリン・ブレーメン・ハンブルク)の実機タップ確認。
- アプリ名、bundle ID、価格(Tier)、無料州の選定。
