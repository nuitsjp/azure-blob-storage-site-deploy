#!/usr/bin/env bats

setup() {
  export MOCK_AZURE_LOG_FILE="${BATS_TEST_TMPDIR}/mock-azure.log"
  export TEST_SOURCE_DIR="${BATS_TEST_TMPDIR}/site"

  mkdir -p "${TEST_SOURCE_DIR}/sub"
  printf '%s\n' "index" > "${TEST_SOURCE_DIR}/index.html"
  printf '%s\n' "sub" > "${TEST_SOURCE_DIR}/sub/page.html"

  source "${BATS_TEST_DIRNAME}/../../tests/helpers/mock_azure.sh"
  source "${BATS_TEST_DIRNAME}/../../scripts/deploy.sh"

  mock_azure_reset
}

@test "deploy_main: delete-batch -> upload-batch の順で実行しURLを出力する" {
  run deploy_main "examplestorage" "${TEST_SOURCE_DIR}" "pr-42"
  [ "$status" -eq 0 ]
  [ "$output" = "https://examplestorage.z22.web.core.windows.net/pr-42/" ]

  [ "$(mock_azure_call_count)" = "2" ]

  local log
  log="$(mock_azure_read_log)"

  local delete_line upload_line
  delete_line="$(printf '%s\n' "$log" | grep -n 'arg=delete-batch' | head -n 1 | cut -d: -f1)"
  upload_line="$(printf '%s\n' "$log" | grep -n 'arg=upload-batch' | head -n 1 | cut -d: -f1)"

  [ -n "$delete_line" ]
  [ -n "$upload_line" ]
  [ "$delete_line" -lt "$upload_line" ]

  [[ "$log" == *"arg=--account-name"* ]]
  [[ "$log" == *"arg=examplestorage"* ]]
  [[ "$log" == *"arg=--pattern"* ]]
  [[ "$log" == *"arg=pr-42/\\*"* ]]
  [[ "$log" == *"arg=--source"* ]]
  [[ "$log" == *"arg=${TEST_SOURCE_DIR}"* ]]
  [[ "$log" == *"arg=--destination-path"* ]]
  [[ "$log" == *"arg=pr-42"* ]]
}

@test "deploy_main: バリデーションエラー時は az 呼び出しを行わない" {
  run deploy_main "examplestorage" "${TEST_SOURCE_DIR}" "feature/add-docs"
  [ "$status" -eq 1 ]
  [[ "$output" == *"ハイフン"* ]]

  [ "$(mock_azure_call_count)" = "0" ]
}
