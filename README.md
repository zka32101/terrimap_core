# terrimap_core
Terrimap シリーズの共通エンジン(地図表示・タップ、出題、進捗、デイリー、packローダー)。

- `lib/` — pack / map / quiz / progress / daily(Dart。`flutter analyze` クリーン、`flutter test` 20件通過を確認済み)
- `packs/de`, `packs/us` — 国別データ(Natural Earth、パブリックドメイン)
- `tools/` — `convert_de.py` `convert_us.py`(変換)、`validate_pack.py`(検証)
- `test/` — 単体テスト

## 注意
- 日本pack(`packs/jp`)は出典の利用規約が未確認のため、このリポジトリには含めません(.gitignore)。
- 出典表示: Made with Natural Earth (naturalearthdata.com)

## 資料(docs/)
- `state-master-spec_v0_5.md` — 企画仕様(旧称 State Master。現ブランドは Terrimap)
- `region_core_min_spec_v0_2.md` — エンジン最小仕様(旧パッケージ名 region_core = 現 terrimap_core)
- `de_app_handoff_v0_1.md` — ドイツ版アプリ引き渡し
- `progress_M0-M4_2026-10-17.md` — 進捗メモ
- `terrimap_icon_design_v0_1.md` — シリーズアイコン共通設計
