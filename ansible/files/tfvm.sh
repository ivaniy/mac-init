function tfvm() {
  local cmd="${1:-}"
  shift || true
  local TFVM_DIR="${HOME}/.tfvm"
  local LINK="/usr/local/bin/terraform"

  case "$cmd" in
    install)
      local ver="${1:-}"
      if [[ -z "$ver" ]]; then
        echo "Usage: tfvm install <x.y.z>"; return 2
      fi

      local arch="$(uname -m)"
      if [[ "$arch" == "arm64" ]]; then arch="arm64"; else arch="amd64"; fi

      local base="${TFVM_DIR}/${ver}"
      local zip="terraform_${ver}_darwin_${arch}.zip"
      local url="https://releases.hashicorp.com/terraform/${ver}/${zip}"
      local sums="https://releases.hashicorp.com/terraform/${ver}/terraform_${ver}_SHA256SUMS"
      local tmp="${TMPDIR:-/tmp}/tfvm.$$.${ver}"

      if [[ -x "${base}/terraform" ]]; then
        echo "Terraform ${ver} already installed at ${base}"; return 0
      fi

      mkdir -p "$tmp" "$base"
      echo ">> Downloading ${zip}"
      curl -fsSL "$url" -o "${tmp}/${zip}"
      if [[ "$?" -ne 0 ]]; then echo "Failed to download terraform version ${ver}"; return 1; fi
      echo ">> Downloading & verifying checksums"
      curl -fsSL "$sums" -o "${tmp}/SHA256SUMS"
      (cd "$tmp" && grep " ${zip}\$" SHA256SUMS | shasum -a 256 -c - || {
        echo "Checksum verification FAILED"; rm -rf "$tmp"; return 1; })

      echo ">> Unpacking"
      /usr/bin/unzip -o "${tmp}/${zip}" -d "$tmp" >/dev/null
      mv "${tmp}/terraform" "${base}/terraform"
      chmod +x "${base}/terraform"
      rm -rf "$tmp"
      echo "Installed terraform ${ver} in ${base}"
      ;;

    use)
      local ver="${1:-}"
      if [[ -z "$ver" ]]; then echo "Usage: tfvm use <x.y.z>"; return 2; fi

      if [[ ! -x "${TFVM_DIR}/${ver}/terraform" ]]; then
        echo "Version ${ver} not installed. Try: tfvm install ${ver}"; return 1
      fi
      mkdir -p "$(dirname "$LINK")"
      rm -f "$LINK"
      ln -s "${TFVM_DIR}/${ver}/terraform" "$LINK"
      echo "Now using terraform ${ver} -> ${TFVM_DIR}/${ver}/terraform"
      terraform version || true
      ;;

    list)
      ls -l "${TFVM_DIR}/" | grep ^d | rev | cut -f1 -d " " | rev 2>/dev/null || echo "(none)"
      ;;

    current)
      if [[ -L "$LINK" ]]; then
        readlink "$LINK" | awk -F'/\.tfvm/' '{print $2}' | cut -d/ -f1
      elif command -v terraform >/dev/null 2>&1; then
        terraform version | head -n1
      else
        echo "(none)"
      fi
      ;;

    remove|uninstall)
      local ver="${1:-}"
      if [[ -z "$ver" ]]; then echo "Usage: tfvm remove <x.y.z>"; return 2; fi
      rm -rf "${TFVM_DIR}/${ver}"
      if [[ -L "$LINK" ]] && [[ "$(readlink "$LINK")" == "${TFVM_DIR}/${ver}/terraform" ]]; then
        rm -f "$LINK"
      fi
      echo "Removed terraform ${ver}"
      ;;

    *)
      cat <<'USAGE'
Usage: tfvm <command> [args]

Commands:
  install <x.y.z>   Download from HashiCorp, verify, install into ~/.tfvm/<ver>
  use <x.y.z>       Point /usr/local/bin/terraform symlink to that version
  list              Show installed versions
  current           Show version selected by the symlink (or detected)
  remove <x.y.z>    Delete a version (and unlink if it was selected)
USAGE
      return 2
      ;;
  esac
}
