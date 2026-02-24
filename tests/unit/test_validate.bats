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

# --- validate_pull_request_number ---

@test "validate_pull_request_number: 正の整数を許可する" {
  run validate_pull_request_number "42"
  [ "$status" -eq 0 ]
}

@test "validate_pull_request_number: 1を許可する" {
  run validate_pull_request_number "1"
  [ "$status" -eq 0 ]
}

@test "validate_pull_request_number: 0を拒否する" {
  run validate_pull_request_number "0"
  [ "$status" -eq 1 ]
  [[ "$output" == *"正の整数"* ]]
}

@test "validate_pull_request_number: 負の数を拒否する" {
  run validate_pull_request_number "-1"
  [ "$status" -eq 1 ]
  [[ "$output" == *"正の整数"* ]]
}

@test "validate_pull_request_number: 英字を拒否する" {
  run validate_pull_request_number "abc"
  [ "$status" -eq 1 ]
  [[ "$output" == *"正の整数"* ]]
}

@test "validate_pull_request_number: 空文字を拒否する" {
  run validate_pull_request_number ""
  [ "$status" -eq 1 ]
  [[ "$output" == *"正の整数"* ]]
}

# --- validate_branch_name ---

@test "validate_branch_name: main を許可する" {
  run validate_branch_name "main"
  [ "$status" -eq 0 ]
}

@test "validate_branch_name: pr-42 を許可する" {
  run validate_branch_name "pr-42"
  [ "$status" -eq 0 ]
}

@test "validate_branch_name: 空文字を拒否する" {
  run validate_branch_name ""
  [ "$status" -eq 1 ]
  [[ "$output" == *"必須"* ]]
}

@test "validate_branch_name: スラッシュを拒否する" {
  run validate_branch_name "feature/add-docs"
  [ "$status" -eq 1 ]
  [[ "$output" == *"ハイフン"* ]]
}

@test "validate_branch_name: 先頭ハイフンを拒否する" {
  run validate_branch_name "-preview"
  [ "$status" -eq 1 ]
  [[ "$output" == *"先頭"* ]]
}

# --- validate_prefix_inputs ---

@test "validate_prefix_inputs: pull_request_number のみ指定で成功する" {
  run validate_prefix_inputs "" "42"
  [ "$status" -eq 0 ]
}

@test "validate_prefix_inputs: branch_name のみ指定で成功する" {
  run validate_prefix_inputs "main" ""
  [ "$status" -eq 0 ]
}

@test "validate_prefix_inputs: 両方指定時は pull_request_number のバリデーションのみ実行する" {
  run validate_prefix_inputs "feature/foo" "42"
  [ "$status" -eq 0 ]
}

@test "validate_prefix_inputs: 両方空で失敗する" {
  run validate_prefix_inputs "" ""
  [ "$status" -eq 1 ]
  [[ "$output" == *"branch_name または pull_request_number"* ]]
}

@test "validate_prefix_inputs: 不正な pull_request_number で失敗する" {
  run validate_prefix_inputs "" "abc"
  [ "$status" -eq 1 ]
  [[ "$output" == *"正の整数"* ]]
}

@test "validate_prefix_inputs: 不正な branch_name で失敗する" {
  run validate_prefix_inputs "feature/add-docs" ""
  [ "$status" -eq 1 ]
  [[ "$output" == *"ハイフン"* ]]
}
