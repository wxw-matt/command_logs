#!/bin/zsh

__cl_log_dir="$HOME/.cache/command_logs"
__cl_log_file="$__cl_log_dir/cmds.log"
__cl_err_log_file="$__cl_log_dir/errors.log"
__cl_env_file="$HOME/.cache/command_logs/cmd_logs_env.sh"
__cl_common_path="$__cl_log_dir/common.sh"
__cl_platform_path="$__cl_log_dir/platform.sh"

if [ -f "$__cl_platform_path" ]; then
    . $__cl_platform_path
else
    . scripts/platform.sh
fi

if [ -f "$__cl_common_path" ]; then
    . $__cl_common_path
else
    . scripts/common.sh
fi

function preexec() {
    __cl_last_command="$1"
}
function __cl_command_logs_hook() {
    local exit_code="$?"
    __cl_send_command_logs $exit_code
    local data=$(__cl_get_cmd_info $exit_code)
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $data" >> ${__cl_log_file}
}


# append the function to our array of precmd functions
if ! [[ $(echo "${precmd_functions[@]}" | grep -wq "__cl_command_logs_hook"; echo $?) -eq 0 ]]; then
    touch ${__cl_log_file}
    touch ${__cl_err_log_file}
    precmd_functions+=(__cl_command_logs_hook)
fi

__cl_ask_and_save_api_key_and_url
__cl_run_command_logs_background
