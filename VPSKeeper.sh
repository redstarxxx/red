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
    declare -a dependencies=("sed" "grep" "awk" "hostnamectl" "systemd")
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
                echo -e "$Err 未知的包管理器, 无法安装依赖. 请手动安装所需依赖后再运行脚本."
                exit 1
            fi
        else
            echo -e "$Tip 已跳过安装."
        fi
    else
        echo -e "$Tip 所有依赖已安装."
    fi
}

# 设置ini参数文件
SetupIniFile() {
    old_TelgramBotToken=""
    old_ChatID_1=""
    old_CPUThreshold=""
    old_CPUTools=""
    old_FlowThreshold=""
    if [ -f $ConfigFile ] && [ -s $ConfigFile ]; then
        old_TelgramBotToken=$TelgramBotToken
        old_ChatID_1=$ChatID_1
        old_CPUThreshold=$CPUThreshold
        old_CPUTools=$CPUTools
        old_FlowThreshold=$FlowThreshold
    fi
    # 设置电报机器人参数
    echo "------------------------------------"
    # echo -e "$Tip Telgram BOT Token 即为电报机器人 Token,"
    echo -e "$Tip ${REB}BOT Token${NC} 获取方法: 在 Telgram 中添加机器人 @BotFather, 输入: /newbot"
    # echo -e "$Tip 根据提示操作后最终获得电报机器人 Token"
    read -p "请输入 BOT Token (回车跳过 / 输入'x'退出设置): " bottoken
    if [ "$bottoken" == "X" ] || [ "$bottoken" == "x" ]; then
        return
    fi
    if [ ! -z "$bottoken" ]; then
        writeini "TelgramBotToken" "$bottoken"
        # echo -e "$Tip 已将 Token 写入 $ConfigFile 文件中."
    else
        echo -e "$Tip 输入为空, 跳过操作."
    fi
    echo "------------------------------------"
    # echo -e "$Tip Chat ID 即为接收电报信息的用户 ID,"
    echo -e "$Tip ${REB}Chat ID${NC} 获取方法: 在 Telgram 中添加机器人 @userinfobot, 点击或输入: /start"
    # echo -e "$Tip 显示的第二行 Id 即为你的用户 ID."
    read -p "请输入 Chat ID (回车跳过 / 输入'x'退出设置): " cahtid
    if [ "$cahtid" == "X" ] || [ "$cahtid" == "x" ]; then
        return
    fi
    if [ ! -z "$cahtid" ]; then
        if [[ $cahtid =~ ^[0-9]+$ ]]; then
            writeini "ChatID_1" "$cahtid"
            # echo -e "$Tip 已将 Chat ID 写入 $ConfigFile 文件中."
        else
            echo -e "$Err 输入无效, Chat ID 必须是数字, 跳过操作."
        fi
    else
        echo -e "$Tip 输入为空, 跳过操作."
    fi
    echo "------------------------------------"
    # 设置CPU报警阀值
    echo -e "$Tip ${REB}CPU 报警${NC} 阀值(%)输入 (1-100) 的整数"
    read -p "请输入 CPU 阀值 (回车跳过 / 输入'x'退出设置): " threshold
    if [ "$threshold" == "X" ] || [ "$threshold" == "x" ]; then
        return
    fi
    if [ ! -z "$threshold" ]; then
        threshold="${threshold//%/}"
        if [[ $threshold =~ ^([1-9][0-9]?|100)$ ]]; then
            writeini "CPUThreshold" "$threshold"
            # echo -e "$Tip 已将 报警阀值 写入 $ConfigFile 文件中."
        else
            echo -e "$Err 输入无效, 报警阀值 必须是数字(1-100), 跳过操作."
        fi
    else
        echo -e "$Tip 输入为空, 跳过操作."
    fi
    echo "------------------------------------"

    echo -e "$Tip 请选择 ${REB}CPU 检测工具${NC}: 1.top(系统自带) 2.sar(更专业) 3.top+sar"
    read -p "请输入序号 (回车默认选择 1.top / 输入'x'退出设置): " choice
    if [ "$threshold" == "X" ] || [ "$threshold" == "x" ]; then
        return
    fi
    if [ ! -z "$choice" ]; then
        if [ "$choice" == "2" ]; then
            CPUTools="sar"
            writeini "CPUTools" "sar"
        elif [ "$choice" == "3" ]; then
            CPUTools="top+sar"
            writeini "CPUTools" "top+sar"
        else
            CPUTools="top"
            writeini "CPUTools" "top"
        fi
    else
        CPUTools="top"
        writeini "CPUTools" "top"
        echo -e "$Tip 输入为空, 默认选择 1.top"
    fi
    echo "------------------------------------"

    # 设置流量报警阀值
    echo -e "$Tip ${REB}流量报警${NC} 阀值输入格式: 数字|数字MB/数字GB, 可带 1 位小数"
    read -p "请输入 流量 阀值 (回车跳过): " threshold
    if [ "$threshold" == "X" ] || [ "$threshold" == "x" ]; then
        return
    fi
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
        else
            echo -e "$Err 输入无效, 报警阀值 必须是: 数字|数字MB/数字GB (%.1f) 的格式, 跳过操作."
        fi
    else
        echo -e "$Tip 输入为空, 跳过操作."
    fi
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
    if [ "$old_FlowThreshold" != "" ]; then
        source $ConfigFile
        if [ "$FlowThreshold" != "$old_FlowThreshold" ]; then
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
        echo "------------------------------------"
        cat $ConfigFile
        echo "------------------------------------"
        echo -e "$Tip 以上为 TelgramBot.ini 文件内容, 可执行(0.选项)或手动修改参数."
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

# 发送Telegram消息的函数
# send_telegram_message() {
#     curl -s -X POST "https://api.telegram.org/bot$TelgramBotToken/sendMessage" -d chat_id="$ChatID_1" -d text="$1" > /dev/null
# }

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
        curl -s -X POST "https://api.telegram.org/bot$TelgramBotToken/sendMessage" -d chat_id="$ChatID_1" -d text="来自 $(hostname) 的测试信息" > /dev/null
        echo -e "$Inf 测试信息已发出, 电报将收到一条\"来自 $(hostname) 的测试信息\"的信息."
        echo -e "$Tip 如果没有收到测试信息, 请检查设置 (重新执行 0 选项)."
    else
        echo -e "$Err 参数丢失, 请设置后再执行 (先执行 0 选项)."
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
            echo "curl -s -X POST \"https://api.telegram.org/bot$TelgramBotToken/sendMessage\" -d chat_id=\"$ChatID_1\" -d text=\"\$(hostname) 已启动.\"" \
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
            echo -e "$Inf 开机 通知已经设置成功, 当开机时你的 Telgram 将收到通知."
            delini "reBootSet"
        else
            echo -e "$Err 参数丢失, 请设置后再执行 (先执行 0 选项)."
        fi
    else
        echo -e "$Err 系统未检测到 \"systemd\" 程序, 无法设置开机通知."
    fi
}

