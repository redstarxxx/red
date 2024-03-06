#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: VPS keeper for telgram
#	Version: 1.0.0
#	Author: tse
#	Blog: https://vtse.eu.org
#=================================================
sh_ver="1.0.1"
FolderPath="/root/.shfile"
ConfigFile="/root/.shfile/TelgramBot.ini"

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

# 创建.shfile目录
CheckAndCreateFolder() {
    if [ ! -d "$FolderPath" ]; then
        mkdir -p "$FolderPath"
    fi
    if [ -f $ConfigFile ]; then
        source $ConfigFile
    else
        touch $ConfigFile
        writeini "TelgramBotToken" "7030486799:AAEa4PyCKGN7347v1mt2gyaBoySdxuh56ws"
        writeini "CPUTools" "top"
        writeini "FlowThresholdMAX" "1TB"
    fi
}

# 清屏
CLS() {
    if command -v apt &>/dev/null; then
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
    echo "————————————————————————————————————————————————"
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
    else
        echo -e "$Err 系统不支持." >&2
        exit 1
    fi
}

# 检测设置标记
CheckSetup() {
    echo "检测中..."
    if [ -f $FolderPath/tg_login.sh ]; then
        if [ -f /etc/bash.bashrc ]; then
            if grep -q "bash $FolderPath/tg_login.sh > /dev/null 2>&1" /etc/bash.bashrc; then
                login_menu_tag="-> 已设置"
            fi
        elif [ -f /etc/profile ]; then
            if grep -q "bash $FolderPath/tg_login.sh > /dev/null 2>&1" /etc/profile; then
                login_menu_tag="-> 已设置"
            fi
        else
            login_menu_tag=""
        fi
    else
        login_menu_tag=""
    fi
    if [ -f $FolderPath/tg_boot.sh ]; then
        if [ -f /etc/systemd/system/tg_boot.service ]; then
            boot_menu_tag="-> 已设置"
        else
            boot_menu_tag=""
        fi
    else
        boot_menu_tag=""
    fi
    if [ -f $FolderPath/tg_shutdown.sh ]; then
        if [ -f /etc/systemd/system/tg_shutdown.service ]; then
            shutdown_menu_tag="-> 已设置"
        else
            shutdown_menu_tag=""
        fi
    else
        shutdown_menu_tag=""
    fi
    if [ -f $FolderPath/tg_docker.sh ]; then
        if crontab -l | grep -q "@reboot nohup $FolderPath/tg_docker.sh > $FolderPath/tg_docker.log 2>&1 &"; then
            docker_menu_tag="-> 已设置"
        else
            docker_menu_tag=""
        fi
    else
        docker_menu_tag=""
    fi
    if [ -f $FolderPath/tg_cpu.sh ]; then
        if crontab -l | grep -q "@reboot nohup $FolderPath/tg_cpu.sh > $FolderPath/tg_cpu.log 2>&1 &"; then
            cpu_menu_tag="-> 已设置"
        else
            cpu_menu_tag=""
        fi
    else
        cpu_menu_tag=""
    fi
    if [ -f $FolderPath/tg_mem.sh ]; then
        if crontab -l | grep -q "@reboot nohup $FolderPath/tg_mem.sh > $FolderPath/tg_mem.log 2>&1 &"; then
            mem_menu_tag="-> 已设置"
        else
            mem_menu_tag=""
        fi
    else
        mem_menu_tag=""
    fi
    if [ -f $FolderPath/tg_disk.sh ]; then
        if crontab -l | grep -q "@reboot nohup $FolderPath/tg_disk.sh > $FolderPath/tg_disk.log 2>&1 &"; then
            disk_menu_tag="-> 已设置"
        else
            disk_menu_tag=""
        fi
    else
        disk_menu_tag=""
    fi
    if [ -f $FolderPath/tg_flow.sh ]; then
        if crontab -l | grep -q "@reboot nohup $FolderPath/tg_flow.sh > $FolderPath/tg_flow.log 2>&1 &"; then
            flow_menu_tag="-> 已设置"
        else
            flow_menu_tag=""
        fi
    else
        flow_menu_tag=""
    fi
    if [ -d "$FolderPath" ]; then
        folder_menu_tag="-> 文件夹存在"
    else
        folder_menu_tag=""
    fi
}

