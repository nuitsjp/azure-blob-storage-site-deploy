#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-v1.11.1}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TOOLS_DIR="${REPO_ROOT}/.tools"
INSTALL_DIR="${TOOLS_DIR}/bats-core/${VERSION}"
BIN_LINK_DIR="${TOOLS_DIR}/bin"
TMP_DIR="${TOOLS_DIR}/tmp"
ARCHIVE_PATH="${TMP_DIR}/bats-core-${VERSION}.tar.gz"
DOWNLOAD_URL="https://github.com/bats-core/bats-core/archive/refs/tags/${VERSION}.tar.gz"

mkdir -p "${BIN_LINK_DIR}" "${TMP_DIR}"

if [[ ! -x "${INSTALL_DIR}/bin/bats" ]]; then
  rm -rf "${INSTALL_DIR}"
  mkdir -p "${INSTALL_DIR}"
  curl -fsSL "${DOWNLOAD_URL}" -o "${ARCHIVE_PATH}"
  tar -xzf "${ARCHIVE_PATH}" -C "${TMP_DIR}"

  EXTRACTED_DIR="${TMP_DIR}/bats-core-${VERSION#v}"
  if [[ ! -d "${EXTRACTED_DIR}" ]]; then
    echo "bats-coreの展開ディレクトリが見つかりません: ${EXTRACTED_DIR}" >&2
    exit 1
  fi

  # bats-coreの install.sh でリポジトリ内にローカル導入する
  "${EXTRACTED_DIR}/install.sh" "${INSTALL_DIR}"
  rm -rf "${EXTRACTED_DIR}"
fi

ln -sfn "${INSTALL_DIR}/bin/bats" "${BIN_LINK_DIR}/bats"

echo "インストール完了: ${BIN_LINK_DIR}/bats"
echo "例: PATH=\"${BIN_LINK_DIR}:\$PATH\" bats --version"