# 设置登陆通知
SetupLogin_TG() {
    if [[ ! -z "${TelgramBotToken}" &&  ! -z "${ChatID_1}" ]]; then
        echo "#!/bin/bash" > $FolderPath/tg_login.sh
        echo "curl -s -X POST \"https://api.telegram.org/bot$TelgramBotToken/sendMessage\" -d chat_id=\"$ChatID_1\" -d text=\"\$(hostname) \$(id -nu) 用户登陆成功.\"" \
        >> $FolderPath/tg_login.sh
        chmod +x $FolderPath/tg_login.sh
        if [ -f /etc/bash.bashrc ]; then
            if ! grep -q "bash $FolderPath/tg_login.sh > /dev/null 2>&1" /etc/bash.bashrc; then
                echo "bash $FolderPath/tg_login.sh > /dev/null 2>&1" >> /etc/bash.bashrc
                # echo -e "$Tip 指令已经添加进 /etc/bash.bashrc 文件"
                echo -e "$Inf 登陆 通知已经设置成功, 当登陆时你的 Telgram 将收到通知."
            fi
            delini "reLoginSet"
        elif [ -f /etc/profile ]; then
            if ! grep -q "bash $FolderPath/tg_login.sh > /dev/null 2>&1" /etc/profile; then
                echo "bash $FolderPath/tg_login.sh > /dev/null 2>&1" >> /etc/profile
                # echo -e "$Tip 指令已经添加进 /etc/profile 文件"
                echo -e "$Inf 登陆 通知已经设置成功, 当登陆时你的 Telgram 将收到通知."
            fi
            delini "reLoginSet"
        else
            echo -e "$Err 未检测到对应文件, 无法设置登陆通知."
        fi
        # ShowContents "$FolderPath/tg_login.sh"
    else
        echo -e "$Err 参数丢失, 请设置后再执行 (先执行 0 选项)."
    fi
}

