#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: VPS keeper for telgram
#	Version: 1.0.3
#	Author: tse
#	Blog: https://vtse.eu.org
#=================================================
sh_ver="1.0.3"
FolderPath="/root/.shfile"
ConfigFile="/root/.shfile/TelgramBot.ini"
BOTToken_de="7030486799:AAEa4PyCKGN7347v1mt2gyaBoySdxuh56ws"
CPUTools_de="top"
CPUThreshold_de="80"
MEMThreshold_de="80"
DISKThreshold_de="80"
FlowThreshold_de="3GB"
FlowThresholdMAX_de="500GB"
ReportTime_de="00:00"
AutoUpdateTime_de="01:01"
interfaces_RP_0=$(ip -br link | awk '$2 == "UP" {print $1}' | grep -v "lo")
interfaces_RP_de=("${interfaces_RP_0[@]}")
StatisticsMode_RP_de="SE"
interfaces_ST_0=$(ip -br link | awk '$2 == "UP" {print $1}' | grep -v "lo")
interfaces_ST_de=("${interfaces_ST_0[@]}")
StatisticsMode_ST_de="SE"
# StatisticsMode_ST_de="OV" # 整体统计
# StatisticsMode_ST_de="SE" # 单独统计

# 检测是否root用户
if [ "$UID" -ne 0 ]; then
    echo "非 \"root\" 用户, 无法执行."
    exit 1
fi

# 导入参数
# if [ -f $ConfigFile ]; then
#     source $ConfigFile
# fi

# 颜色代码
GR="\033[32m" && RE="\033[31m" && GRB="\033[42;37m" && REB="\033[41;37m" && NC="\033[0m"
Inf="${GR}[信息]${NC}:"
Err="${RE}[错误]${NC}:"
Tip="${GR}[提示]${NC}:"
SETTAG="${GR}-> 已设置${NC}"
UNSETTAG="${RE}-> 未设置${NC}"

# 创建.shfile目录
CheckAndCreateFolder() {
    if [ ! -d "$FolderPath" ]; then
        mkdir -p "$FolderPath"
    fi
    if [ -f $ConfigFile ]; then
        source $ConfigFile
    else
        touch $ConfigFile
        writeini "TelgramBotToken" "$BOTToken_de"
        writeini "CPUTools" "$CPUTools_de"
        writeini "FlowThresholdMAX" "$FlowThresholdMAX_de"
        writeini "SHUTDOWN_RT" "false"
        hostname_show=$(hostname)
        writeini "hostname_show" "$hostname_show"
    fi
}

# 清屏
CLS() {
    if command -v apt &>/dev/null; then
        clear
    elif command -v opkg &>/dev/null; then
        clear
    elif command -v yum &>/dev/null; then
        printf "\033c"
    else
        echo
    fi
}

# 暂停
Pause() {
    echo -e "${Tip} 执行完成, 按 \"任意键\" 继续..."
    read -n 1 -s -r -p ""
}

# 分界线条
divline() {
    echo "—————————————————————————————————————————————————————————"
}

# 检测系统
CheckSys() {
    if [[ -f /etc/redhat-release ]]; then
        release="centos"
    elif cat /etc/issue 2>/dev/null | grep -q -E -i "debian"; then
        release="debian"
    elif cat /etc/issue 2>/dev/null | grep -q -E -i "ubuntu"; then
        release="ubuntu"
    elif cat /etc/issue 2>/dev/null | grep -q -E -i "centos|red hat|redhat"; then
        release="centos"
    elif cat /proc/version 2>/dev/null | grep -q -E -i "debian"; then
        release="debian"
    elif cat /proc/version 2>/dev/null | grep -q -E -i "ubuntu"; then
        release="ubuntu"
    elif cat /proc/version 2>/dev/null | grep -q -E -i "centos|red hat|redhat"; then
        release="centos"
    elif cat /proc/version 2>/dev/null | grep -q -E -i "openwrt"; then
        release="openwrt"
    else
        echo -e "$Err 系统不支持." >&2
        exit 1
    fi
    if [ -z $hostname_show ]; then
        if cat /proc/version 2>/dev/null | grep -q -E -i "openwrt"; then
            current_date=$(date +%m%d)
            hostname_show="openwrt_$current_date"
            writeini "hostname_show" "$hostname_show"
        else
            hostname_show=$(hostname)
            writeini "hostname_show" "$hostname_show"
        fi
    fi
}

# 检测设置标记
CheckSetup() {
    echo "检测中..."
    if [ -f $FolderPath/tg_login.sh ]; then
        if [ -f /etc/bash.bashrc ] && [ "$release" != "openwrt" ]; then
            if grep -q "bash $FolderPath/tg_login.sh > /dev/null 2>&1" /etc/bash.bashrc; then
                login_menu_tag="$SETTAG"
            else
                login_menu_tag="$UNSETTAG"
            fi
        elif [ -f /etc/profile ]; then
            if grep -q "bash $FolderPath/tg_login.sh > /dev/null 2>&1" /etc/profile; then
                login_menu_tag="$SETTAG"
            else
                login_menu_tag="$UNSETTAG"
            fi
        else
            login_menu_tag="$UNSETTAG"
        fi
    else
        login_menu_tag="$UNSETTAG"
    fi
    if [ -f $FolderPath/tg_boot.sh ]; then
        if [ -f /etc/systemd/system/tg_boot.service ]; then
            boot_menu_tag="$SETTAG"
        elif [ -f /etc/init.d/tg_boot.sh ]; then
            boot_menu_tag="$SETTAG"
        else
            boot_menu_tag="$UNSETTAG"
        fi
    else
        boot_menu_tag="$UNSETTAG"
    fi
    if [ -f $FolderPath/tg_shutdown.sh ]; then
        if [ -f /etc/systemd/system/tg_shutdown.service ]; then
            shutdown_menu_tag="$SETTAG"
        elif [ -f /etc/init.d/tg_shutdown.sh ]; then
            shutdown_menu_tag="$SETTAG"
        else
            shutdown_menu_tag="$UNSETTAG"
        fi
    else
        shutdown_menu_tag="$UNSETTAG"
    fi
    if [ -f $FolderPath/tg_docker.sh ]; then
        if crontab -l | grep -q "@reboot nohup $FolderPath/tg_docker.sh > $FolderPath/tg_docker.log 2>&1 &"; then
            docker_menu_tag="$SETTAG"
        else
            docker_menu_tag="$UNSETTAG"
        fi
    else
        docker_menu_tag="$UNSETTAG"
    fi
    if [ -f $FolderPath/tg_cpu.sh ]; then
        if crontab -l | grep -q "@reboot nohup $FolderPath/tg_cpu.sh > $FolderPath/tg_cpu.log 2>&1 &"; then
            cpu_menu_tag="$SETTAG"
        else
            cpu_menu_tag="$UNSETTAG"
        fi
    else
        cpu_menu_tag="$UNSETTAG"
    fi
    if [ -f $FolderPath/tg_mem.sh ]; then
        if crontab -l | grep -q "@reboot nohup $FolderPath/tg_mem.sh > $FolderPath/tg_mem.log 2>&1 &"; then
            mem_menu_tag="$SETTAG"
        else
            mem_menu_tag="$UNSETTAG"
        fi
    else
        mem_menu_tag="$UNSETTAG"
    fi
    if [ -f $FolderPath/tg_disk.sh ]; then
        if crontab -l | grep -q "@reboot nohup $FolderPath/tg_disk.sh > $FolderPath/tg_disk.log 2>&1 &"; then
            disk_menu_tag="$SETTAG"
        else
            disk_menu_tag="$UNSETTAG"
        fi
    else
        disk_menu_tag="$UNSETTAG"
    fi
    if [ -f $FolderPath/tg_flow.sh ]; then
        if crontab -l | grep -q "@reboot nohup $FolderPath/tg_flow.sh > $FolderPath/tg_flow.log 2>&1 &"; then
            flow_menu_tag="$SETTAG"
        else
            flow_menu_tag="$UNSETTAG"
        fi
    else
        flow_menu_tag="$UNSETTAG"
    fi
    if [ -f $FolderPath/tg_flowrp.sh ]; then
        if crontab -l | grep -q "@reboot nohup $FolderPath/tg_flowrp.sh > $FolderPath/tg_flowrp.log 2>&1 &"; then
            flowrp_menu_tag="$SETTAG"
        else
            flowrp_menu_tag="$UNSETTAG"
        fi
    else
        flowrp_menu_tag="$UNSETTAG"
    fi
    if [ -f $FolderPath/tg_autoud.sh ]; then
        if crontab -l | grep -q "bash $FolderPath/tg_autoud.sh > $FolderPath/tg_autoud.log 2>&1 &"; then
            autoud_menu_tag="$SETTAG"
        else
            autoud_menu_tag="$UNSETTAG"
        fi
    else
        autoud_menu_tag="$UNSETTAG"
    fi
    if [ -d "$FolderPath" ]; then
        folder_menu_tag="${GR}-> 文件夹存在${NC}"
    else
        folder_menu_tag="${RE}-> 文件夹不存在${NC}"
    fi
}