# 检查并安装依赖
CheckRely() {
    # 检查并安装依赖
    echo "检查并安装依赖..."
    declare -a dependencies=("sed" "grep" "awk" "hostnamectl" "systemd" "curl")
    missing_dependencies=()
    for dep in "${dependencies[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            missing_dependencies+=("$dep")
        fi
    done
    if [ ${#missing_dependencies[@]} -gt 0 ]; then
        echo -e "$Tip 以下依赖未安装: ${missing_dependencies[*]}"
        read -p "是否要安装依赖 Y/其它 : " yorn
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
}

SetAutoUpdate() {
    echo -e "是否要设置${GR}自动更新${NC}脚本? ${GR}Y${NC}.是 ${GR}N${NC}.取消 ${GR}回车${NC}.退出设置"
    divline
    read -p "请输入你的选择: " yorn
    if [ "$yorn" == "Y" ] || [ "$yorn" == "y" ]; then
        cat <<EOF > "$FolderPath/tg_autoupdate.sh"
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
        download_file "https://mirror.ghporxy.com/https://raw.githubusercontent.com/redstarxxx/shell/main/VPSKeeper.sh"
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
        chmod +x $FolderPath/tg_autoupdate.sh
        echo -e "输入定时模式, 采用 crontab 格式, 默认: 1 1 * * * 即第天 ${GR}01:01${NC} 分"
        read -p "请输入定时模式  (回车.采用默认模式): " cront
        if [ -z "$cront" ]; then
            cront="1 1 * * *"
        fi
        # cront_regex='^([0-5]?[0-9]|*|*/[0-5]?[0-9]) ([01]?[0-9]|2[0-3]|*|*/[01]?[0-9]|2[0-3]) ([0-2]?[0-9]|3[0-1]|*|*/[0-2]?[0-9]|3[0-1]) ([0]?[1-9]|1[0-2]|*|*/[0]?[1-9]|1[0-2]) ([0-6]|*|*/[0-6])$'
        # if [[ "$cront" =~ $cront_regex ]]; then
            if crontab -l | grep -q "bash $FolderPath/tg_autoupdate.sh > $FolderPath/tg_autoupdate.log 2>&1 &"; then
                crontab -l | grep -v "bash $FolderPath/tg_autoupdate.sh > $FolderPath/tg_autoupdate.log 2>&1 &" | crontab -
            fi
            (crontab -l 2>/dev/null; echo "$cront bash $FolderPath/tg_autoupdate.sh > $FolderPath/tg_autoupdate.log 2>&1 &") | crontab -
            crontt=$(echo "$cront" | awk '{$1 = ($1 + 1) % 60; print}')
            echo -e "开启 ${REB}静音模式${NC} 更新时你将不会收到提醒通知, 是否要开启静音模式?"
            read -p "请输入你的选择 Y.开启   回车.(跳过/不开启): " choice
            if [ "$choice" == "Y" ] || [ "$choice" == "y" ]; then
                if crontab -l | grep -q "bash $FolderPath/VPSKeeper.sh"; then
                    crontab -l | grep -v "bash $FolderPath/VPSKeeper.sh" | crontab -
                fi
                (crontab -l 2>/dev/null; echo "$crontt bash $FolderPath/VPSKeeper.sh \"auto\" \"mute\" 2>&1 &") | crontab -
                mute="静音模式"
            else
                if crontab -l | grep -q "bash $FolderPath/VPSKeeper.sh"; then
                    crontab -l | grep -v "bash $FolderPath/VPSKeeper.sh" | crontab -
                fi
                (crontab -l 2>/dev/null; echo "$crontt bash $FolderPath/VPSKeeper.sh \"auto\" 2>&1 &") | crontab -
                mute=""
            fi
            crontab -l | grep "tg_autoupdate.sh"
            crontab -l | grep "VPSKeeper.sh"
            echo -e "自动更新设置成功. ${GR}$mute${NC}"
        # else
        #     echo "错误: 定时模式不符合 crontab 格式"
        #     rm -f $FolderPath/tg_autoupdate.sh
        # fi
    elif [ "$yorn" == "N" ] || [ "$yorn" == "n" ]; then
        rm -f $FolderPath/tg_autoupdate.sh
        crontab -l | grep -v "bash $FolderPath/tg_autoupdate.sh > $FolderPath/tg_autoupdate.log 2>&1 &" | crontab -
        crontab -l | grep -v "bash $FolderPath/VPSKeeper.sh" | crontab -
        echo "自动更新已经取消."
    else
        echo "跳过设置."
    fi
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
    mem_total=$(top -bn1 | awk '/^MiB Mem/ { gsub(/Mem|total,|free,|used,|buff\/cache|:/, " ", $0); print int($2) }')
    swap_total=$(top -bn1 | awk '/^MiB Swap/ { gsub(/Swap|total,|free,|used,|buff\/cache|:/, " ", $0); print int($2) }')
    disk_total=$(df -h / | awk 'NR==2 {print $2}')
    disk_used=$(df -h / | awk 'NR==2 {print $3}')
    # echo "主机名: $(hostname)"$'\n'"CPUs: $cpuusedOfcpus"$'\n'"内存: $mem_total"\$'\n'"交换: $swap_total"$'\n'"磁盘: $disk_total"
}

# 设置ini参数文件
SetupIniFile() {
    old_TelgramBotToken=""
    old_ChatID_1=""
    old_CPUThreshold=""
    old_MEMThreshold=""
    old_DISKThreshold=""
    old_CPUTools=""
    old_FlowThreshold=""
    old_FlowThresholdMAX=""
    if [ -f $ConfigFile ] && [ -s $ConfigFile ]; then
        old_TelgramBotToken=$TelgramBotToken
        old_ChatID_1=$ChatID_1
        old_CPUThreshold=$CPUThreshold
        old_MEMThreshold=$MEMThreshold
        old_DISKThreshold=$DISKThreshold
        old_CPUTools=$CPUTools
        old_FlowThreshold=$FlowThreshold
        old_FlowThresholdMAX=$FlowThresholdMAX
    fi
    # 设置电报机器人参数
    divline
    echo -e "$Tip 默认机器人: @iekeeperbot 使用前必须添加并点击 start"
    while true; do
        divline
        echo -e "${GR}1${NC}.修改机器人Token ${GR}2${NC}.CHAT ID (接收信息的用户或群组 ID)"
        echo -e "${GR}3${NC}.CPU报警阀值 ${GR}4${NC}.内存报警阀值 ${GR}5${NC}.磁盘报警阀值 ${GR}6${NC}.流量报警阀值"
        echo -e "${GR}7${NC}.CPU检测工具设置 (默认使用 top) ${GR}回车${NC}.完成 / 退出设置"
        divline
        read -p "请输入你的选择: " choice
        case $choice in
            1)
                # 设置BOT Token
                echo -e "$Tip ${REB}BOT Token${NC} 获取方法: 在 Telgram 中添加机器人 @BotFather, 输入: /newbot"
                read -p "请输入 BOT Token (回车跳过修改 / 输入 R 使用默认机器人): " bottoken
                if [ ! -z "$bottoken" ]; then
                    writeini "TelgramBotToken" "$bottoken"
                else
                    echo -e "$Tip 输入为空, 跳过操作."
                fi
                if [ "$bottoken" == "r" ] || [ "$bottoken" == "R" ]; then
                    writeini "TelgramBotToken" "7030486799:AAEa4PyCKGN7347v1mt2gyaBoySdxuh56ws"
                fi
                ;;
            2)
                # 设置Chat ID
                echo -e "$Tip ${REB}Chat ID${NC} 获取方法: 在 Telgram 中添加机器人 @userinfobot, 点击或输入: /start"
                read -p "请输入 Chat ID (回车跳过修改): " cahtid
                if [ ! -z "$cahtid" ]; then
                    if [[ $cahtid =~ ^[0-9]+$ ]]; then
                        writeini "ChatID_1" "$cahtid"
                    else
                        echo -e "$Err ${REB}输入无效${NC}, Chat ID 必须是数字, 跳过操作."
                    fi
                else
                    echo -e "$Tip 输入为空, 跳过操作."
                fi
                ;;
            3)
                # 设置CPU报警阀值
                echo -e "$Tip ${REB}CPU 报警${NC} 阀值(%)输入 (1-100) 的整数"
                read -p "请输入 CPU 报警阀值 (回车跳过修改): " threshold
                if [ ! -z "$threshold" ]; then
                    threshold="${threshold//%/}"
                    if [[ $threshold =~ ^([1-9][0-9]?|100)$ ]]; then
                        writeini "CPUThreshold" "$threshold"
                    else
                        echo -e "$Err ${REB}输入无效${NC}, 报警阀值 必须是数字 (1-100) 的整数, 跳过操作."
                    fi
                else
                    echo -e "$Tip 输入为空, 跳过操作."
                fi
                ;;
            4)
                # 设置内存报警阀值
                echo -e "$Tip ${REB}内存报警${NC} 阀值(%)输入 (1-100) 的整数"
                read -p "请输入 内存阀值 (回车跳过修改): " threshold
                if [ ! -z "$threshold" ]; then
                    threshold="${threshold//%/}"
                    if [[ $threshold =~ ^([1-9][0-9]?|100)$ ]]; then
                        writeini "MEMThreshold" "$threshold"
                    else
                        echo -e "$Err ${REB}输入无效${NC}, 报警阀值 必须是数字 (1-100) 的整数, 跳过操作."
                    fi
                else
                    echo -e "$Tip 输入为空, 跳过操作."
                fi
                ;;
            5)
                # 设置磁盘报警阀值
                echo -e "$Tip ${REB}磁盘报警${NC} 阀值(%)输入 (1-100) 的整数"
                read -p "请输入 磁盘报警阀值 (回车跳过修改): " threshold
                if [ ! -z "$threshold" ]; then
                    threshold="${threshold//%/}"
                    if [[ $threshold =~ ^([1-9][0-9]?|100)$ ]]; then
                        writeini "DISKThreshold" "$threshold"
                    else
                        echo -e "$Err ${REB}输入无效${NC}, 报警阀值 必须是数字 (1-100) 的整数, 跳过操作."
                    fi
                else
                    echo -e "$Tip 输入为空, 跳过操作."
                fi
                ;;
            6)
                # 设置流量报警阀值
                echo -e "$Tip ${REB}流量报警${NC} 阀值输入格式: 数字|数字MB/数字GB/数字TB, 可带 1 位小数"
                read -p "请输入 流量报警阀值 (回车跳过修改): " threshold
                if [ ! -z "$threshold" ]; then
                    #if [[ $threshold =~ ^[0-9]+$ ]]; then
                    if [[ $threshold =~ ^[0-9]+(\.[0-9])?$ ]]; then
                        if [ "$threshold" -gt 1023 ]; then
                            # threshold=$(echo "scale=1; $threshold/1024" | bc)
                            threshold=$(awk -v value=$threshold 'BEGIN{printf "%.1f", value/1024}')
                            threshold="${threshold}GB" 
                        else
                            threshold="${threshold}MB"
                        fi
                        writeini "FlowThreshold" "$threshold"
                        # echo -e "$Tip 已将 报警阀值 写入 $ConfigFile 文件中."
                    elif [[ $threshold =~ ^[0-9]+(\.[0-9]+)?(MB)$ ]]; then
                        threshold=${threshold%MB}
                        if [ "$threshold" -gt 1023 ]; then
                            # threshold=$(echo "scale=1; $threshold/1024" | bc)
                            threshold=$(awk -v value=$threshold 'BEGIN{printf "%.1f", value/1024}')
                            threshold="${threshold}GB"
                        else
                            threshold="${threshold}MB"
                        fi
                        writeini "FlowThreshold" "$threshold"
                        # echo -e "$Tip 已将 报警阀值 写入 $ConfigFile 文件中."
                    elif [[ $threshold =~ ^[0-9]+(\.[0-9]+)?(GB)$ ]]; then
                        writeini "FlowThreshold" "$threshold"
                        # echo -e "$Tip 已将 报警阀值 写入 $ConfigFile 文件中."
                    elif [[ $threshold =~ ^[0-9]+(\.[0-9]+)?(TB)$ ]]; then
                        threshold=${threshold%TB}
                        threshold=$(awk -v value=$threshold 'BEGIN{printf "%.1f", value*1024}')
                        threshold="${threshold}GB"
                        writeini "FlowThreshold" "$threshold"
                    else
                        echo -e "$Err ${REB}输入无效${NC}, 报警阀值 必须是: 数字|数字MB/数字GB (%.1f) 的格式(支持1位小数), 跳过操作."
                    fi
                    read -p "请设置 流量上限 (回车默认: 1T): " threshold_max
                    if [ ! -z "$threshold_max" ]; then
                        if [[ $threshold_max =~ ^[0-9]+(\.[0-9])?$ ]]; then
                            if [ "$threshold_max" -gt 1023 ]; then
                                # threshold=$(echo "scale=1; $threshold/1024" | bc)
                                threshold_max=$(awk -v value=$threshold_max 'BEGIN{printf "%.1f", value/1024}')
                                threshold_max="${threshold_max}GB" 
                            else
                                threshold_max="${threshold_max}MB"
                            fi
                            writeini "FlowThresholdMAX" "$threshold_max"
                            # echo -e "$Tip 已将 报警阀值 写入 $ConfigFile 文件中."
                        elif [[ $threshold_max =~ ^[0-9]+(\.[0-9]+)?(MB)$ ]]; then
                            threshold_max=${threshold_max%MB}
                            if [ "$threshold_max" -gt 1023 ]; then
                                # threshold=$(echo "scale=1; $threshold/1024" | bc)
                                threshold_max=$(awk -v value=$threshold_max 'BEGIN{printf "%.1f", value/1024}')
                                threshold_max="${threshold_max}GB"
                            else
                                threshold_max="${threshold_max}MB"
                            fi
                            writeini "FlowThresholdMAX" "$threshold_max"
                            # echo -e "$Tip 已将 报警阀值 写入 $ConfigFile 文件中."
                        elif [[ $threshold_max =~ ^[0-9]+(\.[0-9]+)?(GB)$ ]]; then
                            writeini "FlowThresholdMAX" "$threshold_max"
                            # echo -e "$Tip 已将 报警阀值 写入 $ConfigFile 文件中."
                        elif [[ $threshold_max =~ ^[0-9]+(\.[0-9]+)?(TB)$ ]]; then
                            threshold_max=${threshold_max%TB}
                            threshold_max=$(awk -v value=$threshold_max 'BEGIN{printf "%.1f", value*1024}')
                            threshold_max="${threshold_max}GB"
                            writeini "FlowThresholdMAX" "$threshold_max"
                        else
                            echo -e "$Err ${REB}输入无效${NC}, 报警阀值 必须是: 数字|数字MB/数字GB (%.1f) 的格式(支持1位小数), 跳过操作."
                        fi
                    else
                        writeini "FlowThresholdMAX" "1TB"
                        echo -e "$Tip 输入为空, 默认最大流量上限为: 1TB"
                    fi
                else
                    echo -e "$Tip 输入为空, 跳过操作."
                fi
                ;;
            7)
                echo -e "$Tip 请选择 ${REB}CPU 检测工具${NC}: 1.top(系统自带) 2.sar(更专业) 3.top+sar"
                read -p "请输入序号 (默认采用 1.top / 回车跳过修改): " choice
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
                else
                    echo -e "$Tip 输入为空, 跳过操作."
                fi
                ;;
            *)
                echo "退出设置."
                break
            ;;
        esac
    done
    if [ "$old_TelgramBotToken" != "" ] && [ "$old_ChatID_1" != "" ]; then
        source $ConfigFile
        if [ "$TelgramBotToken" != "$old_TelgramBotToken" ] || [ "$ChatID_1" != "$old_ChatID_1" ]; then
            if [ "$boot_menu_tag" == "-> 已设置" ]; then
                writeini "reBootSet" "Reload"
            fi
            if [ "$login_menu_tag" == "-> 已设置" ]; then
                writeini "reLoginSet" "Reload"
            fi
            if [ "$shutdown_menu_tag" == "-> 已设置" ]; then
                writeini "reShutdownSet" "Reload"
            fi
            if [ "$cpu_menu_tag" == "-> 已设置" ]; then
                writeini "reCPUSet" "Reload"
            fi
            if [ "$mem_menu_tag" == "-> 已设置" ]; then
                writeini "reCPUSet" "Reload"
            fi
            if [ "$disk_menu_tag" == "-> 已设置" ]; then
                writeini "reCPUSet" "Reload"
            fi
            if [ "$flow_menu_tag" == "-> 已设置" ]; then
                writeini "reFlowSet" "Reload"
            fi
            if [ "$docker_menu_tag" == "-> 已设置" ]; then
                writeini "reDockerSet" "Reload"
            fi
        fi
    fi
    if [ "$old_CPUThreshold" != "" ]; then
        source $ConfigFile
        if [ "$CPUThreshold" != "$old_CPUThreshold" ] || [ "$CPUTools" != "$old_CPUTools" ]; then
            if [ "$cpu_menu_tag" == "-> 已设置" ]; then
                writeini "reCPUSet" "Reload"
            fi
        fi
    fi
    if [ "$old_MEMThreshold" != "" ]; then
        source $ConfigFile
        if [ "$MEMThreshold" != "$old_MEMThreshold" ] || [ "$CPUTools" != "$old_CPUTools" ]; then
            if [ "$mem_menu_tag" == "-> 已设置" ]; then
                writeini "reMEMSet" "Reload"
            fi
        fi
    fi
    if [ "$old_DISKThreshold" != "" ]; then
        source $ConfigFile
        if [ "$DISKThreshold" != "$old_DISKThreshold" ] || [ "$CPUTools" != "$old_CPUTools" ]; then
            if [ "$disk_menu_tag" == "-> 已设置" ]; then
                writeini "reDISKSet" "Reload"
            fi
        fi
    fi
    if [ "$old_FlowThreshold" != "" ]; then
        source $ConfigFile
        if [ "$FlowThreshold" != "$old_FlowThreshold" ] || [ "$FlowThresholdMAX" != "$old_FlowThresholdMAX" ]; then
            if [ "$flow_menu_tag" == "-> 已设置" ]; then
                writeini "reFlowSet" "Reload"
            fi
        fi
    fi
}