# 设置关机通知
SetupShutdown_TG() {
    if command -v systemd &>/dev/null; then
        if [[ ! -z "${TelgramBotToken}" &&  ! -z "${ChatID_1}" ]]; then
            echo "#!/bin/bash" > $FolderPath/tg_shutdown.sh
            echo "curl -s -X POST \"https://api.telegram.org/bot$TelgramBotToken/sendMessage\" -d chat_id=\"$ChatID_1\" -d text=\"\$(hostname) \$(id -nu) 正在执行关机...\"" \
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
            echo -e "$Inf 关机 通知已经设置成功, 当开机时你的 Telgram 将收到通知."
            delini "reShutdownSet"
        else
            echo -e "$Err 参数丢失, 请设置后再执行 (先执行 0 选项)."
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
        message="DOCKER 列表:"\$'\n'"\$new_message"
        curl -s -X POST "https://api.telegram.org/bot$TelgramBotToken/sendMessage" -d chat_id="$ChatID_1" -d text="\$message"
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
            echo -e "$Inf Docker 通知已经设置成功, 当 Dokcer 挂载发生变化时你的 Telgram 将收到通知."
            delini "reDockerSet"
        else
            echo -e "$Err 参数丢失, 请设置后再执行 (先执行 0 选项)."
        fi
    else
        echo -e "$Err 未检测到 \"Docker\" 程序."
    fi
}

