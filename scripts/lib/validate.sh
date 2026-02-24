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

validate_branch_name() {
  local branch_name="${1-}"

  if [[ -z "$branch_name" ]]; then
    echo "branch_name は必須です。" >&2
    return 1
  fi

  if [[ ! "$branch_name" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
    echo "branch_name は小文字英数字とハイフンのみ使用できます（先頭は小文字英数字）。" >&2
    return 1
  fi

  return 0
}

validate_pull_request_number() {
  local number="${1-}"

  if [[ ! "$number" =~ ^[1-9][0-9]*$ ]]; then
    echo "pull_request_number は正の整数で指定してください。" >&2
    return 1
  fi

  return 0
}

validate_prefix_inputs() {
  local branch_name="${1-}"
  local pull_request_number="${2-}"

  if [[ -n "$pull_request_number" ]]; then
    validate_pull_request_number "$pull_request_number" || return 1
    return 0
  fi

  if [[ -z "$branch_name" ]]; then
    echo "branch_name または pull_request_number のいずれかは必須です。" >&2
    return 1
  fi

  validate_branch_name "$branch_name" || return 1
  return 0
}