# 检查并安装依赖
CheckRely() {
    # 检查并安装依赖
    echo "检查并安装依赖..."
    if cat /proc/version 2>/dev/null | grep -q -E -i "openwrt"; then
        echo "OpenWRT 系统跳过依赖检测..."
    else
        declare -a dependencies=("sed" "grep" "awk" "hostnamectl" "systemd" "curl")
        missing_dependencies=()
        for dep in "${dependencies[@]}"; do
            if ! command -v "$dep" &>/dev/null; then
                missing_dependencies+=("$dep")
            fi
        done
        if [ ${#missing_dependencies[@]} -gt 0 ]; then
            echo -e "$Tip 以下依赖未安装: ${missing_dependencies[*]}"
            read -e -p "是否要安装依赖 Y/其它 : " yorn
            if [ "$yorn" == "Y" ] || [ "$yorn" == "y" ]; then
                echo "正在安装缺失的依赖..."
                if [ -x "$(command -v apt)" ]; then
                    apt install -y "${missing_dependencies[@]}"
                elif [ -x "$(command -v yum)" ]; then
                    yum install -y "${missing_dependencies[@]}"
                else
                    echo -e "$Err 无法安装依赖, 未知的包管理器或系统版本不支持, 请手动安装所需依赖."
                    exit 1
                fi
            else
                echo -e "$Tip 已跳过安装."
            fi
        else
            echo -e "$Tip 所有依赖已安装."
        fi
    fi
}

# 检查时间格式是否正确
validate_time_format() {
    local time=$1
    local regex='^([01]?[0-9]|2[0-3]):([0-5]?[0-9])$'
    if [[ $time =~ $regex ]]; then
        echo "valid" # 正确返回
    else
        echo "invalid" # 不正确返回
    fi
}

SetAutoUpdate() {
    if [[ -z "${TelgramBotToken}" || -z "${ChatID_1}" ]]; then
        tips="$Err 参数丢失, 请设置后再执行 (先执行 ${GR}0${NC} 选项)."
        return 1
    fi
    if [ "$autorun" == "false" ]; then
        echo -e "输入定时更新时间, 格式如: 23:34 (即每天 ${GR}23${NC} 时 ${GR}34${NC} 分)"
        read -e -p "请输入定时模式  (回车默认: $AutoUpdateTime_de ): " input_time
    else
        if [ -z "$AutoUpdateTime" ]; then
            input_time=""
        else
            input_time=$AutoUpdateTime
        fi
    fi
    if [ -z "$input_time" ]; then
        input_time="$AutoUpdateTime_de"
    fi
    if [ $(validate_time_format "$input_time") = "invalid" ]; then
        tips="$Err 输入格式不正确，请确保输入的时间格式为 'HH:MM'"
        return 1
    fi
    writeini "AutoUpdateTime" "$input_time"
    hour_ud=${input_time%%:*}
    minute_ud=${input_time#*:}

    minute_ud_next=$((minute_ud + 1))
    hour_ud_next=$hour_ud

    if [ $minute_ud_next -eq 60 ]; then
        minute_ud_next=0
        hour_ud_next=$((hour + 1))
        if [ $hour_ud_next -eq 24 ]; then
            hour_ud_next=0
        fi
    fi
    if [ ${#hour_ud} -eq 1 ]; then
    hour_ud="0${hour_ud}"
    fi
    if [ ${#minute_ud} -eq 1 ]; then
        minute_ud="0${minute_ud}"
    fi
    if [ ${#hour_ud_next} -eq 1 ]; then
    hour_ud_next="0${hour_ud_next}"
    fi
    if [ ${#minute_ud_next} -eq 1 ]; then
        minute_ud_next="0${minute_ud_next}"
    fi
    cront="$minute_ud $hour_ud * * *"
    cront_next="$minute_ud_next $hour_ud_next * * *"
    echo -e "$Tip 自动更新时间：$hour_ud 时 $minute_ud 分."
    cat <<EOF > "$FolderPath/tg_autoud.sh"
#!/bin/bash

retry=0
max_retries=3
mirror_retries=2

# 下载函数，接受下载链接作为参数
download_file() {
    wget -O "$FolderPath/VPSKeeper.sh" "\$1"
}

# 备份旧文件
if [ -f "$FolderPath/VPSKeeper.sh" ]; then
    mv "$FolderPath/VPSKeeper.sh" "$FolderPath/VPSKeeper_old.sh"
fi

# 尝试从原始地址下载
while [ \$retry -lt \$max_retries ]; do
    download_file "https://raw.githubusercontent.com/redstarxxx/shell/main/VPSKeeper.sh"
    if [ -s "$FolderPath/VPSKeeper.sh" ]; then
        echo "下载成功"
        break
    else
        echo "下载失败，尝试重新下载..."
        ((retry++))
    fi
done

# 如果原始地址下载失败，则尝试从备用镜像地址下载
if [ ! -s "$FolderPath/VPSKeeper.sh" ]; then
    echo "尝试从备用镜像地址下载..."
    retry=0
    while [ \$retry -lt \$mirror_retries ]; do
        download_file "https://mirror.ghproxy.com/https://raw.githubusercontent.com/redstarxxx/shell/main/VPSKeeper.sh"
        if [ -s "$FolderPath/VPSKeeper.sh" ]; then
            echo "备用镜像下载成功"
            break
        else
            echo "备用镜像下载失败，尝试重新下载..."
            ((retry++))
        fi
    done
fi

# 检查是否下载成功
if [ ! -s "$FolderPath/VPSKeeper.sh" ]; then
    echo "下载失败，无法获取 VPSKeeper.sh 文件"
    # 如果下载失败，将旧文件恢复
    if [ -f "$FolderPath/VPSKeeper_old.sh" ]; then
        mv "$FolderPath/VPSKeeper_old.sh" "$FolderPath/VPSKeeper.sh"
    fi
    exit 1
fi

# 比较文件大小
if [ -f "$FolderPath/VPSKeeper_old.sh" ]; then
    old_size=\$(wc -c < "$FolderPath/VPSKeeper_old.sh")
    new_size=\$(wc -c < "$FolderPath/VPSKeeper.sh")
    if [ \$old_size -ne \$new_size ]; then
        echo "更新成功"
    else
        echo "无更新内容"
    fi
fi

# 删除旧文件
if [ -f "$FolderPath/VPSKeeper_old.sh" ]; then
    rm "$FolderPath/VPSKeeper_old.sh"
fi
EOF
    chmod +x $FolderPath/tg_autoud.sh
    if crontab -l | grep -q "bash $FolderPath/tg_autoud.sh > $FolderPath/tg_autoud.log 2>&1 &"; then
        crontab -l | grep -v "bash $FolderPath/tg_autoud.sh > $FolderPath/tg_autoud.log 2>&1 &" | crontab -
    fi
    (crontab -l 2>/dev/null; echo "$cront bash $FolderPath/tg_autoud.sh > $FolderPath/tg_autoud.log 2>&1 &") | crontab -
    if [ "$autorun" == "false" ]; then
        echo -e "如果开启 ${REB}静音模式${NC} 更新时你将不会收到提醒通知, 是否要开启静音模式?"
        read -e -p "请输入你的选择 回车.(默认开启)   N.不开启: " choice
    else
        choice=""
    fi
    if [ "$choice" == "N" ] || [ "$choice" == "n" ]; then
        if crontab -l | grep -q "bash $FolderPath/VPSKeeper.sh"; then
            crontab -l | grep -v "bash $FolderPath/VPSKeeper.sh" | crontab -
        fi
        (crontab -l 2>/dev/null; echo "$cront_next bash $FolderPath/VPSKeeper.sh \"auto\" 2>&1 &") | crontab -
        mute_mode="更新时通知"
    else
        if crontab -l | grep -q "bash $FolderPath/VPSKeeper.sh"; then
            crontab -l | grep -v "bash $FolderPath/VPSKeeper.sh" | crontab -
        fi
        (crontab -l 2>/dev/null; echo "$cront_next bash $FolderPath/VPSKeeper.sh \"auto\" \"mute\" 2>&1 &") | crontab -
        mute_mode="静音模式"
    fi
    if [ "$mute" == "false" ]; then
        $FolderPath/send_tg.sh "$TelgramBotToken" "$ChatID_1" "自动更新脚本设置成功 ⚙️"$'\n'"主机名: $hostname_show"$'\n'"更新时间: 每天 $hour_ud 时 $minute_ud 分"$'\n'"通知模式: $mute_mode" &
    fi
    tips="$Tip 自动更新设置成功, 更新时间: 每天 $hour_ud 时 $minute_ud 分, 通知模式: ${GR}$mute_mode${NC}"
}

# 发送Telegram消息的函数
send_telegram_message() {
    curl -s -X POST "https://api.telegram.org/bot$TelgramBotToken/sendMessage" \
        -d chat_id="$ChatID_1" -d text="$1" > /dev/null
}

# 获取VPS信息
GetVPSInfo() {
    cpu_total=""
    cpu_used=""
    if [ -x "$(command -v lscpu)" ]; then
        cpu_total=$(lscpu | grep "^CPU(s):" | awk '{print $2}')
    fi
    cpu_used=$(cat /proc/cpuinfo | grep "^core id" | wc -l)
    if [ "$cpu_total" == "" ]; then
        cpuusedOfcpus=$cpu_used
    elif [ "$cpu_used" == "$cpu_total" ]; then
        cpuusedOfcpus=$cpu_total
    else
        cpuusedOfcpus=$(cat /proc/cpuinfo | grep "^core id" | wc -l)/$(lscpu | grep "^CPU(s):" | awk '{print $2}')
    fi
    # mem_total=$(top -bn1 | awk '/^MiB Mem/ { gsub(/Mem|total,|free,|used,|buff\/cache|:/, " ", $0); print int($2) }')
    # swap_total=$(top -bn1 | awk '/^MiB Swap/ { gsub(/Swap|total,|free,|used,|buff\/cache|:/, " ", $0); print int($2) }')
    mem_total_bytes=$(free | grep 'Mem:' | awk '{print int($2)}')
    mem_total=$((mem_total_bytes / 1024))
    swap_total_bytes=$(free | grep 'Swap:' | awk '{print int($2)}')
    swap_total=$((swap_total_bytes / 1024))
    disk_total=$(df -h / | awk 'NR==2 {print $2}')
    disk_used=$(df -h / | awk 'NR==2 {print $3}')
    # echo "主机名: $hostname_show"$'\n'"CPUs: $cpuusedOfcpus"$'\n'"内存: $mem_total"\$'\n'"交换: $swap_total"$'\n'"磁盘: $disk_total"
}

# 设置ini参数文件
SetupIniFile() {
    # 设置电报机器人参数
    divline
    echo -e "$Tip 默认机器人: @iekeeperbot 使用前必须添加并点击 start"
    while true; do
        source $ConfigFile
        divline
        echo -e "${GR}1${NC}.BOT Token ${GR}2${NC}.CHAT ID ${GR}3${NC}.CPU检测工具 (默认使用 top)"
        if $SHUTDOWN_RT; then
            srtag="(${RE}已启动${NC})"
        else
            srtag=""
        fi
        echo -e "${GR}4${NC}.设置流量上限（仅参考） ${GR}5${NC}.设置关机记录流量$srtag ${GR}回车${NC}.退出设置"
        divline
        read -e -p "请输入你的选择: " choice
        case $choice in
            1)
                # 设置BOT Token
                echo -e "$Tip ${REB}BOT Token${NC} 获取方法: 在 Telgram 中添加机器人 @BotFather, 输入: /newbot"
                divline
                if [ "$TelgramBotToken" != "" ]; then
                    echo -e "当前${GR}[BOT Token]${NC}: $TelgramBotToken"
                else
                    echo -e "当前${GR}[BOT Token]${NC}: 空"
                fi
                divline
                read -e -p "请输入 BOT Token (回车跳过修改 / 输入 R 使用默认机器人): " bottoken
                if [ "$bottoken" == "r" ] || [ "$bottoken" == "R" ]; then
                    writeini "TelgramBotToken" "7030486799:AAEa4PyCKGN7347v1mt2gyaBoySdxuh56ws"
                    UN_ALL
                    tips="$Tip 接收信息已经改动, 请重新设置所有通知."
                    break
                fi
                if [ ! -z "$bottoken" ]; then
                    writeini "TelgramBotToken" "$bottoken"
                    UN_ALL
                    tips="$Tip 接收信息已经改动, 请重新设置所有通知."
                    break
                else
                    echo -e "$Tip 输入为空, 跳过操作."
                    tips=""
                fi
                ;;
            2)
                # 设置Chat ID
                echo -e "$Tip ${REB}Chat ID${NC} 获取方法: 在 Telgram 中添加机器人 @userinfobot, 点击或输入: /start"
                divline
                if [ "$ChatID_1" != "" ]; then
                    echo -e "当前${GR}[CHAT ID]${NC}: $ChatID_1"
                else
                    echo -e "当前${GR}[CHAT ID]${NC}: 空"
                fi
                divline
                read -e -p "请输入 Chat ID (回车跳过修改): " cahtid
                if [ ! -z "$cahtid" ]; then
                    if [[ $cahtid =~ ^[0-9]+$ ]]; then
                        writeini "ChatID_1" "$cahtid"
                        UN_ALL
                        tips="$Tip 接收信息已经改动, 请重新设置所有通知."
                        break
                    else
                        echo -e "$Err ${REB}输入无效${NC}, Chat ID 必须是数字, 跳过操作."
                    fi
                else
                    echo -e "$Tip 输入为空, 跳过操作."
                    tips=""
                fi
                ;;
            3)
                # 设置CPU检测工具
                if cat /proc/version 2>/dev/null | grep -q -E -i "openwrt"; then
                    tips="$Tip OpenWRT 系统只能使用默认的 top 工具."
                    break
                else
                    echo -e "$Tip 请选择 ${REB}CPU 检测工具${NC}: 1.top(系统自带) 2.sar(更专业) 3.top+sar"
                    divline
                    if [ "$CPUTools" != "" ]; then
                        echo -e "当前${GR}[CPU 检测工具]${NC}: $CPUTools"
                    else
                        echo -e "当前${GR}[CPU 检测工具]${NC}: 空"
                    fi
                    divline
                    read -e -p "请输入序号 (默认采用 1.top / 回车跳过修改): " choice
                    if [ ! -z "$choice" ]; then
                        if [ "$choice" == "1" ]; then
                            CPUTools="top"
                            writeini "CPUTools" "$CPUTools"
                        elif [ "$choice" == "2" ]; then
                            CPUTools="sar"
                            writeini "CPUTools" "$CPUTools"
                        elif [ "$choice" == "3" ]; then
                            CPUTools="top_sar"
                            writeini "CPUTools" "$CPUTools"
                        fi
                        break
                    else
                        echo -e "$Tip 输入为空, 跳过操作."
                        tips=""
                    fi
                fi
                ;;
            4)
                # 设置流量上限（仅参考）
                read -e -p "请设置 流量上限 数字 + MB/GB/TB (回车默认: $FlowThresholdMAX_de): " threshold_max
                if [ ! -z "$threshold_max" ]; then
                    if [[ $threshold_max =~ ^[0-9]+(\.[0-9])?$ ]] || [[ $threshold_max =~ ^[0-9]+(\.[0-9]+)?(M)$ ]] || [[ $threshold_max =~ ^[0-9]+(\.[0-9]+)?(MB)$ ]]; then
                        threshold_max=${threshold_max%M}
                        threshold_max=${threshold_max%MB}
                        if awk -v value="$threshold_max" 'BEGIN { exit !(value >= 1024 * 1024) }'; then
                            threshold_max=$(awk -v value="$threshold_max" 'BEGIN { printf "%.1f", value / (1024 * 1024) }')
                            threshold_max="${threshold_max}TB"
                        elif awk -v value="$threshold_max" 'BEGIN { exit !(value >= 1024) }'; then
                            threshold_max=$(awk -v value="$threshold_max"_max 'BEGIN { printf "%.1f", value / 1024 }')
                            threshold_max="${threshold_max}GB"
                        else
                            threshold_max="${threshold_max}MB"
                        fi
                        writeini "FlowThresholdMAX" "$threshold_max"
                    elif [[ $threshold_max =~ ^[0-9]+(\.[0-9]+)?(G)$ ]] || [[ $threshold_max =~ ^[0-9]+(\.[0-9]+)?(GB)$ ]]; then
                        threshold_max=${threshold_max%G}
                        threshold_max=${threshold_max%GB}
                        if awk -v value="$threshold_max" 'BEGIN { exit !(value >= 1024) }'; then
                            threshold_max=$(awk -v value="$threshold_max"_max 'BEGIN { printf "%.1f", value / 1024 }')
                            threshold_max="${threshold_max}TB"
                        else
                            threshold_max="${threshold_max}GB"
                        fi
                        writeini "FlowThresholdMAX" "$threshold_max"
                    elif [[ $threshold_max =~ ^[0-9]+(\.[0-9]+)?(T)$ ]] || [[ $threshold_max =~ ^[0-9]+(\.[0-9]+)?(TB)$ ]]; then
                        threshold_max=${threshold_max%T}
                        threshold_max=${threshold_max%TB}
                        threshold_max="${threshold_max}TB"
                        writeini "FlowThresholdMAX" "$threshold_max"
                    else
                        echo -e "$Err ${REB}输入无效${NC}, 报警阈值 必须是: 数字|数字MB/数字GB (%.1f) 的格式(支持1位小数), 跳过操作."
                        return 1
                    fi
                else
                    writeini "FlowThresholdMAX" "$FlowThresholdMAX_de"
                    echo -e "$Tip 输入为空, 默认最大流量上限为: $FlowThresholdMAX_de"
                fi
            ;;
            5)
                # 设置关机记录流量
                if cat /proc/version 2>/dev/null | grep -q -E -i "openwrt"; then
                    tips="$Err OpenWRT 系统暂不支持."
                    break
                fi
                if ! command -v systemd &>/dev/null; then
                    tips="$Err 系统未检测到 \"systemd\" 程序, 无法设置关机通知."
                    break
                fi
                if [[ -z "${TelgramBotToken}" || -z "${ChatID_1}" ]]; then
                    tips="$Err 参数丢失, 请设置后再执行 (先执行 ${GR}0${NC} 选项)."
                    break
                fi
                read -e -p "请选择是否开启 设置关机记录流量  N.关闭(删除记录)  回车.开启(默认): " choice
                if [ "$choice" == "n" ] || [ "$choice" == "N" ]; then
                    systemctl stop tg_shutdown_rt.service > /dev/null 2>&1
                    systemctl disable tg_shutdown_rt.service > /dev/null 2>&1
                    sleep 1
                    rm -f /etc/systemd/system/tg_shutdown_rt.service

                    interfaces_get=$(ip -br link | awk '{print $1}')
                    declare -a interfaces=($interfaces_get)
                    for ((i=0; i<${#interfaces[@]}; i++)); do
                        interface=${interfaces[$i]%@*}
                        interface=${interface%:*}
                        interfaces[$i]=$interface
                        sed -i "/^INTERFACE_RT_RX_MB\[$interface\]=/d" $ConfigFile
                        sed -i "/^INTERFACE_RT_TX_MB\[$interface\]=/d" $ConfigFile
                    done
                    writeini "SHUTDOWN_RT" "false"
                    echo -e "$Tip 关机记录流量 (已删除记录) 已经取消 / 删除."
                else
                    cat <<EOF > $FolderPath/tg_shutdown_rt.sh
#!/bin/bash

ConfigFile=$ConfigFile
$(declare -f writeini)

declare -A INTERFACE_RT_RX_b
declare -A INTERFACE_RT_TX_b
declare -A INTERFACE_RT_RX_MB
declare -A INTERFACE_RT_TX_MB

interfaces_get=\$(ip -br link | awk '{print \$1}')
declare -a interfaces=(\$interfaces_get)
echo "1统计接口: \${interfaces[@]}"
for ((i = 0; i < \${#interfaces[@]}; i++)); do
    echo "\$((i+1)): \${interfaces[i]}"
done
for ((i=0; i<\${#interfaces[@]}; i++)); do
    interface=\${interfaces[\$i]%@*}
    interface=\${interface%:*}
    interfaces[\$i]=\$interface
done
source \$ConfigFile
for interface in "\${interfaces[@]}"; do
    echo "----------------------------------- FOR: \$interface"
    rx_bytes=\$(ip -s link show \$interface | awk '/RX:/ { getline; print \$1 }')
    echo "rx_bytes: \$rx_bytes"
    if [ ! -z "\$rx_bytes" ] && [[ \$rx_bytes =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        INTERFACE_RT_RX_b[\$interface]=\$rx_bytes
        writeini "INTERFACE_RT_RX_b[\$interface]" "\${INTERFACE_RT_RX_b[\$interface]}"
        INTERFACE_RT_RX_MB_TEMP=\$(awk -v v1="\$rx_bytes" 'BEGIN { printf "%.1f", v1 / (1024 * 1024) }')

        if [ ! -z "\${INTERFACE_RT_RX_MB[\$interface]}" ] && [[ \${INTERFACE_RT_RX_MB[\$interface]} =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
            INTERFACE_RT_RX_MB[\$interface]=\$(awk -v v1="\$INTERFACE_RT_RX_MB_TEMP" -v v2="\${INTERFACE_RT_RX_MB[\$interface]}" 'BEGIN { printf "%.1f", v1 + v2 }')
        else
            INTERFACE_RT_RX_MB[\$interface]=\$(awk -v v1="\$rx_bytes" 'BEGIN { printf "%.1f", v1 / (1024 * 1024) }')
        fi

        sed -i "/^INTERFACE_RT_RX_MB\[\$interface\]=/d" \$ConfigFile
        # writeini "INTERFACE_RT_RX_MB[\$interface]" "\${INTERFACE_RT_RX_MB[\$interface]}"
        echo "INTERFACE_RT_RX_MB[\$interface]: \${INTERFACE_RT_RX_MB[\$interface]}"
    fi

    tx_bytes=\$(ip -s link show \$interface | awk '/TX:/ { getline; print \$1 }')
    echo "tx_bytes: \$tx_bytes"
    if [ ! -z "\$tx_bytes" ] && [[ \$tx_bytes =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        INTERFACE_RT_TX_b[\$interface]=\$tx_bytes
        writeini "INTERFACE_RT_TX_b[\$interface]" "\${INTERFACE_RT_TX_b[\$interface]}"
        INTERFACE_RT_TX_MB_TEMP=\$(awk -v v1="\$tx_bytes" 'BEGIN { printf "%.1f", v1 / (1024 * 1024) }')

        if [ ! -z "\${INTERFACE_RT_TX_MB[\$interface]}" ] && [[ \${INTERFACE_RT_TX_MB[\$interface]} =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
            INTERFACE_RT_TX_MB[\$interface]=\$(awk -v v1="\$INTERFACE_RT_TX_MB_TEMP" -v v2="\${INTERFACE_RT_TX_MB[\$interface]}" 'BEGIN { printf "%.1f", v1 + v2 }')
        else
            INTERFACE_RT_TX_MB[\$interface]=\$(awk -v v1="\$tx_bytes" 'BEGIN { printf "%.1f", v1 / (1024 * 1024) }')
        fi

        sed -i "/^INTERFACE_RT_TX_MB\[\$interface\]=/d" \$ConfigFile
        # writeini "INTERFACE_RT_TX_MB[\$interface]" "\${INTERFACE_RT_TX_MB[\$interface]}"
        echo "INTERFACE_RT_TX_MB[\$interface]: \${INTERFACE_RT_TX_MB[\$interface]}"
    fi

done
echo "====================================== 检正部分"
cat \$ConfigFile
echo
source \$ConfigFile
for interface in "\${interfaces[@]}"; do
    INTERFACE_RT_RX_b[\$interface]=\${INTERFACE_RT_RX_b[\$interface]}
    echo "读取: INTERFACE_RT_RX_b[\$interface]: \${INTERFACE_RT_RX_b[\$interface]}"
    INTERFACE_RT_TX_b[\$interface]=\${INTERFACE_RT_TX_b[\$interface]}
    echo "读取: INTERFACE_RT_TX_b[\$interface]: \${INTERFACE_RT_TX_b[\$interface]}"
done
for interface in "\${interfaces[@]}"; do
    INTERFACE_RT_RX_MB[\$interface]=\${INTERFACE_RT_RX_MB[\$interface]}
    echo "读取: INTERFACE_RT_RX_MB[\$interface]: \${INTERFACE_RT_RX_MB[\$interface]}"
    INTERFACE_RT_TX_MB[\$interface]=\${INTERFACE_RT_TX_MB[\$interface]}
    echo "读取: INTERFACE_RT_TX_MB[\$interface]: \${INTERFACE_RT_TX_MB[\$interface]}"
done
EOF
                    chmod +x $FolderPath/tg_shutdown_rt.sh
                    cat <<EOF > /etc/systemd/system/tg_shutdown_rt.service
[Unit]
Description=tg_shutdown
DefaultDependencies=no
Before=shutdown.target

[Service]
Type=oneshot
ExecStart=$FolderPath/tg_shutdown_rt.sh
TimeoutStartSec=0

[Install]
WantedBy=shutdown.target
EOF
                    systemctl enable tg_shutdown_rt.service > /dev/null
                    writeini "SHUTDOWN_RT" "true"
                    echo -e "$Tip 关机记录流量 已经成功设置."
                fi
            ;;
            *)
                echo "退出设置."
                tips=""
                break
            ;;
        esac
    done
   
}

# 用于显示内容（调试用）
# SourceAndShowINI() {
#     if [ -f $ConfigFile ] && [ -s $ConfigFile ]; then
#         source $ConfigFile
#         divline
#         cat $ConfigFile
#         divline
#         echo -e "$Tip 以上为 TelgramBot.ini 文件内容, 可重新执行 ${GR}0${NC} 修改参数."
#     fi
# }

# 写入ini文件
writeini() {
    if grep -q "^$1=" $ConfigFile; then
        sed -i "/^$1=/d" $ConfigFile
    fi
    echo "$1=$2" >> $ConfigFile
}

# 删除ini文件指定行
delini() {
    sed -i "/^$1=/d" $ConfigFile
}

# 检查文件是否存在并显示内容（调试用）
ShowContents() {
    if [ -f "$1" ]; then
        cat "$1"
        echo -e "$Inf 上述内容已经写入: $1"
        echo "-------------------------------------------"
    else
        echo -e "$Err 文件不存在: $1"
    fi
}

# 发送测试
test() {
    if [[ -z "${TelgramBotToken}" || -z "${ChatID_1}" ]]; then
        tips="$Err 参数丢失, 请设置后再执行 (先执行 ${GR}0${NC} 选项)."
        return 1
    fi
    curl -s -X POST "https://api.telegram.org/bot$TelgramBotToken/sendMessage" \
        -d chat_id="$ChatID_1" -d text="来自 $hostname_show 的测试信息" > /dev/null
    tips="$Inf 测试信息已发出, 电报将收到一条\"来自 $hostname_show 的测试信息\"的信息."
}

# 修改Hostname
ModifyHostname() {
    echo "当前 主机名 : $hostname_show"
    read -e -p "请输入要修改的 主机名 (回车跳过): " name
    if [[ ! -z "${name}" ]]; then
        writeini "hostname_show" "$name"
        source $ConfigFile
        if command -v hostnamectl &>/dev/null; then
            read -e -p "是否要将 Hostmane 修改成 $hostname_show  Y/回车跳过 : " yorn
            if [ "$yorn" == "Y" ] || [ "$yorn" == "y" ]; then
                echo "修改 hosts 和 hostname..."
                sed -i "s/$hostname_show/$name/g" /etc/hosts
                echo -e "$name" > /etc/hostname
                hostnamectl set-hostname $name
                tips="$Tip 修改后 主机名 : $hostname_show  Hostname: $hostname_show"
            fi
        else
            tips="$Tip 修改后 主机名: $hostname_show, 但未检测到 hostnamectl, 无法修改 Hostname."
        fi
    else
        tips="$Tip 输入为空, 跳过操作."
    fi
}

# 设置开机通知
SetupBoot_TG() {
    if [[ -z "${TelgramBotToken}" || -z "${ChatID_1}" ]]; then
        tips="$Err 参数丢失, 请设置后再执行 (先执行 ${GR}0${NC} 选项)."
        return 1
    fi
    cat <<EOF > $FolderPath/tg_boot.sh
#!/bin/bash

current_date_send=\$(date +"%Y.%m.%d %T")
message="$hostname_show 已启动❗️"'
'"服务器时间: \$current_date_send"

curl -s -X POST "https://api.telegram.org/bot$TelgramBotToken/sendMessage" \
    -d chat_id="$ChatID_1" -d text="\$message"
EOF
    chmod +x $FolderPath/tg_boot.sh
    if command -v systemd &>/dev/null; then
        cat <<EOF > /etc/systemd/system/tg_boot.service
[Unit]
Description=Run tg_boot.sh script at boot time
After=network.target

[Service]
Type=oneshot
ExecStart=$FolderPath/tg_boot.sh
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF
        systemctl enable tg_boot.service > /dev/null
    elif cat /proc/version 2>/dev/null | grep -q -E -i "openwrt"; then
        cat <<EOF > /etc/init.d/tg_boot.sh
#!/bin/sh /etc/rc.common

START=99
STOP=15

start() {
    current_date_send=\$(date +"%Y.%m.%d %T")
    message="$hostname_show 已启动❗️"'
    '"服务器时间: \$current_date_send"

    curl -s -X POST "https://api.telegram.org/bot$TelgramBotToken/sendMessage" \
        -d chat_id="$ChatID_1" -d text="\$message" &
}
EOF
        chmod +x /etc/init.d/tg_boot.sh
        /etc/init.d/tg_boot.sh enable
    else
        tips="$Err 系统未检测到 \"systemd\" 程序, 无法设置开机通知."
        return 1
    fi
    if [ "$mute" == "false" ]; then
        $FolderPath/send_tg.sh "$TelgramBotToken" "$ChatID_1" "设置成功: 开机 通知⚙️"$'\n'"主机名: $hostname_show"$'\n'"💡当 开机 时将收到通知." &
    fi
    tips="$Tip 开机 通知已经设置成功, 当开机时你的 Telgram 将收到通知."
    
}

# 设置登陆通知
SetupLogin_TG() {
    if [[ -z "${TelgramBotToken}" || -z "${ChatID_1}" ]]; then
        tips="$Err 参数丢失, 请设置后再执行 (先执行 ${GR}0${NC} 选项)."
        return 1
    fi
    cat <<EOF > $FolderPath/tg_login.sh
#!/bin/bash

current_date_send=\$(date +"%Y.%m.%d %T")
message="$hostname_show \$(id -nu) 用户登陆成功❗️"'
'"服务器时间: \$current_date_send"

curl -s -X POST "https://api.telegram.org/bot$TelgramBotToken/sendMessage" \
            -d chat_id="$ChatID_1" -d text="\$message" &
EOF
    chmod +x $FolderPath/tg_login.sh
    if [ -f /etc/bash.bashrc ] && [ "$release" != "openwrt" ]; then
        if ! grep -q "bash $FolderPath/tg_login.sh > /dev/null 2>&1" /etc/bash.bashrc; then
            echo "bash $FolderPath/tg_login.sh > /dev/null 2>&1" >> /etc/bash.bashrc
        fi
        if [ "$mute" == "false" ]; then
            $FolderPath/send_tg.sh "$TelgramBotToken" "$ChatID_1" "设置成功: 登陆 通知⚙️"$'\n'"主机名: $hostname_show"$'\n'"💡当 登陆 时将收到通知." &
        fi
        tips="$Tip 登陆 通知已经设置成功, 当登陆时你的 Telgram 将收到通知."
    elif [ -f /etc/profile ]; then
        if ! grep -q "bash $FolderPath/tg_login.sh > /dev/null 2>&1" /etc/profile; then
            echo "bash $FolderPath/tg_login.sh > /dev/null 2>&1" >> /etc/profile
        fi
        if [ "$mute" == "false" ]; then
            $FolderPath/send_tg.sh "$TelgramBotToken" "$ChatID_1" "设置成功: 登陆 通知⚙️"$'\n'"主机名: $hostname_show"$'\n'"💡当 登陆 时将收到通知." &
        fi
        tips="$Tip 登陆 通知已经设置成功, 当登陆时你的 Telgram 将收到通知."
    else
        tips="$Err 未检测到对应文件, 无法设置登陆通知."
    fi
}

# 设置关机通知
SetupShutdown_TG() {
    if [[ -z "${TelgramBotToken}" || -z "${ChatID_1}" ]]; then
        tips="$Err 参数丢失, 请设置后再执行 (先执行 ${GR}0${NC} 选项)."
        return 1
    fi
    cat <<EOF > $FolderPath/tg_shutdown.sh
#!/bin/bash

current_date_send=\$(date +"%Y.%m.%d %T")
message="$hostname_show \$(id -nu) 正在执行关机...❗️"'
'"服务器时间: \$current_date_send"

curl -s -X POST "https://api.telegram.org/bot$TelgramBotToken/sendMessage" \
            -d chat_id="$ChatID_1" -d text="\$message"
EOF
    chmod +x $FolderPath/tg_shutdown.sh
    if command -v systemd &>/dev/null; then
        cat <<EOF > /etc/systemd/system/tg_shutdown.service
[Unit]
Description=tg_shutdown
DefaultDependencies=no
Before=shutdown.target

[Service]
Type=oneshot
ExecStart=$FolderPath/tg_shutdown.sh
TimeoutStartSec=0

[Install]
WantedBy=shutdown.target
EOF
        systemctl enable tg_shutdown.service > /dev/null
    elif cat /proc/version 2>/dev/null | grep -q -E -i "openwrt"; then
        cat <<EOF > /etc/init.d/tg_shutdown.sh
#!/bin/sh /etc/rc.common

STOP=15

stop() {
    current_date_send=\$(date +"%Y.%m.%d %T")
    message="$hostname_show \$(id -nu) 正在执行关机...❗️"'
    '"服务器时间: \$current_date_send"

    curl -s -X POST "https://api.telegram.org/bot$TelgramBotToken/sendMessage" \
        -d chat_id="$ChatID_1" -d text="\$message"
}
EOF
        chmod +x /etc/init.d/tg_shutdown.sh
        /etc/init.d/tg_shutdown.sh enable
    else
        tips="$Err 系统未检测到 \"systemd\" 程序, 无法设置关机通知."
        return 1
    fi
    if [ "$mute" == "false" ]; then
        $FolderPath/send_tg.sh "$TelgramBotToken" "$ChatID_1" "设置成功: 关机 通知⚙️"$'\n'"主机名: $hostname_show"$'\n'"💡当 关机 时将收到通知." &
    fi
    tips="$Tip 关机 通知已经设置成功, 当开机时你的 Telgram 将收到通知."
}

# 设置Dokcer通知
SetupDocker_TG() {
    if ! command -v docker &>/dev/null; then
        tips="$Err 未检测到 \"Docker\" 程序."
        return 1
    fi
    if [[ -z "${TelgramBotToken}" || -z "${ChatID_1}" ]]; then
        tips="$Err 参数丢失, 请设置后再执行 (先执行 ${GR}0${NC} 选项)."
        return 1
    fi
    cat <<EOF > $FolderPath/tg_docker.sh
#!/bin/bash

old_message=""
while true; do
    # new_message=\$(docker ps --format '{{.Names}}' | tr '\n' "\n" | sed 's/|$//')
    new_message=\$(docker ps --format '{{.Names}}' | awk '{print NR". " \$0}')
    if [ "\$new_message" != "\$old_message" ]; then
        current_date_send=\$(date +"%Y.%m.%d %T")
        old_message=\$new_message
        message="DOCKER 列表变更❗️"'
'"───────────────"'
'"\$new_message"'
'"服务器时间: \$current_date_send"
        curl -s -X POST "https://api.telegram.org/bot$TelgramBotToken/sendMessage" \
            -d chat_id="$ChatID_1" -d text="\$message"
    fi
    sleep 10
done
EOF
    chmod +x $FolderPath/tg_docker.sh
    pkill tg_docker.sh > /dev/null 2>&1 &
    pkill tg_docker.sh > /dev/null 2>&1 &
    kill $(ps | grep '[t]g_docker.sh' | awk '{print $1}')
    nohup $FolderPath/tg_docker.sh > $FolderPath/tg_docker.log 2>&1 &
    if ! crontab -l | grep -q "@reboot nohup $FolderPath/tg_docker.sh > $FolderPath/tg_docker.log 2>&1 &"; then
        (crontab -l 2>/dev/null; echo "@reboot nohup $FolderPath/tg_docker.sh > $FolderPath/tg_docker.log 2>&1 &") | crontab -
    fi
    if [ "$mute" == "false" ]; then
        $FolderPath/send_tg.sh "$TelgramBotToken" "$ChatID_1" "设置成功: Docker 变更通知⚙️"$'\n'"主机名: $hostname_show"$'\n'"💡当 Docker 列表变更时将收到通知." &
    fi
    tips="$Tip Docker 通知已经设置成功, 当 Dokcer 挂载发生变化时你的 Telgram 将收到通知."
}

CheckCPU_top() {
    echo "正在检测 CPU 使用率..."
    if top -n 1 | grep '^%Cpu(s)'; then
        cpu_usage_ratio=$(awk '{ gsub(/us,|sy,|ni,|id,|:/, " ", $0); idle+=$5; count++ } END { printf "%.2f", 100 - (idle / count) }' <(grep "Cpu(s)" <(top -bn5 -d 3)))
    fi
    if top -n 1 | grep -q '^CPU'; then
        cpu_usage_ratio=$(top -bn5 -d 3 | grep '^CPU' | awk '{ idle+=$8; count++ } END { printf "%.2f", 100 - (idle / count) }')
    fi
    echo "top检测结果: $cpu_usage_ratio | 日期: $(date)"
}

CheckCPU_sar() {
    echo "正在检测 CPU 使用率..."
    cpu_usage_ratio=$(sar -u 3 5 | awk '/^Average:/ { printf "%.2f", 100 - $NF }')
    echo "sar检测结果: $cpu_usage_ratio | 日期: $(date)"
}

CheckCPU_top_sar() {
    echo "正在检测 CPU 使用率..."
    cpu_usage_sar=$(sar -u 3 5 | awk '/^Average:/ { printf "%.0f", 100 - $NF }')
    cpu_usage_top=$(awk '{ gsub(/us,|sy,|ni,|id,|:/, " ", $0); idle+=$5; count++ } END { printf "%.0f", 100 - (idle / count) }' <(grep "Cpu(s)" <(top -bn5 -d 3)))
    cpu_usage_ratio=$(awk -v sar="$cpu_usage_sar" -v top="$cpu_usage_top" 'BEGIN { printf "%.2f", (sar + top) / 2 }')
    echo "sar检测结果: $cpu_usage_sar | top检测结果: $cpu_usage_top | 平均值: $cpu_usage_ratio | 日期: $(date)"
}

# 获取系统信息
GetInfo_now() {
    echo "正在获取系统信息..."
    # top_output=$(top -bn1)
    top_output=$(top -n 1 -b | head -n 10)
    echo "top: $top_output"
    if echo "$top_output" | grep -q "^%Cpu"; then
        # top -V
        top_output_h=$(echo "$top_output" | awk 'NR > 7')
        cpu_h1=$(echo "$top_output_h" | awk 'NR == 1 || $9 > max { max = $9; process = $NF } END { print process }')
        cpu_h2=$(echo "$top_output_h" | awk 'NR == 2 || $9 > max { max = $9; process = $NF } END { print process }')
        # mem_total=$(echo "$top_output" | awk '/^MiB Mem/ { gsub(/Mem|total,|free,|used,|buff\/cache|:/, " ", $0); print int($2) }')
        # if [ -z "$mem_total" ]; then
        #     mem_total=$(echo "$top_output" | awk '/^KiB Mem/ { gsub(/Mem|total,|free,|used,|buff\/cache|:/, " ", $0); print int($2/1024) }')
        # fi
        # mem_used=$(echo "$top_output" | awk '/^MiB Mem/ { gsub(/Mem|total,|free,|used,|buff\/cache|:/, " ", $0); print int($4) }')
        # if [ -z "$mem_used" ]; then
        #     mem_used=$(echo "$top_output" | awk '/^KiB Mem/ { gsub(/Mem|total,|free,|used,|buff\/cache|:/, " ", $0); print int($4/1024) }')
        # fi
        # mem_use_ratio=$(awk -v used="$mem_used" -v total="$mem_total" 'BEGIN { printf "%.0f", ( used / total ) * 100 }')
        # swap_total=$(echo "$top_output" | awk '/^MiB Swap/ { gsub(/Swap|total,|free,|used,|buff\/cache|:/, " ", $0); print int($2) }')
        # swap_used=$(echo "$top_output" | awk '/^MiB Swap/ { gsub(/Swap|total,|free,|used,|buff\/cache|:/, " ", $0); print int($4) }')
        # swap_use_ratio=$(awk -v used="$swap_used" -v total="$swap_total" 'BEGIN { printf "%.0f", ( used / total ) * 100 }')
    elif echo "$top_output" | grep -q "^CPU"; then
        # top -V
        top_output_h=$(echo "$top_output" | awk 'NR > 4')
        # cpu_h1=$(echo "$top_output_h" | awk 'NR == 1 || $7 > max { max = $7; process = $NF } END { print process }' | awk '{print $1}')
        # cpu_h2=$(echo "$top_output_h" | awk 'NR == 2 || $7 > max { max = $7; process = $NF } END { print process }' | awk '{print $1}')
        cpu_h1=$(echo "$top_output_h" | awk 'NR == 1 || $7 > max { max = $7; process = $8 } END { print process }' | awk '{print $1}')
        cpu_h2=$(echo "$top_output_h" | awk 'NR == 2 || $7 > max { max = $7; process = $8 } END { print process }' | awk '{print $1}')
        # mem_used=$(echo "$top_output" | awk '/^Mem/ { gsub(/K|used,|free,|shrd,|buff,|cached|:/, " ", $0); printf "%.0f", $2 / 1024 }')
        # mem_free=$(echo "$top_output" | awk '/^Mem/ { gsub(/K|used,|free,|shrd,|buff,|cached|:/, " ", $0); printf "%.0f", $3 / 1024 }')
        # # mem_total=$(awk "BEGIN { print $mem_used + $mem_free }") # 支持浮点计算,上面已经采用printf "%.0f"取整,所以使用下行即可
        # mem_total=$((mem_used + mem_free))
        # swap_total=""
        # swap_used=""
        # swap_use_ratio=""
    else
        echo "top 指令获取信息失败."
    fi
    mem_total_bytes=$(free | grep 'Mem:' | awk '{print int($2)}')
    mem_used_bytes=$(free | grep 'Mem:' | awk '{print int($3)}')
    mem_use_ratio=$(awk -v used="$mem_used_bytes" -v total="$mem_total_bytes" 'BEGIN { printf "%.2f", ( used / total ) * 100 }')
    swap_total_bytes=$(free | grep 'Swap:' | awk '{print int($2)}')
    swap_used_bytes=$(free | grep 'Swap:' | awk '{print int($3)}')
    if [ $swap_total_bytes -eq 0 ]; then
        swap_use_ratio=0
    else
        swap_use_ratio=$(awk -v used="$swap_used_bytes" -v total="$swap_total_bytes" 'BEGIN { printf "%.2f", ( used / total ) * 100 }')
    fi
    disk_total=$(df -h / | awk 'NR==2 {print $2}')
    disk_used=$(df -h / | awk 'NR==2 {print $3}')
    disk_use_ratio=$(df -h / | awk 'NR==2 {gsub("%", "", $5); print $5}')
    echo "内存使用率: $mem_use_ratio | 交换使用率: $swap_use_ratio | 磁盘使用率: $disk_use_ratio | 日期: $(date)"
}

# 百分比转换进度条
create_progress_bar() {
    local percentage=$1
    local start_symbol=""
    local used_symbol="▇"
    local free_symbol="▁"
    local progress_bar=""
    local used_count
    local bar_width=10  # 默认进度条宽度为10
    if [[ $percentage -ge 1 && $percentage -le 100 ]]; then
        used_count=$((percentage * bar_width / 100))
        for ((i=0; i<used_count; i++)); do
            progress_bar="${progress_bar}${used_symbol}"
        done
        for ((i=used_count; i<bar_width; i++)); do
            progress_bar="${progress_bar}${free_symbol}"
        done
        echo "${start_symbol}${progress_bar}"
    else
        echo "错误: 参数无效, 必须为 1-100 之间的值."
        return 1
    fi
}

ratioandprogress() {
    # 调用时需要定义全局变量: progress 和 ratio
    lto=false
    gtoh=false
    if [ ! -z "$3" ]; then
        ratio=$3
    elif $(awk -v used="$1" -v total="$2" 'BEGIN { printf "%d", ( used >= 0 && total >= 0 ) }'); then
        ratio=$(awk -v used="$1" -v total="$2" 'BEGIN { printf "%.3f", ( used / total ) * 100 }')
    else
        echo "错误: $1 或 $2 小于 0 ."
        progress="Err 参数有误."
        return 1
    fi
    if $(awk -v v1="$ratio" 'BEGIN { exit !(v1 > 0 && v1 < 1) }'); then
    # if $(awk -v v1="$ratio" 'BEGIN { exit !(v1 < 1) }'); then
        ratio=1
        lto=true
    elif $(awk -v v1="$ratio" 'BEGIN { exit !(v1 > 100) }'); then
        ratio=100
        gtoh=true
    fi
    ratio=$(awk -v v1="$ratio" 'BEGIN { printf "%.0f", v1 }')
    # ratio=$(awk -v v1="$ratio" 'BEGIN { if (v1 > 0 && v1 < 1) { printf "1" } else { printf "%.0f", v1 } }')
    progress=$(create_progress_bar "$ratio")
    return_code=$?
    if [ $return_code -eq 1 ]; then
        progress="🚫"
        ratio=""
    else
        if $lto; then
            ratio="🔽"
        elif $gtoh; then
            ratio="🔼"
        else
            ratio="${ratio}%"
        fi
    fi
    # echo "$progress"
    # echo "$ratio"
}

# 设置CPU报警
SetupCPU_TG() {
    if [[ -z "${TelgramBotToken}" || -z "${ChatID_1}" ]]; then
        tips="$Err 参数丢失, 请设置后再执行 (先执行 ${GR}0${NC} 选项)."
        return 1
    fi
    if [ "$autorun" == "false" ]; then
        read -e -p "请输入 CPU 报警阈值 % (回车跳过修改): " threshold
    else
        if [ ! -z "$CPUThreshold" ]; then
            threshold=$CPUThreshold
        else
            threshold=$CPUThreshold_de
        fi
    fi
    if [ -z "$threshold" ]; then
        tips="$Tip 输入为空, 跳过操作."
        return 1
    fi
    threshold="${threshold//%/}"
    if [[ ! $threshold =~ ^([1-9][0-9]?|100)$ ]]; then
        echo -e "$Err ${REB}输入无效${NC}, 报警阈值 必须是数字 (1-100) 的整数, 跳过操作."
        return 1
    fi
    writeini "CPUThreshold" "$threshold"
    CPUThreshold=$threshold
    if [ "$CPUTools" == "sar" ] || [ "$CPUTools" == "top_sar" ]; then
        if ! command -v sar &>/dev/null; then
            echo "正在安装缺失的依赖 sar, 一个检测 CPU 的专业工具."
            if [ -x "$(command -v apt)" ]; then
                apt -y install sysstat
            elif [ -x "$(command -v yum)" ]; then
                yum -y install sysstat
            else
                echo -e "$Err 未知的包管理器, 无法安装依赖. 请手动安装所需依赖后再运行脚本."
            fi
        fi
    fi
    cat <<EOF > "$FolderPath/tg_cpu.sh"
#!/bin/bash

CPUTools="$CPUTools"
CPUThreshold="$CPUThreshold"

$(declare -f CheckCPU_$CPUTools)
$(declare -f GetInfo_now)
$(declare -f create_progress_bar)
$(declare -f ratioandprogress)
progress=""
ratio=""
count=0
SleepTime=900
while true; do
    CheckCPU_\$CPUTools

    CPUThreshold_com=\$(awk 'BEGIN {printf "%.0f\n", '\$CPUThreshold' * 100}')
    cpu_usage_ratio_com=\$(awk 'BEGIN {printf "%.0f\n", '\$cpu_usage_ratio' * 100}')
    echo "Threshold: \$CPUThreshold_com   usage: \$cpu_usage_ratio_com  # 这里数值是乘100的结果"
    if (( cpu_usage_ratio_com >= \$CPUThreshold_com )); then
        (( count++ ))
    else
        count=0
    fi
    echo "count: \$count   # 当 count 为 3 时将触发警报."
    if (( count >= 3 )); then

        # 获取并计算其它参数
        GetInfo_now

        # output=\$(ratioandprogress "0" "0" "cpu_usage_ratio")
        # cpu_usage_progress=\$(echo "\$output" | awk 'NR==1 {print \$1}')
        # cpu_usage_ratio=\$(echo "\$output" | awk 'NR==2 {print \$1}')

        ratioandprogress "0" "0" "\$cpu_usage_ratio"
        cpu_usage_progress=\$progress
        cpu_usage_ratio=\$ratio

        ratioandprogress "0" "0" "\$mem_use_ratio"
        mem_use_progress=\$progress
        mem_use_ratio=\$ratio

        ratioandprogress "0" "0" "\$swap_use_ratio"
        swap_use_progress=\$progress
        swap_use_ratio=\$ratio

        ratioandprogress "0" "0" "\$disk_use_ratio"
        disk_use_progress=\$progress
        disk_use_ratio=\$ratio

        current_date_send=\$(date +"%Y.%m.%d %T")
        message="CPU 使用率超过阈值 > \$CPUThreshold%❗️"'
'"主机名: $hostname_show"'
'"CPU: \$cpu_usage_progress \$cpu_usage_ratio"'
'"内存: \$mem_use_progress \$mem_use_ratio"'
'"交换: \$swap_use_progress \$swap_use_ratio"'
'"磁盘: \$disk_use_progress \$disk_use_ratio"'
'"使用率排行:"'
'"🟠  \$cpu_h1"'
'"🟠  \$cpu_h2"'
'"检测工具: \$CPUTools 休眠: \$((SleepTime / 60))分钟"'
'"服务器时间: \$current_date_send"
        curl -s -X POST "https://api.telegram.org/bot$TelgramBotToken/sendMessage" \
            -d chat_id="$ChatID_1" -d text="\$message" > /dev/null
        echo "报警信息已发出..."
        count=0  # 发送警告后重置计数器
        sleep \$SleepTime   # 发送后等待SleepTime分钟后再检测
    fi
    sleep 5
done
EOF
    chmod +x $FolderPath/tg_cpu.sh
    pkill tg_cpu.sh > /dev/null 2>&1 &
    pkill tg_cpu.sh > /dev/null 2>&1 &
    kill $(ps | grep '[t]g_cpu.sh' | awk '{print $1}')
    nohup $FolderPath/tg_cpu.sh > $FolderPath/tg_cpu.log 2>&1 &
    if ! crontab -l | grep -q "@reboot nohup $FolderPath/tg_cpu.sh > $FolderPath/tg_cpu.log 2>&1 &"; then
        (crontab -l 2>/dev/null; echo "@reboot nohup $FolderPath/tg_cpu.sh > $FolderPath/tg_cpu.log 2>&1 &") | crontab -
    fi
    if [ "$mute" == "false" ]; then
        $FolderPath/send_tg.sh "$TelgramBotToken" "$ChatID_1" "设置成功: CPU 报警通知⚙️"'
'"主机名: $hostname_show"'
'"CPU: $cpuusedOfcpus"'
'"检测工具: $CPUTools"'
'"💡当 CPU 使用达 $CPUThreshold % 时将收到通知." &
#         $FolderPath/send_tg.sh "$TelgramBotToken" "$ChatID_1" "设置成功: CPU 报警通知⚙️"'
# '"主机名: $hostname_show"'
# '"CPU: $cpuusedOfcpus"'
# '"内存: ${mem_total}MB"'
# '"交换: ${swap_total}MB"'
# '"磁盘: ${disk_total}B     已使用: ${disk_used}B"'
# '"检测工具: $CPUTools"'
# '"💡当 CPU 使用达 $CPUThreshold % 时将收到通知." &
    fi
    tips="$Tip CPU 通知已经设置成功, 当 CPU 使用率达到 $CPUThreshold % 时将收到通知."
}

# 设置内存报警
SetupMEM_TG() {
    if [[ -z "${TelgramBotToken}" || -z "${ChatID_1}" ]]; then
        tips="$Err 参数丢失, 请设置后再执行 (先执行 ${GR}0${NC} 选项)."
        return 1
    fi
    if [ "$autorun" == "false" ]; then
        read -e -p "请输入 内存阈值 % (回车跳过修改): " threshold
    else
        if [ ! -z "$MEMThreshold" ]; then
            threshold=$MEMThreshold
        else
            threshold=$MEMThreshold_de
        fi
    fi
    if [ -z "$threshold" ]; then
        tips="$Tip 输入为空, 跳过操作."
        return 1
    fi
    threshold="${threshold//%/}"
    if [[ ! $threshold =~ ^([1-9][0-9]?|100)$ ]]; then
        echo -e "$Err ${REB}输入无效${NC}, 报警阈值 必须是数字 (1-100) 的整数, 跳过操作."
        return 1
    fi
    writeini "MEMThreshold" "$threshold"
    MEMThreshold=$threshold
    if [ "$CPUTools" == "sar" ] || [ "$CPUTools" == "top_sar" ]; then
        if ! command -v sar &>/dev/null; then
            echo "正在安装缺失的依赖 sar, 一个检测 CPU 的专业工具."
            if [ -x "$(command -v apt)" ]; then
                apt -y install sysstat
            elif [ -x "$(command -v yum)" ]; then
                yum -y install sysstat
            else
                echo -e "$Err 未知的包管理器, 无法安装依赖. 请手动安装所需依赖后再运行脚本."
            fi
        fi
    fi
    cat <<EOF > "$FolderPath/tg_mem.sh"
#!/bin/bash

CPUTools="$CPUTools"
MEMThreshold="$MEMThreshold"

$(declare -f CheckCPU_$CPUTools)
$(declare -f GetInfo_now)
$(declare -f create_progress_bar)
$(declare -f ratioandprogress)
progress=""
ratio=""
count=0
SleepTime=900
while true; do
    GetInfo_now

    MEMThreshold_com=\$(awk 'BEGIN {printf "%.0f\n", '\$MEMThreshold' * 100}')
    mem_use_ratio_com=\$(awk 'BEGIN {printf "%.0f\n", '\$mem_use_ratio' * 100}')
    echo "Threshold: \$MEMThreshold_com   usage: \$mem_use_ratio_com  # 这里数值是乘100的结果"
    if (( mem_use_ratio_com >= \$MEMThreshold_com )); then
        (( count++ ))
    else
        count=0
    fi
    echo "count: \$count   # 当 count 为 3 时将触发警报."
    if (( count >= 3 )); then

        # 获取并计算其它参数
        CheckCPU_\$CPUTools

        ratioandprogress "0" "0" "\$cpu_usage_ratio"
        cpu_usage_progress=\$progress
        cpu_usage_ratio=\$ratio

        ratioandprogress "0" "0" "\$mem_use_ratio"
        mem_use_progress=\$progress
        mem_use_ratio=\$ratio

        ratioandprogress "0" "0" "\$swap_use_ratio"
        swap_use_progress=\$progress
        swap_use_ratio=\$ratio

        ratioandprogress "0" "0" "\$disk_use_ratio"
        disk_use_progress=\$progress
        disk_use_ratio=\$ratio

        current_date_send=\$(date +"%Y.%m.%d %T")
        message="内存 使用率超过阈值 > \$MEMThreshold%❗️"'
'"主机名: $hostname_show"'
'"CPU: \$cpu_usage_progress \$cpu_usage_ratio"'
'"内存: \$mem_use_progress \$mem_use_ratio"'
'"交换: \$swap_use_progress \$swap_use_ratio"'
'"磁盘: \$disk_use_progress \$disk_use_ratio"'
'"使用率排行:"'
'"🟠  \$cpu_h1"'
'"🟠  \$cpu_h2"'
'"检测工具: \$CPUTools 休眠: \$((SleepTime / 60))分钟"'
'"服务器时间: \$current_date_send"
        curl -s -X POST "https://api.telegram.org/bot$TelgramBotToken/sendMessage" \
            -d chat_id="$ChatID_1" -d text="\$message" > /dev/null
        echo "报警信息已发出..."
        count=0  # 发送警告后重置计数器
        sleep \$SleepTime   # 发送后等待SleepTime分钟后再检测
    fi
    sleep 5
done
EOF
    chmod +x $FolderPath/tg_mem.sh
    pkill tg_mem.sh > /dev/null 2>&1 &
    pkill tg_mem.sh > /dev/null 2>&1 &
    kill $(ps | grep '[t]g_mem.sh' | awk '{print $1}')
    nohup $FolderPath/tg_mem.sh > $FolderPath/tg_mem.log 2>&1 &
    if ! crontab -l | grep -q "@reboot nohup $FolderPath/tg_mem.sh > $FolderPath/tg_mem.log 2>&1 &"; then
        (crontab -l 2>/dev/null; echo "@reboot nohup $FolderPath/tg_mem.sh > $FolderPath/tg_mem.log 2>&1 &") | crontab -
    fi
    if [ "$mute" == "false" ]; then
        $FolderPath/send_tg.sh "$TelgramBotToken" "$ChatID_1" "设置成功: 内存 报警通知⚙️"'
'"主机名: $hostname_show"'
'"内存: ${mem_total}MB"'
'"交换: ${swap_total}MB"'
'"💡当 内存 使用达 $MEMThreshold % 时将收到通知." &
    fi
    tips="$Tip 内存 通知已经设置成功, 当 内存 使用率达到 $MEMThreshold % 时将收到通知."

}

# 设置磁盘报警
SetupDISK_TG() {
    if [[ -z "${TelgramBotToken}" || -z "${ChatID_1}" ]]; then
        tips="$Err 参数丢失, 请设置后再执行 (先执行 ${GR}0${NC} 选项)."
        return 1
    fi
    if [ "$autorun" == "false" ]; then
        read -e -p "请输入 磁盘报警阈值 % (回车跳过修改): " threshold
    else
        if [ ! -z "$DISKThreshold" ]; then
            threshold=$DISKThreshold
        else
            threshold=$DISKThreshold_de
        fi
    fi
    if [ -z "$threshold" ]; then
        tips="$Tip 输入为空, 跳过操作."
        return 1
    fi
    threshold="${threshold//%/}"
    if [[ ! $threshold =~ ^([1-9][0-9]?|100)$ ]]; then
        echo -e "$Err ${REB}输入无效${NC}, 报警阈值 必须是数字 (1-100) 的整数, 跳过操作."
        return 1
    fi
    writeini "DISKThreshold" "$threshold"
    DISKThreshold=$threshold
    if [ "$CPUTools" == "sar" ] || [ "$CPUTools" == "top_sar" ]; then
        if ! command -v sar &>/dev/null; then
            echo "正在安装缺失的依赖 sar, 一个检测 CPU 的专业工具."
            if [ -x "$(command -v apt)" ]; then
                apt -y install sysstat
            elif [ -x "$(command -v yum)" ]; then
                yum -y install sysstat
            else
                echo -e "$Err 未知的包管理器, 无法安装依赖. 请手动安装所需依赖后再运行脚本."
            fi
        fi
    fi
    cat <<EOF > "$FolderPath/tg_disk.sh"
#!/bin/bash

CPUTools="$CPUTools"
DISKThreshold="$DISKThreshold"

$(declare -f CheckCPU_$CPUTools)
$(declare -f GetInfo_now)
$(declare -f create_progress_bar)
$(declare -f ratioandprogress)
progress=""
ratio=""
count=0
SleepTime=900
while true; do
    GetInfo_now

    DISKThreshold_com=\$(awk 'BEGIN {printf "%.0f\n", '\$DISKThreshold' * 100}')
    disk_use_ratio_com=\$(awk 'BEGIN {printf "%.0f\n", '\$disk_use_ratio' * 100}')
    echo "Threshold: \$DISKThreshold_com   usage: \$disk_use_ratio_com  # 这里数值是乘100的结果"
    if (( disk_use_ratio_com >= \$DISKThreshold_com )); then
        (( count++ ))
    else
        count=0
    fi
    echo "count: \$count   # 当 count 为 3 时将触发警报."
    if (( count >= 3 )); then

        # 获取并计算其它参数
        CheckCPU_\$CPUTools

        echo "前: cpu: \$cpu_usage_ratio mem: \$mem_use_ratio swap: \$swap_use_ratio disk: \$disk_use_ratio"
        ratioandprogress "0" "0" "\$cpu_usage_ratio"
        cpu_usage_progress=\$progress
        cpu_usage_ratio=\$ratio

        ratioandprogress "0" "0" "\$mem_use_ratio"
        mem_use_progress=\$progress
        mem_use_ratio=\$ratio

        ratioandprogress "0" "0" "\$swap_use_ratio"
        swap_use_progress=\$progress
        swap_use_ratio=\$ratio

        ratioandprogress "0" "0" "\$disk_use_ratio"
        disk_use_progress=\$progress
        disk_use_ratio=\$ratio
        echo "后: cpu: \$cpu_usage_ratio mem: \$mem_use_ratio swap: \$swap_use_ratio disk: \$disk_use_ratio"

        current_date_send=\$(date +"%Y.%m.%d %T")
        message="磁盘 使用率超过阈值 > \$DISKThreshold%❗️"'
'"主机名: $hostname_show"'
'"CPU: \$cpu_usage_progress \$cpu_usage_ratio"'
'"内存: \$mem_use_progress \$mem_use_ratio"'
'"交换: \$swap_use_progress \$swap_use_ratio"'
'"磁盘: \$disk_use_progress \$disk_use_ratio"'
'"使用率排行:"'
'"🟠  \$cpu_h1"'
'"🟠  \$cpu_h2"'
'"检测工具: \$CPUTools 休眠: \$((SleepTime / 60))分钟"'
'"服务器时间: \$current_date_send"
        curl -s -X POST "https://api.telegram.org/bot$TelgramBotToken/sendMessage" \
            -d chat_id="$ChatID_1" -d text="\$message" > /dev/null
        echo "报警信息已发出..."
        count=0  # 发送警告后重置计数器
        sleep \$SleepTime   # 发送后等待SleepTime分钟后再检测
    fi
    sleep 3
done
EOF
    chmod +x $FolderPath/tg_disk.sh
    pkill tg_disk.sh > /dev/null 2>&1 &
    pkill tg_disk.sh > /dev/null 2>&1 &
    kill $(ps | grep '[t]g_disk.sh' | awk '{print $1}')
    nohup $FolderPath/tg_disk.sh > $FolderPath/tg_disk.log 2>&1 &
    if ! crontab -l | grep -q "@reboot nohup $FolderPath/tg_disk.sh > $FolderPath/tg_disk.log 2>&1 &"; then
        (crontab -l 2>/dev/null; echo "@reboot nohup $FolderPath/tg_disk.sh > $FolderPath/tg_disk.log 2>&1 &") | crontab -
    fi
    if [ "$mute" == "false" ]; then
        $FolderPath/send_tg.sh "$TelgramBotToken" "$ChatID_1" "设置成功: 磁盘 报警通知⚙️"'
'"主机名: $hostname_show"'
'"磁盘: ${disk_total}B     已使用: ${disk_used}B"'
'"💡当 磁盘 使用达 $DISKThreshold % 时将收到通知." &
    fi
    tips="$Tip 磁盘 通知已经设置成功, 当 磁盘 使用率达到 $DISKThreshold % 时将收到通知."
}

# 删除变量后面的B
Remove_B() {
    local var="$1"
    echo "${var%B}"
}

Bytes_MBtoGBKB() {
    bitvalue="$1"
    if awk -v bitvalue="$bitvalue" 'BEGIN { exit !(bitvalue >= 1024) }'; then
        bitvalue=$(awk -v value="$bitvalue" 'BEGIN { printf "%.1fGB", value / 1024 }')
    elif awk -v bitvalue="$bitvalue" 'BEGIN { exit !(bitvalue < 1) }'; then
        bitvalue=$(awk -v value="$bitvalue" 'BEGIN { printf "%.0fKB", value * 1024 }')
    else
        bitvalue="${bitvalue}MB"
    fi
    echo "$bitvalue"
}

Bytes_KBtoMBGB () 
{ 
    bitvalue="$1";
    if awk -v bitvalue="$bitvalue" 'BEGIN { exit !(bitvalue >= (1024 * 1024)) }'; then
        bitvalue=$(awk -v value="$bitvalue" 'BEGIN { printf "%.1fGB", value / (1024 * 1024) }');
    else
        if awk -v bitvalue="$bitvalue" 'BEGIN { exit !(bitvalue >= 1024) }'; then
            bitvalue=$(awk -v value="$bitvalue" 'BEGIN { printf "%.1fMB", value / 1024 }');
        else
            bitvalue="${bitvalue}KB";
        fi;
    fi;
    echo "$bitvalue"
}

Bytes_BtoKBMBGB () 
{ 
    bitvalue="$1";
    if awk -v bitvalue="$bitvalue" 'BEGIN { exit !(bitvalue >= (1024 * 1024 * 1024)) }'; then
        bitvalue=$(awk -v value="$bitvalue" 'BEGIN { printf "%.1fGB", value / (1024 * 1024 * 1024) }');
    else
        if awk -v bitvalue="$bitvalue" 'BEGIN { exit !(bitvalue >= 1024 * 1024) }'; then
            bitvalue=$(awk -v value="$bitvalue" 'BEGIN { printf "%.1fMB", value / (1024 * 1024) }');
        else
            if awk -v bitvalue="$bitvalue" 'BEGIN { exit !(bitvalue >= 1024) }'; then
                bitvalue=$(awk -v value="$bitvalue" 'BEGIN { printf "%.1fKB", value / 1024 }');
            else
                bitvalue="${bitvalue}bB";
            fi;
        fi;
    fi;
    echo "$bitvalue"
}

# 设置流量报警
SetupFlow_TG() {
    if [[ -z "${TelgramBotToken}" || -z "${ChatID_1}" ]]; then
        tips="$Err 参数丢失, 请设置后再执行 (先执行 ${GR}0${NC} 选项)."
        return 1
    fi
    if [ "$autorun" == "false" ]; then
        read -e -p "请输入 流量报警阈值 数字 + MB/GB/TB (回车跳过修改): " threshold
    else
        if [ ! -z "$FlowThreshold" ]; then
            threshold=$FlowThreshold
        else
            threshold=$FlowThreshold_de
        fi
    fi
    if [ -z "$threshold" ]; then
        tips="$Tip 输入为空, 跳过操作."
        return 1
    fi
    if [[ $threshold =~ ^[0-9]+(\.[0-9])?$ ]] || [[ $threshold =~ ^[0-9]+(\.[0-9]+)?(M)$ ]] || [[ $threshold =~ ^[0-9]+(\.[0-9]+)?(MB)$ ]]; then
        threshold=${threshold%M}
        threshold=${threshold%MB}
        if awk -v value="$threshold" 'BEGIN { exit !(value >= 1024 * 1024) }'; then
            threshold=$(awk -v value="$threshold" 'BEGIN { printf "%.1f", value / (1024 * 1024) }')
            threshold="${threshold}TB"
        elif awk -v value="$threshold" 'BEGIN { exit !(value >= 1024) }'; then
            threshold=$(awk -v value="$threshold" 'BEGIN { printf "%.1f", value / 1024 }')
            threshold="${threshold}GB"
        else
            threshold="${threshold}MB"
        fi
        writeini "FlowThreshold" "$threshold"
    elif [[ $threshold =~ ^[0-9]+(\.[0-9]+)?(G)$ ]] || [[ $threshold =~ ^[0-9]+(\.[0-9]+)?(GB)$ ]]; then
        threshold=${threshold%G}
        threshold=${threshold%GB}
        if awk -v value="$threshold" 'BEGIN { exit !(value >= 1024) }'; then
            threshold=$(awk -v value="$threshold" 'BEGIN { printf "%.1f", value / 1024 }')
            threshold="${threshold}TB"
        else
            threshold="${threshold}GB"
        fi
        writeini "FlowThreshold" "$threshold"
    elif [[ $threshold =~ ^[0-9]+(\.[0-9]+)?(T)$ ]] || [[ $threshold =~ ^[0-9]+(\.[0-9]+)?(TB)$ ]]; then
        threshold=${threshold%T}
        threshold=${threshold%TB}
        threshold="${threshold}TB"
        writeini "FlowThreshold" "$threshold"
    else
        echo -e "$Err ${REB}输入无效${NC}, 报警阈值 必须是: 数字|数字MB/数字GB (%.1f) 的格式(支持1位小数), 跳过操作."
        return 1
    fi
    if [ "$autorun" == "false" ]; then
        read -e -p "请设置 流量上限 数字 + MB/GB/TB (回车默认: $FlowThresholdMAX_de): " threshold_max
    else
        if [ ! -z "$FlowThresholdMAX" ]; then
            threshold_max=$FlowThresholdMAX
        else
            threshold_max=$FlowThresholdMAX_de
        fi
    fi
    if [ ! -z "$threshold_max" ]; then
        if [[ $threshold_max =~ ^[0-9]+(\.[0-9])?$ ]] || [[ $threshold_max =~ ^[0-9]+(\.[0-9]+)?(M)$ ]] || [[ $threshold_max =~ ^[0-9]+(\.[0-9]+)?(MB)$ ]]; then
            threshold_max=${threshold_max%M}
            threshold_max=${threshold_max%MB}
            if awk -v value="$threshold_max" 'BEGIN { exit !(value >= 1024 * 1024) }'; then
                threshold_max=$(awk -v value="$threshold_max" 'BEGIN { printf "%.1f", value / (1024 * 1024) }')
                threshold_max="${threshold_max}TB"
            elif awk -v value="$threshold_max" 'BEGIN { exit !(value >= 1024) }'; then
                threshold_max=$(awk -v value="$threshold_max"_max 'BEGIN { printf "%.1f", value / 1024 }')
                threshold_max="${threshold_max}GB"
            else
                threshold_max="${threshold_max}MB"
            fi
            writeini "FlowThresholdMAX" "$threshold_max"
        elif [[ $threshold_max =~ ^[0-9]+(\.[0-9]+)?(G)$ ]] || [[ $threshold_max =~ ^[0-9]+(\.[0-9]+)?(GB)$ ]]; then
            threshold_max=${threshold_max%G}
            threshold_max=${threshold_max%GB}
            if awk -v value="$threshold_max" 'BEGIN { exit !(value >= 1024) }'; then
                threshold_max=$(awk -v value="$threshold_max"_max 'BEGIN { printf "%.1f", value / 1024 }')
                threshold_max="${threshold_max}TB"
            else
                threshold_max="${threshold_max}GB"
            fi
            writeini "FlowThresholdMAX" "$threshold_max"
        elif [[ $threshold_max =~ ^[0-9]+(\.[0-9]+)?(T)$ ]] || [[ $threshold_max =~ ^[0-9]+(\.[0-9]+)?(TB)$ ]]; then
            threshold_max=${threshold_max%T}
            threshold_max=${threshold_max%TB}
            threshold_max="${threshold_max}TB"
            writeini "FlowThresholdMAX" "$threshold_max"
        else
            echo -e "$Err ${REB}输入无效${NC}, 报警阈值 必须是: 数字|数字MB/数字GB (%.1f) 的格式(支持1位小数), 跳过操作."
            return 1
        fi
    else
        writeini "FlowThresholdMAX" "$FlowThresholdMAX_de"
        echo -e "$Tip 输入为空, 默认最大流量上限为: $FlowThresholdMAX_de"
    fi
    if [ "$autorun" == "false" ]; then
        interfaces_ST_0=$(ip -br link | awk '$2 == "UP" {print $1}' | grep -v "lo")
        output=$(ip -br link)
        IFS=$'\n'
        count=1
        for line in $output; do
            columns_1=$(echo "$line" | awk '{print $1}')
            columns_1_array+=("$columns_1")
            columns_2=$(echo "$line" | awk '{print $1"\t"$2}')
            if [[ $interfaces_ST_0 =~ $columns_1 ]]; then
                printf "${GR}%d. %s${NC}\n" "$count" "$columns_2"
            else
                printf "${GR}%d. ${NC}%s\n" "$count" "$columns_1"
            fi
            ((count++))
        done
        echo -e "请选择编号进行统计, 例如统计1项和2项可输入: ${GR}12${NC} 或 ${GR}回车自动检测${NC}活动接口:"
        read -e -p "请输入统计接口编号: " choice
        if [[ $choice == *0* ]]; then
            tips="$Err 接口编号中没有 0 选项"
            return 1
        fi
        if [ ! -z "$choice" ]; then
            choice_array=()
            interfaces_ST=()
            choice="${choice//[, ]/}"
            for (( i=0; i<${#choice}; i++ )); do
            char="${choice:$i:1}"
            if [[ "$char" =~ [0-9] ]]; then
                choice_array+=("$char")
            fi
            done
            # echo "解析后的接口编号数组: ${choice_array[@]}"
            for item in "${choice_array[@]}"; do
                index=$((item - 1))
                if [ -z "${columns_1_array[index]}" ]; then
                    tips="$Err 错误: 输入的编号 $item 无效或超出范围."
                    return 1
                else
                    interfaces_ST+=("${columns_1_array[index]}")
                fi
            done
            for ((i = 0; i < ${#interfaces_ST[@]}; i++)); do
                w_interfaces_ST+="${interfaces_ST[$i]}"
                if ((i < ${#interfaces_ST[@]} - 1)); then
                    w_interfaces_ST+=","
                fi
            done
            # echo "确认选择接口: $w_interfaces_ST"
            writeini "interfaces_ST" "$w_interfaces_ST"
        else
            # IFS=',' read -ra interfaces_ST_de <<< "$interfaces_ST_de"
            # IFS=',' read -ra interfaces <<< "$(echo "$interfaces_ST_de" | tr ',' '\n' | sort -u | tr '\n' ',')"
            # IFS=',' read -ra interfaces <<< "$(echo "$interfaces_ST_de" | awk -v RS=, '!a[$1]++ {if (NR>1) printf ",%s", $0; else printf "%s", $0}')"
            # interfaces_ST=("${interfaces_ST_de[@]}")
            interfaces_all=$(ip -br link | awk '{print $1}')
            active_interfaces=()
            echo "检查网络接口流量情况..."
            for interface in $interfaces_all
            do
            clean_interface=${interface%%@*}
            stats=$(ip -s link show $clean_interface)
            rx_packets=$(echo "$stats" | awk '/RX:/{getline; print $2}')
            tx_packets=$(echo "$stats" | awk '/TX:/{getline; print $2}')
            if [ "$rx_packets" -gt 0 ] || [ "$tx_packets" -gt 0 ]; then
                echo "接口: $clean_interface 活跃, 接收: $rx_packets 包, 发送: $tx_packets 包."
                active_interfaces+=($clean_interface)
            else
                echo "接口: $clean_interface 不活跃."
            fi
            done
            echo -e "$Tip 检测到活动的接口: ${active_interfaces[@]}"
            interfaces_ST=("${active_interfaces[@]}")
            for ((i = 0; i < ${#interfaces_ST[@]}; i++)); do
                w_interfaces_ST+="${interfaces_ST[$i]}"
                if ((i < ${#interfaces_ST[@]} - 1)); then
                    w_interfaces_ST+=","
                fi
            done
            # echo "确认选择接口: $w_interfaces_ST"
            writeini "interfaces_ST" "$w_interfaces_ST"
        fi
    else
        if [ ! -z "${interfaces_ST+x}" ]; then
            interfaces_ST=("${interfaces_ST[@]}")
        else
            interfaces_ST=("${interfaces_ST_de[@]}")
        fi
        echo "interfaces_ST: $interfaces_ST"
    fi
    if [ "$autorun" == "false" ]; then
        read -e -p "请选择统计模式: 1.接口合计发送  2.接口单独发送 (回车默认为单独发送): " mode
        if [ "$mode" == "1" ]; then
            StatisticsMode="OV"
        elif [ "$mode" == "2" ]; then
            StatisticsMode="SE"
        else
            StatisticsMode=$StatisticsMode_ST_de
        fi
        writeini "StatisticsMode" "$StatisticsMode"
    else
        if [ ! -z "$StatisticsMode" ]; then
            StatisticsMode=$StatisticsMode
        else
            StatisticsMode=$StatisticsMode_ST_de
        fi
    fi
    echo "统计模式为: $StatisticsMode"

    source $ConfigFile
    FlowThreshold_UB=$FlowThreshold
    FlowThreshold_U=$(Remove_B "$FlowThreshold")
    if [[ $FlowThreshold == *MB ]]; then
        FlowThreshold=${FlowThreshold%MB}
        FlowThreshold=$(awk -v value=$FlowThreshold 'BEGIN { printf "%.1f", value }')
    elif [[ $FlowThreshold == *GB ]]; then
        FlowThreshold=${FlowThreshold%GB}
        FlowThreshold=$(awk -v value=$FlowThreshold 'BEGIN { printf "%.1f", value * 1024 }')
    elif [[ $FlowThreshold == *TB ]]; then
        FlowThreshold=${FlowThreshold%TB}
        FlowThreshold=$(awk -v value=$FlowThreshold 'BEGIN { printf "%.1f", value * 1024 * 1024 }')
    fi
    FlowThresholdMAX_UB=$FlowThresholdMAX
    FlowThresholdMAX_U=$(Remove_B "$FlowThresholdMAX_UB")
    if [[ $FlowThresholdMAX == *MB ]]; then
        FlowThresholdMAX=${FlowThresholdMAX%MB}
        FlowThresholdMAX=$(awk -v value=$FlowThresholdMAX 'BEGIN { printf "%.1f", value }')
    elif [[ $FlowThresholdMAX == *GB ]]; then
        FlowThresholdMAX=${FlowThresholdMAX%GB}
        FlowThresholdMAX=$(awk -v value=$FlowThresholdMAX 'BEGIN { printf "%.1f", value * 1024 }')
    elif [[ $FlowThresholdMAX == *TB ]]; then
        FlowThresholdMAX=${FlowThresholdMAX%TB}
        FlowThresholdMAX=$(awk -v value=$FlowThresholdMAX 'BEGIN { printf "%.1f", value * 1024 * 1024 }')
    fi
    cat <<EOF > $FolderPath/tg_flow.sh
#!/bin/bash

$(declare -f create_progress_bar)
$(declare -f ratioandprogress)
progress=""
ratio=""
$(declare -f Bytes_BtoKBMBGB)
$(declare -f Remove_B)

tt=10
duration=0
StatisticsMode="$StatisticsMode"

THRESHOLD_BYTES=$(awk "BEGIN {print $FlowThreshold * 1024 * 1024}")
THRESHOLD_BYTES_MAX=$(awk "BEGIN {print $FlowThresholdMAX * 1024 * 1024}")

# interfaces_up=\$(ip -br link | awk '\$2 == "UP" {print \$1}' | grep -v "lo")
# interfaces_get=\$(ip -br link | awk '{print \$1}')
# declare -a interfaces=(\$interfaces_get)
# IFS=',' read -ra interfaces <<< "$interfaces_ST"
# 去重并且分割字符串为数组
# IFS=',' read -ra interfaces <<< "$(echo "$interfaces_ST" | tr ',' '\n' | sort -u | tr '\n' ',')"
# 去重并且保持原有顺序，分割字符串为数组
IFS=',' read -ra interfaces <<< "$(echo "$interfaces_ST" | awk -v RS=, '!a[$1]++ {if (NR>1) printf ",%s", $0; else printf "%s", $0}')"


echo "统计接口: \${interfaces[@]}"
for ((i = 0; i < \${#interfaces[@]}; i++)); do
    echo "\$((i+1)): \${interfaces[i]}"
done
for ((i = 0; i < \${#interfaces[@]}; i++)); do
    show_interfaces+="\${interfaces[\$i]}"
    if ((i < \${#interfaces[@]} - 1)); then
        show_interfaces+=","
    fi
done
# 如果接口名称中包含 '@' 或 ':'，则仅保留 '@' 或 ':' 之前的部分
for ((i=0; i<\${#interfaces[@]}; i++)); do
    interface=\${interfaces[\$i]%@*}
    interface=\${interface%:*}
    interfaces[\$i]=\$interface
done
echo "纺计接口(处理后): \${interfaces[@]}"

interfaces_up=\$(ip -br link | awk '\$2 == "UP" {print \$1}' | grep -v "lo")
# 如果接口名称中包含 '@' 或 ':'，则仅保留 '@' 或 ':' 之前的部分
for ((i=0; i<\${#interfaces_up[@]}; i++)); do
    interface=\${interfaces_up[\$i]%@*}
    interface=\${interface%:*}
    interfaces_up[\$i]=\$interface
done
echo "纺计网速接口(处理后): \${interfaces_up[@]}"

# 定义数组
declare -A prev_rx_bytes
declare -A prev_tx_bytes
declare -A prev_rx_bytes_T
declare -A prev_tx_bytes_T
declare -A tt_prev_rx_bytes_T
declare -A tt_prev_tx_bytes_T
declare -A current_rx_bytes
declare -A current_tx_bytes
declare -A INTERFACE_RT_RX_b
declare -A INTERFACE_RT_TX_b
declare -A INTERFACE_RT_RX_MB
declare -A INTERFACE_RT_TX_MB

# 初始化接口流量数据
source $ConfigFile
for interface in "\${interfaces[@]}"; do
    INTERFACE_RT_RX_b[\$interface]=\${INTERFACE_RT_RX_b[\$interface]}
    echo "读取: INTERFACE_RT_RX_b[\$interface]: \${INTERFACE_RT_RX_b[\$interface]}"
    INTERFACE_RT_TX_b[\$interface]=\${INTERFACE_RT_TX_b[\$interface]}
    echo "读取: INTERFACE_RT_TX_b[\$interface]: \${INTERFACE_RT_TX_b[\$interface]}"
done
# for interface in "\${interfaces[@]}"; do
#     INTERFACE_RT_RX_MB[\$interface]=\${INTERFACE_RT_RX_MB[\$interface]}
#     echo "读取: INTERFACE_RT_RX_MB[\$interface]: \${INTERFACE_RT_RX_MB[\$interface]}"
#     INTERFACE_RT_TX_MB[\$interface]=\${INTERFACE_RT_TX_MB[\$interface]}
#     echo "读取: INTERFACE_RT_TX_MB[\$interface]: \${INTERFACE_RT_TX_MB[\$interface]}"
# done

# 循环检查
sendtag=true
tt_prev=false
while true; do

    # 获取tt秒前数据

    ov_prev_rx_bytes=0
    ov_prev_tx_bytes=0
    for interface in "\${interfaces[@]}"; do
        prev_rx_bytes[\$interface]=\$(ip -s link show \$interface | awk '/RX:/ { getline; print \$1 }')
        prev_tx_bytes[\$interface]=\$(ip -s link show \$interface | awk '/TX:/ { getline; print \$1 }')
        ov_prev_rx_bytes=\$((ov_prev_rx_bytes + prev_rx_bytes[\$interface]))
        ov_prev_tx_bytes=\$((ov_prev_tx_bytes + prev_tx_bytes[\$interface]))
    done
    if \$sendtag; then
        echo "发送 \$interface 前只执行一次."

        if ! \$tt_prev; then
            for interface in "\${interfaces[@]}"; do
                prev_rx_bytes_T[\$interface]=\${prev_rx_bytes[\$interface]}
                prev_tx_bytes_T[\$interface]=\${prev_tx_bytes[\$interface]}
            done
            ov_prev_rx_bytes_T=\$ov_prev_rx_bytes
            ov_prev_tx_bytes_T=\$ov_prev_tx_bytes
        else
            for interface in "\${interfaces[@]}"; do
                prev_rx_bytes_T[\$interface]=\${tt_prev_rx_bytes_T[\$interface]}
                prev_tx_bytes_T[\$interface]=\${tt_prev_tx_bytes_T[\$interface]}
            done
            ov_prev_rx_bytes_T=\$tt_ov_prev_rx_bytes_T
            ov_prev_tx_bytes_T=\$tt_ov_prev_tx_bytes_T
        fi

    fi
    sendtag=false

    echo "\${prev_rx_bytes_T[\$interface]} \${prev_tx_bytes_T[\$interface]} \$ov_prev_rx_bytes_T \$ov_prev_tx_bytes_T"

    sp_ov_prev_rx_bytes=0
    sp_ov_prev_tx_bytes=0
    for interface in "\${interfaces_up[@]}"; do
        prev_rx_bytes[\$interface]=\$(ip -s link show \$interface | awk '/RX:/ { getline; print \$1 }')
        prev_tx_bytes[\$interface]=\$(ip -s link show \$interface | awk '/TX:/ { getline; print \$1 }')
        sp_ov_prev_rx_bytes=\$((sp_ov_prev_rx_bytes + prev_rx_bytes[\$interface]))
        sp_ov_prev_tx_bytes=\$((sp_ov_prev_tx_bytes + prev_tx_bytes[\$interface]))
    done

    # 等待tt秒
    end_time=\$(date +%s%N)
    if [ ! -z "\$start_time" ]; then
        time_diff=\$((end_time - start_time))
        time_diff_ms=\$((time_diff / 1000000))

        # 输出执行FOR所花费时间
        echo "上一个 FOR循环 所执行时间 \$time_diff_ms 毫秒."

        duration=\$(awk "BEGIN {print \$time_diff_ms/1000}")
        sleep_time=\$(awk -v v1=\$tt -v v2=\$duration 'BEGIN { printf "%.3f", v1 - v2 }')
    else
        sleep_time=\$tt
    fi
    sleep_time=\$(awk "BEGIN {print (\$sleep_time < 0 ? 0 : \$sleep_time)}")
    echo "sleep_time: \$sleep_time   duration: \$duration"
    sleep \$sleep_time
    start_time=\$(date +%s%N)

    # 获取tt秒后数据
    ov_current_rx_bytes=0
    ov_current_tx_bytes=0
    for interface in "\${interfaces[@]}"; do
        current_rx_bytes[\$interface]=\$(ip -s link show \$interface | awk '/RX:/ { getline; print \$1 }')
        current_tx_bytes[\$interface]=\$(ip -s link show \$interface | awk '/TX:/ { getline; print \$1 }')
        ov_current_rx_bytes=\$((ov_current_rx_bytes + current_rx_bytes[\$interface]))
        ov_current_tx_bytes=\$((ov_current_tx_bytes + current_tx_bytes[\$interface]))
    done
    sp_ov_current_rx_bytes=0
    sp_ov_current_tx_bytes=0
    for interface in "\${interfaces_up[@]}"; do
        sp_current_rx_bytes[\$interface]=\$(ip -s link show \$interface | awk '/RX:/ { getline; print \$1 }')
        sp_current_tx_bytes[\$interface]=\$(ip -s link show \$interface | awk '/TX:/ { getline; print \$1 }')
        sp_ov_current_rx_bytes=\$((sp_ov_current_rx_bytes + sp_current_rx_bytes[\$interface]))
        sp_ov_current_tx_bytes=\$((sp_ov_current_tx_bytes + sp_current_tx_bytes[\$interface]))
    done

    for interface in "\${interfaces[@]}"; do
        tt_prev_rx_bytes_T[\$interface]=\${current_rx_bytes[\$interface]}
        tt_prev_tx_bytes_T[\$interface]=\${current_tx_bytes[\$interface]}
    done
    tt_ov_prev_rx_bytes_T=\$ov_current_rx_bytes
    tt_ov_prev_tx_bytes_T=\$ov_current_tx_bytes
    tt_prev=true

    nline=1
    for interface in "\${interfaces[@]}"; do
        echo "NO.\$nline ----------------------------------------- interface: \$interface"

        # 计算差值
        rx_diff_bytes=\$((current_rx_bytes[\$interface] - prev_rx_bytes_T[\$interface]))
        tx_diff_bytes=\$((current_tx_bytes[\$interface] - prev_tx_bytes_T[\$interface]))
        ov_rx_diff_bytes=\$((ov_current_rx_bytes - ov_prev_rx_bytes_T))
        ov_tx_diff_bytes=\$((ov_current_tx_bytes - ov_prev_tx_bytes_T))

        # 计算网速
        ov_rx_diff_speed=\$((sp_ov_current_rx_bytes - sp_ov_prev_rx_bytes))
        ov_tx_diff_speed=\$((sp_ov_current_tx_bytes - sp_ov_prev_tx_bytes))
        rx_speed=\$(awk "BEGIN { speed = \$ov_rx_diff_speed / (\$tt * 1024); if (speed >= 1024) { printf \"%.1fMB\", speed/1024 } else { printf \"%.1fKB\", speed } }")
        tx_speed=\$(awk "BEGIN { speed = \$ov_tx_diff_speed / (\$tt * 1024); if (speed >= 1024) { printf \"%.1fMB\", speed/1024 } else { printf \"%.1fKB\", speed } }")
        rx_speed=\$(Remove_B "\$rx_speed")
        tx_speed=\$(Remove_B "\$tx_speed")

        # 总流量百分比计算
        all_rx_bytes=\$ov_current_rx_bytes
        all_rx_bytes=\$((all_rx_bytes + INTERFACE_RT_RX_b[\$interface]))
        all_rx_ratio=\$(awk -v used="\$all_rx_bytes" -v total="\$THRESHOLD_BYTES_MAX" 'BEGIN { printf "%.3f", ( used / total ) * 100 }')

        ratioandprogress "0" "0" "\$all_rx_ratio"
        all_rx_progress=\$progress
        all_rx_ratio=\$ratio

        all_rx=\$(Bytes_BtoKBMBGB "\$all_rx_bytes")
        all_rx=\$(Remove_B "\$all_rx")

        all_tx_bytes=\$ov_current_tx_bytes
        all_tx_bytes=\$((all_tx_bytes + INTERFACE_RT_TX_b[\$interface]))
        all_tx_ratio=\$(awk -v used="\$all_tx_bytes" -v total="\$THRESHOLD_BYTES_MAX" 'BEGIN { printf "%.3f", ( used / total ) * 100 }')

        ratioandprogress "0" "0" "\$all_tx_ratio"
        all_tx_progress=\$progress
        all_tx_ratio=\$ratio

        all_tx=\$(Bytes_BtoKBMBGB "\$all_tx_bytes")
        all_tx=\$(Remove_B "\$all_tx")

        # 调试使用(tt秒的流量增量)
        echo "RX_diff(BYTES): \$rx_diff TX_diff(BYTES): \$tx_diff"
        # 调试使用(叠加流量增量)
        echo "OV_RX_diff(BYTES): \$ov_rx_diff_bytes OV_TX_diff(BYTES): \$ov_tx_diff_bytes "
        # 调试使用(TT前记录的流量)
        echo "Prev_rx_bytes_T(BYTES): \${prev_rx_bytes_T[\$interface]} Prev_tx_bytes_T(BYTES): \${prev_tx_bytes_T[\$interface]}"
        # # 调试使用(持续的流量增加)
        # echo "Current_RX(BYTES): \${current_rx_bytes[\$interface]} Current_TX(BYTES): \${current_tx_bytes[\$interface]}"
        # 调试使用(叠加持续的流量增加)
        echo "OV_Current_RX(BYTES): \$ov_current_rx_bytes OV_Current_TX(BYTES): \$ov_current_tx_bytes"
        # 调试使用(网速)
        echo "rx_speed: \$rx_speed  tx_speed: \$tx_speed"

        # 检查是否超过阈值
        if [ "\$StatisticsMode" == "SE" ]; then

            # threshold_reached=\$(awk -v rx_diff="\$rx_diff" -v tx_diff="\$tx_diff" -v threshold="\$THRESHOLD_BYTES" 'BEGIN {print (rx_diff >= threshold) || (tx_diff >= threshold) ? 1 : 0}')
            # if [ "\$threshold_reached" -eq 1 ]; then

            if [ \$rx_diff_bytes -ge \$THRESHOLD_BYTES ] || [ \$tx_diff_bytes -ge \$THRESHOLD_BYTES ]; then

                rx_diff=\$(Bytes_BtoKBMBGB "\$rx_diff_bytes")
                tx_diff=\$(Bytes_BtoKBMBGB "\$tx_diff_bytes")
                rx_diff=\$(Remove_B "\$rx_diff")
                tx_diff=\$(Remove_B "\$tx_diff")

                current_date_send=\$(date +"%Y.%m.%d %T")

                message="流量已达到阈值🧭 > ${FlowThreshold_U}❗️"'
'"主机名: $hostname_show 接口: \$interface"'
'"已接收: \${rx_diff}  已发送: \${tx_diff}"'
'"───────────────"'
'"总接收: \${all_rx}  总发送: \${all_tx}"'
'"设置流量上限: ${FlowThresholdMAX_U}🔒"'
'"使用⬇️: \$all_rx_progress \$all_rx_ratio"'
'"使用⬆️: \$all_tx_progress \$all_tx_ratio"'
'"网络⬇️: \${rx_speed}/s  网络⬆️: \${tx_speed}/s"'
'"服务器时间: \$current_date_send"
                curl -s -X POST "https://api.telegram.org/bot$TelgramBotToken/sendMessage" \
                    -d chat_id="$ChatID_1" -d text="\$message"
                echo "报警信息已发出..."

                # 更新前一个状态的流量数据
                sendtag=true
            fi
        fi
        nline=\$((nline + 1))
    done
    if [ "\$StatisticsMode" == "OV" ]; then

        if [ \$ov_rx_diff_bytes -ge \$THRESHOLD_BYTES ] || [ \$ov_tx_diff_bytes -ge \$THRESHOLD_BYTES ]; then

            ov_rx_diff=\$(Bytes_BtoKBMBGB "\$ov_rx_diff_bytes")
            ov_tx_diff=\$(Bytes_BtoKBMBGB "\$ov_tx_diff_bytes")
            ov_rx_diff=\$(Remove_B "\$ov_rx_diff")
            ov_tx_diff=\$(Remove_B "\$ov_tx_diff")

            current_date_send=\$(date +"%Y.%m.%d %T")

            message="流量已达到阈值🧭 > ${FlowThreshold_U}❗️"'
'"主机名: $hostname_show 接口: \$show_interfaces"'
'"已接收: \${ov_rx_diff}  已发送: \${ov_tx_diff}"'
'"───────────────"'
'"总接收: \${all_rx}  总发送: \${all_tx}"'
'"设置流量上限: ${FlowThresholdMAX_U}🔒"'
'"使用⬇️: \$all_rx_progress \$all_rx_ratio"'
'"使用⬆️: \$all_tx_progress \$all_tx_ratio"'
'"网络⬇️: \${rx_speed}/s  网络⬆️: \${tx_speed}/s"'
'"服务器时间: \$current_date_send"
            curl -s -X POST "https://api.telegram.org/bot$TelgramBotToken/sendMessage" \
                -d chat_id="$ChatID_1" -d text="\$message"
            echo "报警信息已发出..."

            # 更新前一个状态的流量数据
            sendtag=true
        fi
    fi
    if [ "\$StatisticsMode" != "SE" ] && [ "\$StatisticsMode" != "OV" ]; then
        echo "StatisticsMode Err!!! \$StatisticsMode"
    fi
done
EOF
    chmod +x $FolderPath/tg_flow.sh
    pkill tg_flow.sh > /dev/null 2>&1 &
    pkill tg_flow.sh > /dev/null 2>&1 &
    kill $(ps | grep '[t]g_flow.sh' | awk '{print $1}')
    nohup $FolderPath/tg_flow.sh > $FolderPath/tg_flow.log 2>&1 &
    if ! crontab -l | grep -q "@reboot nohup $FolderPath/tg_flow.sh > $FolderPath/tg_flow.log 2>&1 &"; then
        (crontab -l 2>/dev/null; echo "@reboot nohup $FolderPath/tg_flow.sh > $FolderPath/tg_flow.log 2>&1 &") | crontab -
    fi
    cat <<EOF > $FolderPath/tg_interface_re.sh
#!/bin/bash

$(declare -f Remove_B)

if [ ! -d "$FolderPath" ]; then
    mkdir -p "$FolderPath"
fi
FolderPath="$FolderPath"

# 统计接口网速（只统所有接口）
# interfaces=(\$(ip -br link | awk '{print \$1}'))

# 统计接口网速（只统计 UP 接口）
interfaces_up=\$(ip -br link | awk '\$2 == "UP" {print \$1}' | grep -v "lo")
# interfaces=(\$(ip -br link | awk '{print \$1}'))
for ((i=0; i<\${#interfaces_up[@]}; i++)); do
    interface=\${interfaces_up[\$i]%@*}
    interface=\${interface%:*}
    interfaces_up[\$i]=\$interface
done

TT=5
duration=0
CLEAR_TAG=99
CLEAR_TAG_OLD=\$CLEAR_TAG

# 定义数组
declare -A sp_prev_rx_bytes
declare -A sp_prev_tx_bytes
declare -A sp_current_rx_bytes
declare -A sp_current_tx_bytes

clear
while true; do

    # 获取tt秒前数据
    sp_ov_prev_rx_bytes=0
    sp_ov_prev_tx_bytes=0
    for interface in "\${interfaces_up[@]}"; do
        sp_prev_rx_bytes[\$interface]=\$(ip -s link show \$interface | awk '/RX:/ { getline; print \$1 }')
        sp_prev_tx_bytes[\$interface]=\$(ip -s link show \$interface | awk '/TX:/ { getline; print \$1 }')
        sp_ov_prev_rx_bytes=\$((sp_ov_prev_rx_bytes + sp_prev_rx_bytes[\$interface]))
        sp_ov_prev_tx_bytes=\$((sp_ov_prev_tx_bytes + sp_prev_tx_bytes[\$interface]))
    done

    # 等待TT秒
    end_time=\$(date +%s%N)
    if [ ! -z "\$start_time" ]; then
        time_diff=\$((end_time - start_time))
        time_diff_ms=\$((time_diff / 1000000))

        # 输出执行FOR所花费时间
        # echo "上一个 FOR循环 所执行时间 \$time_diff_ms 毫秒."

        duration=\$(awk "BEGIN {print \$time_diff_ms/1000}")
        sleep_time=\$(awk -v v1=\$TT -v v2=\$duration 'BEGIN { printf "%.3f", v1 - v2 }')
    else
        sleep_time=\$TT
    fi
    sleep_time=\$(awk "BEGIN {print (\$sleep_time < 0 ? 0 : \$sleep_time)}")
    echo "休眠时间 (等..): \$sleep_time 秒  时间差: \$duration 秒  清屏: \$CLEAR_TAG"
    sleep \$sleep_time
    start_time=\$(date +%s%N)

    # 获取TT秒后数据
    sp_ov_current_rx_bytes=0
    sp_ov_current_tx_bytes=0
    for interface in "\${interfaces_up[@]}"; do
        sp_current_rx_bytes[\$interface]=\$(ip -s link show \$interface | awk '/RX:/ { getline; print \$1 }')
        sp_current_tx_bytes[\$interface]=\$(ip -s link show \$interface | awk '/TX:/ { getline; print \$1 }')
        sp_ov_current_rx_bytes=\$((sp_ov_current_rx_bytes + sp_current_rx_bytes[\$interface]))
        sp_ov_current_tx_bytes=\$((sp_ov_current_tx_bytes + sp_current_tx_bytes[\$interface]))
    done

    # 计算网速
    sp_ov_rx_diff_speed=\$((sp_ov_current_rx_bytes - sp_ov_prev_rx_bytes))
    sp_ov_tx_diff_speed=\$((sp_ov_current_tx_bytes - sp_ov_prev_tx_bytes))
    rx_speed=\$(awk "BEGIN { speed = \$sp_ov_rx_diff_speed / (\$TT * 1024); if (speed >= 1024) { printf \"%.1fMB\", speed/1024 } else { printf \"%.1fKB\", speed } }")
    tx_speed=\$(awk "BEGIN { speed = \$sp_ov_tx_diff_speed / (\$TT * 1024); if (speed >= 1024) { printf \"%.1fMB\", speed/1024 } else { printf \"%.1fKB\", speed } }")
    rx_speed=\$(Remove_B "\$rx_speed")
    tx_speed=\$(Remove_B "\$tx_speed")

    echo "==================================================="
    echo -e "SPEED_RX: \033[32m\$rx_speed\033[0m   SPEED_TX: \033[32m\$tx_speed\033[0m"
    echo "-----------------------------------"

    if [ \$CLEAR_TAG -eq 1 ]; then
        echo -e "DATE: \$(date +"%Y-%m-%d %H:%M:%S")" > \$FolderPath/interface_re.txt
        CLEAR_TAG=\$((CLEAR_TAG_OLD + 1))
        clear
    else
        echo -e "DATE: \$(date +"%Y-%m-%d %H:%M:%S")" >> \$FolderPath/interface_re.txt
    fi
    echo "SPEED_RX: \$rx_speed  SPEED_TX: \$tx_speed" >> \$FolderPath/interface_re.txt
    echo "===================================================" >> \$FolderPath/interface_re.txt

    CLEAR_TAG=\$((\$CLEAR_TAG - 1))
done
EOF
    # # 此为单独计算网速的子脚本（暂未启用）
    # chmod +x $FolderPath/tg_interface_re.sh
    # pkill -f tg_interface_re.sh > /dev/null 2>&1 &
    # pkill -f tg_interface_re.sh > /dev/null 2>&1 &
    # kill $(ps | grep '[t]g_interface_re.sh' | awk '{print $1}')
    # nohup $FolderPath/tg_interface_re.sh > $FolderPath/tg_interface_re.log 2>&1 &
    ##############################################################################
#     cat <<EOF > /etc/systemd/system/tg_interface_re.service
# [Unit]
# Description=tg_interface_re
# DefaultDependencies=no
# Before=shutdown.target

# [Service]
# Type=oneshot
# ExecStart=$FolderPath/tg_interface_re.sh
# TimeoutStartSec=0

# [Install]
# WantedBy=shutdown.target
# EOF
#     systemctl enable tg_interface_re.service > /dev/null
    if [ "$mute" == "false" ]; then
        $FolderPath/send_tg.sh "$TelgramBotToken" "$ChatID_1" "设置成功: 流量 报警通知⚙️"$'\n'"主机名: $hostname_show"$'\n'"检测接口: $interfaces_ST"$'\n'"💡当流量达阈值 $FlowThreshold_UB 时将收到通知." &
    fi
    tips="$Tip 流量 通知已经设置成功, 当流量使用达到 $FlowThreshold_UB 时将收到通知."
}

SetFlowReport_TG() {
    if [[ -z "${TelgramBotToken}" || -z "${ChatID_1}" ]]; then
        tips="$Err 参数丢失, 请设置后再执行 (先执行 ${GR}0${NC} 选项)."
        return 1
    fi
    if [ "$autorun" == "false" ]; then
        echo -e "$Tip 输入流量报告时间, 格式如: 22:34 (即每天 ${GR}22${NC} 时 ${GR}34${NC} 分)"
        read -e -p "请输入定时模式  (回车默认: $ReportTime_de ): " input_time
    else
        if [ -z "$ReportTime" ]; then
            input_time=""
        else
            input_time=$ReportTime
        fi
    fi
    if [ -z "$input_time" ]; then
        input_time="$ReportTime_de"
    fi
    if [ $(validate_time_format "$input_time") = "invalid" ]; then
        tips="$Err 输入格式不正确，请确保输入的时间格式为 'HH:MM'"
        return 1
    fi
    writeini "ReportTime" "$input_time"
    hour_rp=${input_time%%:*}
    minute_rp=${input_time#*:}
    if [ ${#hour_rp} -eq 1 ]; then
    hour_rp="0${hour_rp}"
    fi
    if [ ${#minute_rp} -eq 1 ]; then
        minute_rp="0${minute_rp}"
    fi
    echo -e "$Tip 流量报告时间: $hour_rp 时 $minute_rp 分."
    cronrp="$minute_rp $hour_rp * * *"

    if [ "$autorun" == "false" ]; then
        interfaces_RP_0=$(ip -br link | awk '$2 == "UP" {print $1}' | grep -v "lo")
        output=$(ip -br link)
        IFS=$'\n'
        count=1
        for line in $output; do
            columns_1=$(echo "$line" | awk '{print $1}')
            columns_1_array+=("$columns_1")
            columns_2=$(echo "$line" | awk '{print $1"\t"$2}')
            if [[ $interfaces_RP_0 =~ $columns_1 ]]; then
                printf "${GR}%d. %s${NC}\n" "$count" "$columns_2"
            else
                printf "${GR}%d. ${NC}%s\n" "$count" "$columns_1"
            fi
            ((count++))
        done
        echo -e "请选择编号进行报告, 例如报告1项和2项可输入: ${GR}12${NC} 或 ${GR}回车自动检测${NC}活动接口:"
        read -e -p "请输入统计接口编号: " choice
        if [[ $choice == *0* ]]; then
            tips="$Err 接口编号中没有 0 选项"
            return 1
        fi
        if [ ! -z "$choice" ]; then
            choice_array=()
            interfaces_RP=()
            choice="${choice//[, ]/}"
            for (( i=0; i<${#choice}; i++ )); do
            char="${choice:$i:1}"
            if [[ "$char" =~ [0-9] ]]; then
                choice_array+=("$char")
            fi
            done
            # echo "解析后的接口编号数组: ${choice_array[@]}"
            for item in "${choice_array[@]}"; do
                index=$((item - 1))
                if [ -z "${columns_1_array[index]}" ]; then
                    tips="$Err 错误: 输入的编号 $item 无效或超出范围."
                    return 1
                else
                    interfaces_RP+=("${columns_1_array[index]}")
                fi
            done
            for ((i = 0; i < ${#interfaces_RP[@]}; i++)); do
                w_interfaces_RP+="${interfaces_RP[$i]}"
                if ((i < ${#interfaces_RP[@]} - 1)); then
                    w_interfaces_RP+=","
                fi
            done
            # echo "确认选择接口: $w_interfaces_RP"
            writeini "interfaces_RP" "$w_interfaces_RP"
        else
            # IFS=',' read -ra interfaces_RP_de <<< "$interfaces_RP_de"
            # IFS=',' read -ra interfaces <<< "$(echo "$interfaces_RP_de" | tr ',' '\n' | sort -u | tr '\n' ',')"
            # IFS=',' read -ra interfaces <<< "$(echo "$interfaces_RP_de" | awk -v RS=, '!a[$1]++ {if (NR>1) printf ",%s", $0; else printf "%s", $0}')"
            # interfaces_RP=("${interfaces_RP_de[@]}")
            interfaces_all=$(ip -br link | awk '{print $1}')
            active_interfaces=()
            echo "检查网络接口流量情况..."
            for interface in $interfaces_all
            do
            clean_interface=${interface%%@*}
            stats=$(ip -s link show $clean_interface)
            rx_packets=$(echo "$stats" | awk '/RX:/{getline; print $2}')
            tx_packets=$(echo "$stats" | awk '/TX:/{getline; print $2}')
            if [ "$rx_packets" -gt 0 ] || [ "$tx_packets" -gt 0 ]; then
                echo "接口: $clean_interface 活跃, 接收: $rx_packets 包, 发送: $tx_packets 包."
                active_interfaces+=($clean_interface)
            else
                echo "接口: $clean_interface 不活跃."
            fi
            done
            echo -e "$Tip 检测到活动的接口: ${active_interfaces[@]}"
            interfaces_RP=("${active_interfaces[@]}")
            for ((i = 0; i < ${#interfaces_RP[@]}; i++)); do
                w_interfaces_RP+="${interfaces_RP[$i]}"
                if ((i < ${#interfaces_RP[@]} - 1)); then
                    w_interfaces_RP+=","
                fi
            done
            # echo "确认选择接口: $w_interfaces_RP"
            writeini "interfaces_RP" "$w_interfaces_RP"
        fi
    else
        if [ ! -z "${interfaces_RP+x}" ]; then
            interfaces_RP=("${interfaces_RP[@]}")
        else
            interfaces_RP=("${interfaces_RP_de[@]}")
        fi
        echo "interfaces_RP: $interfaces_RP"
    fi
    for ((i = 0; i < ${#interfaces[@]}; i++)); do
        show_interfaces_RP+="${interfaces_RP[$i]}"
        if ((i < ${#interfaces_RP[@]} - 1)); then
            show_interfaces_RP+=","
        fi
    done
    if [ "$autorun" == "false" ]; then
        read -e -p "请选择统计模式: 1.接口合计发送  2.接口单独发送 (回车默认为单独发送): " mode
        if [ "$mode" == "1" ]; then
            StatisticsMode="OV"
        elif [ "$mode" == "2" ]; then
            StatisticsMode="SE"
        else
            StatisticsMode=$StatisticsMode_RP_de
        fi
        writeini "StatisticsMode" "$StatisticsMode"
    else
        if [ ! -z "$StatisticsMode" ]; then
            StatisticsMode=$StatisticsMode
        else
            StatisticsMode=$StatisticsMode_RP_de
        fi
    fi
    echo "统计模式为: $StatisticsMode"

    source $ConfigFile
    FlowThresholdMAX_UB=$FlowThresholdMAX
    FlowThresholdMAX_U=$(Remove_B "$FlowThresholdMAX_UB")
    if [[ $FlowThresholdMAX == *MB ]]; then
        FlowThresholdMAX=${FlowThresholdMAX%MB}
        FlowThresholdMAX=$(awk -v value=$FlowThresholdMAX 'BEGIN { printf "%.1f", value }')
    elif [[ $FlowThresholdMAX == *GB ]]; then
        FlowThresholdMAX=${FlowThresholdMAX%GB}
        FlowThresholdMAX=$(awk -v value=$FlowThresholdMAX 'BEGIN { printf "%.1f", value * 1024 }')
    elif [[ $FlowThresholdMAX == *TB ]]; then
        FlowThresholdMAX=${FlowThresholdMAX%TB}
        FlowThresholdMAX=$(awk -v value=$FlowThresholdMAX 'BEGIN { printf "%.1f", value * 1024 * 1024 }')
    fi
    cat <<EOF > "$FolderPath/tg_flowrp.sh"
#!/bin/bash

$(declare -f create_progress_bar)
$(declare -f ratioandprogress)
progress=""
ratio=""
$(declare -f Bytes_BtoKBMBGB)
$(declare -f Remove_B)
StatisticsMode="$StatisticsMode"

THRESHOLD_BYTES_MAX=$(awk "BEGIN {print $FlowThresholdMAX * 1024 * 1024}")

interfaces=()
# interfaces=\$(ip -br link | awk '\$2 == "UP" {print \$1}' | grep -v "lo")
# interfaces=\$(ip -br link | awk '{print \$1}')
# IFS=',' read -ra interfaces <<< "$interfaces_RP"
# 去重并且分割字符串为数组
# IFS=',' read -ra interfaces <<< "$(echo "$interfaces_RP" | tr ',' '\n' | sort -u | tr '\n' ',')"
# 去重并且保持原有顺序，分割字符串为数组
IFS=',' read -ra interfaces <<< "$(echo "$interfaces_RP" | awk -v RS=, '!a[$1]++ {if (NR>1) printf ",%s", $0; else printf "%s", $0}')"

echo "统计接口: \${interfaces[@]}"
for ((i = 0; i < \${#interfaces[@]}; i++)); do
    echo "\$((i+1)): \${interfaces[i]}"
done
for ((i = 0; i < \${#interfaces[@]}; i++)); do
    show_interfaces+="\${interfaces[\$i]}"
    if ((i < \${#interfaces[@]} - 1)); then
        show_interfaces+=","
    fi
done

# 如果接口名称中包含 '@' 或 ':'，则仅保留 '@' 或 ':' 之前的部分
for ((i=0; i<\${#interfaces[@]}; i++)); do
    interface=\${interfaces[\$i]%@*}
    interface=\${interface%:*}
    interfaces[\$i]=\$interface
done
echo "纺计接口(处理后): \${interfaces[@]}"

# 定义数组
declare -A prev_rx_bytes
declare -A prev_tx_bytes
declare -A tt_prev_rx_bytes_T
declare -A tt_prev_tx_bytes_T
declare -A prev_day_rx_bytes
declare -A prev_day_tx_bytes
declare -A prev_month_rx_bytes
declare -A prev_month_tx_bytes
declare -A prev_year_rx_bytes
declare -A prev_year_tx_bytes
declare -A current_rx_bytes
declare -A current_tx_bytes
declare -A INTERFACE_RT_RX_MB
declare -A INTERFACE_RT_TX_MB

source $ConfigFile
for interface in "\${interfaces[@]}"; do
    INTERFACE_RT_RX_MB[\$interface]=\${INTERFACE_RT_RX_MB[\$interface]}
    echo "读取: INTERFACE_RT_RX_MB[\$interface]: \${INTERFACE_RT_RX_MB[\$interface]}"
    INTERFACE_RT_TX_MB[\$interface]=\${INTERFACE_RT_TX_MB[\$interface]}
    echo "读取: INTERFACE_RT_TX_MB[\$interface]: \${INTERFACE_RT_TX_MB[\$interface]}"
done

# test_hour="01"
# test_minute="47"

tt=60
duration=0
tt_prev=false
year_rp=false
month_rp=false
day_rp=false
day_sendtag=true
month_sendtag=true
year_sendtag=true

echo "runing..."
while true; do

    # 获取tt秒前数据
    ov_prev_rx_bytes=0
    ov_prev_tx_bytes=0
    for interface in "\${interfaces[@]}"; do
        prev_rx_bytes[\$interface]=\$(ip -s link show \$interface | awk '/RX:/ { getline; print \$1 }')
        prev_tx_bytes[\$interface]=\$(ip -s link show \$interface | awk '/TX:/ { getline; print \$1 }')
        ov_prev_rx_bytes=\$((ov_prev_rx_bytes + prev_rx_bytes[\$interface]))
        ov_prev_tx_bytes=\$((ov_prev_tx_bytes + prev_tx_bytes[\$interface]))
    done

    if ! \$tt_prev; then
        if \$day_sendtag; then
            for interface in "\${interfaces[@]}"; do
                echo "\$interface 发送前只执行一次 tt_prev_day_sendtag."
                prev_day_rx_bytes[\$interface]=\${prev_rx_bytes[\$interface]}
                prev_day_tx_bytes[\$interface]=\${prev_tx_bytes[\$interface]}
            done
            ov_prev_day_rx_bytes=\$ov_prev_rx_bytes
            ov_prev_day_tx_bytes=\$ov_prev_tx_bytes
        fi
        if \$month_sendtag; then
            for interface in "\${interfaces[@]}"; do
                echo "\$interface 发送前只执行一次 tt_prev_month_sendtag."
                prev_month_rx_bytes[\$interface]=\${prev_rx_bytes[\$interface]}
                prev_month_tx_bytes[\$interface]=\${prev_tx_bytes[\$interface]}
            done
            ov_prev_month_rx_bytes=\$ov_prev_rx_bytes
            ov_prev_month_tx_bytes=\$ov_prev_tx_bytes
        fi
        if \$year_sendtag; then
            for interface in "\${interfaces[@]}"; do
                echo "\$interface 发送前只执行一次 tt_prev_year_sendtag."
                prev_year_rx_bytes[\$interface]=\${prev_rx_bytes[\$interface]}
                prev_year_tx_bytes[\$interface]=\${prev_tx_bytes[\$interface]}
            done
            ov_prev_year_rx_bytes=\$ov_prev_rx_bytes
            ov_prev_year_tx_bytes=\$ov_prev_tx_bytes
        fi
    else
        if \$day_sendtag; then
            for interface in "\${interfaces[@]}"; do
                echo "\$interface 发送前只执行一次 day_sendtag."
                prev_day_rx_bytes[\$interface]=\${tt_prev_rx_bytes_T[\$interface]}
                prev_day_tx_bytes[\$interface]=\${tt_prev_tx_bytes_T[\$interface]}
            done
            ov_prev_day_rx_bytes=\$tt_ov_prev_rx_bytes_T
            ov_prev_day_tx_bytes=\$tt_ov_prev_tx_bytes_T
        fi
        if \$month_sendtag; then
            for interface in "\${interfaces[@]}"; do
                echo "\$interface 发送前只执行一次 month_sendtag."
                prev_month_rx_bytes[\$interface]=\${tt_prev_rx_bytes_T[\$interface]}
                prev_month_tx_bytes[\$interface]=\${tt_prev_tx_bytes_T[\$interface]}
            done
            ov_prev_month_rx_bytes=\$tt_ov_prev_rx_bytes_T
            ov_prev_month_tx_bytes=\$tt_ov_prev_tx_bytes_T
        fi
        if \$year_sendtag; then
            for interface in "\${interfaces[@]}"; do
                echo "\$interface 发送前只执行一次 year_sendtag."
                prev_year_rx_bytes[\$interface]=\${tt_prev_rx_bytes_T[\$interface]}
                prev_year_tx_bytes[\$interface]=\${tt_prev_tx_bytes_T[\$interface]}
            done
            ov_prev_year_rx_bytes=\$tt_ov_prev_rx_bytes_T
            ov_prev_year_tx_bytes=\$tt_ov_prev_tx_bytes_T
        fi
    fi
    day_sendtag=false
    month_sendtag=false
    year_sendtag=false

    # 等待tt秒
    end_time=\$(date +%s%N)
    if [ ! -z "\$start_time" ]; then
        time_diff=\$((end_time - start_time))
        time_diff_ms=\$((time_diff / 1000000))

        # 输出执行FOR所花费时间
        echo "上一个 FOR循环 所执行时间 \$time_diff_ms 毫秒."

        duration=\$(awk "BEGIN {print \$time_diff_ms/1000}")
        sleep_time=\$(awk -v v1=\$tt -v v2=\$duration 'BEGIN { printf "%.3f", v1 - v2 }')
    else
        sleep_time=\$tt
    fi
    sleep_time=\$(awk "BEGIN {print (\$sleep_time < 0 ? 0 : \$sleep_time)}")
    echo "sleep_time: \$sleep_time   duration: \$duration"
    sleep \$sleep_time
    start_time=\$(date +%s%N)

    # 获取tt秒后数据
    ov_current_rx_bytes=0
    ov_current_tx_bytes=0
    for interface in "\${interfaces[@]}"; do
        current_rx_bytes[\$interface]=\$(ip -s link show \$interface | awk '/RX:/ { getline; print \$1 }')
        current_tx_bytes[\$interface]=\$(ip -s link show \$interface | awk '/TX:/ { getline; print \$1 }')
        ov_current_rx_bytes=\$((ov_current_rx_bytes + current_rx_bytes[\$interface]))
        ov_current_tx_bytes=\$((ov_current_tx_bytes + current_tx_bytes[\$interface]))
    done

    for interface in "\${interfaces[@]}"; do
        tt_prev_rx_bytes_T[\$interface]=\${current_rx_bytes[\$interface]}
        tt_prev_tx_bytes_T[\$interface]=\${current_tx_bytes[\$interface]}
    done
    tt_ov_prev_rx_bytes_T=\$ov_current_rx_bytes
    tt_ov_prev_tx_bytes_T=\$ov_current_tx_bytes
    tt_prev=true

    nline=1
    # 获取当前时间的小时和分钟
    current_year=\$(date +"%Y")
    current_month=\$(date +"%m")
    current_day=\$(date +"%d")
    current_hour=\$(date +"%H")
    current_minute=\$(date +"%M")
    # tail_day=\$(date -d "\$(date +'%Y-%m-01 next month') -1 day" +%d)

    for interface in "\${interfaces[@]}"; do
        echo "NO.\$nline --------------------------------------rp--- interface: \$interface"

        all_rx_bytes=\$ov_current_rx_bytes
        all_rx_bytes=\$((all_rx_bytes + INTERFACE_RT_RX_b[\$interface]))
        all_rx_ratio=\$(awk -v used="\$all_rx_bytes" -v total="\$THRESHOLD_BYTES_MAX" 'BEGIN { printf "%.3f", ( used / total ) * 100 }')

        ratioandprogress "0" "0" "\$all_rx_ratio"
        all_rx_progress=\$progress
        all_rx_ratio=\$ratio

        all_rx=\$(Bytes_BtoKBMBGB "\$all_rx_bytes")
        all_rx=\$(Remove_B "\$all_rx")

        all_tx_bytes=\$ov_current_tx_bytes
        all_tx_bytes=\$((all_tx_bytes + INTERFACE_RT_TX_b[\$interface]))
        all_tx_ratio=\$(awk -v used="\$all_tx_bytes" -v total="\$THRESHOLD_BYTES_MAX" 'BEGIN { printf "%.3f", ( used / total ) * 100 }')

        ratioandprogress "0" "0" "\$all_tx_ratio"
        all_tx_progress=\$progress
        all_tx_ratio=\$ratio

        all_tx=\$(Bytes_BtoKBMBGB "\$all_tx_bytes")
        all_tx=\$(Remove_B "\$all_tx")

        # 日报告 #################################################################################################################
        if [ "\$current_hour" == "00" ] && [ "\$current_minute" == "00" ]; then
            diff_day_rx_bytes=\$(( current_rx_bytes[\$interface] - prev_day_rx_bytes[\$interface] ))
            diff_day_tx_bytes=\$(( current_tx_bytes[\$interface] - prev_day_tx_bytes[\$interface] ))
            diff_rx_day=\$(Bytes_BtoKBMBGB "\$diff_day_rx_bytes")
            diff_tx_day=\$(Bytes_BtoKBMBGB "\$diff_day_tx_bytes")

            if [ "\$StatisticsMode" == "OV" ]; then
                ov_diff_day_rx_bytes=\$(( ov_current_rx_bytes - ov_prev_day_rx_bytes ))
                ov_diff_day_tx_bytes=\$(( ov_current_tx_bytes - ov_prev_day_tx_bytes ))
                ov_diff_rx_day=\$(Bytes_BtoKBMBGB "\$ov_diff_day_rx_bytes")
                ov_diff_tx_day=\$(Bytes_BtoKBMBGB "\$ov_diff_day_tx_bytes")
            fi
            # 月报告
            if [ "\$current_day" == "01" ]; then
                diff_month_rx_bytes=\$(( current_rx_bytes[\$interface] - prev_month_rx_bytes[\$interface] ))
                diff_month_tx_bytes=\$(( current_tx_bytes[\$interface] - prev_month_tx_bytes[\$interface] ))
                diff_rx_month=\$(Bytes_BtoKBMBGB "\$diff_month_rx_bytes")
                diff_tx_month=\$(Bytes_BtoKBMBGB "\$diff_month_tx_bytes")

                if [ "\$StatisticsMode" == "OV" ]; then
                    ov_diff_month_rx_bytes=\$(( ov_current_rx_bytes - ov_prev_month_rx_bytes ))
                    ov_diff_month_tx_bytes=\$(( ov_current_tx_bytes - ov_prev_month_tx_bytes ))
                    ov_diff_rx_month=\$(Bytes_BtoKBMBGB "\$ov_diff_month_rx_bytes")
                    ov_diff_tx_month=\$(Bytes_BtoKBMBGB "\$ov_diff_month_tx_bytes")
                fi
                # 年报告
                if [ "\$current_month" == "01" ] && [ "\$current_day" == "01" ]; then
                    diff_year_rx_bytes=\$(( current_rx_bytes[\$interface] - prev_year_rx_bytes[\$interface] ))
                    diff_year_tx_bytes=\$(( current_tx_bytes[\$interface] - prev_year_tx_bytes[\$interface] ))
                    diff_rx_year=\$(Bytes_BtoKBMBGB "\$diff_year_rx_bytes")
                    diff_tx_year=\$(Bytes_BtoKBMBGB "\$diff_year_tx_bytes")

                    if [ "\$StatisticsMode" == "OV" ]; then
                        ov_diff_year_rx_bytes=\$(( ov_current_rx_bytes - ov_prev_year_rx_bytes ))
                        ov_diff_year_tx_bytes=\$(( ov_current_tx_bytes - ov_prev_year_tx_bytes ))
                        ov_diff_rx_year=\$(Bytes_BtoKBMBGB "\$ov_diff_year_rx_bytes")
                        ov_diff_tx_year=\$(Bytes_BtoKBMBGB "\$ov_diff_year_tx_bytes")
                    fi
                    year_rp=true
                fi
                month_rp=true
            fi
            day_rp=true
        fi

        # SE发送报告
        if [ "\$StatisticsMode" == "SE" ]; then
            if [ "\$current_hour" == "$hour_rp" ] && [ "\$current_minute" == "$minute_rp" ]; then

                current_date_send=\$(date +"%Y.%m.%d %T")

                if \$day_rp; then

                    # if cat /proc/version 2>/dev/null | grep -q -E -i "openwrt"; then
                        current_timestamp=\$(date +%s)
                        one_day_seconds=\$((24 * 60 * 60))
                        yesterday_timestamp=\$((current_timestamp - one_day_seconds))
                        yesterday_date=\$(date -d "@\$yesterday_timestamp" +'%m月%d日')
                        yesterday="\$yesterday_date"

                        # current_month=\$(date +'%m')
                        # current_day=\$(date +'%d')
                        # yesterday_day=\$((current_day - 1))
                        # yesterday_month=\$current_month
                        # if [ \$yesterday_day -eq 0 ]; then
                        #     yesterday_month=\$((current_month - 1))
                        #     if [ \$yesterday_month -eq 0 ]; then
                        #         yesterday_month=12
                        #     fi
                        #     yesterday_day=\$(date -d "1-\${yesterday_month}-01 -1 day" +'%d')
                        # fi
                        # yesterday="\${yesterday_month}-\${yesterday_day}"

                    # else
                    #     yesterday=\$(date -d "1 day ago" +%m月%d日)
                    # fi

                    diff_rx_day=\$(Remove_B "\$diff_rx_day")
                    diff_tx_day=\$(Remove_B "\$diff_tx_day")

                    message="\${yesterday}🌞流量报告 📈"'
'"主机名: $hostname_show 接口: \$interface"'
'"🌞接收: \${diff_rx_day}  🌞发送: \${diff_tx_day}"'
'"───────────────"'
'"总接收: \${all_rx}  总发送: \${all_tx}"'
'"设置流量上限: ${FlowThresholdMAX_U}🔒"'
'"使用⬇️: \$all_rx_progress \$all_rx_ratio"'
'"使用⬆️: \$all_tx_progress \$all_tx_ratio"'
'"服务器时间: \$current_date_send"
                    curl -s -X POST "https://api.telegram.org/bot$TelgramBotToken/sendMessage" \
                        -d chat_id="$ChatID_1" -d text="\$message"
                    echo "报告信息已发出..."
                    echo "时间: \$current_date, 活动接口: \$interface, 日接收: \$diff_rx_day, 日发送: \$diff_tx_day"
                    echo "----------------------------------------------------------------"
                    day_rp=false
                    day_sendtag=true
                fi

                if \$month_rp; then

                    # if cat /proc/version 2>/dev/null | grep -q -E -i "openwrt"; then
                        current_year=\$(date +'%Y')
                        current_month=\$(date +'%m')
                        previous_month=\$((current_month - 1))
                        if [ "\$previous_month" -eq 0 ]; then
                            previous_month=12
                            current_year=\$((current_year - 1))
                        fi
                        last_month="\${current_year}年\${previous_month}月份"
                    # else
                    #     last_month=\$(date -d "1 month ago" +%Y年%m月份)
                    # fi

                    diff_rx_month=\$(Remove_B "\$diff_rx_month")
                    diff_tx_month=\$(Remove_B "\$diff_tx_month")

                    message="\${last_month}🌙总流量报告 📈"'
'"主机名: $hostname_show 接口: \$interface"'
'"🌙接收: \${diff_rx_month}  🌙发送: \${diff_tx_month}"'
'"───────────────"'
'"总接收: \${all_rx}  总发送: \${all_tx}"'
'"设置流量上限: ${FlowThresholdMAX_U}🔒"'
'"使用⬇️: \$all_rx_progress \$all_rx_ratio"'
'"使用⬆️: \$all_tx_progress \$all_tx_ratio"'
'"服务器时间: \$current_date_send"
                    curl -s -X POST "https://api.telegram.org/bot$TelgramBotToken/sendMessage" \
                        -d chat_id="$ChatID_1" -d text="\$message"
                    echo "报告信息已发出..."
                    echo "时间: \$current_date, 活动接口: \$interface, 月接收: \$diff_rx_day, 月发送: \$diff_tx_day"
                    echo "----------------------------------------------------------------"
                    month_rp=false
                    month_sendtag=true
                fi

                if \$year_rp; then

                    # if cat /proc/version 2>/dev/null | grep -q -E -i "openwrt"; then
                        current_year=\$(date +'%Y')
                        previous_year=\$((current_year - 1))
                        last_year="\$previous_year"
                    # else
                    #     last_year=\$(date -d "1 year ago" +%Y)
                    # fi

                    diff_rx_year=\$(Remove_B "\$diff_rx_year")
                    diff_tx_year=\$(Remove_B "\$diff_tx_year")

                    message="\${last_year}年🧧总流量报告 📈"'
'"主机名: $hostname_show 接口: \$interface"'
'"🧧接收: \${diff_rx_year}  🧧发送: \${diff_tx_year}"'
'"───────────────"'
'"总接收: \${all_rx}  总发送: \${all_tx}"'
'"设置流量上限: ${FlowThresholdMAX_U}🔒"'
'"使用⬇️: \$all_rx_progress \$all_rx_ratio"'
'"使用⬆️: \$all_tx_progress \$all_tx_ratio"'
'"服务器时间: \$current_date_send"
                    curl -s -X POST "https://api.telegram.org/bot$TelgramBotToken/sendMessage" \
                        -d chat_id="$ChatID_1" -d text="\$message"
                    echo "报告信息已发出..."
                    echo "年报告信息:"
                    echo "时间: \$current_date, 活动接口: \$interface, 年接收: \$diff_rx_year, 年发送: \$diff_tx_year"
                    echo "----------------------------------------------------------------"
                    year_rp=false
                    year_sendtag=true
                fi
            fi
        fi
    nline=\$((nline + 1))
    done

    # OV发送报告
    if [ "\$StatisticsMode" == "OV" ]; then
        if [ "\$current_hour" == "$hour_rp" ] && [ "\$current_minute" == "$minute_rp" ]; then

            current_date_send=\$(date +"%Y.%m.%d %T")

            if \$day_rp; then

                # if cat /proc/version 2>/dev/null | grep -q -E -i "openwrt"; then
                    current_timestamp=\$(date +%s)
                    one_day_seconds=\$((24 * 60 * 60))
                    yesterday_timestamp=\$((current_timestamp - one_day_seconds))
                    yesterday_date=\$(date -d "@\$yesterday_timestamp" +'%m月%d日')
                    yesterday="\$yesterday_date"

                    # current_month=\$(date +'%m')
                    # current_day=\$(date +'%d')
                    # yesterday_day=\$((current_day - 1))
                    # yesterday_month=\$current_month
                    # if [ \$yesterday_day -eq 0 ]; then
                    #     yesterday_month=\$((current_month - 1))
                    #     if [ \$yesterday_month -eq 0 ]; then
                    #         yesterday_month=12
                    #     fi
                    #     yesterday_day=\$(date -d "1-\${yesterday_month}-01 -1 day" +'%d')
                    # fi
                    # yesterday="\${yesterday_month}-\${yesterday_day}"

                # else
                #     yesterday=\$(date -d "1 day ago" +%m月%d日)
                # fi

                ov_diff_rx_day=\$(Remove_B "\$ov_diff_rx_day")
                ov_diff_tx_day=\$(Remove_B "\$ov_diff_tx_day")

                message="\${yesterday}🌞流量报告 📈"'
'"主机名: $hostname_show 接口: \$show_interfaces"'
'"🌞接收: \${ov_diff_rx_day}  🌞发送: \${ov_diff_tx_day}"'
'"───────────────"'
'"总接收: \${all_rx}  总发送: \${all_tx}"'
'"设置流量上限: ${FlowThresholdMAX_U}🔒"'
'"使用⬇️: \$all_rx_progress \$all_rx_ratio"'
'"使用⬆️: \$all_tx_progress \$all_tx_ratio"'
'"服务器时间: \$current_date_send"
                curl -s -X POST "https://api.telegram.org/bot$TelgramBotToken/sendMessage" \
                    -d chat_id="$ChatID_1" -d text="\$message"
                echo "报告信息已发出..."
                echo "时间: \$current_date, 活动接口: \$interface, 日接收: \$diff_rx_day, 日发送: \$diff_tx_day"
                echo "----------------------------------------------------------------"
                day_rp=false
                day_sendtag=true
            fi

            if \$month_rp; then
                
                # if cat /proc/version 2>/dev/null | grep -q -E -i "openwrt"; then
                    current_year=\$(date +'%Y')
                    current_month=\$(date +'%m')
                    previous_month=\$((current_month - 1))
                    if [ "\$previous_month" -eq 0 ]; then
                        previous_month=12
                        current_year=\$((current_year - 1))
                    fi
                    last_month="\${current_year}年\${previous_month}月份"
                # else
                #     last_month=\$(date -d "1 month ago" +%Y年%m月份)
                # fi

                ov_diff_rx_month=\$(Remove_B "\$ov_diff_rx_month")
                ov_diff_tx_month=\$(Remove_B "\$ov_diff_tx_month")

                message="\${last_month}🌙总流量报告 📈"'
'"主机名: $hostname_show 接口: \$show_interfaces"'
'"🌙接收: \${ov_diff_rx_month}  🌙发送: \${ov_diff_tx_month}"'
'"───────────────"'
'"总接收: \${all_rx}  总发送: \${all_tx}"'
'"设置流量上限: ${FlowThresholdMAX_U}🔒"'
'"使用⬇️: \$all_rx_progress \$all_rx_ratio"'
'"使用⬆️: \$all_tx_progress \$all_tx_ratio"'
'"服务器时间: \$current_date_send"
                curl -s -X POST "https://api.telegram.org/bot$TelgramBotToken/sendMessage" \
                    -d chat_id="$ChatID_1" -d text="\$message"
                echo "报告信息已发出..."
                echo "时间: \$current_date, 活动接口: \$interface, 月接收: \$diff_rx_day, 月发送: \$diff_tx_day"
                echo "----------------------------------------------------------------"
                month_rp=false
                month_sendtag=true
            fi

            if \$year_rp; then
                
                # if cat /proc/version 2>/dev/null | grep -q -E -i "openwrt"; then
                    current_year=\$(date +'%Y')
                    previous_year=\$((current_year - 1))
                    last_year="\$previous_year"
                # else
                #     last_year=\$(date -d "1 year ago" +%Y)
                # fi

                ov_diff_rx_year=\$(Remove_B "\$ov_diff_rx_year")
                ov_diff_tx_year=\$(Remove_B "\$ov_diff_tx_year")

                message="\${last_year}年🧧总流量报告 📈"'
'"主机名: $hostname_show 接口: \$show_interfaces"'
'"🧧接收: \${ov_diff_rx_year}  🧧发送: \${ov_diff_tx_year}"'
'"───────────────"'
'"总接收: \${all_rx}  总发送: \${all_tx}"'
'"设置流量上限: ${FlowThresholdMAX_U}🔒"'
'"使用⬇️: \$all_rx_progress \$all_rx_ratio"'
'"使用⬆️: \$all_tx_progress \$all_tx_ratio"'
'"服务器时间: \$current_date_send"
                curl -s -X POST "https://api.telegram.org/bot$TelgramBotToken/sendMessage" \
                    -d chat_id="$ChatID_1" -d text="\$message"
                echo "报告信息已发出..."
                echo "年报告信息:"
                echo "时间: \$current_date, 活动接口: \$interface, 年接收: \$diff_rx_year, 年发送: \$diff_tx_year"
                echo "----------------------------------------------------------------"
                year_rp=false
                year_sendtag=true
            fi
        fi
    fi
    for interface in "\${interfaces[@]}"; do
        echo "prev_day_rx_bytes[\$interface]: \${prev_day_rx_bytes[\$interface]}"
        echo "prev_day_tx_bytes[\$interface]: \${prev_day_tx_bytes[\$interface]}"
    done
    echo "活动接口: \$show_interfaces  接收总流量: \$all_rx_mb 发送总流量: \$all_tx_mb"
    echo "活动接口: \$show_interfaces  接收日流量: \$diff_rx_day  发送日流量: \$diff_tx_day 报告时间: $hour_rp 时 $minute_rp 分"
    echo "活动接口: \$show_interfaces  接收月流量: \$diff_rx_month  发送月流量: \$diff_tx_month 报告时间: $hour_rp 时 $minute_rp 分"
    echo "活动接口: \$show_interfaces  接收年流量: \$diff_rx_year  发送年流量: \$diff_tx_year 报告时间: $hour_rp 时 $minute_rp 分"
    echo "当前时间: \$(date)"
    echo "------------------------------------------------------"
done
EOF
    chmod +x $FolderPath/tg_flowrp.sh
    pkill tg_flowrp.sh > /dev/null 2>&1 &
    pkill tg_flowrp.sh > /dev/null 2>&1 &
    kill $(ps | grep '[t]g_flowrp.sh' | awk '{print $1}')
    nohup $FolderPath/tg_flowrp.sh > $FolderPath/tg_flowrp.log 2>&1 &
    if crontab -l | grep -q "@reboot nohup $FolderPath/tg_flowrp.sh > $FolderPath/tg_flowrp.log 2>&1 &"; then
        crontab -l | grep -v "@reboot nohup $FolderPath/tg_flowrp.sh > $FolderPath/tg_flowrp.log 2>&1 &" | crontab -
    fi
    (crontab -l 2>/dev/null; echo "@reboot nohup $FolderPath/tg_flowrp.sh > $FolderPath/tg_flowrp.log 2>&1 &") | crontab -
    if [ "$mute" == "false" ]; then
        message="流量定时报告设置成功 ⚙️"$'\n'"主机名: $hostname_show"$'\n'"报告接口: $show_interfaces_RP  报告模式: $StatisticsMode"$'\n'"报告时间: 每天 $hour_rp 时 $minute_rp 分"
        $FolderPath/send_tg.sh "$TelgramBotToken" "$ChatID_1" "$message" &
    fi
    tips="$Tip 流量定时报告设置成功, 报告时间: 每天 $hour_rp 时 $minute_rp 分 ($input_time)"
}

# 卸载
UN_SetupBoot_TG() {
    if [ "$boot_menu_tag" == "$SETTAG" ]; then
        systemctl stop tg_boot.service > /dev/null 2>&1
        systemctl disable tg_boot.service > /dev/null 2>&1
        sleep 1
        rm -f /etc/systemd/system/tg_boot.service
        if [ -f /etc/init.d/tg_boot.sh ]; then
            /etc/init.d/tg_boot.sh disable
            rm -f /etc/init.d/tg_boot.sh
        fi
        tips="$Tip 机开通知 已经取消 / 删除."
    fi
}
UN_SetupLogin_TG() {
    if [ "$login_menu_tag" == "$SETTAG" ]; then
        if [ -f /etc/bash.bashrc ]; then
            sed -i '/bash \/root\/.shfile\/tg_login.sh/d' /etc/bash.bashrc
        fi
        if [ -f /etc/profile ]; then
            sed -i '/bash \/root\/.shfile\/tg_login.sh/d' /etc/profile
        fi
        tips="$Tip 登陆通知 已经取消 / 删除."
    fi
}
UN_SetupShutdown_TG() {
    if [ "$shutdown_menu_tag" == "$SETTAG" ]; then
        systemctl stop tg_shutdown.service > /dev/null 2>&1
        systemctl disable tg_shutdown.service > /dev/null 2>&1
        sleep 1
        rm -f /etc/systemd/system/tg_shutdown.service
        if [ -f /etc/init.d/tg_shutdown.sh ]; then
            /etc/init.d/tg_shutdown.sh disable
            rm -f /etc/init.d/tg_shutdown.sh
        fi
        tips="$Tip 关机通知 已经取消 / 删除."
    fi
}
UN_SetupCPU_TG() {
    if [ "$cpu_menu_tag" == "$SETTAG" ]; then
        pkill tg_cpu.sh > /dev/null 2>&1 &
        pkill tg_cpu.sh > /dev/null 2>&1 &
        kill $(ps | grep '[t]g_cpu.sh' | awk '{print $1}')
        crontab -l | grep -v "@reboot nohup $FolderPath/tg_cpu.sh > $FolderPath/tg_cpu.log 2>&1 &" | crontab -
        tips="$Tip CPU报警 已经取消 / 删除."
    fi
}
UN_SetupMEM_TG() {
    if [ "$mem_menu_tag" == "$SETTAG" ]; then
        pkill tg_mem.sh > /dev/null 2>&1 &
        pkill tg_mem.sh > /dev/null 2>&1 &
        kill $(ps | grep '[t]g_mem.sh' | awk '{print $1}')
        crontab -l | grep -v "@reboot nohup $FolderPath/tg_mem.sh > $FolderPath/tg_mem.log 2>&1 &" | crontab -
        tips="$Tip 内存报警 已经取消 / 删除."
    fi
}
UN_SetupDISK_TG() {
    if [ "$disk_menu_tag" == "$SETTAG" ]; then
        pkill tg_disk.sh > /dev/null 2>&1 &
        pkill tg_disk.sh > /dev/null 2>&1 &
        kill $(ps | grep '[t]g_disk.sh' | awk '{print $1}')
        crontab -l | grep -v "@reboot nohup $FolderPath/tg_disk.sh > $FolderPath/tg_disk.log 2>&1 &" | crontab -
        tips="$Tip 磁盘报警 已经取消 / 删除."
    fi
}
UN_SetupFlow_TG() {
    if [ "$flow_menu_tag" == "$SETTAG" ]; then
        pkill tg_flow.sh > /dev/null 2>&1 &
        pkill tg_flow.sh > /dev/null 2>&1 &
        kill $(ps | grep '[t]g_flow.sh' | awk '{print $1}')
        crontab -l | grep -v "@reboot nohup $FolderPath/tg_flow.sh > $FolderPath/tg_flow.log 2>&1 &" | crontab -
        tips="$Tip 流量报警 已经取消 / 删除."
    fi
}
UN_SetFlowReport_TG() {
    if [ "$flowrp_menu_tag" == "$SETTAG" ]; then
        pkill tg_flowrp.sh > /dev/null 2>&1 &
        pkill tg_flowrp.sh > /dev/null 2>&1 &
        kill $(ps | grep '[t]g_flowrp.sh' | awk '{print $1}')
        crontab -l | grep -v "@reboot nohup $FolderPath/tg_flowrp.sh > $FolderPath/tg_flowrp.log 2>&1 &" | crontab -
        tips="$Tip 流量定时报告 已经取消 / 删除."
    fi

}
UN_SetupDocker_TG() {
    if [ "$docker_menu_tag" == "$SETTAG" ]; then
        pkill tg_docker.sh > /dev/null 2>&1 &
        pkill tg_docker.sh > /dev/null 2>&1 &
        kill $(ps | grep '[t]g_docker.sh' | awk '{print $1}')
        crontab -l | grep -v "@reboot nohup $FolderPath/tg_docker.sh > $FolderPath/tg_docker.log 2>&1 &" | crontab -
        tips="$Tip Docker变更通知 已经取消 / 删除."
    fi
}
UN_SetAutoUpdate() {
    if [ "$autoud_menu_tag" == "$SETTAG" ]; then
        pkill tg_autoud.sh > /dev/null 2>&1 &
        pkill tg_autoud.sh > /dev/null 2>&1 &
        kill $(ps | grep '[t]g_autoud.sh' | awk '{print $1}')
        crontab -l | grep -v "bash $FolderPath/tg_autoud.sh > $FolderPath/tg_autoud.log 2>&1 &" | crontab -
        crontab -l | grep -v "bash $FolderPath/VPSKeeper.sh" | crontab -
        tips="$Tip 自动更新已经取消."
    fi
}

UN_ALL() {
    UN_SetupBoot_TG
    UN_SetupLogin_TG
    UN_SetupShutdown_TG
    UN_SetupCPU_TG
    UN_SetupMEM_TG
    UN_SetupDISK_TG
    UN_SetupFlow_TG
    UN_SetFlowReport_TG
    UN_SetupDocker_TG
    UN_SetAutoUpdate
    pkill -f 'tg_.+.sh' > /dev/null 2>&1 &
    # ps | grep '[t]g_' | awk '{print $1}' | xargs kill
    kill $(ps | grep '[t]g_' | awk '{print $1}')
    sleep 1
    if pgrep -f 'tg_.+.sh' > /dev/null; then
    pkill -9 -f 'tg_.+.sh' > /dev/null 2>&1 &
    # ps | grep '[t]g_' | awk '{print $1}' | xargs kill -9
    kill -9 $(ps | grep '[t]g_' | awk '{print $1}')
    fi
    crontab -l | grep -v "$FolderPath/tg_" | crontab -
    tips="$Tip 已取消 / 删除所有通知."
}

DELFOLDER() {
    if [ "$boot_menu_tag" == "$UNSETTAG" ] && [ "$login_menu_tag" == "$UNSETTAG" ] && [ "$shutdown_menu_tag" == "$UNSETTAG" ] && [ "$cpu_menu_tag" == "$UNSETTAG" ] && [ "$mem_menu_tag" == "$UNSETTAG" ] && [ "$disk_menu_tag" == "$UNSETTAG" ] && [ "$flow_menu_tag" == "$UNSETTAG" ] && [ "$docker_menu_tag" == "$UNSETTAG" ]; then
        if [ -d "$FolderPath" ]; then
            read -e -p "是否要删除 $FolderPath 文件夹? (建议保留) Y/其它 : " yorn
            if [ "$yorn" == "Y" ] || [ "$yorn" == "y" ]; then
                rm -rf $FolderPath
                folder_menu_tag=""
                tips="$Tip $FolderPath 文件夹已经${RE}删除${NC}."
            else
                tips="$Tip $FolderPath 文件夹已经${GR}保留${NC}."
            fi
        fi
    else
        tips="$Err 请先取消所有通知后再删除文件夹."
    fi
}

# 一键默认设置
OneKeydefault () {
    mutebakup=$mute
    autorun=true
    mute=true
    SetupBoot_TG
    SetupLogin_TG
    SetupShutdown_TG
    writeini "CPUThreshold" "$CPUThreshold_de"
    writeini "MEMThreshold" "$MEMThreshold_de"
    writeini "DISKThreshold" "$DISKThreshold_de"
    writeini "FlowThreshold" "$FlowThreshold_de"
    writeini "FlowThresholdMAX" "$FlowThresholdMAX_de"
    writeini "ReportTime" "$ReportTime_de"
    writeini "AutoUpdateTime" "$AutoUpdateTime_de"
    source $ConfigFile
    SetupCPU_TG
    SetupMEM_TG
    SetupDISK_TG
    SetupFlow_TG
    SetFlowReport_TG
    SetAutoUpdate
    if [ "$mutebakup" == "false" ]; then
        current_date_send=$(date +"%Y.%m.%d %T")
        $FolderPath/send_tg.sh "$TelgramBotToken" "$ChatID_1" "已成功启动以下通知 ☎️"'
'"主机名: $hostname_show"'
'"───────────────"'
'"开机通知"'
'"登陆通知"'
'"关机通知"'
'"CPU使用率超 ${CPUThreshold}% 报警"'
'"内存使用率超 ${MEMThreshold}% 报警"'
'"磁盘使用率超 ${DISKThreshold}% 报警"'
'"流量使用率超 ${FlowThreshold_UB} 报警"'
'"流量报告时间 ${ReportTime}"'
'"自动更新时间 ${AutoUpdateTime}"'
'"───────────────"'
'"服务器时间: $current_date_send" &
    fi
    tips="$Tip 已经启动所有通知 (除了Docker 变更通知)."
    autorun=false
    mute=false
    mute=$mutebakup
}

# 主程序
CheckAndCreateFolder
CheckSys
if [[ "$1" =~ ^[0-9]{5,}$ ]]; then
    ChatID_1="$1"
    writeini "ChatID_1" "$1"
elif [[ "$2" =~ ^[0-9]{5,}$ ]]; then
    ChatID_1="$2"
    writeini "ChatID_1" "$2"
elif [[ "$3" =~ ^[0-9]{5,}$ ]]; then
    ChatID_1="$3"
    writeini "ChatID_1" "$3"
fi
declare -f send_telegram_message | sed -n '/^{/,/^}/p' | sed '1d;$d' | sed 's/$1/$3/g; s/$TelgramBotToken/$1/g; s/$ChatID_1/$2/g' > $FolderPath/send_tg.sh
chmod +x $FolderPath/send_tg.sh
if [ -z "$ChatID_1" ]; then
    CLS
    echo -e "$Tip 在使用前请先设置 [${GR}CHAT ID${NC}] 用以接收通知信息."
    echo -e "$Tip [${REB}CHAT ID${NC}] 获取方法: 在 Telgram 中添加机器人 @userinfobot, 点击或输入: /start"
    read -e -p "请输入你的 [CHAT ID] : " cahtid
    if [ ! -z "$cahtid" ]; then
        if [[ $cahtid =~ ^[0-9]+$ ]]; then
            writeini "ChatID_1" "$cahtid"
            ChatID_1=$cahtid
            # source $ConfigFile
        else
            echo -e "$Err ${REB}输入无效${NC}, Chat ID 必须是数字, 退出操作."
            exit 1
        fi
    else
        echo -e "$Tip 输入为空, 退出操作."
        exit 1
    fi
fi

if [ "$1" == "mute" ] || [ "$2" == "mute" ] || [ "$3" == "mute" ]; then
    mute=true
else
    mute=false
fi

if [ "$1" == "ok" ] || [ "$2" == "ok" ] || [ "$3" == "ok" ]; then
    OneKeydefault
    exit 0
fi

if [ "$1" == "auto" ] || [ "$2" == "auto" ] || [ "$3" == "auto" ]; then
    autorun=true
    echo "自动模式..."
    CheckAndCreateFolder
    CheckSetup
    GetVPSInfo
    UN_ALL
    sleep 1

    mute=true
    Setuped=false
    if [ "$boot_menu_tag" == "$SETTAG" ] || [ "$login_menu_tag" == "$SETTAG" ] || [ "$shutdown_menu_tag" == "$SETTAG" ] || [ "$cpu_menu_tag" == "$SETTAG" ] || [ "$mem_menu_tag" == "$SETTAG" ] || [ "$disk_menu_tag" == "$SETTAG" ] || [ "$flow_menu_tag" == "$SETTAG" ] || [ "$flowrp_menu_tag" == "$SETTAG" ] || [ "$docker_menu_tag" == "$SETTAG" ] || [ "$autoud_menu_tag" == "$SETTAG" ]; then
        Setuped=true
    fi
    if [ "$boot_menu_tag" == "$SETTAG" ]; then
        SetupBoot_TG
    fi
    if [ "$login_menu_tag" == "$SETTAG" ]; then
        SetupLogin_TG
    fi
    if [ "$shutdown_menu_tag" == "$SETTAG" ]; then
        SetupShutdown_TG
    fi
    if [ "$cpu_menu_tag" == "$SETTAG" ]; then
        SetupCPU_TG
    fi
    if [ "$mem_menu_tag" == "$SETTAG" ]; then
        SetupMEM_TG
    fi
    if [ "$disk_menu_tag" == "$SETTAG" ]; then
        SetupDISK_TG
    fi
    if [ "$flow_menu_tag" == "$SETTAG" ]; then
        SetupFlow_TG
    fi
    if [ "$flowrp_menu_tag" == "$SETTAG" ]; then
        SetFlowReport_TG
    fi
    if [ "$docker_menu_tag" == "$SETTAG" ]; then
        SetupDocker_TG
    fi
    if [ "$autoud_menu_tag" == "$SETTAG" ]; then
        SetAutoUpdate
    fi
    mute=false

    if [ "$1" != "mute" ] && [ "$2" != "mute" ] && [ "$3" != "mute" ]; then
        if [[ "$boot_menu_tag" == "$SETTAG" || "$login_menu_tag" == "$SETTAG" || "$shutdown_menu_tag" == "$SETTAG" || "$cpu_menu_tag" == "$SETTAG" || "$mem_menu_tag" == "$SETTAG" || "$disk_menu_tag" == "$SETTAG" || "$flow_menu_tag" == "$SETTAG" || "$flowrp_menu_tag" == "$SETTAG" || "$docker_menu_tag" == "$SETTAG" || "$autoud_menu_tag" == "$SETTAG" ]] && [[ "$Setuped" ]]; then
            message="脚本已更新.（ 主机名: $hostname_show ）"
            $FolderPath/send_tg.sh "$TelgramBotToken" "$ChatID_1" "$message" &
        fi
    fi

    echo "自动模式执行完成."
    exit 0
else
    autorun=false
fi

tips=""

while true; do
CheckSetup
GetVPSInfo
source $ConfigFile
if [ -z "$CPUThreshold" ]; then
    CPUThreshold_tag="${RE}未设置${NC}"
else
    CPUThreshold_tag="${GR}$CPUThreshold %${NC}"
fi
if [ -z "$MEMThreshold" ]; then
    MEMThreshold_tag="${RE}未设置${NC}"
else
    MEMThreshold_tag="${GR}$MEMThreshold %${NC}"
fi
if [ -z "$DISKThreshold" ]; then
    DISKThreshold_tag="${RE}未设置${NC}"
else
    DISKThreshold_tag="${GR}$DISKThreshold %${NC}"
fi
if [ -z "$FlowThreshold" ]; then
    FlowThreshold_tag="${RE}未设置${NC}"
else
    FlowThreshold_tag="${GR}$FlowThreshold${NC}"
fi
CLS
echo && echo -e "VPS 守护一键管理脚本 ${RE}[v${sh_ver}]${NC}
-- tse | vtse.eu.org | $release -- 
  
 ${GR}0.${NC} 检查依赖 / 设置参数 \t$reset_menu_tag
———————————————————————
 ${GR}1.${NC} 设置 ${GR}[开机]${NC} Telgram 通知 \t\t\t$boot_menu_tag
 ${GR}2.${NC} 设置 ${GR}[登陆]${NC} Telgram 通知 \t\t\t$login_menu_tag
 ${GR}3.${NC} 设置 ${GR}[关机]${NC} Telgram 通知 \t\t\t$shutdown_menu_tag
 ${GR}4.${NC} 设置 ${GR}[CPU 报警]${NC} Telgram 通知 ${REB}阈值${NC}: $CPUThreshold_tag \t$cpu_menu_tag
 ${GR}5.${NC} 设置 ${GR}[内存报警]${NC} Telgram 通知 ${REB}阈值${NC}: $MEMThreshold_tag \t$mem_menu_tag
 ${GR}6.${NC} 设置 ${GR}[磁盘报警]${NC} Telgram 通知 ${REB}阈值${NC}: $DISKThreshold_tag \t$disk_menu_tag
 ${GR}7.${NC} 设置 ${GR}[流量报警]${NC} Telgram 通知 ${REB}阈值${NC}: $FlowThreshold_tag \t$flow_menu_tag
 ${GR}8.${NC} 设置 ${GR}[流量定时报告]${NC} Telgram 通知 \t\t$flowrp_menu_tag${NC}
 ${GR}9.${NC} 设置 ${GR}[Docker 变更]${NC} Telgram 通知 \t\t$docker_menu_tag${NC} ${REB}$reDockerSet${NC}
 ———————————————————————————————————————————————————————
 ${GR}t.${NC} 测试 - 发送一条信息用以检验参数设置
 ——————————————————————————————————————
 ${GR}h.${NC} 修改 - 主机名 以此作为主机标记
 ——————————————————————————————————————
 ${GR}o.${NC} ${GRB}一键${NC} ${GR}开启${NC} 所有通知
 ${GR}c.${NC} ${GRB}一键${NC} ${RE}取消 / 删除${NC} 所有通知
 ${GR}f.${NC} ${GRB}一键${NC} ${RE}删除${NC} 所有脚本子文件 \t${GR}$folder_menu_tag${NC}
 ———————————————————————————————————————————————
 ${GR}u.${NC} 设置自动更新脚本 \t$autoud_menu_tag
 ——————————————————————————————————————
 ${GR}x.${NC} 退出脚本
————————————"
if [ "$tips" = "" ]; then
    echo -e "$Tip 使用前先执行 0 进入参数设置, 启动后再次选择则为取消." && echo
else
    echo -e "$tips" && echo
fi
read -e -p "请输入选项 [0-8|t|h|o|c|f|u|x]:" num
case "$num" in
    0)
    CheckAndCreateFolder
    source $ConfigFile
    CheckRely
    SetupIniFile
    source $ConfigFile
    ;;
    1)
    CheckAndCreateFolder
    if [ "$boot_menu_tag" == "$SETTAG" ]; then
        UN_SetupBoot_TG
    else
        SetupBoot_TG
    fi
    ;;
    2)
    CheckAndCreateFolder
    if [ "$login_menu_tag" == "$SETTAG" ]; then
        UN_SetupLogin_TG
    else
        SetupLogin_TG
    fi
    ;;
    3)
    CheckAndCreateFolder
    if [ "$shutdown_menu_tag" == "$SETTAG" ]; then
        UN_SetupShutdown_TG
    else
        SetupShutdown_TG
    fi
    ;;
    4)
    CheckAndCreateFolder
    if [ "$cpu_menu_tag" == "$SETTAG" ]; then
        UN_SetupCPU_TG
    else
        SetupCPU_TG
    fi
    ;;
    5)
    CheckAndCreateFolder
    if [ "$mem_menu_tag" == "$SETTAG" ]; then
        UN_SetupMEM_TG
    else
        SetupMEM_TG
    fi
    ;;
    6)
    CheckAndCreateFolder
    if [ "$disk_menu_tag" == "$SETTAG" ]; then
        UN_SetupDISK_TG
    else
        SetupDISK_TG
    fi
    ;;
    7)
    CheckAndCreateFolder
    if [ "$flow_menu_tag" == "$SETTAG" ]; then
        UN_SetupFlow_TG
    else
        SetupFlow_TG
    fi
    ;;
    8)
    CheckAndCreateFolder
    if [ "$flowrp_menu_tag" == "$SETTAG" ]; then
        UN_SetFlowReport_TG
    else
        SetFlowReport_TG
    fi
    ;;
    9)
    CheckAndCreateFolder
    if [ "$docker_menu_tag" == "$SETTAG" ]; then
        UN_SetupDocker_TG
    else
        SetupDocker_TG
    fi
    ;;
    t|T)
    CheckAndCreateFolder
    test
    ;;
    h|H)
    ModifyHostname
    ;;
    o|O)
    OneKeydefault
    ;;
    c|C)
    echo "卸载前:"
    pgrep '^tg_' | xargs -I {} ps -p {} -o pid,cmd
    UN_ALL
    echo "卸载后:"
    pgrep '^tg_' | xargs -I {} ps -p {} -o pid,cmd
    ;;
    f|F)
    DELFOLDER
    ;;
    u|U)
    CheckAndCreateFolder
    if [ "$autoud_menu_tag" == "$SETTAG" ]; then
        UN_SetAutoUpdate
    else
        SetAutoUpdate
    fi
    ;;
    x|X)
    exit 0
    ;;
    *)
    tips="$Err 请输入正确数字或字母."
    ;;
esac
done
# END