# 用于显示内容（调试用）
SourceAndShowINI() {
    if [ -f $ConfigFile ] && [ -s $ConfigFile ]; then
        source $ConfigFile
        divline
        cat $ConfigFile
        divline
        echo -e "$Tip 以上为 TelgramBot.ini 文件内容, 可重新执行 ${GR}0${NC} 修改参数."
    fi
}

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

# 更新
Update() {
    echo "升级脚本."
}

# 发送测试
test() {
    if [[ ! -z "${TelgramBotToken}" &&  ! -z "${ChatID_1}" ]]; then
        curl -s -X POST "https://api.telegram.org/bot$TelgramBotToken/sendMessage" \
            -d chat_id="$ChatID_1" -d text="来自 $(hostname) 的测试信息" > /dev/null
        echo -e "$Inf 测试信息已发出, 电报将收到一条\"来自 $(hostname) 的测试信息\"的信息."
        echo -e "$Tip 如果没有收到测试信息, 请检查设置 (重新执行 ${GR}0${NC} 选项)."
    else
        echo -e "$Err 参数丢失, 请设置后再执行 (先执行 ${GR}0${NC} 选项)."
    fi
}

# 修改Hostname
ModifyHostname() {
    if command -v hostnamectl &>/dev/null; then
        # 修改 hosts 和 hostname
        echo "当前 Hostname : $(hostname)"
        read -p "请输入要修改的 Hostname (回车跳过): " name
        if [[ ! -z "${name}" ]]; then
            echo "修改 hosts 和 hostname..."
            sed -i "s/$(hostname)/$name/g" /etc/hosts
            echo -e "$name" > /etc/hostname
            hostnamectl set-hostname $name
        else
            echo -e "$Tip 输入为空, 跳过操作."
        fi
    else
        echo -e "$Err 系统未检测到 \"hostnamectl\" 程序, 无法修改Hostname."
    fi
}

# 设置开机通知
SetupBoot_TG() {
    if command -v systemd &>/dev/null; then
        if [[ ! -z "${TelgramBotToken}" &&  ! -z "${ChatID_1}" ]]; then
            echo "#!/bin/bash" > $FolderPath/tg_boot.sh
            echo "curl -s -X POST \"https://api.telegram.org/bot$TelgramBotToken/sendMessage\" -d chat_id=\"$ChatID_1\" -d text=\"\$(hostname) 已启动❗️\"" \
            >> $FolderPath/tg_boot.sh
            chmod +x $FolderPath/tg_boot.sh
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
            # ShowContents "$FolderPath/tg_boot.sh"
            # ShowContents "/etc/systemd/system/tg_boot.service"
            # if [ ! "$(systemctl is-active tg_boot.service)" = "active" ]; then
                systemctl enable tg_boot.service
            # fi
            if [ "$mute" != "true" ]; then
                send_telegram_message "设置成功: 开机 通知⚙️"$'\n'"主机名: $(hostname)"$'\n'"💡当 开机 时将收到通知."
            fi
            echo -e "$Inf 开机 通知已经设置成功, 当开机时你的 Telgram 将收到通知."
            delini "reBootSet"
        else
            echo -e "$Err 参数丢失, 请设置后再执行 (先执行 ${GR}0${NC} 选项)."
        fi
    else
        echo -e "$Err 系统未检测到 \"systemd\" 程序, 无法设置开机通知."
    fi
}

# 设置登陆通知
SetupLogin_TG() {
    if [[ ! -z "${TelgramBotToken}" &&  ! -z "${ChatID_1}" ]]; then
        echo "#!/bin/bash" > $FolderPath/tg_login.sh
        echo "curl -s -X POST \"https://api.telegram.org/bot$TelgramBotToken/sendMessage\" -d chat_id=\"$ChatID_1\" -d text=\"\$(hostname) \$(id -nu) 用户登陆成功❗️\"" \
        >> $FolderPath/tg_login.sh
        chmod +x $FolderPath/tg_login.sh
        if [ -f /etc/bash.bashrc ]; then
            if ! grep -q "bash $FolderPath/tg_login.sh > /dev/null 2>&1" /etc/bash.bashrc; then
                echo "bash $FolderPath/tg_login.sh > /dev/null 2>&1" >> /etc/bash.bashrc
                # echo -e "$Tip 指令已经添加进 /etc/bash.bashrc 文件"
                if [ "$mute" != "true" ]; then
                    send_telegram_message "设置成功: 登陆 通知⚙️"$'\n'"主机名: $(hostname)"$'\n'"💡当 登陆 时将收到通知."
                fi
                echo -e "$Inf 登陆 通知已经设置成功, 当登陆时你的 Telgram 将收到通知."
            fi
            delini "reLoginSet"
        elif [ -f /etc/profile ]; then
            if ! grep -q "bash $FolderPath/tg_login.sh > /dev/null 2>&1" /etc/profile; then
                echo "bash $FolderPath/tg_login.sh > /dev/null 2>&1" >> /etc/profile
                # echo -e "$Tip 指令已经添加进 /etc/profile 文件"
                if [ "$mute" != "true" ]; then
                    send_telegram_message "设置成功: 登陆 通知⚙️"$'\n'"主机名: $(hostname)"$'\n'"💡当 登陆 时将收到通知."
                fi
                echo -e "$Inf 登陆 通知已经设置成功, 当登陆时你的 Telgram 将收到通知."
            fi
            delini "reLoginSet"
        else
            echo -e "$Err 未检测到对应文件, 无法设置登陆通知."
        fi
        # ShowContents "$FolderPath/tg_login.sh"
    else
        echo -e "$Err 参数丢失, 请设置后再执行 (先执行 ${GR}0${NC} 选项)."
    fi
}

