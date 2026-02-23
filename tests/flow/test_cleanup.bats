#!/usr/bin/env bats

setup() {
  export MOCK_AZURE_LOG_FILE="${BATS_TEST_TMPDIR}/mock-azure.log"

  source "${BATS_TEST_DIRNAME}/../../tests/helpers/mock_azure.sh"
  source "${BATS_TEST_DIRNAME}/../../scripts/cleanup.sh"

  mock_azure_reset
}

@test "cleanup_main: delete-batch を正しいパターンで1回だけ実行する" {
  run cleanup_main "examplestorage" "pr-42"
  [ "$status" -eq 0 ]
  [ "$output" = "" ]

  [ "$(mock_azure_call_count)" = "1" ]

  local log
  log="$(mock_azure_read_log)"

  [[ "$log" == *"arg=delete-batch"* ]]
  [[ "$log" != *"arg=upload-batch"* ]]
  [[ "$log" == *"arg=--account-name"* ]]
  [[ "$log" == *"arg=examplestorage"* ]]
  [[ "$log" == *"arg=--pattern"* ]]
  [[ "$log" == *"arg=pr-42/\\*"* ]]
}

@test "cleanup_main: バリデーションエラー時は az 呼び出しを行わない" {
  run cleanup_main "examplestorage" "feature/add-docs"
  [ "$status" -eq 1 ]
  [[ "$output" == *"ハイフン"* ]]

  [ "$(mock_azure_call_count)" = "0" ]
}
