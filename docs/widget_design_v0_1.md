# ホーム画面ウィジェット 設計 v0.1（Android 実装済み・iOS はソースと導入手順まで）

ネイティブ（Kotlin/XML、iOSはSwiftUI）が必要で、開発環境にAndroid SDK/Xcodeが無くビルド検証できないため、実装は手元の環境で行う。

## 表示内容（小・1×2程度）
- ストリーク日数（`DailyStreak.currentOn(today)`）
- 今日の名所の名前（`DailyLandmark.pick`）。タップでアプリ起動
- 今日のチャレンジが済んでいるか（済 / 未）

## 方式
- パッケージ: `home_widget`（Flutter→ウィジェットへ SharedPreferences / App Group 経由でデータを渡す）。
- Dart側: `AppState` の更新時（ストリーク・チャレンジ完了・言語変更）に `HomeWidget.saveWidgetData` → `updateWidget`。文言は `UiStrings` の翻訳を渡す。純粋なデータ組み立ては core に `WidgetSnapshot`（テスト可）として置く。
- Android: `AppWidgetProvider`（Kotlin）、`res/xml/widget_info.xml`、`res/layout/widget.xml`、manifest に receiver。更新間隔は端末任せ＋アプリ側から更新。
- iOS: WidgetKit 拡張＋App Group。ターゲット追加が必要（Xcode作業）。

## 注意
- 日付: デイリーは UTC、端末の0時とずれる。ウィジェットは「最終更新日」を持ち、古ければ「未」扱いにしない（表示を隠す）。
- 個人情報は保存しない（日数と名所名のみ）。データセーフティの変更なし。
- 両アプリ（ge/us）に同じ構成。applicationId ごとに provider 名を合わせる。

## 手元での確認
- ホームに追加→表示、アプリでクイズ後に更新、言語切替、ダークテーマ、再起動後も残る。
- 実装後は `docs/device_check_battle_v0_1.md` に項目を追加。

## iOS の状況
SwiftUI のソース（各アプリの `ios/StreakWidget/StreakWidget.swift`）と、Dart 側の書き出しは用意した。Xcode での拡張ターゲットの作成・App Group の設定は手元で行う: [`ios_widget_setup_v0_1.md`](ios_widget_setup_v0_1.md)。