# 设置关机通知
SetupShutdown_TG() {
    if command -v systemd &>/dev/null; then
        if [[ ! -z "${TelgramBotToken}" &&  ! -z "${ChatID_1}" ]]; then
            echo "#!/bin/bash" > $FolderPath/tg_shutdown.sh
            echo "curl -s -X POST \"https://api.telegram.org/bot$TelgramBotToken/sendMessage\" -d chat_id=\"$ChatID_1\" -d text=\"\$(hostname) \$(id -nu) 正在执行关机...❗️\"" \
            >> $FolderPath/tg_shutdown.sh
            chmod +x $FolderPath/tg_shutdown.sh
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
            # ShowContents "$FolderPath/tg_shutdown.sh"
            # ShowContents "/etc/systemd/system/tg_shutdown.service"
            # if [ ! "$(systemctl is-active tg_shutdown.service)" = "active" ]; then
                systemctl enable tg_shutdown.service
            # fi
            if [ "$mute" != "true" ]; then
                send_telegram_message "设置成功: 关机 通知⚙️"$'\n'"主机名: $(hostname)"$'\n'"💡当 关机 时将收到通知."
            fi
            echo -e "$Inf 关机 通知已经设置成功, 当开机时你的 Telgram 将收到通知."
            delini "reShutdownSet"
        else
            echo -e "$Err 参数丢失, 请设置后再执行 (先执行 ${GR}0${NC} 选项)."
        fi
    else
        echo -e "$Err 系统未检测到 \"systemd\" 程序, 无法设置关机通知."
    fi
}

# 设置Dokcer通知
SetupDocker_TG() {
    if command -v docker &>/dev/null; then
        if [[ ! -z "${TelgramBotToken}" &&  ! -z "${ChatID_1}" ]]; then
            cat <<EOF > $FolderPath/tg_docker.sh
#!/bin/bash

old_message=""
while true; do
    # new_message=\$(docker ps --format '{{.Names}}' | tr '\n' "\n" | sed 's/|$//')
    new_message=\$(docker ps --format '{{.Names}}' | awk '{print NR". " \$0}')
    if [ "\$new_message" != "\$old_message" ]; then
        old_message=\$new_message
        message="DOCKER 列表变更❗️"\$'\n'"\$new_message"
        curl -s -X POST "https://api.telegram.org/bot$TelgramBotToken/sendMessage" \
            -d chat_id="$ChatID_1" -d text="\$message"
    fi
    sleep 10
done
EOF
            chmod +x $FolderPath/tg_docker.sh
            pkill tg_docker.sh
            pkill tg_docker.sh
            nohup $FolderPath/tg_docker.sh > $FolderPath/tg_docker.log 2>&1 &
            if ! crontab -l | grep -q "@reboot nohup $FolderPath/tg_docker.sh > $FolderPath/tg_docker.log 2>&1 &"; then
                (crontab -l 2>/dev/null; echo "@reboot nohup $FolderPath/tg_docker.sh > $FolderPath/tg_docker.log 2>&1 &") | crontab -
            fi
            # ShowContents "$FolderPath/tg_docker.sh"
            if [ "$mute" != "true" ]; then
                send_telegram_message "设置成功: Docker 变更通知⚙️"$'\n'"主机名: $(hostname)"$'\n'"💡当 Docker 列表变更时将收到通知."
            fi
            echo -e "$Inf Docker 通知已经设置成功, 当 Dokcer 挂载发生变化时你的 Telgram 将收到通知."
            delini "reDockerSet"
        else
            echo -e "$Err 参数丢失, 请设置后再执行 (先执行 ${GR}0${NC} 选项)."
        fi
    else
        echo -e "$Err 未检测到 \"Docker\" 程序."
    fi
}

CheckCPU_top() {
    echo "正在检测 CPU 使用率..."
    cpu_usage_ratio=$(awk '{ gsub(/us,|sy,|ni,|id,|:/, " ", $0); idle+=$5; count++ } END { printf "%.0f", 100 - (idle / count) }' <(grep "Cpu(s)" <(top -bn5 -d 3)))
    echo "top检测结果: $cpu_usage_ratio | 日期: $(date)"
}

CheckCPU_sar() {
    echo "正在检测 CPU 使用率..."
    cpu_usage_ratio=$(sar -u 3 5 | awk '/^Average:/ { printf "%.0f\n", 100 - $NF }')
    echo "sar检测结果: $cpu_usage_ratio | 日期: $(date)"
}

CheckCPU_top_sar() {
    echo "正在检测 CPU 使用率..."
    cpu_usage_sar=$(sar -u 3 5 | awk '/^Average:/ { printf "%.0f\n", 100 - $NF }')
    cpu_usage_top=$(awk '{ gsub(/us,|sy,|ni,|id,|:/, " ", $0); idle+=$5; count++ } END { printf "%.0f", 100 - (idle / count) }' <(grep "Cpu(s)" <(top -bn5 -d 3)))
    cpu_usage_ratio=$(awk -v sar="$cpu_usage_sar" -v top="$cpu_usage_top" 'BEGIN { printf "%.0f\n", (sar + top) / 2 }')
    echo "sar检测结果: $cpu_usage_sar | top检测结果: $cpu_usage_top | 平均值: $cpu_usage_ratio | 日期: $(date)"
}

# 获取系统信息
GetInfo_now() {
    echo "正在获取系统信息..."
    # top_output=$(top -bn1)
    top_output=$(top -n 1 -b | head -n 10)
    echo "top: $top_output"
    if echo "$top_output" | grep -q "^%Cpu"; then
        top -V
        top_output_h=$(echo "$top_output" | awk 'NR > 7')
        cpu_h1=$(echo "$top_output_h" | awk 'NR == 1 || $9 > max { max = $9; process = $NF } END { print process }')
        cpu_h2=$(echo "$top_output_h" | awk 'NR == 2 || $9 > max { max = $9; process = $NF } END { print process }')
        mem_total=$(echo "$top_output" | awk '/^MiB Mem/ { gsub(/Mem|total,|free,|used,|buff\/cache|:/, " ", $0); print int($2) }')
        mem_used=$(echo "$top_output" | awk '/^MiB Mem/ { gsub(/Mem|total,|free,|used,|buff\/cache|:/, " ", $0); print int($4) }')
        mem_use_ratio=$(awk -v used="$mem_used" -v total="$mem_total" 'BEGIN { printf "%.0f\n", ( used / total ) * 100 }')
        swap_total=$(echo "$top_output" | awk '/^MiB Swap/ { gsub(/Swap|total,|free,|used,|buff\/cache|:/, " ", $0); print int($2) }')
        swap_used=$(echo "$top_output" | awk '/^MiB Swap/ { gsub(/Swap|total,|free,|used,|buff\/cache|:/, " ", $0); print int($4) }')
        swap_use_ratio=$(awk -v used="$swap_used" -v total="$swap_total" 'BEGIN { printf "%.0f\n", ( used / total ) * 100 }')
    elif echo "$top_output" | grep -q "^CPU"; then
        top -V
        top_output_h=$(echo "$top_output" | awk 'NR > 4')
        cpu_h1=$(echo "$top_output_h" | awk 'NR == 1 || $7 > max { max = $7; process = $NF } END { print process }' | awk '{print $1}')
        cpu_h2=$(echo "$top_output_h" | awk 'NR == 2 || $7 > max { max = $7; process = $NF } END { print process }' | awk '{print $1}')
        mem_used=$(echo "$top_output" | awk '/^Mem/ { gsub(/K|used,|free,|shrd,|buff,|cached|:/, " ", $0); printf "%.0f", $2 / 1024 }')
        mem_free=$(echo "$top_output" | awk '/^Mem/ { gsub(/K|used,|free,|shrd,|buff,|cached|:/, " ", $0); printf "%.0f", $3 / 1024 }')
        # mem_total=$(awk "BEGIN { print $mem_used + $mem_free }") # 支持浮点计算,上面已经采用printf "%.0f"取整,所以使用下行即可
        mem_total=$((mem_used + mem_free))
        swap_total=""
        swap_used=""
        swap_use_ratio=""
    else
        echo "top 指令获取信息失败."
    fi
    disk_total=$(df -h / | awk 'NR==2 {print $2}')
    disk_used=$(df -h / | awk 'NR==2 {print $3}')
    disk_use_ratio=$(df -h / | awk 'NR==2 {gsub("%", "", $5); print $5}')
    echo "内存使用率: $mem_use_ratio | 交换使用率: $swap_use_ratio | 磁盘使用率: $disk_use_ratio | 日期: $(date)"
}

