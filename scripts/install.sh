SHELL_NAME=$(basename "$SHELL")
function __cl_get_file_name() {
    local platform=$(uname | tr '[:upper:]' '[:lower:]')
    local arch=$(uname -m)
    local file="$1_${platform}_${arch}"
    echo $file
}

function add_shell_line() {
    if grep -Fxq "source \$HOME/.cache/command_logs/${SHELL_NAME}.sh" ~/.${SHELL_NAME}rc
    then
        echo "Command_logs script has been installed in .${SHELL_NAME}rc. Nothing to do."
    else
        echo "Adding line to .${SHELL_NAME}rc..."
        echo "source \$HOME/.cache/command_logs/${SHELL_NAME}.sh" >> ~/.${SHELL_NAME}rc
    fi
}

__cl_log_dir="$HOME/.cache/command_logs"

mkdir -p ${__cl_log_dir}

command_logs=$(__cl_get_file_name command_logs)
send_to_unix_socket=$(__cl_get_file_name command_logs)

echo "Installing $command_logs"
cp "bin/$command_logs" $__cl_log_dir/
echo "Installing $send_to_unix_socket"
cp "bin/$(__cl_get_file_name send_to_unix_socket)" $__cl_log_dir/

echo "Installing ${SHELL_NAME} script"
cp "scripts/common.sh" $__cl_log_dir/
cp "scripts/${SHELL_NAME}.sh" $__cl_log_dir/

add_shell_line $SHELL_NAME
