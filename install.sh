#!/bin/bash

tag_name=$(curl --silent "https://api.github.com/repos/wxw-matt/command_logs/releases/latest" |  grep -Po '"tag_name": "\K.*?(?=")')

# Get the tag name from the first argument if provided
if [[ $# -ge 1 ]]; then
  tag_name="$1"
fi

platform=$(uname | tr '[:upper:]' '[:lower:]')
arch=$(uname -m)
filename=release-$platform-$arch-$tag_name.zip
fileurl=https://github.com/wxw-matt/command_logs/releases/download/$tag_name/$filename

curl -sSL $fileurl -o /tmp/$filename
unzip /tmp/$filename -d /tmp/command_logs_tmp
rm /tmp/$filename
cd /tmp/command_logs_tmp/releases
./scripts/install.sh
source $HOME/.cache/command_logs/bash.sh
