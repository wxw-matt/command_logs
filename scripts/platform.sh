get_platform() {
    local platform
    case "$(uname -s)" in
        Darwin)
            platform='macos'
            ;;
        Linux)
            platform='linux'
            ;;
        *)
            platform='unknown'
            ;;
    esac
    echo "${platform}"
}

get_arch() {
  uname="$(uname -m)"
  case "${uname}" in
    x86_64)
      echo "amd64"
      ;;
    armv8* | aarch64)
      echo "arm64"
      ;;
    *)
      echo "${uname}"
      ;;
  esac
}

get_shell() {
  if [ "$(get_platform)" = "macos" ]; then
    shell="$(dscl . -read /Users/$USER UserShell)"
  else
    shell="$(grep "^$(id -un):" /etc/passwd | awk -F: '{print $7}')"
  fi
  case "${shell}" in
    *zsh)
      echo "zsh"
      ;;
    *bash)
      echo "bash"
      ;;
    *)
      echo "$shell"
      ;;
  esac
}
