#!/usr/bin/env bats

setup() {
  source "${BATS_TEST_DIRNAME}/../../scripts/lib/validate.sh"
}

@test "validate_storage_account: 正常な値を許可する" {
  run validate_storage_account "abc123"
  [ "$status" -eq 0 ]
}

@test "validate_storage_account: 2文字は拒否する" {
  run validate_storage_account "ab"
  [ "$status" -eq 1 ]
  [[ "$output" == *"3〜24文字"* ]]
}

@test "validate_storage_account: 25文字は拒否する" {
  run validate_storage_account "abcdefghijklmnopqrstuvwxyz"
  [ "$status" -eq 1 ]
  [[ "$output" == *"3〜24文字"* ]]
}

@test "validate_storage_account: 大文字を拒否する" {
  run validate_storage_account "Abc123"
  [ "$status" -eq 1 ]
  [[ "$output" == *"小文字英数字"* ]]
}

@test "validate_action: deploy を許可する" {
  run validate_action "deploy"
  [ "$status" -eq 0 ]
}

@test "validate_action: cleanup を許可する" {
  run validate_action "cleanup"
  [ "$status" -eq 0 ]
}

@test "validate_action: 未定義の値を拒否する" {
  run validate_action "delete"
  [ "$status" -eq 1 ]
  [[ "$output" == *"deploy または cleanup"* ]]
}

@test "validate_source_dir: cleanup では空でも許可する" {
  run validate_source_dir "cleanup" ""
  [ "$status" -eq 0 ]
}

@test "validate_source_dir: deploy では空を拒否する" {
  run validate_source_dir "deploy" ""
  [ "$status" -eq 1 ]
  [[ "$output" == *"action=deploy"* ]]
}

@test "validate_source_dir: deploy で存在するディレクトリを許可する" {
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  run validate_source_dir "deploy" "$tmp_dir"
  rm -rf "$tmp_dir"
  [ "$status" -eq 0 ]
}

@test "validate_source_dir: deploy で存在しないディレクトリを拒否する" {
  run validate_source_dir "deploy" "${BATS_TEST_TMPDIR}/not-found"
  [ "$status" -eq 1 ]
  [[ "$output" == *"ディレクトリではありません"* ]]
}

@test "validate_target_prefix: main を許可する" {
  run validate_target_prefix "main"
  [ "$status" -eq 0 ]
}

@test "validate_target_prefix: pr-42 を許可する" {
  run validate_target_prefix "pr-42"
  [ "$status" -eq 0 ]
}

@test "validate_target_prefix: 空文字を拒否する" {
  run validate_target_prefix ""
  [ "$status" -eq 1 ]
  [[ "$output" == *"必須"* ]]
}

@test "validate_target_prefix: スラッシュを拒否する" {
  run validate_target_prefix "feature/add-docs"
  [ "$status" -eq 1 ]
  [[ "$output" == *"ハイフン"* ]]
}

@test "validate_target_prefix: 先頭ハイフンを拒否する" {
  run validate_target_prefix "-preview"
  [ "$status" -eq 1 ]
  [[ "$output" == *"先頭"* ]]
}
