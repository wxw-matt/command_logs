. scripts/platform.sh
__cl_platform=$(get_platform)
__cl_arch=$(get_arch)
__cl_shell_name=$(get_shell)

__cl_get_file_name() {
    local file="$1_${__cl_platform}_${__cl_arch}"
    echo $file
}

__cl_add_shell_line() {
    if grep -Fxq "source \$HOME/.cache/command_logs/${__cl_shell_name}.sh" ~/.${__cl_shell_name}rc
    then
        echo "Command_logs script has been installed in .${__cl_shell_name}rc. Nothing to do."
    else
        echo "Adding line to .${__cl_shell_name}rc..."
        echo "source \$HOME/.cache/command_logs/${__cl_shell_name}.sh" >> ~/.${__cl_shell_name}rc
    fi
}

__cl_log_dir="$HOME/.cache/command_logs"

mkdir -p ${__cl_log_dir}

command_logs=$(__cl_get_file_name command_logs)
send_to_unix_socket=$(__cl_get_file_name send_to_unix_socket)

echo "Stopping process ..."
echo "bye" | bin/$send_to_unix_socket /tmp/command_logs.sock > /dev/null

echo "Installing $command_logs"
cp "bin/$command_logs" $__cl_log_dir/
echo "Installing $send_to_unix_socket"
cp "bin/$send_to_unix_socket" $__cl_log_dir/

echo "Installing ${__cl_shell_name} script"
cp "scripts/platform.sh" $__cl_log_dir/
cp "scripts/common.sh" $__cl_log_dir/
cp "scripts/${__cl_shell_name}.sh" $__cl_log_dir/

__cl_add_shell_line $__cl_shell_name