# 判断子程序
Setupbody() {
    echo "计划中..."
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
        # if [[ $percentage -lt 10 ]]; then
        #     used_count=1
        # elif [[ $percentage -eq 100 ]]; then
        #     used_count=10
        # else
        #     used_count=${percentage:0:1}
        # fi
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

# 设置CPU报警
SetupCPU_TG() {
    if [[ ! -z "${TelgramBotToken}" &&  ! -z "${ChatID_1}" &&  ! -z "${CPUThreshold}" &&  ! -z "${CPUTools}" ]]; then
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

$(declare -f CheckCPU_$CPUTools)
$(declare -f GetInfo_now)
$(declare -f create_progress_bar)
count=0
while true; do
    SleepTime=900
    CheckCPU_$CPUTools
    if (( cpu_usage_ratio > $CPUThreshold )); then
        (( count++ ))
    else
        count=0
    fi
    if (( count >= 3 )); then

        # 获取并计算其它参数
        GetInfo_now

        cpu_usage_progress=\$(create_progress_bar "\$cpu_usage_ratio")
        return_code=\$?
        if [ \$return_code -eq 1 ]; then
            cpu_usage_progress="🚫"
            cpu_usage_ratio=""
        else
            cpu_usage_ratio=\${cpu_usage_ratio}%
        fi

        mem_use_progress=\$(create_progress_bar "\$mem_use_ratio")
        return_code=\$?
        if [ \$return_code -eq 1 ]; then
            mem_use_progress="🚫"
            mem_use_ratio=""
        else
            mem_use_ratio=\${mem_use_ratio}%
        fi

        swap_use_progress=\$(create_progress_bar "\$swap_use_ratio")
        return_code=\$?
        if [ \$return_code -eq 1 ]; then
            swap_use_progress="🚫"
            swap_use_ratio=""
        else
            swap_use_ratio=\${swap_use_ratio}%
        fi

        disk_use_progress=\$(create_progress_bar "\$disk_use_ratio")
        return_code=\$?
        if [ \$return_code -eq 1 ]; then
            disk_use_progress="🚫"
            disk_use_ratio=""
        else
            disk_use_ratio=\${disk_use_ratio}%
        fi

        message="CPU 使用率超过阀值 > $CPUThreshold%❗️"'
'"主机名: \$(hostname)"'
'"CPU: \$cpu_usage_progress \$cpu_usage_ratio"'
'"内存: \$mem_use_progress \$mem_use_ratio"'
'"交换: \$swap_use_progress \$swap_use_ratio"'
'"磁盘: \$disk_use_progress \$disk_use_ratio"'
'"使用率排行:"'
'"🧨  \$cpu_h1"'
'"🧨  \$cpu_h2"'
'"检测工具: $CPUTools"'
'"休眠时间: \$((SleepTime / 60))分钟"
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
        pkill tg_cpu.sh
        pkill tg_cpu.sh
        nohup $FolderPath/tg_cpu.sh > $FolderPath/tg_cpu.log 2>&1 &
        if ! crontab -l | grep -q "@reboot nohup $FolderPath/tg_cpu.sh > $FolderPath/tg_cpu.log 2>&1 &"; then
            (crontab -l 2>/dev/null; echo "@reboot nohup $FolderPath/tg_cpu.sh > $FolderPath/tg_cpu.log 2>&1 &") | crontab -
        fi
        # ShowContents "$FolderPath/tg_cpu.sh"
        if [ "$mute" != "true" ]; then
            send_telegram_message "设置成功: CPU 报警通知⚙️"'
'"主机名: $(hostname)"'
'"CPU: $cpuusedOfcpus"'
'"内存: ${mem_total}MB"'
'"交换: ${swap_total}MB"'
'"磁盘: ${disk_total}B     已使用: ${disk_used}B"'
'"检测工具: $CPUTools"'
'"💡当 CPU 使用达 $CPUThreshold % 时将收到通知."
        fi
        echo -e "$Inf CPU 通知已经设置成功, 当 CPU 使用率达到 $CPUThreshold % 时将收到通知."
        delini "reCPUSet"
    else
        echo -e "$Err 参数丢失, 请设置后再执行 (先执行 ${GR}0${NC} 选项)."
    fi
}

# 设置内存报警
SetupMEM_TG() {
    if [[ ! -z "${TelgramBotToken}" &&  ! -z "${ChatID_1}" &&  ! -z "${MEMThreshold}" &&  ! -z "${CPUTools}" ]]; then
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

$(declare -f CheckCPU_$CPUTools)
$(declare -f GetInfo_now)
$(declare -f create_progress_bar)
count=0
while true; do
    SleepTime=900
    GetInfo_now
    if (( mem_use_ratio > $MEMThreshold )); then
        (( count++ ))
    else
        count=0
    fi
    if (( count >= 3 )); then

        # 获取并计算其它参数
        CheckCPU_$CPUTools

        cpu_usage_progress=\$(create_progress_bar "\$cpu_usage_ratio")
        return_code=\$?
        if [ \$return_code -eq 1 ]; then
            cpu_usage_progress="🚫"
            cpu_usage_ratio=""
        else
            cpu_usage_ratio=\${cpu_usage_ratio}%
        fi

        mem_use_progress=\$(create_progress_bar "\$mem_use_ratio")
        return_code=\$?
        if [ \$return_code -eq 1 ]; then
            mem_use_progress="🚫"
            mem_use_ratio=""
        else
            mem_use_ratio=\${mem_use_ratio}%
        fi

        swap_use_progress=\$(create_progress_bar "\$swap_use_ratio")
        return_code=\$?
        if [ \$return_code -eq 1 ]; then
            swap_use_progress="🚫"
            swap_use_ratio=""
        else
            swap_use_ratio=\${swap_use_ratio}%
        fi

        disk_use_progress=\$(create_progress_bar "\$disk_use_ratio")
        return_code=\$?
        if [ \$return_code -eq 1 ]; then
            disk_use_progress="🚫"
            disk_use_ratio=""
        else
            disk_use_ratio=\${disk_use_ratio}%
        fi

        message="内存 使用率超过阀值 > $MEMThreshold%❗️"'
'"主机名: \$(hostname)"'
'"CPU: \$cpu_usage_progress \$cpu_usage_ratio"'
'"内存: \$mem_use_progress \$mem_use_ratio"'
'"交换: \$swap_use_progress \$swap_use_ratio"'
'"磁盘: \$disk_use_progress \$disk_use_ratio"'
'"使用率排行:"'
'"🧨  \$cpu_h1"'
'"🧨  \$cpu_h2"'
'"检测工具: $CPUTools"'
'"休眠时间: \$((SleepTime / 60))分钟"
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
        pkill tg_mem.sh
        pkill tg_mem.sh
        nohup $FolderPath/tg_mem.sh > $FolderPath/tg_mem.log 2>&1 &
        if ! crontab -l | grep -q "@reboot nohup $FolderPath/tg_mem.sh > $FolderPath/tg_mem.log 2>&1 &"; then
            (crontab -l 2>/dev/null; echo "@reboot nohup $FolderPath/tg_mem.sh > $FolderPath/tg_mem.log 2>&1 &") | crontab -
        fi
        # ShowContents "$FolderPath/tg_mem.sh"
        if [ "$mute" != "true" ]; then
            send_telegram_message "设置成功: 内存 报警通知⚙️"'
'"主机名: $(hostname)"'
'"CPU: $cpuusedOfcpus"'
'"内存: ${mem_total}MB"'
'"交换: ${swap_total}MB"'
'"磁盘: ${disk_total}B     已使用: ${disk_used}B"'
'"检测工具: $CPUTools"'
'"💡当 内存 使用达 $MEMThreshold % 时将收到通知."
        fi
        echo -e "$Inf 内存 通知已经设置成功, 当 内存 使用率达到 $MEMThreshold % 时将收到通知."
        delini "reMEMSet"
    else
        echo -e "$Err 参数丢失, 请设置后再执行 (先执行 ${GR}0${NC} 选项)."
    fi
}

# 设置磁盘报警
SetupDISK_TG() {
    if [[ ! -z "${TelgramBotToken}" &&  ! -z "${ChatID_1}" &&  ! -z "${DISKThreshold}" &&  ! -z "${CPUTools}" ]]; then
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

$(declare -f CheckCPU_$CPUTools)
$(declare -f GetInfo_now)
$(declare -f create_progress_bar)
count=0
while true; do
    SleepTime=900
    GetInfo_now
    if (( mem_use_ratio > $DISKThreshold )); then
        (( count++ ))
    else
        count=0
    fi
    if (( count >= 3 )); then

        # 获取并计算其它参数
        CheckCPU_$CPUTools

        cpu_usage_progress=\$(create_progress_bar "\$cpu_usage_ratio")
        return_code=\$?
        if [ \$return_code -eq 1 ]; then
            cpu_usage_progress="🚫"
            cpu_usage_ratio=""
        else
            cpu_usage_ratio=\${cpu_usage_ratio}%
        fi

        mem_use_progress=\$(create_progress_bar "\$mem_use_ratio")
        return_code=\$?
        if [ \$return_code -eq 1 ]; then
            mem_use_progress="🚫"
            mem_use_ratio=""
        else
            mem_use_ratio=\${mem_use_ratio}%
        fi

        swap_use_progress=\$(create_progress_bar "\$swap_use_ratio")
        return_code=\$?
        if [ \$return_code -eq 1 ]; then
            swap_use_progress="🚫"
            swap_use_ratio=""
        else
            swap_use_ratio=\${swap_use_ratio}%
        fi

        disk_use_progress=\$(create_progress_bar "\$disk_use_ratio")
        return_code=\$?
        if [ \$return_code -eq 1 ]; then
            disk_use_progress="🚫"
            disk_use_ratio=""
        else
            disk_use_ratio=\${disk_use_ratio}%
        fi

        message="磁盘 使用率超过阀值 > $DISKThreshold%❗️"'
'"主机名: \$(hostname)"'
'"CPU: \$cpu_usage_progress \$cpu_usage_ratio"'
'"内存: \$mem_use_progress \$mem_use_ratio"'
'"交换: \$swap_use_progress \$swap_use_ratio"'
'"磁盘: \$disk_use_progress \$disk_use_ratio"'
'"使用率排行:"'
'"🧨  \$cpu_h1"'
'"🧨  \$cpu_h2"'
'"检测工具: $CPUTools"'
'"休眠时间: \$((SleepTime / 60))分钟"
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
        pkill tg_disk.sh
        pkill tg_disk.sh
        nohup $FolderPath/tg_disk.sh > $FolderPath/tg_disk.log 2>&1 &
        if ! crontab -l | grep -q "@reboot nohup $FolderPath/tg_disk.sh > $FolderPath/tg_disk.log 2>&1 &"; then
            (crontab -l 2>/dev/null; echo "@reboot nohup $FolderPath/tg_disk.sh > $FolderPath/tg_disk.log 2>&1 &") | crontab -
        fi
        # ShowContents "$FolderPath/tg_disk.sh"
        if [ "$mute" != "true" ]; then
            send_telegram_message "设置成功: 磁盘 报警通知⚙️"'
'"主机名: $(hostname)"'
'"CPU: $cpuusedOfcpus"'
'"内存: ${mem_total}MB"'
'"交换: ${swap_total}MB"'
'"磁盘: ${disk_total}B     已使用: ${disk_used}B"'
'"检测工具: $CPUTools"'
'"💡当 磁盘 使用达 $DISKThreshold % 时将收到通知."
        fi
        echo -e "$Inf 磁盘 通知已经设置成功, 当 磁盘 使用率达到 $DISKThreshold % 时将收到通知."
        delini "reDISKSet"
    else
        echo -e "$Err 参数丢失, 请设置后再执行 (先执行 ${GR}0${NC} 选项)."
    fi
}

# 设置流量报警
SetupFlow_TG() {
    if [[ ! -z "${TelgramBotToken}" &&  ! -z "${ChatID_1}" &&  ! -z "${FlowThreshold}" &&  ! -z "${FlowThresholdMAX}" ]]; then
        # FlowThreshold=500
        FlowThreshold_U=$FlowThreshold
        if [[ $FlowThreshold == *MB ]]; then
            FlowThreshold=${FlowThreshold%MB}
            FlowThreshold=$(awk -v value=$FlowThreshold 'BEGIN { printf "%.1f", value }')
        elif [[ $FlowThreshold == *GB ]]; then
            FlowThreshold=${FlowThreshold%GB}
            FlowThreshold=$(awk -v value=$FlowThreshold 'BEGIN { printf "%.1f", value*1024 }')
        elif [[ $FlowThreshold == *TB ]]; then
            FlowThreshold=${FlowThreshold%TB}
            FlowThreshold=$(awk -v value=$FlowThreshold 'BEGIN { printf "%.1f", value*1024*1024 }')
        fi
        FlowThresholdMAX_U=$FlowThresholdMAX
        if [[ $FlowThresholdMAX == *MB ]]; then
            FlowThresholdMAX=${FlowThresholdMAX%MB}
            FlowThresholdMAX=$(awk -v value=$FlowThresholdMAX 'BEGIN { printf "%.1f", value }')
        elif [[ $FlowThresholdMAX == *GB ]]; then
            FlowThresholdMAX=${FlowThresholdMAX%GB}
            FlowThresholdMAX=$(awk -v value=$FlowThresholdMAX 'BEGIN { printf "%.1f", value*1024 }')
        elif [[ $FlowThresholdMAX == *TB ]]; then
            FlowThresholdMAX=${FlowThresholdMAX%TB}
            FlowThresholdMAX=$(awk -v value=$FlowThresholdMAX 'BEGIN { printf "%.1f", value*1024*1024 }')
        fi
        cat <<EOF > $FolderPath/tg_flow.sh
#!/bin/bash

$(declare -f create_progress_bar)
# 流量阈值设置 (MB)
# FlowThreshold=500
# FlowThresholdMAX=1024
tt=10

# THRESHOLD_BYTES=\$((FlowThreshold * 1024 * 1024)) # 仅支持整数计算 (已经被下现一行代码替换)
THRESHOLD_BYTES=$(awk "BEGIN {print $FlowThreshold * 1024 * 1024}")

# 获取所有活动网络接口（排除lo本地接口）
interfaces=\$(ip -br link | awk '\$2 == "UP" {print \$1}' | grep -v "lo")

# 初始化字典存储前一个状态的流量数据
declare -A prev_rx_data
declare -A prev_tx_data

# 初始化接口流量数据
for interface in \$interfaces; do
    # 如果接口名称中包含 '@'，则仅保留 '@' 之前的部分
    sanitized_interface=\${interface%@*}

    rx_bytes=\$(ip -s link show \$sanitized_interface | awk '/RX:/ { getline; print \$1 }')
    tx_bytes=\$(ip -s link show \$sanitized_interface | awk '/TX:/ { getline; print \$1 }')
    prev_rx_data[\$sanitized_interface]=\$rx_bytes
    prev_tx_data[\$sanitized_interface]=\$tx_bytes
done

# 循环检查
while true; do
    for interface in \$interfaces; do
        # 如果接口名称中包含 '@'，则仅保留 '@' 之前的部分
        sanitized_interface=\${interface%@*}

        # 获取当前流量数据
        current_rx_bytes=\$(ip -s link show \$sanitized_interface | awk '/RX:/ { getline; print \$1 }')
        current_tx_bytes=\$(ip -s link show \$sanitized_interface | awk '/TX:/ { getline; print \$1 }')
        
        all_rx_mb=\$((current_rx_bytes / 1024 / 1024))
        all_rx_ratio=\$(awk -v used="\$all_rx_mb" -v total="$FlowThresholdMAX" 'BEGIN { printf "%.0f\n", ( used / total ) * 100 }')
        if awk -v ratio="\$all_rx_ratio" 'BEGIN { exit !(ratio < 1) }'; then
            all_rx_ratio=1
            all_rx_lessone=true
        fi
        all_rx_progress=\$(create_progress_bar "\$all_rx_ratio")
        return_code=\$?
        if [ \$return_code -eq 1 ]; then
            all_rx_progress="🚫"
            all_rx_ratio=""
        else
            if [ "\$all_rx_lessone" == "true" ]; then
                all_rx_ratio=🔽\${all_rx_ratio}%
            else
                all_rx_ratio=\${all_rx_ratio}%
            fi
        fi

        if [ "\$all_rx_mb" -gt 1023 ]; then
            all_rx_mb=\$(awk -v value=\$all_rx_mb 'BEGIN{printf "%.1f", value/1024}')
            all_rx_mb="\${all_rx_mb}GB" 
        else
            all_rx_mb="\${all_rx_mb}MB"
        fi

        all_tx_mb=\$((current_tx_bytes / 1024 / 1024))
        all_tx_ratio=\$(awk -v used="\$all_tx_mb" -v total="$FlowThresholdMAX" 'BEGIN { printf "%.0f\n", ( used / total ) * 100 }')
        if awk -v ratio="\$all_tx_ratio" 'BEGIN { exit !(ratio < 1) }'; then
            all_tx_ratio=1
            all_tx_lessone=true
        fi
        all_tx_progress=\$(create_progress_bar "\$all_tx_ratio")
        return_code=\$?
        if [ \$return_code -eq 1 ]; then
            all_tx_progress="🚫"
            all_tx_ratio=""
        else
            if [ "\$all_tx_lessone" == "true" ]; then
                all_tx_ratio=🔽\${all_tx_ratio}%
            else
                all_tx_ratio=\${all_tx_ratio}%
            fi
        fi

        if [ "\$all_tx_mb" -gt 1023 ]; then
            all_tx_mb=\$(awk -v value=\$all_tx_mb 'BEGIN{printf "%.1f", value/1024}')
            all_tx_mb="\${all_tx_mb}GB" 
        else
            all_tx_mb="\${all_tx_mb}MB"
        fi

        # 计算增量
        rx_diff=\$((current_rx_bytes - prev_rx_data[\$sanitized_interface]))
        tx_diff=\$((current_tx_bytes - prev_tx_data[\$sanitized_interface]))

        # 调试使用(tt秒的流量增量)
        echo "Interface: \$sanitized_interface RX_diff(BYTES): \$rx_diff TX_diff(BYTES): \$tx_diff"

        # 调试使用(持续的流量增加)
        echo "Interface: \$sanitized_interface Current_RX(BYTES): \$current_rx_bytes Current_TX(BYTES): \$current_tx_bytes"

        # 检查是否超过阈值
        # if [ \$rx_diff -ge \$THRESHOLD_BYTES ] || [ \$tx_diff -ge \$THRESHOLD_BYTES ]; then # 仅支持整数计算 (已经被下面两行代码替换)
        threshold_reached=\$(awk -v rx_diff="\$rx_diff" -v tx_diff="\$tx_diff" -v threshold="\$THRESHOLD_BYTES" 'BEGIN {print (rx_diff >= threshold) || (tx_diff >= threshold) ? 1 : 0}')
        if [ "\$threshold_reached" -eq 1 ]; then
            rx_mb=\$((rx_diff / 1024 / 1024))
            if [ "\$rx_mb" -gt 1023 ]; then
                rx_mb=\$(awk -v value=\$rx_mb 'BEGIN{printf "%.1f", value/1024}')
                rx_mb="\${rx_mb}GB" 
            else
                rx_mb="\${rx_mb}MB"
            fi
            tx_mb=\$((tx_diff / 1024 / 1024))
            if [ "\$tx_mb" -gt 1023 ]; then
                tx_mb=\$(awk -v value=\$tx_mb 'BEGIN{printf "%.1f", value/1024}')
                tx_mb="\${tx_mb}GB" 
            else
                tx_mb="\${tx_mb}MB"
            fi
            if [ ! -z "\${prev_tt_rx_data[\$sanitized_interface]}" ]; then
                rx_diff_tt=\$((current_rx_bytes - prev_tt_rx_data[\$sanitized_interface]))
            else
                rx_diff_tt=0
            fi
            if [ ! -z "\${prev_tt_tx_data[\$sanitized_interface]}" ]; then
                tx_diff_tt=\$((current_tx_bytes - prev_tt_tx_data[\$sanitized_interface]))
            else
                tx_diff_tt=0
            fi

            rx_speed=\$(awk "BEGIN { speed = \$rx_diff_tt / (\$tt * 1024); if (speed > 1023) { printf \"%.1fMB\", speed/1024 } else { printf \"%.1fKB\", speed } }")
            tx_speed=\$(awk "BEGIN { speed = \$tx_diff_tt / (\$tt * 1024); if (speed > 1023) { printf \"%.1fMB\", speed/1024 } else { printf \"%.1fKB\", speed } }")

            message="流量已达到阀值 > $FlowThreshold_U%❗️"'
'"主机名: \$(hostname) 端口: \$sanitized_interface"'
'"已接收: \${rx_mb}  已发送: \${tx_mb}"'
'"总接收: \${all_rx_mb}  总发送: \${all_tx_mb}"'
'"使用⬇️: \$all_rx_progress \$all_rx_ratio"'
'"使用⬆️: \$all_tx_progress \$all_tx_ratio"'
'"网络⬇️: \${rx_speed}  网络⬆️: \${tx_speed}"
            curl -s -X POST "https://api.telegram.org/bot$TelgramBotToken/sendMessage" \
                -d chat_id="$ChatID_1" -d text="\$message"

            # 更新前一个状态的流量数据
            prev_rx_data[\$sanitized_interface]=\$current_rx_bytes
            prev_tx_data[\$sanitized_interface]=\$current_tx_bytes
        fi

        # 把当前的流量数据保存到一个变量用于计算速率
        prev_tt_rx_data[\$sanitized_interface]=\$current_rx_bytes
        prev_tt_tx_data[\$sanitized_interface]=\$current_tx_bytes
    done

    # 等待tt秒
    sleep \$tt
done
EOF
        chmod +x $FolderPath/tg_flow.sh
        pkill tg_flow.sh
        pkill tg_flow.sh
        nohup $FolderPath/tg_flow.sh > $FolderPath/tg_flow.log 2>&1 &
        if ! crontab -l | grep -q "@reboot nohup $FolderPath/tg_flow.sh > $FolderPath/tg_flow.log 2>&1 &"; then
            (crontab -l 2>/dev/null; echo "@reboot nohup $FolderPath/tg_flow.sh > $FolderPath/tg_flow.log 2>&1 &") | crontab -
        fi
        # ShowContents "$FolderPath/tg_flow.sh"
        if [ "$mute" != "true" ]; then
            send_telegram_message "设置成功: 流量 报警通知⚙️"$'\n'"主机名: $(hostname)"$'\n'"💡当流量达阀值 $FlowThreshold_U 时将收到通知."
        fi
        echo -e "$Inf 流量 通知已经设置成功, 当流量使用达到 $FlowThreshold_U 时将收到通知."
        delini "reFlowSet"
    else
        echo -e "$Err 参数丢失, 请设置后再执行 (先执行 ${GR}0${NC} 选项)."
    fi
}

# 卸载
UnsetupAll() {
    while true; do
    CheckSetup
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
  
 取消 / 删除 模式
———————————————————————
 ${GR}1.${NC} ${RE}取消${NC} ${GR}[开机]${NC} Telgram 通知 \t\t\t${GR}$boot_menu_tag${NC}
 ${GR}2.${NC} ${RE}取消${NC} ${GR}[登陆]${NC} Telgram 通知 \t\t\t${GR}$login_menu_tag${NC}
 ${GR}3.${NC} ${RE}取消${NC} ${GR}[关机]${NC} Telgram 通知 \t\t\t${GR}$shutdown_menu_tag${NC}
 ${GR}4.${NC} ${RE}取消${NC} ${GR}[CPU 报警]${NC} Telgram 通知 ${REB}阀值${NC}: $CPUThreshold_tag \t${GR}$cpu_menu_tag${NC}
 ${GR}5.${NC} ${RE}取消${NC} ${GR}[内存报警]${NC} Telgram 通知 ${REB}阀值${NC}: $MEMThreshold_tag \t${GR}$mem_menu_tag${NC}
 ${GR}6.${NC} ${RE}取消${NC} ${GR}[磁盘报警]${NC} Telgram 通知 ${REB}阀值${NC}: $DISKThreshold_tag \t${GR}$disk_menu_tag${NC}
 ${GR}7.${NC} ${RE}取消${NC} ${GR}[流量报警]${NC} Telgram 通知 ${REB}阀值${NC}: $FlowThreshold_tag \t${GR}$flow_menu_tag${NC}
 ${GR}8.${NC} ${RE}取消${NC} ${GR}[Docker 变更]${NC} Telgram 通知 \t\t${GR}$docker_menu_tag${NC}
 ———————————————————————————————————————————————————————
 ${GR}a.${NC} ${RE}取消所有${NC} Telgram 通知
 ——————————————————————————————————————
 ${GR}f.${NC} ${RE}删除${NC} 脚本文件夹 \t${GR}$folder_menu_tag${NC}
 ——————————————————————————————————————
 ${GR}b.${NC} 返回 普通模式
 ——————————————————————————————————————
 ${GR}x.${NC} 退出脚本
————————————
$Tip 使用前请先执行 ${GR}0${NC} 确保依赖完整并完成相关参数设置." && echo
    read -e -p "请输入选项 [0-6|a|f|b|x]:" num
    case "$num" in
        1) # 开机
        if [ "$boot_menu_tag" == "-> 已设置" ]; then
            systemctl stop tg_boot.service > /dev/null 2>&1
            systemctl disable tg_boot.service > /dev/null 2>&1
            sleep 1
            rm -f /etc/systemd/system/tg_boot.service
            boot_menu_tag=""
            delini "reBootSet"
            # echo "已经取消 / 删除."
            # Pause
        fi
        ;;
        2) # 登陆
        if [ "$login_menu_tag" == "-> 已设置" ]; then
            if [ -f /etc/bash.bashrc ]; then
                sed -i '/bash \/root\/.shfile\/tg_login.sh/d' /etc/bash.bashrc
            fi
            if [ -f /etc/profile ]; then
                sed -i '/bash \/root\/.shfile\/tg_login.sh/d' /etc/profile
            fi
            login_menu_tag=""
            delini "reLoginSet"
            # echo "已经取消 / 删除."
            # Pause
        fi
        ;;
        3) # 关机
        if [ "$shutdown_menu_tag" == "-> 已设置" ]; then
            systemctl stop tg_shutdown.service > /dev/null 2>&1
            systemctl disable tg_shutdown.service > /dev/null 2>&1
            sleep 1
            rm -f /etc/systemd/system/tg_shutdown.service
            shutdown_menu_tag=""
            delini "reShutdownSet"
            # echo "已经取消 / 删除."
            # Pause
        fi
        ;;
        4) # CPU 报警
        if [ "$cpu_menu_tag" == "-> 已设置" ]; then
            pkill tg_cpu.sh
            pkill tg_cpu.sh
            crontab -l | grep -v "@reboot nohup $FolderPath/tg_cpu.sh > $FolderPath/tg_cpu.log 2>&1 &" | crontab -
            cpu_menu_tag=""
            delini "reCPUSet"
            # echo "已经取消 / 删除."
            # Pause
        fi
        ;;
        5) # 内存报警
        if [ "$mem_menu_tag" == "-> 已设置" ]; then
            pkill tg_mem.sh
            pkill tg_mem.sh
            crontab -l | grep -v "@reboot nohup $FolderPath/tg_mem.sh > $FolderPath/tg_mem.log 2>&1 &" | crontab -
            mem_menu_tag=""
            delini "reMEMSet"
            # echo "已经取消 / 删除."
            # Pause
        fi
        ;;
        6) # 磁盘报警
        if [ "$disk_menu_tag" == "-> 已设置" ]; then
            pkill tg_disk.sh
            pkill tg_disk.sh
            crontab -l | grep -v "@reboot nohup $FolderPath/tg_disk.sh > $FolderPath/tg_disk.log 2>&1 &" | crontab -
            disk_menu_tag=""
            delini "reDISKSet"
            # echo "已经取消 / 删除."
            # Pause
        fi
        ;;
        7) # 流量 报警
        if [ "$flow_menu_tag" == "-> 已设置" ]; then
            pkill tg_flow.sh
            pkill tg_flow.sh
            crontab -l | grep -v "@reboot nohup $FolderPath/tg_flow.sh > $FolderPath/tg_flow.log 2>&1 &" | crontab -
            flow_menu_tag=""
            delini "reFlowSet"
            # echo "已经取消 / 删除."
            # Pause
        fi
        ;;
        8) # Docker 提示
        if [ "$docker_menu_tag" == "-> 已设置" ]; then
            pkill tg_docker.sh
            pkill tg_docker.sh
            crontab -l | grep -v "@reboot nohup $FolderPath/tg_docker.sh > $FolderPath/tg_docker.log 2>&1 &" | crontab -
            docker_menu_tag=""
            delini "reDockerSet"
            # echo "已经取消 / 删除."
            # Pause
        fi
        ;;
        a|A)
        untag=false
        if [ "$boot_menu_tag" == "-> 已设置" ]; then
            systemctl stop tg_boot.service > /dev/null 2>&1
            systemctl disable tg_boot.service > /dev/null 2>&1
            sleep 1
            rm -f /etc/systemd/system/tg_boot.service
            boot_menu_tag=""
            untag=true
        fi
        if [ "$login_menu_tag" == "-> 已设置" ]; then
            if [ -f /etc/bash.bashrc ]; then
                sed -i '/bash \/root\/.shfile\/tg_login.sh/d' /etc/bash.bashrc
            fi
            if [ -f /etc/profile ]; then
                sed -i '/bash \/root\/.shfile\/tg_login.sh/d' /etc/profile
            fi
            login_menu_tag=""
            untag=true
        fi
        if [ "$shutdown_menu_tag" == "-> 已设置" ]; then
            systemctl stop tg_shutdown.service > /dev/null 2>&1
            systemctl disable tg_shutdown.service > /dev/null 2>&1
            sleep 1
            rm -f /etc/systemd/system/tg_shutdown.service
            shutdown_menu_tag=""
            untag=true
        fi
        if [ "$cpu_menu_tag" == "-> 已设置" ]; then
            pkill tg_cpu.sh
            pkill tg_cpu.sh
            crontab -l | grep -v "@reboot nohup $FolderPath/tg_cpu.sh > $FolderPath/tg_cpu.log 2>&1 &" | crontab -
            cpu_menu_tag=""
            untag=true
        fi
        if [ "$mem_menu_tag" == "-> 已设置" ]; then
            pkill tg_mem.sh
            pkill tg_mem.sh
            crontab -l | grep -v "@reboot nohup $FolderPath/tg_mem.sh > $FolderPath/tg_mem.log 2>&1 &" | crontab -
            mem_menu_tag=""
            untag=true
        fi
        if [ "$disk_menu_tag" == "-> 已设置" ]; then
            pkill tg_disk.sh
            pkill tg_disk.sh
            crontab -l | grep -v "@reboot nohup $FolderPath/tg_disk.sh > $FolderPath/tg_disk.log 2>&1 &" | crontab -
            disk_menu_tag=""
            untag=true
        fi
        if [ "$flow_menu_tag" == "-> 已设置" ]; then
            pkill tg_flow.sh
            pkill tg_flow.sh
            crontab -l | grep -v "@reboot nohup $FolderPath/tg_flow.sh > $FolderPath/tg_flow.log 2>&1 &" | crontab -
            flow_menu_tag=""
            untag=true
        fi
        if [ "$docker_menu_tag" == "-> 已设置" ]; then
            pkill tg_docker.sh
            pkill tg_docker.sh
            crontab -l | grep -v "@reboot nohup $FolderPath/tg_docker.sh > $FolderPath/tg_docker.log 2>&1 &" | crontab -
            docker_menu_tag=""
            untag=true
        fi
        if [ "$untag" == "true" ]; then
            delini "reBootSet"
            delini "reLoginSet"
            delini "reShutdownSet"
            delini "reCPUSet"
            delini "reMEMSet"
            delini "reDISKSet"
            delini "reFlowSet"
            delini "reDockerSet"
            echo -e "$Tip 已取消 / 删除所有通知."
            Pause
        fi
        ;;
        f|F)
        if [ "$boot_menu_tag" == "" ] && [ "$login_menu_tag" == "" ] && [ "$shutdown_menu_tag" == "" ] && [ "$cpu_menu_tag" == "" ] && [ "$mem_menu_tag" == "" ] && [ "$disk_menu_tag" == "" ] && [ "$flow_menu_tag" == "" ] && [ "$docker_menu_tag" == "" ]; then
            if [ -d "$FolderPath" ]; then
                read -p "是否要删除 $FolderPath 文件夹? (建议保留) Y/其它 : " yorn
                if [ "$yorn" == "Y" ] || [ "$yorn" == "y" ]; then
                    rm -rf $FolderPath
                    folder_menu_tag=""
                    echo -e "$Tip $FolderPath 文件夹已经删除."
                else
                    echo -e "$Tip $FolderPath 文件夹已经保留."
                fi
            fi
        else
            echo -e "$Err 请先取消所有通知后再删除文件夹."
        fi
        Pause
        ;;
        b|B)
        break
        ;;
        x|X)
        exit 0
        ;;
        *)
        echo "请输入正确数字 [0-6|a|f|b|x]"
        ;;
    esac
    done    
}

