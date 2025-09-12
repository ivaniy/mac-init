function kubvm() {
  local cmd="${1:-}"
  shift || true
  local KUBVM_DIR="${HOME}/.kubvm"
  local LINK="/usr/local/bin/kubectl"

  case "$cmd" in
    install)
      local ver="${1:-stable}"
      if [[ "$ver" == "stable" ]]; then
        ver="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"
      fi
      [[ "$ver" =~ ^v ]] || ver="v$ver"   # allow "1.30.4" or "v1.30.4"
      [[ "$ver" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "Invalid version: $ver"; echo "Usage: kubvm install <X.Y.Z|vX.Y.Z|stable>"; return 2; }

      local arch="$(uname -m)"
      if [[ "$arch" == "arm64" ]]; then arch="arm64"; else arch="amd64"; fi

      local base="${KUBVM_DIR}/${ver}"
      local url="https://dl.k8s.io/release/${ver}/bin/darwin/${arch}/kubectl"
      local sums="${url}.sha256"
      local tmp="${TMPDIR:-/tmp}/kubvm.$$.${ver}"

      if [[ -x "${base}/kubectl" ]]; then
        echo "kubectl ${ver} already installed at ${base}"; return 0
      fi

      mkdir -p "$tmp" "$base"
      echo ">> Downloading kubectl ${ver}"
      curl -fsSL "$url" -o "${tmp}/kubectl"
      if [[ "$?" -ne 0 ]]; then echo "Failed to download kubectl version ${ver}"; return 1; fi
      echo ">> Downloading & verifying checksums"
      curl -fsSL "${url}.sha256" -o "${tmp}/kubectl.sha256"
      echo "$(<"${tmp}/kubectl.sha256")  ${tmp}/kubectl" | shasum -a 256 -c - || {
        echo "Checksum verification FAILED"; rm -rf "$tmp"; return 1; }

      mv "${tmp}/kubectl" "${base}/kubectl"
      chmod +x "${base}/kubectl"
      rm -rf "$tmp"
      echo "Installed kubectl ${ver} in ${base}"
      ;;

    use)
      local ver="${1:-}"
      if [[ -z "$ver" ]]; then echo "Usage: kubvm use <vX.Y.Z>"; return 2; fi
      [[ "$ver" =~ ^v ]] || ver="v$ver"
      if [[ ! -x "${KUBVM_DIR}/${ver}/kubectl" ]]; then
        echo "Version ${ver} not installed. Try: kubvm install ${ver}"; return 1
      fi
      mkdir -p "$(dirname "$LINK")"
      rm -f "$LINK"
      ln -s "${KUBVM_DIR}/${ver}/kubectl" "$LINK"
      echo "Now using kubectl ${ver} -> ${KUBVM_DIR}/${ver}/kubectl"
      "$LINK" version --client || true
      ;;

    list)
      ls -l "${KUBVM_DIR}/" | grep ^d | rev | cut -f1 -d " " | rev 2>/dev/null || echo "(none)"
      ;;

    current)
      if [[ -L "$LINK" ]]; then
        readlink "$LINK" | awk -F'/.kubvm/' '{print $2}' | cut -d/ -f1
      elif command -v kubectl >/dev/null 2>&1; then
        kubectl version --client --short
      else
        echo "(none)"
      fi
      ;;

    remove|uninstall)
      local ver="${1:-}"
      if [[ -z "$ver" ]]; then echo "Usage: kubvm remove <X.Y.Z|vX.Y.Z>"; return 2; fi
      [[ "$ver" =~ ^v ]] || ver="v$ver"
      rm -rf "${KUBVM_DIR}/${ver}"
      if [[ -L "$LINK" ]] && [[ "$(readlink "$LINK")" == "${KUBVM_DIR}/${ver}/kubectl" ]]; then
        rm -f "$LINK"
      fi
      echo "Removed kubectl ${ver}"
      ;;

    *)
      cat <<'USAGE'
Usage: kubvm <command> [args]

Commands:
  install <X.Y.Z|vX.Y.Z|stable>   Install official kubectl (macOS arm64/amd64) with checksum
  use <X.Y.Z|vX.Y.Z>              Point /usr/local/bin/kubectl at that version (uses sudo if needed)
  list                            Show installed versions
  current                         Show the selected version
  remove <X.Y.Z|vX.Y.Z>           Delete a version (unlink if selected)

Examples:
  kubvm install stable
  kubvm install v1.30.4
  kubvm use 1.30.4
  kubvm list
  kubvm current
USAGE
      return 2
      ;;
  esac
}
