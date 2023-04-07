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

download_with_retry() {
  local url="$1"
  local filename="$2"
  local max_retries=3
  local retry_count=0

  while [ $retry_count -lt $max_retries ]
  do
    status_code=$(curl --write-out %{http_code} -SL --silent --output $filename "$url")
    if [ $status_code -eq 200 ]; then
      echo "Download successful!"
      return 0
    else
      echo "Download failed with status code $status_code. Retrying in 2 seconds..."
      sleep 2
      retry_count=$((retry_count+1))
    fi
  done

  return 1 # failure
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

printf "Downloading $filename ...\n"
rm -rf /tmp/command_logs_tmp

download_with_retry $fileurl /tmp/$filename
return_code=$?
if [ $return_code -ne 0 ]; then
  printf "Failed to download $fileurl, exiting ...\n"
  exit $return_code
fi

mkdir -p /tmp/command_logs_tmp
cd /tmp/command_logs_tmp
tar xf /tmp/$filename
cd /tmp/command_logs_tmp/releases

printf "Installing into $HOME/.cache/command_logs\n\n"
./scripts/install.sh

printf "\nPlease load the script by running the following command:\n"
printf "\tsource $HOME/.cache/command_logs/$(basename "$(get_shell)").sh\n\n"