# 设置CPU报警
SetupCPU_TG() {
    if [[ ! -z "${TelgramBotToken}" &&  ! -z "${ChatID_1}" &&  ! -z "${CPUThreshold}" &&  ! -z "${CPUTools}" ]]; then
        if [ "$CPUTools" == "top" ]; then
            cat <<EOF > $FolderPath/tg_cpu.sh
#!/bin/bash

count=0
while true; do
    SleepTime=900
    echo "正在检测 CPU 使用率..."
    # cpu_usage=\$(sar -u 3 5 | awk '/^Average:/ { printf "%.0f\n", 100 - \$NF }')
    # 下面是两种方式
    # cpu_usage=\$(awk '{idle+=\$8; count++} END {printf "%.0f", 100 - (idle / count)}' <(grep "Cpu(s)" <(top -bn5 -d 3)))
    cpu_usage=\$(awk '{ gsub(/us,|sy,|ni,|id,|:/, " ", \$0); idle+=\$5; count++ } END { printf "%.0f", 100 - (idle / count) }' <(grep "Cpu(s)" <(top -bn5 -d 3)))
    echo "top检测结果: \$cpu_usage | 日期: \$(date)"
    if (( cpu_usage > $CPUThreshold )); then
        (( count++ ))
    else
        count=0
    fi
    if (( count >= 3 )); then
        top_output=\$(top -n 1 -b | awk 'NR > 7')
        cpu_h1=\$(echo "\$top_output" | awk 'NR == 1 || \$9 > max { max = \$9; process = \$12 } END { print process }')
        cpu_h2=\$(echo "\$top_output" | awk 'NR == 2 || \$9 > max { max = \$9; process = \$12 } END { print process }')
        message="CPU 使用率超过阀值 > $CPUThreshold%❗️"\$'\n'"主机名: \$(hostname)"\$'\n'"CPU 当前使用率: \$cpu_usage%"\$'\n'"使用率排行: 1.\$cpu_h1 2.\$cpu_h2"\$'\n'"检测工具: $CPUTools"\$'\n'"休眠时间: \$((SleepTime / 60))分钟"
        curl -s -X POST "https://api.telegram.org/bot$TelgramBotToken/sendMessage" -d chat_id="$ChatID_1" -d text="\$message" > /dev/null
        echo "报警信息已发出..."
        count=0  # 发送警告后重置计数器
        sleep \$SleepTime   # 发送后等待10分钟再检测
    fi
    # sleep 5
done
EOF
        elif [ "$CPUTools" == "sar" ]; then
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
            cat <<EOF > $FolderPath/tg_cpu.sh
#!/bin/bash

count=0
while true; do
    SleepTime=900
    echo "正在检测 CPU 使用率..."
    cpu_usage=\$(sar -u 3 5 | awk '/^Average:/ { printf "%.0f\n", 100 - \$NF }')
    # 下面是两种方式
    # cpu_usage=\$(awk '{idle+=\$8; count++} END {printf "%.0f", 100 - (idle / count)}' <(grep "Cpu(s)" <(top -bn5 -d 3)))
    # cpu_usage=\$(awk '{ gsub(/us,|sy,|ni,|id,|:/, " ", \$0); idle+=\$5; count++ } END { printf "%.0f", 100 - (idle / count) }' <(grep "Cpu(s)" <(top -bn5 -d 3)))
    echo "sar检测结果: \$cpu_usage | 日期: \$(date)"
    if (( cpu_usage > $CPUThreshold )); then
        (( count++ ))
    else
        count=0
    fi
    if (( count >= 3 )); then
        top_output=\$(top -n 1 -b | awk 'NR > 7')
        cpu_h1=\$(echo "\$top_output" | awk 'NR == 1 || \$9 > max { max = \$9; process = \$12 } END { print process }')
        cpu_h2=\$(echo "\$top_output" | awk 'NR == 2 || \$9 > max { max = \$9; process = \$12 } END { print process }')
        message="CPU 使用率超过阀值 > $CPUThreshold%❗️"\$'\n'"主机名: \$(hostname)"\$'\n'"CPU 当前使用率: \$cpu_usage%"\$'\n'"使用率排行: 1.\$cpu_h1 2.\$cpu_h2"\$'\n'"检测工具: $CPUTools"\$'\n'"休眠时间: \$((SleepTime / 60))分钟"
        curl -s -X POST "https://api.telegram.org/bot$TelgramBotToken/sendMessage" -d chat_id="$ChatID_1" -d text="\$message" > /dev/null
        echo "报警信息已发出..."
        count=0  # 发送警告后重置计数器
        sleep \$SleepTime   # 发送后等待10分钟再检测
    fi
    # sleep 5
done
EOF
        elif [ "$CPUTools" == "top+sar" ]; then
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
            cat <<EOF > $FolderPath/tg_cpu.sh
#!/bin/bash

count=0
while true; do
    SleepTime=900
    echo "正在检测 CPU 使用率..."
    cpu_usage_sar=\$(sar -u 3 5 | awk '/^Average:/ { printf "%.0f\n", 100 - \$NF }')
    # 下面是两种方式
    # cpu_usage_top=\$(awk '{idle+=\$8; count++} END {printf "%.0f", 100 - (idle / count)}' <(grep "Cpu(s)" <(top -bn5 -d 3)))
    cpu_usage_top=\$(awk '{ gsub(/us,|sy,|ni,|id,|:/, " ", \$0); idle+=\$5; count++ } END { printf "%.0f", 100 - (idle / count) }' <(grep "Cpu(s)" <(top -bn5 -d 3)))
    # 计算平均值
    # cpu_usage=\$(echo "scale=2; (\$cpu_usage_sar + \$cpu_usage_top) / 2" | bc)
    cpu_usage=\$(awk -v sar="\$cpu_usage_sar" -v top="\$cpu_usage_top" 'BEGIN { printf "%.0f\n", (sar + top) / 2 }')
    echo "sar检测结果: \$cpu_usage_sar | top检测结果: \$cpu_usage_top | 平均值: \$cpu_usage | 日期: \$(date)"
    if (( cpu_usage > $CPUThreshold )); then
        (( count++ ))
    else
        count=0
    fi
    if (( count >= 3 )); then
        top_output=\$(top -n 1 -b | awk 'NR > 7')
        cpu_h1=\$(echo "\$top_output" | awk 'NR == 1 || \$9 > max { max = \$9; process = \$12 } END { print process }')
        cpu_h2=\$(echo "\$top_output" | awk 'NR == 2 || \$9 > max { max = \$9; process = \$12 } END { print process }')
        message="CPU 使用率超过阀值 > $CPUThreshold%❗️"\$'\n'"主机名: \$(hostname)"\$'\n'"CPU 当前使用率: \$cpu_usage%"\$'\n'"使用率排行: 1.\$cpu_h1 2.\$cpu_h2"\$'\n'"检测工具: $CPUTools"\$'\n'"休眠时间: \$((SleepTime / 60))分钟"
        curl -s -X POST "https://api.telegram.org/bot$TelgramBotToken/sendMessage" -d chat_id="$ChatID_1" -d text="\$message" > /dev/null
        echo "报警信息已发出..."
        count=0  # 发送警告后重置计数器
        sleep \$SleepTime   # 发送后等待10分钟再检测
    fi
    # sleep 5
done
EOF
        else
            echo -e "$Err 不应该出现的错误, 请重新选择 0 配置."
        fi
        chmod +x $FolderPath/tg_cpu.sh
        pkill tg_cpu.sh
        pkill tg_cpu.sh
        nohup $FolderPath/tg_cpu.sh > $FolderPath/tg_cpu.log 2>&1 &
        if ! crontab -l | grep -q "@reboot nohup $FolderPath/tg_cpu.sh > $FolderPath/tg_cpu.log 2>&1 &"; then
            (crontab -l 2>/dev/null; echo "@reboot nohup $FolderPath/tg_cpu.sh > $FolderPath/tg_cpu.log 2>&1 &") | crontab -
        fi
        # ShowContents "$FolderPath/tg_cpu.sh"
        echo -e "$Inf CPU 通知已经设置成功, 当 CPU 使用率达到 $CPUThreshold % 时, 你的 Telgram 将收到通知."
        delini "reCPUSet"
    else
        echo -e "$Err 参数丢失, 请设置后再执行 (先执行 0 选项)."
    fi
}

