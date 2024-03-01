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
sh_ver="1.0.0"

# 检测是否root用户
if [ "$UID" -ne 0 ]; then
    echo "非 \"root\" 用户, 无法执行."
    exit 1
fi

# 导入参数
# if [ -f /root/.shfile/TelgramBot.ini ]; then
#     source /root/.shfile/TelgramBot.ini
# fi

# 颜色代码
GR="\033[32m" && RE="\033[31m" && GRB="\033[42;37m" && REB="\033[41;37m" && NC="\033[0m"
Inf="${GR}[信息]${NC}:"
Err="${RE}[错误]${NC}:"
Tip="${GR}[提示]${NC}:"

# 创建.shfile目录
CheckAndCreateFold() {
    if [ ! -d "/root/.shfile" ]; then
        mkdir -p "/root/.shfile"
    fi
    if [ -f /root/.shfile/TelgramBot.ini ]; then
        source /root/.shfile/TelgramBot.ini
    else
        touch /root/.shfile/TelgramBot.ini
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
    elif cat /etc/issue | grep -q -E -i "debian"; then
        release="debian"
    elif cat /etc/issue | grep -q -E -i "ubuntu"; then
        release="ubuntu"
    elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
        release="centos"
    elif cat /proc/version | grep -q -E -i "debian"; then
        release="debian"
    elif cat /proc/version | grep -q -E -i "ubuntu"; then
        release="ubuntu"
    elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
        release="centos"
    fi
    #bit=`uname -m`
}

# 检测依赖
CheckRely() {
    # 检查并安装依赖
    echo "检查并安装依赖..."
    declare -a dependencies=("sed" "passwd" "hostnamectl" "grep")
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
                echo -e "$Tip 未知的包管理器, 无法安装依赖. 请手动安装所需依赖后再运行脚本."
            fi
        else
            echo -e "$Tip 已跳过安装."
        fi
    else
        echo -e "$Tip 所有依赖已安装."
    fi
}

SetupTelgramBot() {
    # if [ ! -f /root/.shfile/TelgramBot.ini ]; then
    #     touch /root/.shfile/TelgramBot.ini
    # fi
    # echo -e "$Tip Telgram BOT Token 即为电报机器人 Token,"
    echo -e "$Tip Token 获取方法: 在 Telgram 中添加机器人 @BotFather, 输入: /newbot"
    # echo -e "$Tip 根据提示操作后最终获得电报机器人 Token"
    read -p "请输入 Telgram BOT Token : " bottoken
    if [ ! -z "$bottoken" ]; then
        if grep -q "^TelgramBotToken=" /root/.shfile/TelgramBot.ini; then
            sed -i "/^TelgramBotToken=/d" /root/.shfile/TelgramBot.ini
        fi
        echo "TelgramBotToken=$bottoken" >> /root/.shfile/TelgramBot.ini
        echo -e "$Tip 已将 Token 写入 /root/.shfile/TelgramBot.ini 文件中."
    else
        echo "输入为空, 跳过操作."
    fi
    # echo -e "$Tip Chat ID 即为接收电报信息的用户 ID,"
    echo -e "$Tip ID 获取方法: 在 Telgram 中添加机器人 @userinfobot, 点击或输入: /start"
    # echo -e "$Tip 显示的第二行 Id 即为你的用户 ID."
    read -p "请输入 Chat ID : " cahtid
    if [ ! -z "$cahtid" ]; then
        if grep -q "^ChatID_1=" /root/.shfile/TelgramBot.ini; then
            sed -i "/^ChatID_1=/d" /root/.shfile/TelgramBot.ini
        fi
        echo "ChatID_1=$cahtid" >> /root/.shfile/TelgramBot.ini
        echo -e "$Tip 已将 Chat ID 写入 /root/.shfile/TelgramBot.ini 文件中."
    else
        echo "输入为空, 跳过操作."
    fi
    source /root/.shfile/TelgramBot.ini
    echo "------------------------------------"
    cat /root/.shfile/TelgramBot.ini
    echo "------------------------------------"
    echo -e "$Tip 以上为 TelgramBot.ini 文件内容, 可重新执行或手动修改 Token 和 ID."
}

# 检查文件是否存在并显示内容
ShowContents() {
    if [ -f "$1" ]; then
        cat "$1"
        echo -e "$Inf 上述内容已经写入: $1"
        echo "----------------------------------------------"
    else
        echo -e "$Err 文件不存在: $1"
    fi
}

# 更新
Update() {
    echo "升级脚本."
}

