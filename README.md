# terrimap_core
Terrimap シリーズの共通エンジン(地図表示・タップ、出題、進捗、デイリー、packローダー)。

- `lib/` — pack / map / quiz / progress / daily(Dart。未実行: `flutter test` / `flutter analyze` は未確認)
- `packs/de`, `packs/us` — 国別データ(Natural Earth、パブリックドメイン)
- `tools/` — `convert_de.py` `convert_us.py`(変換)、`validate_pack.py`(検証)
- `test/` — 単体テスト

## 注意
- 日本pack(`packs/jp`)は出典の利用規約が未確認のため、このリポジトリには含めません(.gitignore)。
- 出典表示: Made with Natural Earth (naturalearthdata.com)