# 设置流量报警
SetupFlow_TG() {
    if [[ ! -z "${TelgramBotToken}" &&  ! -z "${ChatID_1}" &&  ! -z "${FlowThreshold}" ]]; then
        # FlowThreshold=500
        FlowThreshold_U=$FlowThreshold
        if [[ $FlowThreshold == *MB ]]; then
            FlowThreshold=${FlowThreshold%MB}
            FlowThreshold=$(awk -v value=$FlowThreshold 'BEGIN { printf "%.1f", value }')
        elif [[ $FlowThreshold == *GB ]]; then
            FlowThreshold=${FlowThreshold%GB}
            FlowThreshold=$(awk -v value=$FlowThreshold 'BEGIN { printf "%.1f", value*1024 }')
        fi
        cat <<EOF > $FolderPath/tg_flow.sh
#!/bin/bash

# 流量阈值设置 (MB)
# FlowThreshold=500
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
        if [ "\$all_rx_mb" -gt 1023 ]; then
            all_rx_mb=\$(awk -v value=\$all_rx_mb 'BEGIN{printf "%.1f", value/1024}')
            all_rx_mb="\${all_rx_mb}GB" 
        else
            all_rx_mb="\${all_rx_mb}MB"
        fi
        all_tx_mb=\$((current_tx_bytes / 1024 / 1024))
        if [ "\$all_tx_mb" -gt 1023 ]; then
            all_tx_mb=\$(awk -v value=\$all_tx_mb 'BEGIN{printf "%.1f", value/1024}')
            all_tx_mb="\${all_tx_mb}GB" 
        else
            all_tx_mb="\${all_tx_mb}MB"
        fi

        # 计算增量
        rx_diff=\$((current_rx_bytes - prev_rx_data[\$sanitized_interface]))
        tx_diff=\$((current_tx_bytes - prev_tx_data[\$sanitized_interface]))

        # 调试使用(30秒的流量增量)
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
        
            message="流量已达到阀值 > $FlowThreshold_U%❗️"\$'\n'"主机名: \$(hostname) 端口: \$sanitized_interface"\$'\n'"已接收: \${rx_mb}  已发送: \${tx_mb}"\$'\n'"总接收: \${all_rx_mb}  总发送: \${all_tx_mb}"
            curl -s -X POST "https://api.telegram.org/bot$TelgramBotToken/sendMessage" -d chat_id="$ChatID_1" -d text="\$message"

            # 更新前一个状态的流量数据
            prev_rx_data[\$sanitized_interface]=\$current_rx_bytes
            prev_tx_data[\$sanitized_interface]=\$current_tx_bytes
        fi

        # # 更新前一个状态的流量数据
        # prev_rx_data[\$sanitized_interface]=\$current_rx_bytes
        # prev_tx_data[\$sanitized_interface]=\$current_tx_bytes
    done

    # 等待30秒
    sleep 30
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
        echo -e "$Inf 流量 通知已经设置成功, 当流量使用达到 $FlowThreshold_U 时, 你的 Telgram 将收到通知."
        delini "reFlowSet"
    else
        echo -e "$Err 参数丢失, 请设置后再执行 (先执行 0 选项)."
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
        CPUThreshold_tag=${GR}$CPUThreshold %${NC}
    fi
    if [ -z "$FlowThreshold" ]; then
        FlowThreshold_tag="${RE}未设置${NC}"
    else
        FlowThreshold_tag=${GR}$FlowThreshold${NC}
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
 ${GR}5.${NC} ${RE}取消${NC} ${GR}[流量报警]${NC} Telgram 通知 ${REB}阀值${NC}: $FlowThreshold_tag \t${GR}$flow_menu_tag${NC}
 ${GR}6.${NC} ${RE}取消${NC} ${GR}[Docker 变更]${NC} Telgram 通知 \t\t${GR}$docker_menu_tag${NC}
 ———————————————————————————————————————————————————————
 ${GR}a.${NC} ${RE}取消所有${NC} Telgram 通知
 ——————————————————————————————————————
 ${GR}f.${NC} ${RE}删除${NC} 脚本文件夹 \t${GR}$folder_menu_tag${NC}
 ——————————————————————————————————————
 ${GR}b.${NC} 返回 普通模式
 ——————————————————————————————————————
 ${GR}x.${NC} 退出脚本
————————————
$Tip 使用前请先执行 0 确保依赖完整并完成相关参数设置." && echo
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
        5) # 流量 报警
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
        6) # Docker 提示
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
            delini "reFlowSet"
            delini "reDockerSet"
            echo -e "$Tip 已取消 / 删除所有通知."
            Pause
        fi
        ;;
        f|F)
        if [ "$boot_menu_tag" == "" ] && [ "$login_menu_tag" == "" ] && [ "$shutdown_menu_tag" == "" ] && [ "$cpu_menu_tag" == "" ] && [ "$flow_menu_tag" == "" ] && [ "$docker_menu_tag" == "" ]; then
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
while true; do
CheckSetup
reChatID_1=""
reBootSet=""
reLoginSet=""
reShutdownSet=""
reCPUSet=""
reFlowSet=""
reDockerSet=""
source $ConfigFile
if [ "$reBootSet" == "" ] && [ "$reLoginSet" == "" ] && [ "$reShutdownSet" == "" ] && [ "$reCPUSet" == "" ] && [ "$reFlowSet" == "" ] && [ "$reDockerSet" == "" ]; then
    reset_menu_tag=""
