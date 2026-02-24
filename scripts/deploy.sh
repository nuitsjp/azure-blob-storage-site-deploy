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
  local branch_name="${3-${INPUT_BRANCH_NAME-}}"
  local pull_request_number="${4-${INPUT_PULL_REQUEST_NUMBER-}}"
  local action="${5-${INPUT_ACTION-deploy}}"
  local static_website_endpoint="${6-${INPUT_STATIC_WEBSITE_ENDPOINT-}}"
  local site_name="${7-${INPUT_SITE_NAME-}}"
  local target_prefix
  local blob_prefix
  local blob_pattern
  local site_url

  validate_action "$action" || return 1
  validate_storage_account "$storage_account" || return 1
  validate_source_dir "$action" "$source_dir" || return 1
  site_name="$(resolve_site_name "$site_name")" || return 1
  validate_site_name "$site_name" || return 1
  validate_prefix_inputs "$branch_name" "$pull_request_number" || return 1

  target_prefix="$(resolve_target_prefix "$branch_name" "$pull_request_number")" || return 1
  blob_prefix="$(build_blob_prefix "$site_name" "$target_prefix")" || return 1

  blob_pattern="$(build_blob_pattern "$blob_prefix")" || return 1
  if [[ -n "$static_website_endpoint" ]]; then
    site_url="$(build_site_url_from_endpoint "$static_website_endpoint" "$blob_prefix")" || return 1
  else
    site_url="$(build_site_url "$storage_account" "$blob_prefix")" || return 1
  fi

  azure_delete_prefix "$storage_account" "$blob_pattern" || return 1
  azure_upload_dir "$storage_account" "$source_dir" "$blob_prefix" || return 1

  printf '%s\n' "$site_url"
}

deploy_load_libs

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
  deploy_main "$@"
fi