# 修改Hostname
ModifyHostname() {
    # 修改 hosts 和 hostname
    echo "当前 Hostname : $(hostname)"
    read -p "请输入要修改的 Hostname : " name
    if [[ ! -z "${name}" ]]; then
        echo "修改 hosts 和 hostname..."
        sed -i "s/$(hostname)/$name/g" /etc/hosts
        echo "$name" > /etc/hostname
        hostnamectl set-hostname $name
    else
        echo "输入为空, 未改动."
    fi
}

# 设置登陆通知

SetupBoot_TG() {
    echo "#!/bin/bash" > /root/.shfile/tg_boot.sh
    echo "curl -s -X POST \"https://api.telegram.org/bot$TelgramBotToken/sendMessage\" -d chat_id=\"$ChatID_1\" -d text=\"\$(hostname) 已启动.\"" \
    >> /root/.shfile/tg_boot.sh
    chmod +x /root/.shfile/tg_boot.sh
    if command -v systemd &>/dev/null; then
        if [[ ! -z "${TelgramBotToken}" &&  ! -z "${ChatID_1}" ]]; then
            cat <<EOF > /etc/systemd/system/tg_boot.service
[Unit]
Description=Run tg_boot.sh script at boot time
After=network.target

[Service]
Type=oneshot
ExecStart=/root/.shfile/tg_boot.sh
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF
            ShowContents "/root/.shfile/tg_boot.sh"
            ShowContents "/etc/systemd/system/tg_boot.service"
            if [ ! "$(systemctl is-active tg_boot.service)" = "active" ]; then
                systemctl enable tg_boot.service
            fi
        else
            echo -e "$Err \"Telgram BOT Token\" 或 \"Chat ID\" 为空, 请设置(0选项)后再执行."
        fi
    else
        echo -e "$Err 系统未检测到 \"systemd\" 程序, 无法设置关闭通知."
    fi
}

SetupLogin_TG() {
    if [[ ! -z "${TelgramBotToken}" &&  ! -z "${ChatID_1}" ]]; then
        echo "#!/bin/bash" > /root/.shfile/tg_login.sh
        echo "curl -s -X POST \"https://api.telegram.org/bot$TelgramBotToken/sendMessage\" -d chat_id=\"$ChatID_1\" -d text=\"\$(hostname) \$(id -nu) 用户登陆成功.\"" \
        >> /root/.shfile/tg_login.sh
        chmod +x /root/.shfile/tg_login.sh
        if [ -f /etc/bash.bashrc ]; then
            if ! grep -q "bash /root/.shfile/tg_login.sh > /dev/null 2>&1" /etc/bash.bashrc; then
                echo "bash /root/.shfile/tg_login.sh > /dev/null 2>&1" >> /etc/bash.bashrc
                echo -e "$Tip 指令已经添加进 /etc/bash.bashrc 文件"
            fi
        elif [ -f /etc/profile ]; then
            if ! grep -q "bash /root/.shfile/tg_login.sh > /dev/null 2>&1" /etc/profile; then
                echo "bash /root/.shfile/tg_login.sh > /dev/null 2>&1" >> /etc/profile
                echo -e "$Tip 指令已经添加进 /etc/profile 文件"
            fi
        else
            echo -e "$Err 未检测到对应文件, 无法设置登陆通知."
        fi
        ShowContents "/root/.shfile/tg_login.sh"
    else
        echo -e "$Err \"Telgram BOT Token\" 或 \"Chat ID\" 为空, 请设置(0选项)后再执行."
    fi
}

# 设置关机通知
SetupShutdown_TG() {
    echo "#!/bin/bash" > /root/.shfile/tg_shutdown.sh
    echo "curl -s -X POST \"https://api.telegram.org/bot$TelgramBotToken/sendMessage\" -d chat_id=\"$ChatID_1\" -d text=\"\$(hostname) \$(id -nu) 正在执行关机...\"" \
    >> /root/.shfile/tg_shutdown.sh
    chmod +x /root/.shfile/tg_shutdown.sh
    if command -v systemd &>/dev/null; then
        if [[ ! -z "${TelgramBotToken}" &&  ! -z "${ChatID_1}" ]]; then
            cat <<EOF > /etc/systemd/system/tg_shutdown.service
[Unit]
Description=tg_shutdown
DefaultDependencies=no
Before=shutdown.target

[Service]
Type=oneshot
ExecStart=/root/.shfile/tg_shutdown.sh
TimeoutStartSec=0

[Install]
WantedBy=shutdown.target
EOF
            ShowContents "/root/.shfile/tg_shutdown.sh"
            ShowContents "/etc/systemd/system/tg_shutdown.service"
            # if [ ! "$(systemctl is-active tg_shutdown.service)" = "active" ]; then
                systemctl enable tg_shutdown.service
            # fi
        else
            echo -e "$Err \"Telgram BOT Token\" 或 \"Chat ID\" 为空, 请设置(0选项)后再执行."
        fi
    else
        echo -e "$Err 系统未检测到 \"systemd\" 程序, 无法设置关闭通知."
    fi
}

