# Command Logs

## Install

```
/bin/bash -c "$(curl -L -s 'https://raw.githubusercontent.com/wxw-matt/command_logs/main/install.sh')"
```
Note:
> The command above is for the installation on both Bash and Zsh. As the users have to use `source` to load the script in any way, or start a terminal.

## Build

The `build_all.sh` script builds the programs for Linux (amd64/arm64) and macOS (amd64/arm64).
Eight programs will be created:
```
command_logs_linux_x86_64
command_logs_linux_arm64
command_logs_darwin_x86_64
command_logs_darwin_arm64

send_to_unix_socket_linux_x86_64
send_to_unix_socket_linux_arm64
send_to_unix_socket_darwin_x86_64
send_to_unix_socket_darwin_arm64
```
### Build them

```bash
./build_all.sh
```

## Install locally

```bash
./scripts/install.sh
```
The script will copy `command_logs_${platform}_${arch}`, `send_to_unxi_socket_${platform}_${arch}`, and `zsh.sh` to `$HOME/.cache/command_logs`.

It also add this line `source $HOME/.cache/command_logs/(zsh|bash).sh` to `.(zsh|bash)rc` if it does not have it.
