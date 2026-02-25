#!/usr/bin/env bash

azure_get_static_website_endpoint() {
  local storage_account="${1-}"
  local endpoint

  endpoint="$(
    az storage account show \
      --name "$storage_account" \
      --query primaryEndpoints.web \
      --output tsv
  )"
  endpoint="${endpoint%/}"

  if [[ -z "$endpoint" ]]; then
    echo "静的Webサイトのエンドポイント取得に失敗しました: ${storage_account}" >&2
    return 1
  fi

  printf '%s\n' "$endpoint"
}

azure_delete_prefix() {
  local storage_account="${1-}"
  local blob_pattern="${2-}"

  az storage blob delete-batch \
    --account-name "$storage_account" \
    --source '$web' \
    --pattern "$blob_pattern" \
    --auth-mode login \
    --only-show-errors
}

azure_upload_dir() {
  local storage_account="${1-}"
  local source_dir="${2-}"
  local target_prefix="${3-}"

  local -a cmd=(
    az storage blob upload-batch
    --account-name "$storage_account"
    --source "$source_dir"
    --destination '$web'
    --auth-mode login
    --only-show-errors
    --overwrite true
  )

  if [[ -n "$target_prefix" ]]; then
    cmd+=(--destination-path "$target_prefix")
  fi

  "${cmd[@]}"
}