# 设置Dokcer通知
SetupDocker_TG() {
    if command -v docker &>/dev/null; then
        if [[ ! -z "${TelgramBotToken}" &&  ! -z "${ChatID_1}" ]]; then
            cat <<EOF > /root/.shfile/tg_docker.sh
#!/bin/bash

old_message=""

while true; do
    new_message=\$(docker ps --format '{{.Names}}' | tr '\n' "\n" | sed 's/|$//')
    
    if [ "\$new_message" != "\$old_message" ]; then
        old_message=\$new_message
        message="Docker List:"\$'\n'"\$new_message"
        curl -s -X POST "https://api.telegram.org/bot$TelgramBotToken/sendMessage" -d chat_id="$ChatID_1" -d text="\$message"
    fi
    
    sleep 10
done
EOF

            chmod +x /root/.shfile/tg_docker.sh
            echo "@reboot bash /root/.shfile/tg_docker.sh" | crontab -
            ShowContents "/root/.shfile/tg_docker.sh"
            echo -e "$Inf Docker 通知已经设置成功, 当 Dokcer 挂载发生变化时你的 Telgram 将收到通知."
        else
            echo -e "$Err \"Telgram BOT Token\" 或 \"Chat ID\" 为空, 请设置(0选项)后再执行."
        fi
    else
        echo -e "$Err 未检测到 \"Docker\" 程序."
    fi
}

# 卸载
UnsetupAll() {
    # if [ "$(systemctl is-active tg_boot.service)" = "active" ]; then
        systemctl stop tg_boot.service > /dev/null 2>&1
        systemctl disable tg_boot.service > /dev/null 2>&1
    # fi
    sleep 1
    rm -f /etc/systemd/system/tg_boot.service
    # if [ "$(systemctl is-active tg_shutdown.service)" = "active" ]; then
        systemctl stop tg_shutdown.service > /dev/null 2>&1
        systemctl disable tg_shutdown.service > /dev/null 2>&1
    # fi
    sleep 1
    rm -f /etc/systemd/system/tg_shutdown.service
    rm -rf /root/.shfile
    crontab -l | grep -v "@reboot bash /root/.shfile/tg_docker.sh" | crontab -
    if [ -f /etc/bash.bashrc ]; then
        sed -i '/bash \/root\/.shfile\/tg_login.sh/d' /etc/bash.bashrc
    fi
    if [ -f /etc/profile ]; then
        sed -i '/bash \/root\/.shfile\/tg_login.sh/d' /etc/profile
    fi
    echo "已经成功删除所有通知."
}

# 以下为主程序
# CheckSys
while true; do
CLS
echo && echo -e "VPS 守护一键管理脚本 ${RE}[v${sh_ver}]${NC}
-- tse | vtse.eu.org --
  
 ${GR}0.${NC} 检查依赖 / 设置 Telgram 机器人
————————————
 ${GR}1.${NC} 修改 HOSTNAME
 ${GR}2.${NC} 一键设置 ${GR}[开机]${NC} Telgram 通知
 ${GR}3.${NC} 一键设置 ${GR}[登陆]${NC} Telgram 通知
 ${GR}4.${NC} 一键设置 ${GR}[关机]${NC} Telgram 通知
 ${GR}5.${NC} 一键设置 ${GR}[Docker 变更]${NC} Telgram 通知
 ———————————————————————————————————————
 ${GR}d.${NC} 一键取消并删除所有通知设置
———————————————————————————————————————
 ${GR}x.${NC} 退出脚本
————————————
$Tip 使用前请先执行 0 确保依赖完整和完成 Telgram 机器人设置." && echo
read -e -p "请输入数字 [0-4]:" num
case "$num" in
    0)
    CheckAndCreateFold
    CheckRely
    SetupTelgramBot
    Pause
    ;;
    1)
    ModifyHostname
    Pause
    ;;
    2)
    CheckAndCreateFold
    SetupBoot_TG
    Pause
    ;;
    3)
    CheckAndCreateFold
    SetupLogin_TG
    Pause
    ;;
    4)
    CheckAndCreateFold
    SetupShutdown_TG
    Pause
    ;;
    5)
    CheckAndCreateFold
    SetupDocker_TG
    Pause
    ;;
    d|D)
    UnsetupAll
    exit 0
    ;;
    x|X)
    exit 0
    ;;
    *)
    echo "请输入正确数字 [0-4]"
    ;;
esac
done
# END
