#!/usr/bin/env bash

script_dir() {
  local source_path="${BASH_SOURCE[0]}"
  cd "$(dirname "$source_path")" && pwd
}

cleanup_load_libs() {
  local dir
  dir="$(script_dir)"

  # テストでは同一シェル内で source して az をモック差し替えする。
  source "${dir}/lib/validate.sh"
  source "${dir}/lib/prefix.sh"
  source "${dir}/lib/azure.sh"
}

cleanup_main() {
  local storage_account="${1-${INPUT_STORAGE_ACCOUNT-}}"
  local target_prefix="${2-${INPUT_TARGET_PREFIX-}}"
  local action="${3-${INPUT_ACTION-cleanup}}"
  local blob_pattern

  validate_action "$action" || return 1
  validate_storage_account "$storage_account" || return 1
  validate_target_prefix "$target_prefix" || return 1

  blob_pattern="$(build_blob_pattern "$target_prefix")" || return 1

  azure_delete_prefix "$storage_account" "$blob_pattern" || return 1
}

cleanup_load_libs

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
  cleanup_main "$@"
fi
