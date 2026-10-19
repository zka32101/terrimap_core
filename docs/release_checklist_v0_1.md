# リリース前チェック v0.1（terrimap_ge / terrimap_us）

## リポジトリ側の現状（確認済み）
| 項目 | 現状 | 公開前にやること |
|---|---|---|
| applicationId | `dev.terrimap.terrimap_de` / `dev.terrimap.terrimap_us` | 変更不可になるので最終確認 |
| バージョン | 0.1.0+1 | 提出ごとに +1 |
| プライバシーポリシー/利用規約URL | `lib/legal.dart` が空 | URLを用意して設定（ストア申告にも必須） |
| AdMob アプリID | Google のテストID（AndroidManifest / Info.plist） | 本番IDへ置換 |
| 広告ユニットID | デバッグはテストID | リリース用の本番IDを設定 |
| 権限 | POST_NOTIFICATIONS, RECEIVE_BOOT_COMPLETED（リマインダー）、広告ID | データセーフティに記載 |
| 署名 | 未確認 | リリース用キーストアを用意 |

## データセーフティ申告の材料
- 端末内保存のみ: 進捗、履歴、設定（SharedPreferences）。サーバー送信なし。
- 広告SDK（AdMob）が広告IDを使う。iOSはATT文言あり。
- 通知は端末内のローカル通知（時刻は端末のタイムゾーン）。

## ストア掲載
- 掲載文: `docs/store_listing_v0_1.md`（新機能の段落を追加済み。他言語は未反映 → 翻訳後に追加）。
- スクリーンショット案は同ファイル末尾。新機能（週間グラフ・共有カード）の画面も1〜2枚入れる。

## 実機でのみ確認できるもの
`docs/device_check_battle_v0_1.md` の 7c（音・BGM・通知・共有シート・広告・購入）。

## ユーザー側の未了
- 翻訳（機械翻訳）のネイティブ確認、名所の事実確認、Leonardo 利用規約の確認。
- 小さい画面でのチュートリアル表示、ダークテーマの見た目。
- ホーム画面ウィジェットは未実装（ネイティブ検証が必要）。
