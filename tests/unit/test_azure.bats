#!/usr/bin/env bats

setup() {
  source "${BATS_TEST_DIRNAME}/../../tests/helpers/mock_azure.sh"
  source "${BATS_TEST_DIRNAME}/../../scripts/lib/azure.sh"
  export MOCK_AZURE_LOG_FILE="${BATS_TEST_TMPDIR}/mock-azure.log"
  mock_azure_reset
}

@test "azure_delete_prefix: delete-batch の引数を組み立てる" {
  run azure_delete_prefix "examplestorage" "pr-42/*"
  [ "$status" -eq 0 ]

  [ "$(mock_azure_call_count)" = "1" ]

  run mock_azure_read_log
  [ "$status" -eq 0 ]
  [[ "$output" == *"arg=storage"* ]]
  [[ "$output" == *"arg=blob"* ]]
  [[ "$output" == *"arg=delete-batch"* ]]
  [[ "$output" == *"arg=--account-name"* ]]
  [[ "$output" == *"arg=examplestorage"* ]]
  [[ "$output" == *"arg=--source"* ]]
  [[ "$output" == *"arg=\\$web"* ]]
  [[ "$output" == *"arg=--pattern"* ]]
  [[ "$output" == *"arg=pr-42/\\*"* ]]
  [[ "$output" == *"arg=--auth-mode"* ]]
  [[ "$output" == *"arg=login"* ]]
}

@test "azure_upload_dir: upload-batch の引数を組み立てる" {
  run azure_upload_dir "examplestorage" "./site" "pr-42"
  [ "$status" -eq 0 ]

  [ "$(mock_azure_call_count)" = "1" ]

  run mock_azure_read_log
  [ "$status" -eq 0 ]
  [[ "$output" == *"arg=upload-batch"* ]]
  [[ "$output" == *"arg=--source"* ]]
  [[ "$output" == *"arg=./site"* ]]
  [[ "$output" == *"arg=--destination"* ]]
  [[ "$output" == *"arg=\\$web"* ]]
  [[ "$output" == *"arg=--destination-path"* ]]
  [[ "$output" == *"arg=pr-42"* ]]
  [[ "$output" == *"arg=--overwrite"* ]]
  [[ "$output" == *"arg=true"* ]]
}

@test "azure_upload_dir: 空プレフィックス時は destination-path を付けない" {
  run azure_upload_dir "examplestorage" "./site" ""
  [ "$status" -eq 0 ]

  run mock_azure_read_log
  [ "$status" -eq 0 ]
  [[ "$output" != *"arg=--destination-path"* ]]
}

@test "mock_azure: 複数回の呼び出し件数を記録できる" {
  azure_delete_prefix "examplestorage" "main/*"
  azure_upload_dir "examplestorage" "./site" "main"

  [ "$(mock_azure_call_count)" = "2" ]
}