else
    reset_menu_tag="${REB}Reload${NC} ${RE}标记项需要重新设置生效${NC}<<<"
fi
if [ -z "$CPUThreshold" ]; then
    CPUThreshold_tag="${RE}未设置${NC}"
else
    CPUThreshold_tag="${GR}$CPUThreshold %${NC}"
fi
if [ -z "$FlowThreshold" ]; then
    FlowThreshold_tag="${RE}未设置${NC}"
else
    FlowThreshold_tag=${GR}$FlowThreshold${NC}
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
 ${GR}5.${NC} 设置 ${GR}[流量报警]${NC} Telgram 通知 ${REB}阀值${NC}: $FlowThreshold_tag \t${GR}$flow_menu_tag${NC} ${REB}$reFlowSet${NC}
 ${GR}6.${NC} 设置 ${GR}[Docker 变更]${NC} Telgram 通知 \t\t${GR}$docker_menu_tag${NC} ${REB}$reDockerSet${NC}
 ———————————————————————————————————————————————————————
 ${GR}t.${NC} 测试 - 发送一条信息用以检验参数设置
 ——————————————————————————————————————
 ${GR}h.${NC} 修改 - Hostname 以此作为主机标记
 ——————————————————————————————————————
 ${GR}d.${NC} ${RE}进入${NC} - 取消 / 删除 模式
 ——————————————————————————————————————
 ${GR}x.${NC} 退出脚本
————————————
$Tip 使用前请先执行 0 确保依赖完整并完成相关参数设置." && echo
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
    SetupFlow_TG
    Pause
    ;;
    6)
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
    x|X)
    exit 0
    ;;
    *)
    echo "请输入正确数字 [0-6|t|h|d|x]"
    ;;
esac
done
# END
