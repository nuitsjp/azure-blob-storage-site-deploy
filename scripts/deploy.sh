#!/usr/bin/env bash

script_dir() {
  local source_path="${BASH_SOURCE[0]}"
  cd "$(dirname "$source_path")" && pwd
}

deploy_load_libs() {
  local dir
  dir="$(script_dir)"

  # テストでは同一シェル内で source して az をモック差し替えする。
  source "${dir}/lib/validate.sh"
  source "${dir}/lib/prefix.sh"
  source "${dir}/lib/azure.sh"
}

deploy_main() {
  local storage_account="${1-${INPUT_STORAGE_ACCOUNT-}}"
  local source_dir="${2-${INPUT_SOURCE_DIR-}}"
  local target_prefix="${3-${INPUT_TARGET_PREFIX-}}"
  local action="${4-${INPUT_ACTION-deploy}}"
  local blob_pattern
  local site_url

  validate_action "$action" || return 1
  validate_storage_account "$storage_account" || return 1
  validate_source_dir "$action" "$source_dir" || return 1
  validate_target_prefix "$target_prefix" || return 1

  blob_pattern="$(build_blob_pattern "$target_prefix")" || return 1
  site_url="$(build_site_url "$storage_account" "$target_prefix")" || return 1

  azure_delete_prefix "$storage_account" "$blob_pattern" || return 1
  azure_upload_dir "$storage_account" "$source_dir" "$target_prefix" || return 1

  printf '%s\n' "$site_url"
}

deploy_load_libs

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
  deploy_main "$@"
fi
