#!/bin/bash

export LANG="en_US.UTF-8"
BK='\033[0;30m'
RE='\033[0;31m'
GR='\033[0;32m'
YE='\033[0;33m'
BL='\033[0;34m'
MA='\033[0;35m'
CY='\033[0;36m'
WH='\033[0;37m'
NC='\033[0m'
# echo -e "BK=BLACK RE=RED GR=GREEN YE=YELLOW BL=BLUE MA=MAGENTA CY=CYAN WH=WHITE NC=RESET"
clear_screen() {
    if command -v apt &>/dev/null; then
        clear
    elif command -v yum &>/dev/null; then
        printf "\033c"
    else
        echo
        echo -e "${BK}■ ${RE}■ ${GR}■ ${YE}■ ${BL}■ ${MA}■ ${CY}■ ${WH}■ ${BL}■ ${GR}■ ${BK}■"
    fi
}
echoo() {
    if [ ${#choice} -eq 2 ]; then
        echo
    fi
}
remind1p() {
    if [ "$etag" == 1 ]; then
        echo -e "${MA}✘${NC}"
        etag=0
    else
        echo -e "${GR}●${NC}"
    fi
}
remind3p() {
    if [ "$etag" == 1 ]; then
        echo -e "${MA}✘ ✘ ✘${NC}"
        etag=0
    else
        echo -e "${GR}● ● ●${NC}"
    fi
}
waitfor() {
    echo -e "执行完成, ${NC}按${MA}任意键${NC}继续..."
    read -n 1 -s -r -p ""
}
get_random_color() {
    colors=($BL $RE $GR $YE $MA $CY $WH)
    random_index=$((RANDOM % ${#colors[@]}))
    echo "${colors[random_index]}"
}
text1="-------------------------------"
text2="==============================="
colored_text1=""
colored_text2=""
color1=$(get_random_color)
color2=$(get_random_color)
for ((i=0; i<${#text1}; i++)); do
    if ((i % 2 == 0)); then
        colored_text1="${colored_text1}${color1}${text1:$i:1}"
        colored_text2="${colored_text2}${color1}${text2:$i:1}"
    else
        colored_text1="${colored_text1}${color2}${text1:$i:1}"
        colored_text2="${colored_text2}${color2}${text2:$i:1}"
    fi
done
if command -v apt &>/dev/null; then
    pm="apt"
elif command -v yum &>/dev/null; then
    pm="yum"
else
    echo "不支持的Linux包管理器"
    exit 1
fi
(EUID=$(id -u)) 2>/dev/null
onlyone=1
clear_screen
if [ "$EUID" -eq 0 ]; then
    user_path="/root"
else
    user_path="/home/$(whoami)"
    echo -e "${GR}当前用户为非root用户, 部分操作可能无法顺利进行.${NC}"
fi
frp_dir="/etc/frp"
if [ ! -d "$frp_dir" ]; then
    sudo mkdir -p "$frp_dir"
fi
if [ ! -f "$frp_dir/1.x" ] && [ ! -f "$frp_dir/2.x" ]; then
    echo -e "${MA} 欢迎使用 FRP 一键脚本工具 ${NC}"
    # echo -e "${BK}■ ${RE}■ ${GR}■ ${YE}■ ${BL}■ ${MA}■ ${CY}■ ${WH}■ ${BL}■ ${GR}■ ${RE}■ ${YE}■ ${BK}■"
    echo -e "${BK}■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■${NC}"
    echo -e "请选择配置 FRP 服务类型 ${GR}(可更改)${NC}"
    echo -e "1.服务端   2.客户端"
    echo -e "${colored_text1}${NC}"
    read -e -p "请输入你的选择: " -n 2 -r choice && echo
    if [[ $choice == 1 ]] || [[ $choice == 11 ]]; then
        choice=1
    fi
    if [[ $choice == 2 ]] || [[ $choice == 22 ]]; then
        choice=2
    fi
    if [[ $choice == 1 ]] || [[ $choice == 2 ]]; then
        rm -f *.x
        touch "$frp_dir/$choice.x"
    else
        echo "输入有误."
        exit 0
    fi
fi
if [ -f "$frp_dir/1.x" ]; then
    while true; do
    runtag="${RE}Not running${NC}"
    setuptag="${RE}Not ready${NC}"
    if netstat -untlp | grep -q "frps"; then
        runtag="${GR}FRPS runing${NC}"
    fi
    if netstat -untlp | grep -q "frpc"; then
        runtag="${GR}FRPC runing${NC}"
    fi
    if [ -f "$frp_dir/frps" ]; then
        setuptag="${GR}Ready${NC}"
    fi
    clear_screen
    echo -e "${MA} 欢迎使用 FRP 一键脚本工具 ${NC}"
    # echo -e "${BK}■ ${RE}■ ${GR}■ ${YE}■ ${BL}■ ${MA}■ ${CY}■ ${WH}■ ${BL}■ ${GR}■ ${RE}■ ${YE}■ ${BK}■"
    echo -e "${BK}■ ■ ■ ■ ■ ■ ■ ■ ■ ■${NC} $runtag"
    echo -e "${colored_text2}${NC}"
    echo -e "1.  配置 FRP${GR}S${NC} ${YE}服务端${NC} ▶"
    echo -e "2.  手动修改 FRP${GR}S${NC}.toml 配置文件"
    echo -e "${colored_text1}${NC}"
    echo -e "3.  启动/重启 FRP${GR}S${NC}"
    echo -e "4.  停止 FRP"
    echo -e "${colored_text1}${NC}"
    echo -e "+.  下载/解压 FRP  $setuptag"
    echo -e "-.  删除 FRP"
    echo -e "${colored_text1}${NC}"
    echo -e "c.  切换服务端/客户端"
    echo -e "o.  更新脚本"
    echo -e "x.  退出脚本"
    echo -e "${colored_text1}${NC}"
    if [[ $onlyone == 1 ]]; then
        echo -e "${MA}支持双击操作...${NC}"
    else
        remind3p
    fi
    read -e -p "请输入你的选择: " -n 2 -r choice && echoo
    case $choice in
        1|11)
            if [ ! -f "$frp_dir/frps" ]; then
                echo "请先运行选项 + 进行安装。"
                waitfor
                break
            fi
            frpport=$(netstat -untlp | grep "frps" | awk '{print $4}' | awk -F '[:/]' '{print $4}')
            echo "端口范围: 1-65535，请自行规避其它程序占用的端口。"
            read -e -p "请输入绑定端口号 (回车跳过默认: $frpport) : " port
            if [[ -n $port && $port -ge 1 && $port -le 65535 ]]; then
                bindPort=$port
                echo "bindPort = $bindPort" > $frp_dir/frps.toml
                echo "" >> $frp_dir/frps.toml
            fi
            
            echo "[Unit]" > /etc/systemd/system/frps.service
            echo "Description=frp server" >> /etc/systemd/system/frps.service
            echo "After=network.target syslog.target" >> /etc/systemd/system/frps.service
            echo "Wants=network.target" >> /etc/systemd/system/frps.service
            echo "" >> /etc/systemd/system/frps.service
            echo "[Service]" >> /etc/systemd/system/frps.service
            echo "Type=simple" >> /etc/systemd/system/frps.service
            echo "ExecStart=$frp_dir/frps -c $frp_dir/frps.toml" >> /etc/systemd/system/frps.service
            echo "" >> /etc/systemd/system/frps.service
            echo "[Install]" >> /etc/systemd/system/frps.service
            echo "WantedBy=multi-user.target" >> /etc/systemd/system/frps.service

            cat /etc/systemd/system/frps.service
            sudo systemctl restart frps
            sudo systemctl enable frps
            systemctl daemon-reload
            waitfor
            ;;
        2|22)
            nano $frp_dir/frps.toml
            ;;
        3|33)
            service_file="/etc/systemd/system/frps.service"
            if [ -f "$service_file" ]; then
                sudo systemctl restart frps
                sudo systemctl enable frps
                echo "FRPS 服务已经启动."
            else
                echo "FRPS 服务未配置，请先配置服务."
            fi
            waitfor
            onlyone=0
            ;;
        4|44)
            if netstat -untlp | grep -q "frps"; then
                sudo systemctl stop frps
                sudo systemctl disable frps
                echo "已停止并禁用 FRPS 服务."
            else
                echo "FRPS 服务未启动."
            fi
            waitfor
            onlyone=0
            ;;
        +|++)
            arch=$(uname -m)
            sys_output=$(uname -s)
            if [ "$sys_output" = "Linux" ] && [ "$arch" = "x86_64" ]; then
                arch="amd64"
            fi
            file_name="frp_$(uname -m)"
            file_extension=".tar.gz"
            cd "$frp_dir" || exit
            latest=$(curl -sL https://api.github.com/repos/fatedier/frp/releases/latest | grep -oP 'tag_name": "\K(.*)(?=")' | sed 's/v//')
            download_link="https://github.com/fatedier/frp/releases/download/v${latest}/frp_${latest}_${sys_output}_${arch}.tar.gz"
            echo "$download_link"
            wget -O "frp_${latest}_${sys_output}_${arch}.tar.gz" "${download_link}"
            tar -zxvf "frp_${latest}_${sys_output}_${arch}.tar.gz" --strip-components=1
            rm *.tar.gz
            echo -e "${colored_text1}${NC}"
            echo -e "PATH: ${GR}$frp_dir${NC}"
            ls "$frp_dir"
            if [ -s "frps" ] && [ -s "frpc" ] ; then
                echo "下载/解压成功."
            else
                echo "下载/解压失败!"
            fi
            waitfor
            ;;
        -|--)
            if netstat -untlp | grep -q "frps"; then
                sudo systemctl stop frps
                sudo systemctl disable frps
                echo "已停止并禁用 FRPS 服务."
            fi
            if netstat -untlp | grep -q "frpc"; then
                sudo systemctl stop frpc
                sudo systemctl disable frpc
                echo "已停止并禁用 FRPC 服务."
            fi
            find $frp_dir -type f ! -name '*.toml' -delete
            echo "已成功删除 FRP 服务."
            echo -e "FRP 已成功删除/卸载, 但仍然保留*.toml文件, 如需要进行删除请运行指令: ${GR}rm -rf $frp_dir${NC}"
            waitfor
            ;;
        c|cc)
            rm $frp_dir/*.x
            echo "已经清除标记, 请重新启动脚本."
            waitfor
            exit 0
            onlyone=0
            ;;
        o|O|oo|OO)
            onlyone=0
            ;;
        x|X|xx|XX)
            exit 0
            ;;
        *)
            etag=1
            onlyone=0
            ;;
    esac
    done
######################################################################
elif [ -f "$frp_dir/2.x" ]; then
    while true; do
    runtag="${RE}Not running${NC}"
    setuptag="${RE}Not ready${NC}"
    if netstat -untlp | grep -q "frps"; then
        runtag="${GR}FRPS runing${NC}"
    fi
    if netstat -untlp | grep -q "frpc"; then
        runtag="${GR}FRPC runing${NC}"
    fi
    if [ -f "$frp_dir/frpc" ]; then
        setuptag="${GR}Ready${NC}"
    fi
    clear_screen
    echo -e "${MA} 欢迎使用 FRP 一键脚本工具 ${NC}"
    # echo -e "${BK}■ ${RE}■ ${GR}■ ${YE}■ ${BL}■ ${MA}■ ${CY}■ ${WH}■ ${BL}■ ${GR}■ ${RE}■ ${YE}■ ${BK}■"
    echo -e "${BK}■ ■ ■ ■ ■ ■ ■ ■ ■ ■${NC} $runtag"
    echo -e "${colored_text2}${NC}"
    echo -e "1.  配置 FRP${GR}C${NC} ${YE}客户端${NC} ▶"
    echo -e "2.  手动修改 FRP${GR}C${NC}.toml 配置文件"
    echo -e "${colored_text1}${NC}"
    echo -e "3.  启动/重启 FRP${GR}C${NC}"
    echo -e "4.  停止 FRP"
    echo -e "${colored_text1}${NC}"
    echo -e "+.  下载/解压 FRP  $setuptag"
    echo -e "-.  删除 FRP"
    echo -e "${colored_text1}${NC}"
    echo -e "c.  切换服务端/客户端"
    echo -e "o.  更新脚本"
    echo -e "x.  退出脚本"
    echo -e "${colored_text1}${NC}"
    if [[ $onlyone == 1 ]]; then
        echo -e "${MA}支持双击操作...${NC}"
    else
        remind3p
    fi
    read -e -p "请输入你的选择: " -n 2 -r choice && echoo
    case $choice in
        1|11)
            if [ ! -f "$frp_dir/frpc" ]; then
                echo "请先运行选项 + 进行安装。"
                waitfor
                break
            fi
            read -e -p "请输入服务端的IP地址: " serverAddr
            read -e -p "请输入服务端的端口号: " serverPort

            ;;
        2|22)
            nano $frp_dir/frpc.toml
            ;;
        3|33)
            service_file="/etc/systemd/system/frpc.service"
            if [ -f "$service_file" ]; then
                sudo systemctl restart frpc
                sudo systemctl enable frpc
                echo "FRPC 服务已经启动."
            else
                echo "FRPC 服务未配置，请先配置服务."
            fi
            waitfor
            onlyone=0
            ;;
        4|44)
            if netstat -untlp | grep -q "frpc"; then
                sudo systemctl stop frpc
                sudo systemctl disable frpc
                echo "已停止并禁用 FRPC 服务."
            else
                echo "FRP 服务未启动."
            fi
            waitfor
            onlyone=0
            ;;
        +|++)
            arch=$(uname -m)
            sys_output=$(uname -s)
            if [ "$sys_output" = "Linux" ] && [ "$arch" = "x86_64" ]; then
                arch="amd64"
            fi
            file_name="frp_$(uname -m)"
            file_extension=".tar.gz"
            cd "$frp_dir" || exit
            latest=$(curl -sL https://api.github.com/repos/fatedier/frp/releases/latest | grep -oP 'tag_name": "\K(.*)(?=")' | sed 's/v//')
            download_link="https://github.com/fatedier/frp/releases/download/v${latest}/frp_${latest}_${sys_output}_${arch}.tar.gz"
            echo "$download_link"
            wget -O "frp_${latest}_${sys_output}_${arch}.tar.gz" "${download_link}"
            tar -zxvf "frp_${latest}_${sys_output}_${arch}.tar.gz" --strip-components=1
            rm *.tar.gz
            echo -e "${colored_text1}${NC}"
            echo -e "PATH: ${GR}$frp_dir${NC}"
            ls "$frp_dir"
            if [ -s "frps" ] && [ -s "frpc" ] ; then
                echo "下载/解压成功."
            else
                echo "下载/解压失败!"
            fi
            waitfor
            ;;
        -|--)
            if netstat -untlp | grep -q "frps"; then
                sudo systemctl stop frps
                sudo systemctl disable frps
                echo "已停止并禁用 FRPS 服务."
            fi
            if netstat -untlp | grep -q "frpc"; then
                sudo systemctl stop frpc
                sudo systemctl disable frpc
                echo "已停止并禁用 FRPC 服务."
            fi
            find $frp_dir -type f ! -name '*.toml' -delete
            echo "已成功删除 FRP 服务."
            echo -e "FRP 已成功删除/卸载, 但仍然保留*.toml文件, 如需要进行删除请运行指令: ${GR}rm -rf $frp_dir${NC}"
            waitfor
            ;;
        c|cc)
            rm $frp_dir/*.x
            echo "已经清除标记, 请重新启动脚本."
            waitfor
            exit 0
            onlyone=0
            ;;
        o|O|oo|OO)
            onlyone=0
            ;;
        x|X|xx|XX)
            exit 0
            ;;
        *)
            etag=1
            onlyone=0
            ;;
    esac
    done

fi