# 主程序
CheckSys
if [ "$1" == "auto" ]; then
    if [ "$2" == "mute" ]; then
        mute=true
    fi
    echo "自动模式..."
    CheckAndCreateFolder
    CheckSetup
    GetVPSInfo
    if [ "$boot_menu_tag" == "-> 已设置" ]; then
        SetupBoot_TG
    fi
    if [ "$login_menu_tag" == "-> 已设置" ]; then
        SetupLogin_TG
    fi
    if [ "$shutdown_menu_tag" == "-> 已设置" ]; then
        SetupShutdown_TG
    fi
    if [ "$cpu_menu_tag" == "-> 已设置" ]; then
        SetupCPU_TG
    fi
    if [ "$mem_menu_tag" == "-> 已设置" ]; then
        SetupMEM_TG
    fi
    if [ "$disk_menu_tag" == "-> 已设置" ]; then
        SetupDISK_TG
    fi
    if [ "$flow_menu_tag" == "-> 已设置" ]; then
        SetupFlow_TG
    fi
    if [ "$docker_menu_tag" == "-> 已设置" ]; then
        SetupDocker_TG
    fi
    echo "自动模式执行完成."
    exit 0
fi
mute=""
while true; do
CheckSetup
GetVPSInfo
reChatID_1=""
reBootSet=""
reLoginSet=""
reShutdownSet=""
reCPUSet=""
reMEMSet=""
reDISKSet=""
reFlowSet=""
reDockerSet=""
source $ConfigFile
if [ "$reBootSet" == "" ] && [ "$reLoginSet" == "" ] && [ "$reShutdownSet" == "" ] && [ "$reCPUSet" == "" ] && [ "$reMEMSet" == "" ] && [ "$reDISKSet" == "" ] && [ "$reFlowSet" == "" ] && [ "$reDockerSet" == "" ]; then
    reset_menu_tag=""
