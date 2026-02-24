#!/usr/bin/env bats

setup() {
  export MOCK_AZURE_LOG_FILE="${BATS_TEST_TMPDIR}/mock-azure.log"

  source "${BATS_TEST_DIRNAME}/../../tests/helpers/mock_azure.sh"
  source "${BATS_TEST_DIRNAME}/../../scripts/cleanup.sh"

  mock_azure_reset
}

@test "cleanup_main: pull_request_number 指定時は site_name/pr-<number> で delete-batch を実行する" {
  run cleanup_main "examplestorage" "" "42" "cleanup" "api-docs"
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
  [[ "$log" == *"arg=api-docs/pr-42/\\*"* ]]
}

@test "cleanup_main: branch_name 指定時は site_name/branch_name で delete-batch を実行する" {
  run cleanup_main "examplestorage" "develop" "" "cleanup" "user-guide"
  [ "$status" -eq 0 ]

  [ "$(mock_azure_call_count)" = "1" ]

  local log
  log="$(mock_azure_read_log)"

  [[ "$log" == *"arg=user-guide/develop/\\*"* ]]
}

@test "cleanup_main: バリデーションエラー時は az 呼び出しを行わない（prefix未指定）" {
  run cleanup_main "examplestorage" "" "" "cleanup" "api-docs"
  [ "$status" -eq 1 ]
  [[ "$output" == *"branch_name または pull_request_number"* ]]

  [ "$(mock_azure_call_count)" = "0" ]
}

@test "cleanup_main: バリデーションエラー時は az 呼び出しを行わない（site_name未指定）" {
  run cleanup_main "examplestorage" "" "42" "cleanup" ""
  [ "$status" -eq 1 ]
  [[ "$output" == *"site_name"* ]]

  [ "$(mock_azure_call_count)" = "0" ]
}
