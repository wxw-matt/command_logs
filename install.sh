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

tag_name=$(curl --silent "https://api.github.com/repos/wxw-matt/command_logs/releases/latest" | grep -o '"tag_name": ".*"' | cut -d '"' -f 4)

# Get the tag name from the first argument if provided
if [[ $# -ge 1 ]]; then
  tag_name="$1"
fi

platform=$(get_platform)
arch=$(get_arch)
filename=release-$platform-$arch-$tag_name.tar.gz
fileurl=https://github.com/wxw-matt/command_logs/releases/download/$tag_name/$filename

curl -sSL $fileurl -o /tmp/$filename
mkdir -p /tmp/command_logs_tmp
cd /tmp/command_logs_tmp
tar xf /tmp/$filename
rm /tmp/$filename
cd /tmp/command_logs_tmp/releases
./scripts/install.sh
source $HOME/.cache/command_logs/$(basename "$(get_shell)").sh
