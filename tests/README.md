# tests

テスト実行前にローカルへ bats-core を導入します。

## セットアップ

```bash
./scripts/install-bats.sh
```

## 動作確認

```bash
cd tests
PATH="$(pwd)/bin:$PATH" bats --version
```
