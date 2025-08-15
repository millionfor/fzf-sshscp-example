si=0
set_server() {
    servers[$si]="$1"
    cmds[$si]="$2"
    targets[$si]="$3"
    hosts[$si]="$4"
    si=$(($si+1))
}

# 从同目录下的 `config` 文件读取条目，字段映射：名称 -> Host，端口 -> Port
parse_config() {
    local cfg_path="$1"
    [[ ! -f "$cfg_path" ]] && return 0

    local current_host=""
    local current_hostname=""
    local current_port=""
    local current_user=""
    local current_server_alive=""
    local current_request_tty=""
    local current_preferred_auth=""
    local current_identity_file=""

    local line key value
    while IFS= read -r line || [[ -n "$line" ]]; do
        # 去掉行首尾空白
        line="${line%%[[:space:]]*\n}"
        line="${line%%$'\r'}"
        # 跳过注释与空行
        [[ -z "${line//[[:space:]]/}" ]] && continue
        [[ "$line" =~ ^[[:space:]]*# ]] && continue

        # 拆分 key 与 value（只按第一个空白分割）
        key="${line%%[[:space:]]*}"
        value="${line#*$key}"
        value="${value##[[:space:]]}"
        value="${value#[[:space:]]}"

        case "$key" in
            Host)
                # 遇到新 Host 前，先提交上一段
                if [[ -n "$current_host" ]]; then
                    local display_port="$current_port"
                    [[ -z "$display_port" || ! "$display_port" =~ ^[0-9]+$ ]] && display_port="22"
                    local _hostname="${current_hostname:-$current_host}"
                    local _user="${current_user:-$USER}"
                    local _remote="${_user}@${_hostname}"
                    local _args=""
                    [[ -n "$current_port" && "$current_port" =~ ^[0-9]+$ ]] && _args+=" -p $current_port"
                    [[ -n "$current_server_alive" ]] && _args+=" -o ServerAliveInterval=$current_server_alive"
                    [[ -n "$current_request_tty" ]] && _args+=" -o RequestTTY=$current_request_tty"
                    [[ -n "$current_preferred_auth" ]] && _args+=" -o PreferredAuthentications=$current_preferred_auth"
                    [[ -n "$current_identity_file" ]] && _args+=" -i $current_identity_file"
                    # servers: 显示为 “Host<TAB>Port”；ssh 命令 = cmds + targets
                    set_server "$current_host"$'\t'"$display_port" "ssh$_args" "$_remote" "$_hostname"
                fi
                current_host="$value"
                current_hostname=""
                current_port=""
                current_user=""
                current_server_alive=""
                current_request_tty=""
                current_preferred_auth=""
                current_identity_file=""
                ;;
            HostName)
                current_hostname="$value"
                ;;
            Port)
                current_port="$value"
                ;;
            User)
                current_user="$value"
                ;;
            ServerAliveInterval)
                current_server_alive="$value"
                ;;
            RequestTTY)
                current_request_tty="$value"
                ;;
            PreferredAuthentications)
                current_preferred_auth="$value"
                ;;
            IdentityFile)
                current_identity_file="$value"
                ;;
            *) ;;
        esac
    done < "$cfg_path"

    # 提交最后一段
    if [[ -n "$current_host" ]]; then
        local display_port="$current_port"
        [[ -z "$display_port" || ! "$display_port" =~ ^[0-9]+$ ]] && display_port="22"
        local _hostname="${current_hostname:-$current_host}"
        local _user="${current_user:-$USER}"
        local _remote="${_user}@${_hostname}"
        local _args=""
        [[ -n "$current_port" && "$current_port" =~ ^[0-9]+$ ]] && _args+=" -p $current_port"
        [[ -n "$current_server_alive" ]] && _args+=" -o ServerAliveInterval=$current_server_alive"
        [[ -n "$current_request_tty" ]] && _args+=" -o RequestTTY=$current_request_tty"
        [[ -n "$current_preferred_auth" ]] && _args+=" -o PreferredAuthentications=$current_preferred_auth"
        [[ -n "$current_identity_file" ]] && _args+=" -i $current_identity_file"
        set_server "$current_host"$'\t'"$display_port" "ssh$_args" "$_remote" "$_hostname"
    fi
}

# 解析同目录下的 config（可用环境变量 CONFIG_FILE 覆盖）
_this_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
_cfg_file="${CONFIG_FILE:-$_this_dir/config}"
parse_config "$_cfg_file"

_list() {
    for ((i = 0; i < ${#servers[@]}; i++)); do
        _item=${servers[$i]}
        echo "${_item[@]}"
    done
}

_index() {
    for ((i = 0; i < ${#servers[@]}; i++)); do
        _item=${servers[$i]}
        [[ "$_item" == "$1" ]] && echo $i && break
    done
}
