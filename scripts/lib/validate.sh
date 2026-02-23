#!/usr/bin/env bash

validate_storage_account() {
  local storage_account="${1-}"
  local length="${#storage_account}"

  if [[ -z "$storage_account" ]]; then
    echo "storage_account は必須です。" >&2
    return 1
  fi

  if (( length < 3 || length > 24 )); then
    echo "storage_account は3〜24文字で指定してください。" >&2
    return 1
  fi

  if [[ ! "$storage_account" =~ ^[a-z0-9]+$ ]]; then
    echo "storage_account は小文字英数字のみ使用できます。" >&2
    return 1
  fi

  return 0
}

validate_action() {
  local action="${1-}"

  case "$action" in
    deploy|cleanup)
      return 0
      ;;
    *)
      echo "action は deploy または cleanup を指定してください。" >&2
      return 1
      ;;
  esac
}

validate_source_dir() {
  local action="${1-}"
  local source_dir="${2-}"

  if [[ "$action" != "deploy" ]]; then
    return 0
  fi

  if [[ -z "$source_dir" ]]; then
    echo "source_dir は action=deploy の場合に必須です。" >&2
    return 1
  fi

  if [[ ! -d "$source_dir" ]]; then
    echo "source_dir が存在しないか、ディレクトリではありません: $source_dir" >&2
    return 1
  fi

  return 0
}

validate_target_prefix() {
  local target_prefix="${1-}"

  if [[ -z "$target_prefix" ]]; then
    echo "target_prefix は必須です。" >&2
    return 1
  fi

  if [[ ! "$target_prefix" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
    echo "target_prefix は小文字英数字とハイフンのみ使用できます（先頭は小文字英数字）。" >&2
    return 1
  fi

  return 0
}