else
    reset_menu_tag="${REB}Reload${NC} ${RE}标记项需要重新设置生效${NC}<<<"
fi
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
if crontab -l | grep -q "tg_autoupdate.sh"; then
    crontab_menu_tag="-> 已设置"
else
    crontab_menu_tag=""
fi
CLS
echo && echo -e "VPS 守护一键管理脚本 ${RE}[v${sh_ver}]${NC}
-- tse | vtse.eu.org | $release -- 
  
 ${GR}0.${NC} 检查依赖 / 设置参数 \t$reset_menu_tag
———————————————————————
 ${GR}1.${NC} 设置 ${GR}[开机]${NC} Telgram 通知 \t\t\t${GR}$boot_menu_tag${NC} ${REB}$reBootSet${NC}
 ${GR}2.${NC} 设置 ${GR}[登陆]${NC} Telgram 通知 \t\t\t${GR}$login_menu_tag${NC} ${REB}$reLoginSet${NC}
 ${GR}3.${NC} 设置 ${GR}[关机]${NC} Telgram 通知 \t\t\t${GR}$shutdown_menu_tag${NC} ${REB}$reShutdownSet${NC}
 ${GR}4.${NC} 设置 ${GR}[CPU 报警]${NC} Telgram 通知 ${REB}阀值${NC}: $CPUThreshold_tag \t${GR}$cpu_menu_tag${NC} ${REB}$reCPUSet${NC}
 ${GR}5.${NC} 设置 ${GR}[内存报警]${NC} Telgram 通知 ${REB}阀值${NC}: $MEMThreshold_tag \t${GR}$mem_menu_tag${NC} ${REB}$reMEMSet${NC}
 ${GR}6.${NC} 设置 ${GR}[磁盘报警]${NC} Telgram 通知 ${REB}阀值${NC}: $DISKThreshold_tag \t${GR}$disk_menu_tag${NC} ${REB}$reDISKSet${NC}
 ${GR}7.${NC} 设置 ${GR}[流量报警]${NC} Telgram 通知 ${REB}阀值${NC}: $FlowThreshold_tag \t${GR}$flow_menu_tag${NC} ${REB}$reFlowSet${NC}
 ${GR}8.${NC} 设置 ${GR}[Docker 变更]${NC} Telgram 通知 \t\t${GR}$docker_menu_tag${NC} ${REB}$reDockerSet${NC}
 ———————————————————————————————————————————————————————
 ${GR}t.${NC} 测试 - 发送一条信息用以检验参数设置
 ——————————————————————————————————————
 ${GR}h.${NC} 修改 - Hostname 以此作为主机标记
 ——————————————————————————————————————
 ${GR}d.${NC} ${RE}进入${NC} - 取消 / 删除 模式
 ——————————————————————————————————————
 ${GR}u.${NC} 设置自动更新脚本 \t${GR}$crontab_menu_tag${NC}
 ——————————————————————————————————————
 ${GR}x.${NC} 退出脚本
