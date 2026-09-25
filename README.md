# NewDen

ひとつの主題と3つの要素を「田」の形で書く、iPhone向けのジャーナルです。

## 開発

- Xcode 27 / Swift 6、iOS 26.0以降。
- `NewDen.xcodeproj` を開き、共有Scheme `NewDen` とiPhone Simulatorを選んで実行します。
- 実機で実行する場合は、NewDenターゲットのSigning & Capabilitiesで開発Teamを設定してください。
- 外部ライブラリはありません。保存にはSwiftDataを使用し、CloudKitは無効です。
- プロジェクト本体をリポジトリに含めています。構成を変更するときのみ、XcodeGenで `project.yml` から `xcodegen generate` を実行してください。

## 最初の実装単位（段階1〜3）

- 田んぼ一覧、新規作成、削除、更新日時順の表示。
- 固定6種類の型、2×2のマス、編集シート、未完／完成の表示。
- 完了で保存、キャンセルで破棄。編集中にバックグラウンドへ移ると確定します。
- Three Good Thingsの主題への日本語日付入力。
- 最大4階層の子作成と通常の画面遷移。子の主題は親の要素と共有します。
- 操作単位のUndo／Redo、永続化、保存エラー表示と再試行。
- VersionedSchema・SchemaMigrationPlan、メモリ内ストアを使うPreview。

入れ子配置、段階ズーム、パンくず、周囲の田の表示は段階4です。リンク・参照・発展のモデル属性は、それぞれを実装する段階で新しいスキーマとして追加します。

## Undoの実装

SwiftDataの自動Undoで親子関係の欠落と削除復元時のクラッシュを再現したため、対象の田んぼの値スナップショットをシステムのUndoManagerに登録しています。復元時はUUIDを維持し、その場で再保存します。保存失敗時は変更を保持し、再試行が成功するまで追加の保存操作を止めます。

## テスト

XcodeのProduct > Test、または次のコマンドを使います（端末名は利用可能なものに置き換えてください）。

```sh
xcodebuild -project NewDen.xcodeproj -scheme NewDen \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' test
```

`NewDenTests` はSwift Testingによる保存・操作ルールの検証、`NewDenUITests` はXCUITestによる編集・キャンセル・Undo／Redo・終了後の再表示の検証です。UIテストは起動ごとに専用の保存先を指定し、通常の保存データには触れません。

2026-09-25時点で、iOS 27.0（iPhone 18 Pro）とiOS 26.2（iPhone 16e）の保存・操作テスト13本（パラメータ展開で20ケース）が成功しています。両環境でUIテストも成功し、4マス編集・キャンセル・Undo／Redo・バックグラウンド確定・終了後の再表示を確認しました。

実機の日本語IME・シェイクUndo・VoiceOver、およびiOS 26.0そのものは未確認です。

仕様と計画は [docs/concept.md](docs/concept.md)、[docs/data-model.md](docs/data-model.md)、[docs/implementation-plan.md](docs/implementation-plan.md) を参照してください。
