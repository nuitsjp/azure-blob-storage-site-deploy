#!/usr/bin/env bats

setup() {
  source "${BATS_TEST_DIRNAME}/../../scripts/lib/prefix.sh"
}

@test "build_site_url: プレフィックス付きURLを生成し末尾スラッシュを付与する" {
  run build_site_url "examplestorage" "main"
  [ "$status" -eq 0 ]
  [ "$output" = "https://examplestorage.z22.web.core.windows.net/main/" ]
}

@test "build_site_url: prプレフィックスでも末尾スラッシュを付与する" {
  run build_site_url "examplestorage" "pr-42"
  [ "$status" -eq 0 ]
  [ "$output" = "https://examplestorage.z22.web.core.windows.net/pr-42/" ]
}

@test "build_site_url: プレフィックス空文字ではルートURLを返す" {
  run build_site_url "examplestorage" ""
  [ "$status" -eq 0 ]
  [ "$output" = "https://examplestorage.z22.web.core.windows.net/" ]
}

@test "build_site_url: プレフィックスがスラッシュのみでもルートURLを返す" {
  run build_site_url "examplestorage" "/"
  [ "$status" -eq 0 ]
  [ "$output" = "https://examplestorage.z22.web.core.windows.net/" ]
}

@test "build_site_url: 前後スラッシュを正規化する" {
  run build_site_url "examplestorage" "/preview/"
  [ "$status" -eq 0 ]
  [ "$output" = "https://examplestorage.z22.web.core.windows.net/preview/" ]
}

@test "build_site_url_from_endpoint: エンドポイントとプレフィックスからURLを生成する" {
  run build_site_url_from_endpoint "https://examplestorage.z11.web.core.windows.net" "pr-42"
  [ "$status" -eq 0 ]
  [ "$output" = "https://examplestorage.z11.web.core.windows.net/pr-42/" ]
}

@test "build_site_url_from_endpoint: エンドポイント末尾スラッシュとプレフィックスを正規化する" {
  run build_site_url_from_endpoint "https://examplestorage.z11.web.core.windows.net/" "/preview/"
  [ "$status" -eq 0 ]
  [ "$output" = "https://examplestorage.z11.web.core.windows.net/preview/" ]
}

@test "build_blob_pattern: プレフィックス付きパターンを生成する" {
  run build_blob_pattern "main"
  [ "$status" -eq 0 ]
  [ "$output" = "main/*" ]
}

@test "build_blob_pattern: prプレフィックスのパターンを生成する" {
  run build_blob_pattern "pr-42"
  [ "$status" -eq 0 ]
  [ "$output" = "pr-42/*" ]
}

@test "build_blob_pattern: プレフィックス空文字では全件パターンを返す" {
  run build_blob_pattern ""
  [ "$status" -eq 0 ]
  [ "$output" = "*" ]
}

@test "build_blob_pattern: プレフィックスがスラッシュのみでも全件パターンを返す" {
  run build_blob_pattern "/"
  [ "$status" -eq 0 ]
  [ "$output" = "*" ]
}

@test "build_blob_pattern: 前後スラッシュを正規化する" {
  run build_blob_pattern "/preview/"
  [ "$status" -eq 0 ]
  [ "$output" = "preview/*" ]
}

# --- resolve_target_prefix ---

@test "resolve_target_prefix: branch_name のみ指定時はそのまま返す" {
  run resolve_target_prefix "main" ""
  [ "$status" -eq 0 ]
  [ "$output" = "main" ]
}

@test "resolve_target_prefix: pull_request_number 指定時は pr-<number> を返す" {
  run resolve_target_prefix "feature/foo" "42"
  [ "$status" -eq 0 ]
  [ "$output" = "pr-42" ]
}

@test "resolve_target_prefix: branch_name 空でも pull_request_number があれば pr-<number> を返す" {
  run resolve_target_prefix "" "42"
  [ "$status" -eq 0 ]
  [ "$output" = "pr-42" ]
}
