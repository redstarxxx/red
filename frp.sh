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
    elif command -v opkg &>/dev/null; then
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
elif command -v opkg &>/dev/null; then
    pm="opkg"
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
    mkdir -p "$frp_dir"
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
    if [ -f "$frp_dir/frps" ] || [ "$(command -v frps)" ] ; then
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
            if [ -f "$frp_dir/frps" ] || [ "$(command -v frps)" ]; then
                if [ ! -f "$frp_dir/frps.toml" ]; then
                    touch "$frp_dir/frps.toml"
                fi
                # bindPort=$(netstat -untlp | grep "frps" | awk '{print $4}' | awk -F '[:/]' '{print $4}')
                # bindPort=$(grep -Po '^bindPort = \K\d+' "$frp_dir/frps.toml")
                bindPort=$(grep '^bindPort = [0-9]\+' "$frp_dir/frps.toml" | sed 's/^bindPort = \([0-9]\+\)/\1/')
                if [ -z "$bindPort" ]; then
                    bindPort="none"
                fi
                # vhostHTTPPort=$(grep -Po '^vhostHTTPPort = \K\d+' "$frp_dir/frps.toml")
                vhostHTTPPort=$(grep '^vhostHTTPPort = [0-9]\+' "$frp_dir/frps.toml" | sed 's/^vhostHTTPPort = \([0-9]\+\)/\1/')
                if [ -z "$vhostHTTPPort" ]; then
                    vhostHTTPPort="none"
                fi
                # vhostHTTPSPort=$(grep -Po '^vhostHTTPSPort = \K\d+' "$frp_dir/frps.toml")
                vhostHTTPSPort=$(grep '^vhostHTTPSPort = [0-9]\+' "$frp_dir/frps.toml" | sed 's/^vhostHTTPSPort = \([0-9]\+\)/\1/')
                if [ -z "$vhostHTTPSPort" ]; then
                    vhostHTTPSPort="none"
                fi
                echo "端口范围: 1-65535, 请自行规避占用的端口, 输入时不在此范围则直接跳过."
                read -e -p "请输入FRP绑定端口号 (回车跳过|使用中: $bindPort) : " port
                if [[ -n $port && $port -ge 1 && $port -le 65535 ]]; then
                    bindPort=$port
                fi
                read -e -p "请输入HTTP端口号 (回车跳过|使用中: $vhostHTTPPort) : " port
                if [[ -n $port && $port -ge 1 && $port -le 65535 ]]; then
                    vhostHTTPPort=$port
                fi
                read -e -p "请输入HTTPS端口号 (回车跳过|使用中: $vhostHTTPSPort) : " port
                if [[ -n $port && $port -ge 1 && $port -le 65535 ]]; then
                    vhostHTTPSPort=$port
                fi
                echo "bindPort = $bindPort" > $frp_dir/frps.toml
                echo "kcpBindPort = $bindPort" >> $frp_dir/frps.toml
                echo "vhostHTTPPort = $vhostHTTPPort" >> $frp_dir/frps.toml
                echo "vhostHTTPSPort = $vhostHTTPSPort" >> $frp_dir/frps.toml
                read -e -p "请输入服务端的TOKEN (回车跳过) : " authToken
                if [ -n "$authToken" ]; then
                    echo "auth.token = \"$authToken\"" >> $frp_dir/frps.toml
                fi
                echo -e "是否开启服务端 DASHBOARD? 如果开启请直接${GR}输入端口号${NC} (回车跳过) : \c"
                read port
                if [[ -n $port && $port -ge 1 && $port -le 65535 ]]; then
                    echo "webServer.addr = \"0.0.0.0\"" >> $frp_dir/frps.toml
                    webServerPort=$port
                    echo "webServer.port = $webServerPort" >> $frp_dir/frps.toml
                    read -e -p "请输入 DASHBOARD 用户名: " user
                    echo "webServer.user = \"$user\"" >> $frp_dir/frps.toml
                    read -e -p "请输入 DASHBOARD 密码: " password
                    echo "webServer.password = \"$password\"" >> $frp_dir/frps.toml
                    # read -e -p "是否配置服务端 DASHBOARD TSL 证书? (回车跳过/不配置) : " ifnone
                    # if [ -n "$ifnone" ]; then
                    #     read ssl
                    # fi
                fi
                read -e -p "是否开启TCP多路复用, 回车默认开启/N: " tmyn
                if [ ! "$tmyn" = "n" ] && [ ! "$tmyn" = "N" ]; then
                    echo "transport.tcpMux = true" >> "$frp_dir/frps.toml"
                else
                    echo "transport.tcpMux = false" >> "$frp_dir/frps.toml"
                fi
                echo "本脚本只配置可运行的基本信息, 如果需要更多的配置, 请阅读官方文档: https://gofrp.org/zh-cn/docs/reference/server-configures/ 并手动添加."
                read -e -p "配置完成, 是否启动/重启FRPS服务? 回车默认开启/N" choice
                if [ ! "$choice" = "n" ] && [ ! "$choice" = "N" ]; then
                    if command -v systemctl &>/dev/null; then
                        if netstat -untlp | grep -q "frps"; then
                            sudo systemctl restart frps
                        else
                            sudo systemctl start frps
                        fi
                        sudo systemctl enable frps
                        systemctl daemon-reload
                    elif command -v opkg &>/dev/null; then
                        if netstat -untlp | grep -q "frps"; then
                            killall -9 frps
                        fi
                        nohup frps -c "$frp_dir/frps.toml" > "$frp_dir/frps.log" 2>&1 &
                        cat "nohup.out"
                        ps -ef | grep "frps"
                    fi
                    waitfor
                fi
            else
                echo "请先运行选项 + 进行安装。"
                waitfor
            fi
            ;;
        2|22)
            if [ "$(command -v nano)" ]; then
                nano $frp_dir/frps.toml
            else
                vi $frp_dir/frps.toml
            fi
            ;;
        3|33)
            if command -v systemctl &>/dev/null; then
                service_file="/etc/systemd/system/frps.service"
                if [ -f "$service_file" ]; then
                    if netstat -untlp | grep -q "frps"; then
                        sudo systemctl restart frps
                    else
                        sudo systemctl start frps
                    fi
                    sudo systemctl enable frps
                    echo "FRPS 服务已经启动. (systemctl)"
                else
                    echo "FRPS 服务未配置，请先配置服务."
                fi
            elif command -v nohup &>/dev/null; then
                nohup frps -c "$frp_dir/frps.toml" > "$frp_dir/frps.log" 2>&1 &
                cat "nohup.out"
                ps -ef | grep "frps"
                echo "FRPS 服务已经启动. (nohup)"
            else
                echo "运行失败：未检测到相关指令 (systemctl 或 nohup)."
            fi
            waitfor
            onlyone=0
            ;;
        4|44)
            if netstat -untlp | grep -q "frps"; then
                if command -v systemctl &>/dev/null; then
                    sudo systemctl stop frps
                    sudo systemctl disable frps
                else
                    killall -9 frps
                fi
                echo "已停止并禁用 FRPS 服务."
            else
                echo "FRPS 服务未启动."
            fi
            waitfor
            onlyone=0
            ;;
        +|++)
            arch=$(uname -m)
            if command -v opkg &>/dev/null; then
                if [ "$(command -v frps)" ] ; then
                    echo "检测到系统已经安装FPRS."
                else
                    latest=$(curl -sL https://github.com/kuoruan/openwrt-frp/releases/latest | grep -oE "/tag/v[^\"]+" | awk -F '/' '{print $NF}' | sed -n '1s/^v//p')
                    download_link="https://github.com/kuoruan/openwrt-frp/releases/download/v${latest}/frps_${latest}_${arch}.ipk"
                    echo "Download link: $download_link"
                    wget $download_link
                    opkg install "frps_${latest}_${arch}.ipk"
                    if [ "$(command -v frps)" ] ; then
                        echo "安装成功."
                    else
                        echo "安装失败!"
                    fi
                    rm -f "frps_${latest}_${arch}.ipk"
                fi
            else
                sys_output=$(uname -s)
                if [ "$sys_output" = "Linux" ] && [ "$arch" = "x86_64" ]; then
                    arch="amd64"
                fi
                file_name="frp_$(uname -m)"
                file_extension=".tar.gz"
                cd "$frp_dir" || exit
                latest=$(curl -sL https://api.github.com/repos/fatedier/frp/releases/latest | grep -oP 'tag_name": "\K(.*)(?=")' | sed 's/v//')
                download_link="https://github.com/fatedier/frp/releases/download/v${latest}/frp_${latest}_${sys_output}_${arch}.tar.gz"
                echo "Download link: $download_link"
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
            fi
            waitfor
            ;;
        -|--)
            if netstat -untlp | grep -q "frps"; then
                if command -v systemctl &>/dev/null; then
                    sudo systemctl stop frps
                    sudo systemctl disable frps
                else
                    killall -9 frps
                fi
                echo "已停止并禁用 FRPS 服务."
            fi
            if netstat -untlp | grep -q "frpc"; then
                if command -v systemctl &>/dev/null; then
                    sudo systemctl stop frpc
                    sudo systemctl disable frpc
                else
                    killall -9 frpc
                fi
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
    if [ -f "$frp_dir/frpc" ] || [ "$(command -v frpc)" ] ; then
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
            if [ ! -f "$frp_dir/frpc" ] && [ ! "$(command -v frpc)" ]; then
                echo "请先运行选项 + 进行安装。"
                waitfor
                break
            fi
            if command -v systemctl &>/dev/null; then
                service_frpc_file="/etc/systemd/system/frpc.service"
                if [ ! -f "$service_frpc_file" ] || ! grep -q "ExecStart=$frp_dir/frpc -c $frp_dir/frpc.toml" "$service_frpc_file"; then
                    touch "/etc/systemd/system/frpc.service"
                    echo "[Unit]" > /etc/systemd/system/frpc.service
                    echo "Description=frp server" >> /etc/systemd/system/frpc.service
                    echo "After=network.target syslog.target" >> /etc/systemd/system/frpc.service
                    echo "Wants=network.target" >> /etc/systemd/system/frpc.service
                    echo "" >> /etc/systemd/system/frpc.service
                    echo "[Service]" >> /etc/systemd/system/frpc.service
                    echo "Type=simple" >> /etc/systemd/system/frpc.service
                    echo "ExecStart=$frp_dir/frpc -c $frp_dir/frpc.toml" >> /etc/systemd/system/frpc.service
                    echo "" >> /etc/systemd/system/frpc.service
                    echo "[Install]" >> /etc/systemd/system/frpc.service
                    echo "WantedBy=multi-user.target" >> /etc/systemd/system/frpc.service
                fi
            fi
            if [ -s $frp_dir/frpc.toml ]; then
                echo -e "${colored_text1}${NC}"
                cat "$frp_dir/frpc.toml"
                echo -e "${colored_text1}${NC}"
                echo -e "配置文件已经存在. 1.添加客户端 2.手动修改 3.删除配置文件(${GR}重新配置${NC}) 4.回车取消, 请选择操作类型: \c"
                read choice
                if [ "$choice" == "1" ]; then
                    echo "你选择了添加客户端"
                    # name = "PandoraNext"
                    # type = "tcp"
                    # localIP = "10.0.0.100"
                    # localPort = 8181
                    # remotePort = 7002
                    read -e -p "请输入客户端名称: " pname
                    while true; do
                    remind1p
                    echo "传输协议类型: 1.tcp  2.kcp  3.quic  4.websocket  5.wss"
                    read -e -p "请先择 (1/2/3/4/5/C取消): " -n 2 -r choice && echoo
                        case $choice in
                            1|11)
                                en_network="tcp"
                                break
                                ;;
                            2|22)
                                en_network="kcp"
                                break
                                ;;
                            3|33)
                                en_network="quic"
                                break
                                ;;
                            4|44)
                                en_network="websocket"
                                break
                                ;;
                            5|55)
                                en_network="wss"
                                break
                                ;;
                            c|cc|C|CC)
                                break 2
                                ;;
                            *)
                                etag=1
                                ;;
                        esac
                    done
                    read -e -p "请输入本地IP地址: " lIP
                    read -e -p "请输入本地端口号: " lPort
                    read -e -p "请输入远程端口号: " rPort
                    echo "" >> "$frp_dir/frpc.toml"
                    echo "[[proxies]]" >> "$frp_dir/frpc.toml"
                    echo "name = \"$pname\"" >> "$frp_dir/frpc.toml"
                    echo "type = \"$en_network\"" >> "$frp_dir/frpc.toml"
                    echo "localIP = \"$lIP\"" >> "$frp_dir/frpc.toml"
                    echo "localPort = $lPort" >> "$frp_dir/frpc.toml"
                    echo "remotePort = $rPort" >> "$frp_dir/frpc.toml"
                elif [ "$choice" == "2" ]; then
                    if [ "$(command -v nano)" ]; then
                        nano $frp_dir/frpc.toml
                    else
                        vi $frp_dir/frpc.toml
                    fi
                elif [ "$choice" == "3" ]; then
                    rm -f "$frp_dir/frpc.toml"
                    echo "已经删除配置文件$frp_dir/frpc.toml, 请选择选项1重新配置."
                else
                    echo "取消操作."
                fi
            else
                read -e -p "请输入服务端的IP地址: " serverAddr
                read -e -p "请输入服务端的端口号: " serverPort
                while true; do
                remind1p
                echo "传输协议类型: 1.tcp  2.kcp  3.quic  4.websocket  5.wss"
                read -e -p "请先择 (1/2/3/4/5/C取消): " -n 2 -r choice && echoo
                    case $choice in
                        1|11)
                            en_network="tcp"
                            break
                            ;;
                        2|22)
                            en_network="kcp"
                            break
                            ;;
                        3|33)
                            en_network="quic"
                            break
                            ;;
                        4|44)
                            en_network="websocket"
                            break
                            ;;
                        5|55)
                            en_network="wss"
                            break
                            ;;
                        c|cc|C|CC)
                            break 2
                            ;;
                        *)
                            etag=1
                            ;;
                    esac
                done
                if [ -n "$serverAddr" ]; then
                    echo "serverAddr = \"$serverAddr\"" > "$frp_dir/frpc.toml"
                fi
                if [ -n "$serverPort" ]; then
                    echo "serverPort = $serverPort" >> $frp_dir/frpc.toml
                fi
                if [ -n "$choice" ]; then
                    echo "transport.protocol = \"$en_network\"" >> $frp_dir/frpc.toml
                fi
                read -e -p "请输入服务端的TOKEN: " authToken
                if [ -n "$authToken" ]; then
                    echo "auth.token = \"$authToken\"" >> $frp_dir/frpc.toml
                fi
                read -e -p "是否开启TCP多路复用, 回车默认开启/N: " tmyn
                if [ ! "$tmyn" = "n" ] && [ ! "$tmyn" = "N" ]; then
                    echo "transport.tcpMux = true" >> "$frp_dir/frpc.toml"
                else
                    echo "transport.tcpMux = false" >> "$frp_dir/frpc.toml"
                fi
                echo "本脚本只配置可运行的基本信息, 如果需要更多的配置, 请阅读官方文档: https://gofrp.org/zh-cn/docs/reference/client-configures/ 并手动添加."
            fi
            read -e -p "配置完成, 是否启动/重启FRPC服务? Y/回车默认不开启 : " choice
            if [ "$choice" = "y" ] || [ "$choice" = "Y" ]; then
                if command -v systemctl &>/dev/null; then
                    if netstat -untlp | grep -q "frpc"; then
                        sudo systemctl restart frpc
                    else
                        sudo systemctl start frpc
                    fi
                    sudo systemctl enable frpc
                    systemctl daemon-reload
                elif command -v opkg &>/dev/null; then
                    if netstat -untlp | grep -q "frpc"; then
                        killall -9 frpc
                    fi
                    nohup frpc -c "$frp_dir/frpc.toml" > "$frp_dir/frpc.log" 2>&1 &
                    cat "nohup.out"
                    ps -ef | grep "frpc"
                fi
            fi
            waitfor
            ;;
        2|22)
            if [ "$(command -v nano)" ]; then
                nano $frp_dir/frpc.toml
            else
                vi $frp_dir/frpc.toml
            fi
            ;;
        3|33)
            if command -v systemctl &>/dev/null; then
                service_file="/etc/systemd/system/frpc.service"
                if [ -f "$service_file" ]; then
                    if netstat -untlp | grep -q "frpc"; then
                        sudo systemctl restart frpc
                    else
                        sudo systemctl start frpc
                    fi
                    sudo systemctl enable frpc
                    echo "FRPC 服务已经启动. (systemctl)"
                else
                    echo "FRPC 服务未配置，请先配置服务."
                fi
            elif command -v nohup &>/dev/null; then
                nohup frpc -c "$frp_dir/frpc.toml" > "$frp_dir/frpc.log" 2>&1 &
                cat "nohup.out"
                ps -ef | grep "frpc"
                echo "FRPC 服务已经启动. (nohup)"
            else
                echo "运行失败：未检测到相关指令 (systemctl 或 nohup)."
            fi
            waitfor
            onlyone=0
            ;;
        4|44)
            if netstat -untlp | grep -q "frpc"; then
                if command -v systemctl &>/dev/null; then
                    sudo systemctl stop frpc
                    sudo systemctl disable frpc
                else
                    killall -9 frpc
                fi
                echo "已停止并禁用 FRPC 服务."
            else
                echo "FRP 服务未启动."
            fi
            waitfor
            onlyone=0
            ;;
        +|++)
            arch=$(uname -m)
            if command -v opkg &>/dev/null; then
                if [ "$(command -v frpc)" ] ; then
                    echo "检测到系统已经安装FPRC."
                else
                    latest=$(curl -sL https://github.com/kuoruan/openwrt-frp/releases/latest | grep -oE "/tag/v[^\"]+" | awk -F '/' '{print $NF}' | sed -n '1s/^v//p')
                    download_link="https://github.com/kuoruan/openwrt-frp/releases/download/v${latest}/frpc_${latest}_${arch}.ipk"
                    echo "Download link: $download_link"
                    wget $download_link
                    opkg install "frpc_${latest}_${arch}.ipk"
                    if [ "$(command -v frpc)" ] ; then
                        echo "安装成功."
                        echo -e "如果需要安装Frpc的Web管理界面, 请到 https://github.com/kuoruan/luci-app-frpc/releases 下载两个 ${GR}*.ipk${NC} 文件并依次执行 ${GR}opkg install *.ipk${NC} 进行安装."
                    else
                        echo "安装失败!"
                    fi
                    rm -f "frpc_${latest}_${arch}.ipk"
                fi
            else
                sys_output=$(uname -s)
                if [ "$sys_output" = "Linux" ] && [ "$arch" = "x86_64" ]; then
                    arch="amd64"
                fi
                file_name="frp_$(uname -m)"
                file_extension=".tar.gz"
                cd "$frp_dir" || exit
                latest=$(curl -sL https://api.github.com/repos/fatedier/frp/releases/latest | grep -oP 'tag_name": "\K(.*)(?=")' | sed 's/v//')
                download_link="https://github.com/fatedier/frp/releases/download/v${latest}/frp_${latest}_${sys_output}_${arch}.tar.gz"
                echo "Download link: $download_link"
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
            fi
            waitfor
            ;;
        -|--)
            if netstat -untlp | grep -q "frps"; then
                if command -v systemctl &>/dev/null; then
                    sudo systemctl stop frps
                    sudo systemctl disable frps
                else
                    killall -9 frps
                fi
                echo "已停止并禁用 FRPS 服务."
            fi
            if netstat -untlp | grep -q "frpc"; then
                if command -v systemctl &>/dev/null; then
                    sudo systemctl stop frpc
                    sudo systemctl disable frpc
                else
                    killall -9 frpc
                fi
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
        t|T)
            latest=$(curl -sL https://github.com/kuoruan/openwrt-frp/releases/latest | grep -oE "/tag/v[^\"]+" | awk -F '/' '{print $NF}' | sed -n '1s/^v//p')
            echo $latest
            echo "此指令仅调试使用..."
            waitfor
            ;;
        *)
            etag=1
            onlyone=0
            ;;
    esac
    done

fi
