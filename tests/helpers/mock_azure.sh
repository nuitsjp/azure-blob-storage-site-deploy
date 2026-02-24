#!/usr/bin/env bash

mock_azure_default_log_file() {
  printf '%s\n' "${BATS_TEST_TMPDIR:-/tmp}/mock-azure.log"
}

mock_azure_log_file() {
  printf '%s\n' "${MOCK_AZURE_LOG_FILE:-$(mock_azure_default_log_file)}"
}

mock_azure_reset() {
  : > "$(mock_azure_log_file)"
}

mock_azure_record_call() {
  local log_file
  log_file="$(mock_azure_log_file)"
  mkdir -p "$(dirname "$log_file")"

  {
    printf 'argc=%s\n' "$#"
    local arg
    for arg in "$@"; do
      printf 'arg=%q\n' "$arg"
    done
    printf -- '---\n'
  } >> "$log_file"
}

mock_azure_call_count() {
  local log_file
  log_file="$(mock_azure_log_file)"

  if [[ ! -f "$log_file" ]]; then
    printf '0\n'
    return 0
  fi

  grep -c '^---$' "$log_file"
}

mock_azure_read_log() {
  local log_file
  log_file="$(mock_azure_log_file)"

  if [[ -f "$log_file" ]]; then
    cat "$log_file"
  fi
}

az() {
  mock_azure_record_call "$@"
}
