__cl_log_dir="$HOME/.cache/command_logs"
__cl_log_file="$__cl_log_dir/cmds.log"
__cl_err_log_file="$__cl_log_dir/errors.log"
__cl_env_file="$HOME/.cache/command_logs/cmd_logs_env.sh"

. "${__cl_log_dir}/common.sh"

function _bash_command_logs_last_command() {
    history 1 | awk '{$1=""; print $0}' | sed -e 's/^[[:space:]]*//'
}


function _command_logs_hook() {
    local exit_code="$?"
    __cl_last_command=$(_bash_command_logs_last_command)
    __cl_send_command_logs $exit_code
    local data=$(__cl_get_cmd_info $exit_code)
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $data" >> ${__cl_log_file}
}

if [[ "$PROMPT_COMMAND" != *"_command_logs_hook"* ]]; then

    mkdir -p ${__cl_log_dir}
    touch ${__cl_log_file}
    touch ${__cl_err_log_file}
    PROMPT_COMMAND="_command_logs_hook;${PROMPT_COMMAND:+$PROMPT_COMMAND;}"
    __cl_ask_and_save_api_key_and_url
    __cl_run_command_logs_background
fi
