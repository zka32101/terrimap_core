# iOS ホーム画面ウィジェット 導入手順 v0.1

Android 版と同じ中身（ストリーク日数・今日の名所・今日のチャレンジ）を、WidgetKit（SwiftUI）で出す。**Xcode でのターゲット作成が要るので、手元の Mac で行う**（この環境では、Xcode がなく、ビルドを確認できていない）。

## すでに用意してあるもの（両アプリ）
- `lib/widget_sync.dart`: `HomeWidgetSync` が、iOS では App Group を設定し（`setAppGroupId`）、3つの文字列（`streak` / `landmark` / `status`）を書き、`updateWidget(iOSName: 'StreakWidget')` で更新を知らせる。拡張が無い・未設定でも、例外は握りつぶされ、アプリは普通に動く
- `ios/StreakWidget/StreakWidget.swift`: ウィジェット本体（小サイズ）。App Group の UserDefaults から3つの文字列を読んで出す。**このフォルダは Xcode のプロジェクトには入っていない**（ビルドに影響しない）

## ID の決まり
| アプリ | Runner の Bundle ID | App Group（コードの `iosAppGroup`） |
|---|---|---|
| ge（ドイツ） | `dev.terrimap.terrimapDe` | `group.dev.terrimap.terrimapDe` |
| us（米国） | `dev.terrimap.terrimapUs`（下の注意を参照） | `group.dev.terrimap.terrimapUs` |

拡張の Bundle ID は、Runner の Bundle ID に `.StreakWidget` を付ける（例 `dev.terrimap.terrimapDe.StreakWidget`）。

## 手順（アプリごとに1回）
1. `open ios/Runner.xcworkspace` で Xcode を開く
2. File → New → Target… → **Widget Extension**。Product Name は `StreakWidget`、「Include Live Activity」「Include Configuration App Intent」は外す。Embed in Application は Runner
3. 自動で作られた Swift ファイル（`StreakWidget.swift` など）を削除し、`ios/StreakWidget/StreakWidget.swift` をターゲットに追加する（Xcode が作った同名フォルダは、このファイルで置き換える）
4. **App Group**: Runner と StreakWidget の両ターゲットで、Signing & Capabilities → ＋Capability → App Groups → 上の表の App Group を追加（Apple Developer の Identifiers にも、同じ App Group を登録する）
5. iOS の Deployment Target は 14.0 以上（`widgetBackground` が iOS 17 の API を使えない場合の分岐を持っている）
6. 実機かシミュレータで Runner を起動 → ホーム画面を長押し → ＋ → Terrimap → 小サイズを追加

## 確認すること
- 追加直後に、日数・名所名・チャレンジの状態が出る（アプリを一度起動して、クイズかバトルを1回してから）
- クイズに答えたあと、ウィジェットが更新される
- 言語を切り替えたあと、ウィジェットの文言が変わる
- ダークテーマ、アプリを閉じて再起動したあと
- 失敗するとき: App Group の id が、Runner・拡張・コードの3か所で同じか／両ターゲットに Capability があるか

## 注意（us の Bundle ID）
`terrimap_us` の `ios/Runner.xcodeproj/project.pbxproj` の `PRODUCT_BUNDLE_IDENTIFIER` が、現在 **ge と同じ `dev.terrimap.terrimapDe`** のまま（コピーの名残とみられる。Android の applicationId は `dev.terrimap.terrimap_us`）。このままだと、ストアに出すときに ge と衝突するので、公開前に `dev.terrimap.terrimapUs` などに直す（Apple 側の App ID の登録に合わせる）。直したら、上の表の ID と `lib/widget_sync.dart` の `iosAppGroup` を、その ID に合わせる。この PR では変えていない（公開の識別子なので、人が決める）。