————————————
$Tip 使用前请先执行 ${GR}0${NC} 确保依赖完整并完成相关参数设置." && echo
read -e -p "请输入选项 [0-6|t|h|d|x]:" num
case "$num" in
    0)
    CheckAndCreateFolder
    SourceAndShowINI
    CheckRely
    SetupIniFile
    SourceAndShowINI
    Pause
    ;;
    1)
    CheckAndCreateFolder
    SetupBoot_TG
    Pause
    ;;
    2)
    CheckAndCreateFolder
    SetupLogin_TG
    Pause
    ;;
    3)
    CheckAndCreateFolder
    SetupShutdown_TG
    Pause
    ;;
    4)
    CheckAndCreateFolder
    SetupCPU_TG
    Pause
    ;;
    5)
    CheckAndCreateFolder
    SetupMEM_TG
    Pause
    ;;
    6)
    CheckAndCreateFolder
    SetupDISK_TG
    Pause
    ;;
    7)
    CheckAndCreateFolder
    SetupFlow_TG
    Pause
    ;;
    8)
    CheckAndCreateFolder
    SetupDocker_TG
    Pause
    ;;
    t|T)
    CheckAndCreateFolder
    test
    Pause
    ;;
    h|H)
    ModifyHostname
    Pause
    ;;
    d|D)
    UnsetupAll
    ;;
    u|U)
    CheckAndCreateFolder
    SetAutoUpdate
    Pause
    ;;
    x|X)
    exit 0
    ;;
    *)
    echo "请输入正确数字 [0-6|t|h|d|x]"
    ;;
esac
done
# END
