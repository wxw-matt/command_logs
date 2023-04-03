#!/bin/sh

function __cl_locate_file() {
    local filename=$1
    local file_path=""

    # Search in ./bin
    if [ -d "./bin" ]; then
        file_path=$(find "./bin" -name $filename -type f -print -quit)
        file_path="$(pwd)/$filename"
    fi

    # Search in $HOME/.cache/command_logs/
    if [ ! -f "$file_path" ] && [ -d "$HOME/.cache/command_logs/" ]; then
        file_path=$(find "$HOME/.cache/command_logs/" -name $filename -type f -print -quit)
    fi

    if [ -n "$file_path" ]; then
        echo "$file_path"
    else
        echo ""
    fi
}

function __cl_get_command_logs() {
    local platform=$(uname | tr '[:upper:]' '[:lower:]')
    local arch=$(uname -m)
    local file=$(__cl_locate_file "command_logs_${platform}_${arch}")
    echo $file
}

function __cl_get_send_to_unix_socket() {
    local platform=$(uname | tr '[:upper:]' '[:lower:]')
    local arch=$(uname -m)
    local file=$(__cl_locate_file "send_to_unix_socket_${platform}_${arch}")
    echo $file
}

function __cl_ask_and_save_api_key_and_url() {
    if [ -f "$__cl_env_file" ]; then
        return 0
    fi

    echo "To find the values for the following quesions, please see the page of the trigger settings for the lambda function"
    printf "Please enter your AWS API Key: "
    read api_key

    printf "Please enter the AWS Lambda Function URL: "
    read lambda_url

    # Create directory if it does not exist
    mkdir -p "$HOME/.cache/command_logs"

    # Save values to file in shell export format
    echo "CMD_LOGS_API_KEY=$api_key" > "$__cl_env_file"
    echo "CMD_LOGS_URL=$lambda_url" >> "$__cl_env_file"

    echo "API key and Lambda Function URL saved to $__cl_env_file"
}

__cl_last_command="Loading command_logs ..."
function __cl_get_last_command() {
    echo "${__cl_last_command}"
}

function __cl_get_cmd_info() {
    local exit_code=$1
    local current_dir=$(pwd)
    local current_user=$(whoami)
    local timezone=$(date +%Z)

    # Check if the current directory is a Git repository
    local is_git=false
    if git rev-parse --git-dir >/dev/null 2>&1; then
        local branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "no-branch")
        local commit_id=$(git rev-parse --short HEAD 2>/dev/null || echo "no-commit")
        local remote_url=$(git remote get-url origin 2>/dev/null || echo "no-origin")
        is_git=true
    else
        local branch=""
        local commit_id=""
        local remote_url=""
    fi

    # Build JSON object
    local cmd="$(__cl_get_last_command)"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local host=$(hostname)
    local data="{\"hostname\":\"${host}\", \"exit_code\":\"${exit_code}\", \"created_at\":\"${timestamp}\",\"cmd\":\"${cmd}\",\"pwd\":\"${current_dir}\",\"user\":\"${current_user}\",\"timezone\":\"${timezone}\",\"is_git\":${is_git},\"git_remote\":\"${remote_url}\", \"git_branch\":\"${branch}\",\"git_commit\":\"${commit_id}\"}"

    echo $data
}


function __cl_run_command_logs_background() {
    . ${__cl_env_file}
    CMD_LOGS_URL=$CMD_LOGS_URL CMD_LOGS_API_KEY=$CMD_LOGS_API_KEY  $(__cl_get_command_logs) >> $__cl_log_file 2>&1
}

function __cl_send_command_logs() {
    local data=$(__cl_get_cmd_info $1)
    __cl_send_command "${data}"
}


function __cl_send_command() {
    local __cl_send_to_unix_socket="/not/existed"
    if [ ! -f "$__cl_send_to_unix_socket" ]; then
        __cl_send_to_unix_socket=$(__cl_get_send_to_unix_socket)
        if [ ! -f "$__cl_send_to_unix_socket" ]; then
            echo "send_to_unix_socket not found in ./bin and $HOME/.cache/command_logs/"
            return 2
        fi
    fi

    local __cl_socket_path="/tmp/command_logs.sock"
    echo "${1}" | ${__cl_send_to_unix_socket} "${__cl_socket_path}" >> $__cl_err_log_file 2>&1
}

function cl_send_bye_command() {
    __cl_send_command "bye"
}
