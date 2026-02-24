#!/usr/bin/env bash

build_blob_prefix() {
  local site_name="${1-}"
  local target_prefix="${2-}"

  printf '%s/%s\n' "$site_name" "$target_prefix"
}

resolve_target_prefix() {
  local branch_name="${1-}"
  local pull_request_number="${2-}"

  if [[ -n "$pull_request_number" ]]; then
    printf 'pr-%s\n' "$pull_request_number"
    return 0
  fi

  printf '%s\n' "$branch_name"
}

build_site_url() {
  local storage_account="${1-}"
  local target_prefix="${2-}"
  local base_url="https://${storage_account}.z22.web.core.windows.net"

  if [[ -z "$target_prefix" ]]; then
    printf '%s/\n' "$base_url"
    return 0
  fi

  target_prefix="${target_prefix#/}"
  target_prefix="${target_prefix%/}"

  if [[ -z "$target_prefix" ]]; then
    printf '%s/\n' "$base_url"
    return 0
  fi

  printf '%s/%s/\n' "$base_url" "$target_prefix"
}

build_site_url_from_endpoint() {
  local static_website_endpoint="${1-}"
  local target_prefix="${2-}"
  local base_url="${static_website_endpoint%/}"

  if [[ -z "$base_url" ]]; then
    printf '/\n'
    return 0
  fi

  if [[ -z "$target_prefix" ]]; then
    printf '%s/\n' "$base_url"
    return 0
  fi

  target_prefix="${target_prefix#/}"
  target_prefix="${target_prefix%/}"

  if [[ -z "$target_prefix" ]]; then
    printf '%s/\n' "$base_url"
    return 0
  fi

  printf '%s/%s/\n' "$base_url" "$target_prefix"
}

build_blob_pattern() {
  local target_prefix="${1-}"

  target_prefix="${target_prefix#/}"
  target_prefix="${target_prefix%/}"

  if [[ -z "$target_prefix" ]]; then
    printf '*\n'
    return 0
  fi

  printf '%s/*\n' "$target_prefix"
}
