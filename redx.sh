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
virt_check() {
    cname=$(awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//')
    virtualx=$(dmesg 2>/dev/null)
    if [ $(which dmidecode) ]; then
        sys_manu=$(dmidecode -s system-manufacturer 2>/dev/null)
        sys_product=$(dmidecode -s system-product-name 2>/dev/null)
        sys_ver=$(dmidecode -s system-version 2>/dev/null)
    else
        sys_manu=""
        sys_product=""
        sys_ver=""
    fi
    if grep docker /proc/1/cgroup -qa; then
        virtual="Docker"
    elif grep lxc /proc/1/cgroup -qa || grep -qa container=lxc /proc/1/environ; then
        virtual="Lxc"
    elif [ -f /proc/user_beancounters ]; then
        virtual="OpenVZ"
    elif [[ "$virtualx" == *kvm-clock* || "$cname" == *KVM* || "$cname" == *QEMU* ]]; then
        virtual="KVM"
    elif [[ "$virtualx" == *"VMware Virtual Platform"* ]]; then
        virtual="VMware"
    elif [[ "$virtualx" == *"Parallels Software International"* ]]; then
        virtual="Parallels"
    elif [[ "$virtualx" == *VirtualBox* ]]; then
        virtual="VirtualBox"
    elif [ -e /proc/xen ]; then
        virtual="Xen"
    elif [[ "$sys_manu" == *"Microsoft Corporation"* && "$sys_product" == *"Virtual Machine"* ]]; then
        if [[ "$sys_ver" == *"7.0"* || "$sys_ver" == *"Hyper-V"* ]]; then
            virtual="Hyper-V"
        else
            virtual="Microsoft Virtual Machine"
        fi
    else
        virtual="Dedicated"
    fi
}
stopfire() {
    sudo service iptables stop > /dev/null 2>&1
    sudo systemctl stop firewalld > /dev/null 2>&1
    iptables-save > firewall_rules_backup
    iptables -F > /dev/null 2>&1
    ufw disable > /dev/null 2>&1
    # echo "尝试暂停防火墙, 请在操作后重新启动以恢复防火墙功能."
}
recoverfire(){
    sudo service iptables start > /dev/null 2>&1
    sudo systemctl start firewalld > /dev/null 2>&1
    iptables-restore < firewall_rules_backup
    rm -f firewall_rules_backup
    ufw enable > /dev/null 2>&1
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
if ! command -v curl &>/dev/null || ! command -v wget &>/dev/null || ! command -v nano &>/dev/null || ! command -v ifconfig &>/dev/null || ! command -v lsof &>/dev/null; then
    clear_screen
    echo -e "${GR}▼${NC}"
    echo -e "${colored_text2}${NC}"
    echo -e "CURL/WGET/NANO/NET-TOOLS/LSOF"
    read -e -p "检查到部分依赖工具没有安装, 是否要进行安装? (Y/其它跳过): " -n 3 -r choice
    if [[ $choice == "Y" || $choice == "y" ]]; then
        $pm install -y curl wget nano net-tools lsof
    fi
fi
(EUID=$(id -u)) 2>/dev/null
virt_check
onlyone=1
while true; do
clear_screen
if [ "$EUID" -eq 0 ]; then
    user_path="/root"
else
    user_path="/home/$(whoami)"
    echo -e "${GR}当前用户为非root用户, 部分操作可能无法顺利进行.${NC}"
fi
echo -e "${RE}RedX 一键脚本工具 v1.0${NC}"
if [ "$virtual" != "" ]; then
    echo -e "VPS虚拟化类型: ${GR}$virtual${NC}"
fi
echo -e "${MA} ____  _____ ____  ${NC}${RE}__  __ ${NC}"
echo -e "${MA}|  _ \| ____|  _ \ ${NC}${RE}\ \/ / ${NC}"
echo -e "${MA}| |_| |  _| | | | | ${NC}${RE}\  /  ${NC}"
echo -e "${MA}|  _ <| |___| |_| | ${NC}${RE}/  \  ${NC}"
echo -e "${MA}|_| \_\_____|____ /${NC}${RE}/_/\_\ ${NC}"
# echo -e "${BK}■ ${RE}■ ${GR}■ ${YE}■ ${BL}■ ${MA}■ ${CY}■ ${WH}■ ${BL}■ ${GR}■ ${RE}■ ${YE}■ ${BK}■"
echo -e "${BK}■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■${NC}"
echo -e "${colored_text2}${NC}"
echo -e "1.  XRAY  节点相关操作 ▶"
echo -e "2.  ACME  证书相关操作 ▶"
echo -e "3.  BBR   相关操作 ▶"
echo -e "4.  WARP  相关操作 ▶"
echo -e "5.  WIREGUARD  相关操作 ▶"
echo -e "6.  IPTABLES   相关操作 ▶"
echo -e "${colored_text1}${NC}"
echo -e "-.  删除所有.sh子文件"
echo -e "o.  更新脚本"
echo -e "x.  退出脚本"
echo -e "${colored_text1}${NC}"
echo -e "v.  >>>>>>> 声 明 <<<<<<<"
echo -e "${colored_text1}${NC}"
if [[ $onlyone == 1 ]]; then
    echo -e "${MA}支持双击操作...${NC}"
else
    remind3p
fi
read -e -p "请输入你的选择: " -n 2 -r choice && echoo
case $choice in
    1|11)
        if ! command -v jq &>/dev/null || ! command -v qrencode &>/dev/null; then
            clear_screen
            echo -e "${GR}▼${NC}"
            echo -e "${colored_text2}${NC}"
            echo -e "JQ/QRENCODE"
            read -e -p "检查到部分依赖工具没有安装, 是否要进行安装? (Y/其它跳过): " -n 3 -r choice
            if [[ $choice == "Y" || $choice == "y" ]]; then
                $pm install -y jq qrencode
            fi
        fi
        jsonfile="/usr/local/etc/xray/config.json"
        jsonfile_path=$(dirname "$jsonfile")
        check_and_echo() {
            local label="$1"
            local value="$2"
            if [ -n "$value" ] && [ "$value" != "null" ]; then
                local label_length_add2=$(echo -e "$label" | sed 's/\x1B\[[0-9;]*[JKmsu]//g' | wc -c)
                local label_a=$(echo "$label" | tr -cd '[:alnum:]:-' | wc -c)
                label_b=$((label_a - 13))
                label_c=$((label_length_add2 - label_b - 2))
                label_d=$((label_c / 3))
                local spaces=$((30 - label_length_add2 + label_d))
                printf "%b%*s%s\n" "$label" "$spaces" "" "$value"
            fi
        }
        # ====================================================
        # 考虑接管X-UI设置
        #
        # jsonfiletag=""
        # jsonfilen=0
        # if [ -f /usr/local/x-ui/bin/config.json ]; then
        #     jsonfile="/usr/local/x-ui/bin/config.json"
        #     jsonfiletag="X-UI"
        #     jsonfilen=$((jsonfilen+1))
        # fi
        # if [ -f /usr/local/etc/xray/config.json ]; then
        #     jsonfile="/usr/local/etc/xray/config.json"
        #     jsonfiletag="XRAY"
        #     jsonfilen=$((jsonfilen+1))
        # fi
        # if [ $jsonfilen -eq 2 ]; then
        #     while true; do
        #     echo "系统发现以下配置文件:"
        #     echo "1. XRAY官方脚本配置文件  2. XUI面板配置文件"
        #     read -e -p "请选择配置配置文件编号: " choice
        #     if [ $choice -eq 1 ]; then
        #         jsonfile="/usr/local/etc/xray/config.json"
        #         jsonfiletag="XRAY"
        #         break
        #     elif [ $choice -eq 2 ]; then
        #         jsonfile="/usr/local/x-ui/bin/config.json"
        #         jsonfiletag="X-UI"
        #         break
        #     else
        #         echo "请重新选择."
        #     fi
        #     done
        # fi
        # if [[ $jsonfilen -eq 0 ]]; then
        #     while true; do
        #     #echo -e "系统${MA}未发现${NC}配置文件:"
        #     echo "1. XRAY官方脚本  2. X-UI面板"
        #     read -e -p "请选择需要配置类型 (回车默认1.XRAY官方脚本): " choice
        #     if [[ $choice == "1" ]]; then
        #         jsonfile="/usr/local/etc/xray/config.json"
        #         jsonfiletag="XRAY"
        #         break
        #     elif [[ $choice == "2" ]]; then
        #         jsonfile="/usr/local/x-ui/bin/config.json"
        #         jsonfiletag="X-UI"
        #         break
        #     elif [[ $choice == "" ]]; then
        #         jsonfile="/usr/local/etc/xray/config.json"
        #         jsonfiletag="XRAY"
        #         break
        #     else
        #         echo "请重新选择."
        #     fi
        #     done
        # fi
        # ====================================================
        while true; do
        xtag=""
        if ! command -v jq &>/dev/null; then
            xtag="${YE}*${NC}"
        fi
        if command -v xray &>/dev/null; then
            xrayver=$(xray version | head -n 1 | awk '{print $2}')
        else
            xrayver="未安装"
            xtag="${MA}*${NC}"
        fi
        xrayactive=($(systemctl is-active xray.service | tr -d '\n'))
        clear_screen
        echo -e "${GR}▼▼${NC}"
        echo -e "${GR}XRAY${NC} ${MA}$xrayver${NC}   运行状态: ${MA}$xrayactive${NC}"
        echo -e "${colored_text2}${NC}"
        echo -e "1.  创建节点"
        echo -e "2.  查询节点明细"
        echo -e "3.  修改节点   ${BL}未开发暂使用5功能${NC}"
        echo -e "4.  删除节点"
        echo -e "${colored_text1}${NC}"
        echo -e "5.  手动编辑配置文件"
        echo -e "${colored_text1}${NC}"
        echo -e "8.  启动/重启 XRAY 服务"
        echo -e "9.  停止 XRAY 服务"
        echo -e "${colored_text1}${NC}"
        echo -e "v.  查询 XRAY 运行状态"
        echo -e "l.  查询 XRAY 运行日志"
        echo -e "${colored_text1}${NC}"
        echo -e "i.  安装/更新 XRAY 官方脚本 $xtag"
        echo -e "u.  更新 geodata 文件"
        echo -e "d.  删除 XRAY 官方脚本"
        echo -e "${colored_text1}${NC}"
        echo -e "r.  返回主菜单"
        echo -e "x.  退出脚本"
        echo -e "${colored_text1}${NC}"
        remind3p
        read -e -p "请输入你的选择: " -n 2 -r choice && echoo
        case $choice in
            1|11)
                # if ! command -v xray &>/dev/null; then
                if [[ $xtag == *"*"* ]]; then
                    echo -e "检测到系统未安装XRAY, 请先选择第 ${MA}i${NC} 项进行安装."
                    waitfor
                    continue
                fi
                makejsonfile() {
                    jq -n '{
                        "log": {
                            "loglevel": "warning",
                            "access": "/var/log/xray/access.log",
                            "error": "/var/log/xray/error.log"
                        },
                        "api": {
                            "tag": "api",
                            "services": [
                                "HandlerService",
                                "LoggerService",
                                "StatsService"
                            ]
                        },
                        "dns": {
                            "tag": "dns_inbound",
                            "hosts": {},
                            "servers": [
                                "8.8.8.8",
                                "1.1.1.1"
                            ]
                        },
                        "routing": {
                            "domainStrategy": "IPIfNonMatch",
                            "rules": [
                                {
                                    "type": "field",
                                    "outboundTag": "common",
                                    "network": "udp,tcp"
                                },
                                {
                                    "type": "field",
                                    "outboundTag": "blocked",
                                    "ip": [
                                        "geoip:cn",
                                        "geoip:private"
                                    ],
                                    "protocol": [
                                        "bittorrent"
                                    ]
                                }
                            ]
                        },
                        "policy": {
                            "system": {
                                "statsInboundUplink": true,
                                "statsInboundDownlink": true
                            },
                            "levels": {
                                "0": {
                                    "handshake": 5,
                                    "connIdle": 200,
                                    "uplinkOnly": 2,
                                    "downlinkOnly": 5,
                                    "bufferSize": 10240
                                }
                            }
                        },
                        "inbounds": [],
                        "outbounds": [
                            {
                                "tag": "common",
                                "protocol": "freedom"
                            },
                            {
                                "tag": "blocked",
                                "protocol": "blackhole",
                                "settings": {}
                            }
                        ],
                        "stats": null,
                        "reverse": null,
                        "transport": null,
                        "fakeDns": null
                    }' > $jsonfile
                        echo "文件 $jsonfile 创建成功."
                }
                #############################################
                if [ ! -e "$jsonfile" ]; then
                    read -e -p "config.json配置文件不存在。是否创建? (Y/其它跳过): " create
                    if [ "$create" = "y" ] || [ "$create" = "Y" ]; then
                        mkdir -p /usr/local/etc/xray
                        touch $jsonfile
                        makejsonfile
                        waitfor
                    else
                        waitfor
                        continue
                    fi
                fi
                if [[ $(cat $jsonfile | wc -l) -eq 1 ]]; then
                    read -e -p "文件未初始化, 是否要初始化 JSON 文件? (Y/其它取消): " create
                    if [ "$create" = "y" ] || [ "$create" = "Y" ]; then
                        makejsonfile
                        waitfor
                    else
                        echo "未初始化文件, 脚本无法顺利执行."
                        waitfor
                        continue
                    fi
                fi
                short_chars="0123456789abcdef"
                short_id_length=8
                short_id=""
                for (( i = 0; i < short_id_length; i++ )); do
                    short_id+=${short_chars:$RANDOM%16:1}
                done
                while true; do
                en_protocol=""
                en_port=""
                en_trojan_password=""
                en_shadowsocks_method=""
                en_shadowsocks_password=""
                en_network=""
                en_security=""
                en_ws_path=""
                en_ws_host=""
                en_http_user=""
                en_http_password=""
                en_quic_method=""
                en_quic_password=""
                en_quic_fake=""
                en_grpc_serviceName=""
                en_flow=""
                en_tls_serverName=""
                en_tls_certificateFile=""
                en_tls_keyFile=""
                en_reality_dest=""
                en_reality_serverNames=""
                en_reality_fingerprint=""
                en_reality_privateKey=""
                en_reality_publicKey=""
                en_reality_shortIds=""
                en_dokodemo_door_url=""
                en_dokodemo_door_port=""
                en_dokodemo_door_network=""
                en_socks_user=""
                en_socks_password=""
                en_socks_udp=""
                en_socks_udp_ip=""
                en_security_http_path=""
                en_security_http_host=""
                echo -e "${colored_text1}${NC}"
                while true; do
                remind1p
                echo "节点类型: 1.Vmess  2.Vless  3.Trojan  4.Shadowsocks  5.dokodemo-door  6.socks  7.http  8.Wireguard(出口)"
                read -e -p "请先择创建节点类型 (1/2/3/4/5/6/7/8/C取消): " -n 2 -r choice && echoo
                case $choice in
                    1|11)
                        en_protocol="vmess"
                        break
                        ;;
                    2|22)
                        en_protocol="vless"
                        break
                        ;;
                    3|33)
                        en_protocol="trojan"
                        break
                        ;;
                    4|44)
                        en_protocol="shadowsocks"
                        break
                        ;;
                    5|55)
                        en_protocol="dokodemo-door"
                        break
                        ;;
                    6|66)
                        en_protocol="socks"
                        break
                        ;;
                    7|77)
                        en_protocol="http"
                        break
                        ;;
                    8|88)
                        en_protocol="wireguard"
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
                while true; do
                echo -e "${colored_text1}${NC}"
                remind1p
                port_con=0
                echo "使用中的端口:"
                check_port_array=($(jq '.inbounds[] | .port' "$jsonfile"))
                for check_port in "${check_port_array[@]}"; do
                    echo "$check_port"
                done
                echo "端口范围: 1-65535, 请自行规避其它程序占用的端口."
                read -e -p "请输入端口号: " number
                if [[ $number =~ ^[0-9]+$ && $number -ge 1 && $number -le 65535 ]]; then
                    for check_port in "${check_port_array[@]}"; do
                    if [[ $check_port -eq $number ]]; then
                        echo "端口 $number 已经被使用, 请重新输入."
                        port_con=1
                        break
                    fi
                    done
                    if [[ ! $port_con -eq 1 ]]; then
                        en_port=$number
                        break 1
                    fi
                fi
                etag=1
                done
                if [[ $en_protocol == "trojan" ]]; then
                    while true; do
                        characters="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
                        password_length=10
                        random_password=""
                        for i in $(seq 1 $password_length); do
                            random_index=$((RANDOM % ${#characters}))
                            random_char=${characters:$random_index:1}
                            random_password="${random_password}${random_char}"
                        done
                        echo -e "${colored_text1}${NC}"
                        remind1p
                        read -e -p "请设置Trojan密码 (回车默认: 系统生成): " password
                            if [[ $password == "" ]]; then
                                en_trojan_password="$random_password"
                                break
                            else
                                en_trojan_password="$password"
                                break
                            fi
                    done
                fi
                if [[ $en_protocol == "shadowsocks" ]]; then
                    echo -e "${colored_text1}${NC}"
                    while true; do
                    remind1p
                    echo "1. aes-128-gcm"
                    echo "2. aes-256-gcm"
                    echo "3. chacha20-poly1305"
                    echo "4. 2022-blake3-aes-128-gcm"
                    echo "5. 2022-blake3-aes-256-gcm"
                    echo "6. 2022-blake3-chacha20-poly1305"
                    read -e -p "请选择加密模式: " choice
                    case $choice in
                        1|11)
                            en_shadowsocks_method="aes-128-gcm"
                            break
                            ;;
                        2|22)
                            en_shadowsocks_method="aes-256-gcm"
                            break
                            ;;
                        3|33)
                            en_shadowsocks_method="chacha20-poly1305"
                            break
                            ;;
                        4|44)
                            en_shadowsocks_method="2022-blake3-aes-128-gcm"
                            break
                            ;;
                        5|55)
                            en_shadowsocks_method="2022-blake3-aes-256-gcm"
                            break
                            ;;
                        6|66)
                            en_shadowsocks_method="2022-blake3-chacha20-poly1305"
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
                    while true; do
                        characters="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
                        password_length=64
                        random_password=""
                        for i in $(seq 1 $password_length); do
                            random_index=$((RANDOM % ${#characters}))
                            random_char=${characters:$random_index:1}
                            random_password="${random_password}${random_char}"
                        done
                        random_password="${random_password}=="
                        echo -e "${colored_text1}${NC}"
                        remind1p
                        read -e -p "请设置shadowsocks密码 (回车默认: 系统生成): " password
                            if [[ $password == "" ]]; then
                                en_shadowsocks_password="$random_password"
                                break
                            else
                                en_shadowsocks_password="$password"
                                break
                            fi
                    done
                fi
                if [[ $en_protocol == "vmess" || $en_protocol == "vless" || $en_protocol == "trojan" || $en_protocol == "shadowsocks" ]]; then
                    echo -e "${colored_text1}${NC}"
                    while true; do
                    remind1p
                    echo "传输协议类型: 1.tcp  2.kcp  3.ws  4.http  5.quic  6.grpc"
                    read -e -p "请先择 (1/2/3/4/5/6/C取消): " -n 2 -r choice && echoo
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
                            en_network="ws"
                            break
                            ;;
                        4|44)
                            en_network="http"
                            break
                            ;;
                        5|55)
                            en_network="quic"
                            break
                            ;;
                        6|66)
                            en_network="grpc"
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
                    if [[ $en_network == "tcp" ]]; then
                        echo -e "${colored_text1}${NC}"
                        while true; do
                        remind1p
                        echo "传输层安全类型: 1.tls  2.http  3.reality  0.不使用"
                        read -e -p "请先择 (1/2/3/0/C取消): " -n 2 -r choice && echoo
                        case $choice in
                            1|11)
                                en_security="tls"
                                break
                                ;;
                            2|22)
                                en_security="http"
                                break
                                ;;
                            3|33)
                                if [[ $en_protocol == "vless" ]] || [[ $en_protocol == "trojan" ]]; then
                                    en_security="reality"
                                    break
                                else
                                    echo -e "注意, 只有当协议为${MA}Vless${NC}或${MA}Trojan${NC}的时候才能使用Reality传输."
                                    etag=1
                                fi
                                ;;
                            0)
                                en_security=""
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
                    fi
                    if [[ $en_network == "grpc" || $en_network == "http" ]]; then
                        echo -e "${colored_text1}${NC}"
                        while true; do
                        remind1p
                        echo "传输层安全类型: 1.tls  2.reality  0.不使用"
                        read -e -p "请先择 (1/2/0/C取消): " -n 2 -r choice && echoo
                        case $choice in
                            1|11)
                                en_security="tls"
                                break
                                ;;
                            2|22)
                                if [[ $en_protocol == "vless" ]] || [[ $en_protocol == "trojan" ]]; then
                                    en_security="reality"
                                    break
                                else
                                    echo -e "注意, 只有当协议为${MA}Vless${NC}或${MA}Trojan${NC}的时候才能使用Reality传输."
                                    etag=1
                                fi
                                ;;
                            0)
                                en_security=""
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
                    fi
                    if [[ $en_network == "kcp" ]]; then
                        :
                    fi
                    if [[ $en_network == "ws" ]]; then
                        read -e -p "请输入WS-PATH (格式: /path)(回车默认./): " path
                        if [[ $path != "" ]]; then
                            en_ws_path="$path"
                        else
                            en_ws_path="/"
                        fi
                        read -e -p "请输入WS-HOST (回车.无): " host
                        if [[ $host != "" ]]; then
                            en_ws_host="$host"
                        else
                            en_ws_host=""
                        fi
                        while true; do
                        remind1p
                        echo "传输层安全类型: 1.tls  0.不使用"
                        read -e -p "请先择 (1/0/C取消): " -n 2 -r choice && echoo
                        case $choice in
                            1|11)
                                en_security="tls"
                                break
                                ;;
                            0)
                                en_security=""
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
                    fi
                    if [[ $en_network == "http" ]]; then
                        read -e -p "请输入http-PATH (格式: /path)(回车默认./): " path
                        if [[ $path != "" ]]; then
                            en_http_path="$path"
                        else
                            en_http_path="/"
                        fi
                        read -e -p "请输入http-HOST (回车.无): " host
                        if [[ $host != "" ]]; then
                            en_http_host="$host"
                        else
                            en_http_host=""
                        fi
                    fi
                    if [[ $en_network == "quic" ]]; then
                        echo -e "${colored_text1}${NC}"
                        while true; do
                        remind1p
                        echo "1. aes-128-gcm"
                        echo "2. chacha20-poly1305"
                        read -e -p "请选择加密模式: " choice
                        case $choice in
                            1|11)
                                en_quic_method="aes-128-gcm"
                                break
                                ;;
                            2|22)
                                en_quic_method="chacha20-poly1305"
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
                        while true; do
                        characters="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
                        password_length=10
                        random_password=""
                        for i in $(seq 1 $password_length); do
                            random_index=$((RANDOM % ${#characters}))
                            random_char=${characters:$random_index:1}
                            random_password="${random_password}${random_char}"
                        done
                        echo -e "${colored_text1}${NC}"
                        remind1p
                        read -e -p "请设置QUIC密码 (回车默认: 系统生成): " password
                            if [[ $password == "" ]]; then
                                en_quic_password="$random_password"
                                break
                            else
                                en_quic_password="$password"
                                break
                            fi
                        done
                        echo -e "${colored_text1}${NC}"
                        while true; do
                        remind1p
                        echo "1.srtp 2.utp 3.wechat-video 4.dtls 5.wireguard"
                        echo "2. chacha20-poly1305"
                        read -e -p "请选择伪装模式: " choice
                        case $choice in
                            1|11)
                                en_quic_fake="srtp"
                                break
                                ;;
                            2|22)
                                en_quic_fake="utp"
                                break
                                ;;
                            3|33)
                                en_quic_fake="wechat-video"
                                break
                                ;;
                            4|44)
                                en_quic_fake="dtls"
                                break
                                ;;
                            5|55)
                                en_quic_fake="wireguard"
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
                    fi
                    if [[ $en_network == "grpc" ]]; then
                        read -e -p "请输入grpc-serviceName (回车.无): " name
                        if [[ $name != "" ]]; then
                            en_grpc_serviceName="$name"
                        else
                            en_grpc_serviceName=""
                        fi
                    fi
                    if [[ $en_protocol == "vless" && $en_network == "tcp" && $en_security == "tls" ]] ||
                    [[ $en_protocol == "vless" && $en_network == "tcp" && $en_security == "reality" ]] ||
                    [[ $en_protocol == "vless" && $en_network == "grpc" && $en_security == "reality" ]]; then
                        echo -e "${colored_text1}${NC}"
                        remind1p
                        echo -e "流控Flow方式 :  1.xtls-rprx-vision  0/其它.无"
                        read -e -p "请选择流控flow方式编号 : " choice
                        if [[ $choice == 1 ]]; then
                            en_flow="xtls-rprx-vision"
                        else
                            en_flow=""
                        fi
                    fi
                    if [[ $en_security == "tls" ]]; then
                        echo -e "${colored_text1}${NC}"
                        remind1p
                        read -e -p "请输入tls域名: " url
                        en_tls_serverName="$url"
                        read -e -p "请输入公钥文件路径: " url
                        en_tls_certificateFile="$url"
                        read -e -p "请输入密钥文件路径: " url
                        en_tls_keyFile="$url"
                    fi
                    if [[ $en_security == "http" ]]; then
                        echo -e "${colored_text1}${NC}"
                        remind1p
                        read -e -p "请输入请求路径: " url
                        en_security_http_path="$url"
                        read -e -p "请输入请求头: " url
                        en_security_http_host="$url"
                    fi
                    if [[ $en_security == "reality" ]]; then
                        echo -e "${colored_text1}${NC}"
                        remind1p
                        read -e -p "请输入dest地址(带端口) (回车默认: www.yahoo.com:443): " url
                        if [[ $url == "" ]]; then
                            en_reality_dest="www.yahoo.com:443"
                        else
                            en_reality_dest="$url"
                        fi
                        remind1p
                        read -e -p "请输入serverNames地址 (回车默认: www.yahoo.com): " url
                        if [[ $url == "" ]]; then
                            en_reality_serverNames="www.yahoo.com"
                        else
                            en_reality_serverNames="$url"
                        fi
                        remind1p
                        echo -e "请选择fingerprint: 1.chrome  2.firefox  3.safari  4.edge  5.ios  6.android"
                        read -e -p "请输入fingerprint编号: (回车默认: chrome): " choice
                        case $choice in
                        1|11)
                            en_reality_fingerprint="chrome"
                            ;;
                        2|22)
                            en_reality_fingerprint="firefox"
                            ;;
                        3|33)
                            en_reality_fingerprint="safari"
                            ;;
                        4|44)
                            en_reality_fingerprint="edge"
                            ;;
                        5|55)
                            en_reality_fingerprint="ios"
                            ;;
                        6|66)
                            en_reality_fingerprint="android"
                            ;;
                        "")
                            en_reality_fingerprint="chrome"
                            ;;
                        *)
                            etag=1
                            break
                            ;;
                        esac
                        en_reality_privateKey=$(echo "$(xray x25519)" | sed -n 's/Private key: \(.*\)/\1/p')
                        en_reality_publicKey=$(echo "$(xray x25519)" | sed -n 's/Public key: \(.*\)/\1/p')
                        en_reality_shortIds=$short_id

                        ############## 自行输入设置
                        # read -e -p "请输入privateKey (回车默认: 系统生成): " url
                        # if [[ $url == "" ]]; then
                        #     en_reality_privateKey=$(echo "$(xray x25519)" | sed -n 's/Private key: \(.*\)/\1/p')
                        # else
                        #     en_reality_privateKey="$url"
                        # fi
                        # read -e -p "请输入publicKey (回车默认: 系统生成): " url
                        # if [[ $url == "" ]]; then
                        #     en_reality_publicKey=$(echo "$(xray x25519)" | sed -n 's/Public key: \(.*\)/\1/p')
                        # else
                        #     en_reality_publicKey="$url"
                        # fi
                        # read -e -p "请输入shortIds (回车默认: 系统生成): " url
                        # if [[ $url == "" ]]; then
                        #     en_reality_shortIds=$short_id
                        # else
                        #     en_reality_shortIds="$url"
                        # fi
                        #########################################
                    fi
                fi
                if [[ $en_protocol == "dokodemo-door" ]]; then
                    echo -e "${colored_text1}${NC}"
                    remind1p
                    read -e -p "请输入目标地址: " url
                    en_dokodemo_door_url="$url"
                    read -e -p "请输入目标端口: " port
                    en_dokodemo_door_port="$port"
                    while true; do
                    remind1p
                    echo "1.TCP+UDP  2.TCP  3.UDP"
                    read -e -p "请选择网络模式: " choice
                    case $choice in
                        1|11)
                            en_dokodemo_door_network="tcp,udp"
                            break
                            ;;
                        2|22)
                            en_dokodemo_door_network="tcp"
                            break
                            ;;
                        3|33)
                            en_dokodemo_door_network="udp"
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

                fi
                if [[ $en_protocol == "socks" ]]; then
                    echo -e "${colored_text1}${NC}"
                    remind1p
                    read -e -p "是否启用密码认证? (Y/N): " choice
                    if [[ $choice == "Y" || $choice == "y" ]]; then
                        read -e -p "请输入SOCKS用户名: " name
                        en_socks_user="$name"
                        read -e -p "请输入密码: " password
                        en_socks_password="$password"
                    fi
                    read -e -p "是否启用UDP? (Y/N): " choice
                    if [[ $choice == "Y" || $choice == "y" ]]; then
                        en_socks_udp="true"
                        read -e -p "请输入IP (回车默认: 127.0.0.1): " ip
                        if [[ $ip == "" ]]; then
                            en_socks_udp_ip="127.0.0.1"
                        fi
                        en_socks_udp_ip="$ip"
                    else
                        en_socks_udp="false"
                    fi
                fi
                if [[ $en_protocol == "http" ]]; then
                    echo -e "${colored_text1}${NC}"
                    remind1p
                    read -e -p "请输入HTTP用户名: " name
                    en_http_user="$name"
                    read -e -p "请输入密码: " password
                    en_http_password="$password"
                fi
                if [[ $en_protocol == "wireguard" ]]; then
                    echo -e "${colored_text1}${NC}"
                    remind1p
                    read -e -p "暂未开发..." , choice
                    waitfor
                fi
                echo -e "${colored_text1}${NC}"
                echo -e "${CY}信息确认${NC}"
                check_and_echo "${GR}协议类型${NC}:" "$en_protocol"
                check_and_echo "${GR}端口号${NC}:" "$en_port"
                check_and_echo "${GR}UUID${NC}:" "$uuid"
                check_and_echo "${GR}流控Flow方式${NC}:" "$en_flow"
                check_and_echo "${GR}Trojan密码${NC}:" "$en_trojan_password"
                check_and_echo "${GR}Shadowsocks加密方式${NC}:" "$en_shadowsocks_method"
                check_and_echo "${GR}Shadowsocks密码${NC}:" "$en_shadowsocks_password"
                check_and_echo "${GR}网络类型${NC}:" "$en_network"
                check_and_echo "${GR}安全性设置${NC}:" "$en_security"
                check_and_echo "${GR}WS路径${NC}:" "$en_ws_path"
                check_and_echo "${GR}WS主机${NC}:" "$en_ws_host"
                check_and_echo "${GR}HTTP路径${NC}:" "$en_security_http_path"
                check_and_echo "${GR}HTTP主机${NC}:" "$en_security_http_host"
                check_and_echo "${GR}QUIC加密方式${NC}:" "$en_quic_method"
                check_and_echo "${GR}QUIC密码${NC}:" "$en_quic_password"
                check_and_echo "${GR}QUIC伪装类型${NC}:" "$en_quic_fake"
                check_and_echo "${GR}gRPC服务名${NC}:" "$en_grpc_serviceName"
                check_and_echo "${GR}TLS服务器名${NC}:" "$en_tls_serverName"
                check_and_echo "${GR}TLS证书文件路径${NC}:" "$en_tls_certificateFile"
                check_and_echo "${GR}TLS私钥文件路径${NC}:" "$en_tls_keyFile"
                check_and_echo "${GR}Reality目标地址${NC}:" "$en_reality_dest"
                check_and_echo "${GR}Reality服务器名${NC}:" "$en_reality_serverNames"
                check_and_echo "${GR}Reality指纹${NC}:" "$en_reality_fingerprint"
                check_and_echo "${GR}Reality私钥${NC}:" "$en_reality_privateKey"
                check_and_echo "${GR}Reality公钥${NC}:" "$en_reality_publicKey"
                check_and_echo "${GR}Reality-ShortIds${NC}:" "$en_reality_shortIds"
                check_and_echo "${GR}Dokodemo-Door目标地址${NC}:" "$en_dokodemo_door_url"
                check_and_echo "${GR}Dokodemo-Door目标端口${NC}:" "$en_dokodemo_door_port"
                check_and_echo "${GR}Dokodemo-Door网络模式${NC}:" "$en_dokodemo_door_network"
                check_and_echo "${GR}SOCKS用户名${NC}:" "$en_socks_user"
                check_and_echo "${GR}SOCKS密码${NC}:" "$en_socks_password"
                check_and_echo "${GR}SOCKS-UDP-IP${NC}:" "$en_socks_udp_ip"
                check_and_echo "${GR}HTTP用户名${NC}:" "$en_http_user"
                check_and_echo "${GR}HTTP密码${NC}:" "$en_http_password"
                remind1p
                while true; do
                read -e -p "请确认信息，是否决定创建? (Y/C取消): " choice
                if [[ $choice == "Y" || $choice == "y" ]]; then
                    echo "节点正在创建..."
                    # ipaddress=$(curl ifconfig.me)
                    # 新对象的内容
                    new_inbound='{
                    "listen": null,
                    "port": null,
                    "protocol": null,
                    "settings": {
                        "clients": [],
                        "decryption": "none",
                        "fallbacks": [],
                        "accounts": []
                    },
                    "streamSettings": {
                        "network": null,
                        "security": "none",
                        "tlsSettings": {
                            "serverName": null,
                            "minVersion": "1.2",
                            "maxVersion": "1.3",
                            "cipherSuites": "",
                            "certificates": [
                                {
                                "ocspStapling": 3600
                                }
                            ],
                            "alpn": [
                                "http/1.1",
                                "h2"
                            ],
                            "settings": [
                                {
                                "allowInsecure": false,
                                "fingerprint": "",
                                "serverName": ""
                                }
                            ]
                        },
                        "realitySettings": {
                            "show": false,
                            "fingerprint": null,
                            "dest": null,
                            "xver": 0,
                            "serverNames": [
                            ],
                            "privateKey": null,
                            "publicKey": null,
                            "minClientVer": "",
                            "maxClientVer": "",
                            "maxTimeDiff": 0,
                            "shortIds": [
                            ]
                        },
                        "tcpSettings": {
                            "acceptProxyProtocol": false,
                            "header": {
                                "type": "none"
                            }
                        }
                    },
                    "tag": null,
                    "sniffing": {
                        "enabled": true,
                        "destOverride": [
                        "http",
                        "tls",
                        "quic"
                        ]
                    }
                    }'
                    #############################################
                    # 定义方式暂未使用
                    #
                    # i_protocol=".protocol"
                    # i_port=".port"
                    # i_id=".settings.clients[0].id"
                    # i_network=".streamSettings.network"
                    # i_security=".streamSettings.security"
                    # i_tls_flow=".settings.clients[0].flow"
                    # i_tls_serverName=".streamSettings.tlsSettings.serverName"
                    # i_tls_certificateFile=".streamSettings.tlsSettings.certificates[0].certificateFile"
                    # i_tls_keyFile=".streamSettings.tlsSettings.certificates[0].keyFile"
                    # i_reality_dest=".streamSettings.realitySettings.dest"
                    # i_reality_fingerprint=".streamSettings.realitySettings.fingerprint"
                    # i_reality_serverNames=".streamSettings.realitySettings.serverNames[0]"
                    # i_reality_privateKey=".streamSettings.realitySettings.privateKey"
                    # i_reality_publicKey=".streamSettings.realitySettings.publicKey"
                    # i_reality_shortIds=".streamSettings.realitySettings.shortIds[0]"
                    # i_ws_path=".streamSettings.wsSettings.path"
                    # i_ws_host=".streamSettings.wsSettings.headers.Host"
                    #############################################
                    jq ".inbounds += [$new_inbound]" "$jsonfile" > temp.json && mv temp.json "$jsonfile"

                    write_json_if() {
                        address="$1"
                        label="$2"
                        if [[ $label != "" ]]; then
                            jq --arg label "$label" '$address = $label' "$jsonfile" > temp.json && mv temp.json "$jsonfile"
                        fi
                    }

                    jq --argjson en_port "$en_port" \
                    --arg en_protocol "$en_protocol" \
                    --arg en_network "$en_network" \
                    '.inbounds[-1].port = $en_port |
                    .inbounds[-1].protocol = $en_protocol |
                    .inbounds[-1].tag = "inbound-\($en_port)" |
                    .inbounds[-1].streamSettings.network = $en_network' \
                    "$jsonfile" > temp.json && mv temp.json "$jsonfile"

                    if [[ $en_protocol == "vmess" ]] || [[ $en_protocol == "vless" ]]; then
                        uuid=$(xray uuid)
                        jq --arg uuid "$uuid" \
                        '.inbounds[-1].settings.clients[0].id = $uuid' \
                        "$jsonfile" > temp.json && mv temp.json "$jsonfile"
                    fi
                    if [[ $en_protocol == "vmess" ]]; then
                        jq '.inbounds[-1].settings.disableInsecureEncryption = false' \
                        "$jsonfile" > temp.json && mv temp.json "$jsonfile"
                    fi
                    if [[ $en_protocol == "trojan" ]]; then
                        jq --arg en_trojan_password "$en_trojan_password" \
                        '.inbounds[-1].settings.clients[0].password = $en_trojan_password' \
                        "$jsonfile" > temp.json && mv temp.json "$jsonfile"
                    fi

                    if [[ $en_protocol == "shadowsocks" ]]; then
                        jq --arg en_shadowsocks_method "$en_shadowsocks_method" \
                        --arg en_shadowsocks_password "$en_shadowsocks_password" \
                        '.inbounds[-1].settings.method = $en_shadowsocks_method |
                        .inbounds[-1].settings.password = $en_shadowsocks_password' \
                        "$jsonfile" > temp.json && mv temp.json "$jsonfile"
                    fi
                    if [[ $en_protocol == "dokodemo-door" ]]; then
                        jq --arg en_dokodemo_door_url "$en_dokodemo_door_url" \
                        --arg en_dokodemo_door_port "$en_dokodemo_door_port" \
                        --arg en_dokodemo_door_network "$en_dokodemo_door_network" \
                        'del(.inbounds[-1].streamSettings.tlsSettings) |
                        del(.inbounds[-1].streamSettings.realitySettings) |
                        .inbounds[-1].settings.address = $en_dokodemo_door_url |
                        .inbounds[-1].settings.port = $en_dokodemo_door_port |
                        .inbounds[-1].settings.network = $en_dokodemo_door_network' \
                        "$jsonfile" > temp.json && mv temp.json "$jsonfile"
                    fi
                    if [[ $en_protocol == "socks" ]]; then
                        jq --arg en_socks_user "$en_socks_user" \
                        --arg en_socks_password "$en_socks_password" \
                        'del(.inbounds[-1].streamSettings.tlsSettings) |
                        del(.inbounds[-1].streamSettings.realitySettings) |
                        .inbounds[-1].settings.auth = "password" |
                        .inbounds[-1].settings.accounts[0].user = $en_socks_user |
                        .inbounds[-1].settings.accounts[0].pass = $en_socks_password' \
                        "$jsonfile" > temp.json && mv temp.json "$jsonfile"
                        if [[ "$en_socks_udp" == "true" ]]; then
                            jq --argjson en_socks_udp true \
                            --arg en_socks_udp_ip "$en_socks_udp_ip" \
                            '.inbounds[-1].settings.udp = $en_socks_udp |
                            .inbounds[-1].settings.ip = $en_socks_udp_ip' \
                            "$jsonfile" > temp.json && mv temp.json "$jsonfile"
                        fi
                    fi
                    if [[ $en_protocol == "http" ]]; then
                        jq --arg en_http_user "$en_http_user" \
                        --arg en_http_password "$en_http_password" \
                        'del(.inbounds[-1].streamSettings.tlsSettings) |
                        del(.inbounds[-1].streamSettings.realitySettings) |
                        .inbounds[-1].settings.accounts[0].user = $en_http_user |
                        .inbounds[-1].settings.accounts[0].pass = $en_http_password' \
                        "$jsonfile" > temp.json && mv temp.json "$jsonfile"
                    fi
                    if [[ $en_network == "grpc" ]]; then
                        jq --arg en_grpc_serviceName "$en_grpc_serviceName" \
                        '.inbounds[-1].streamSettings.grpcSettings.serviceName = $en_grpc_serviceName' \
                        "$jsonfile" > temp.json && mv temp.json "$jsonfile"
                    fi
                    if [[ $en_network == "ws" ]]; then
                        jq --arg en_ws_path "$en_ws_path" \
                        --arg en_ws_host "$en_ws_host" \
                        'del(.inbounds[-1].streamSettings.tcpSettings) |
                        .inbounds[-1].streamSettings.wsSettings.path = $en_ws_path |
                        .inbounds[-1].streamSettings.wsSettings.headers.Host = $en_ws_host |
                        .inbounds[-1].streamSettings.wsSettings.acceptProxyProtocol = false' \
                        "$jsonfile" > temp.json && mv temp.json "$jsonfile"
                    fi
                    ##############默认文件已经添加，这里留着备用
                    # if [[ $en_network == "tcp" ]]; then
                    #     jq '.inbounds[-1].streamSettings.tlsSettings.acceptProxyProtocol = false' \
                    #     "$jsonfile" > temp.json && mv temp.json "$jsonfile"
                    # fi
                    ##########################
                    if [[ $en_flow != "" ]]; then
                        jq --arg en_flow "$en_flow" \
                        '.inbounds[-1].settings.clients[0].flow = $en_flow' \
                        "$jsonfile" > temp.json && mv temp.json "$jsonfile"
                    fi
                    if [[ $en_security != "" ]]; then
                        jq --arg en_security "$en_security" \
                        '.inbounds[-1].streamSettings.security = $en_security' \
                        "$jsonfile" > temp.json && mv temp.json "$jsonfile"
                    fi
                    if [[ $en_security == "tls" ]]; then

                        if [ -f "$en_tls_certificateFile" ]; then
                            mkdir -p "$jsonfile_path/ssl"
                            chown -R nobody:nogroup "$jsonfile_path/ssl"
                            cer_name=$(basename "$en_tls_certificateFile")
                            cp "$en_tls_certificateFile" "$jsonfile_path/ssl" && chown -R nobody:nogroup "$jsonfile_path/ssl/$cer_name"
                            new_en_tls_certificateFile="$jsonfile_path/ssl/$cer_name"
                        else
                            echo "cer文件未找到"
                            new_en_tls_certificateFile=""
                        fi
                        if [ -f "$en_tls_keyFile" ]; then
                            mkdir -p "$jsonfile_path/ssl"
                            chown -R nobody:nogroup "$jsonfile_path/ssl"
                            key_name=$(basename "$en_tls_keyFile")
                            cp "$en_tls_keyFile" "$jsonfile_path/ssl" && chown -R nobody:nogroup "$jsonfile_path/ssl/$key_name"
                            new_en_tls_keyFile="$jsonfile_path/ssl/$key_name"
                        else
                            echo "key文件未找到"
                            new_en_tls_keyFile=""
                        fi

                        jq --arg en_tls_serverName "$en_tls_serverName" \
                        --arg new_en_tls_certificateFile "$new_en_tls_certificateFile" \
                        --arg new_en_tls_keyFile "$new_en_tls_keyFile" \
                        'del(.inbounds[-1].streamSettings.realitySettings) |
                        .inbounds[-1].streamSettings.tlsSettings.serverName = $en_tls_serverName |
                        .inbounds[-1].streamSettings.tlsSettings.certificates[0].certificateFile = $new_en_tls_certificateFile |
                        .inbounds[-1].streamSettings.tlsSettings.certificates[0].keyFile = $new_en_tls_keyFile' \
                        "$jsonfile" > temp.json && mv temp.json "$jsonfile"
                    fi
                    if [[ $en_security == "reality" ]]; then
                        jq --arg en_reality_dest "$en_reality_dest" \
                        --arg en_reality_serverNames "$en_reality_serverNames" \
                        --arg en_reality_fingerprint "$en_reality_fingerprint" \
                        --arg en_reality_privateKey "$en_reality_privateKey" \
                        --arg en_reality_publicKey "$en_reality_publicKey" \
                        --arg en_reality_shortIds "$en_reality_shortIds" \
                        'del(.inbounds[-1].streamSettings.tlsSettings) |
                        .inbounds[-1].streamSettings.realitySettings.dest = $en_reality_dest |
                        .inbounds[-1].streamSettings.realitySettings.serverNames[0] = $en_reality_serverNames |
                        .inbounds[-1].streamSettings.realitySettings.fingerprint = $en_reality_fingerprint |
                        .inbounds[-1].streamSettings.realitySettings.privateKey = $en_reality_privateKey |
                        .inbounds[-1].streamSettings.realitySettings.publicKey = $en_reality_publicKey |
                        .inbounds[-1].streamSettings.realitySettings.shortIds[0] = $en_reality_shortIds' \
                        "$jsonfile" > temp.json && mv temp.json "$jsonfile"
                    fi
                    if [[ $en_security == "http" ]]; then
                        http_header='{
                            "header": {
                                "type": "http",
                                "request": {
                                    "method": "GET",
                                    "path": [
                                        "/pathxxx"
                                    ],
                                    "headers": {
                                        "Host": [
                                            "hostxxx.com"
                                        ]
                                    }
                                },
                                "response": {
                                    "version": "1.1",
                                    "status": "200",
                                    "reason": "OK",
                                    "headers": {}
                                }
                            }
                        }'
                        jq ".inbounds[-1].streamSettings.tcpSettings += {$http_header}" "$jsonfile" > temp.json && mv temp.json "$jsonfile"
                        jq --arg en_security_http_path "$en_security_http_path" \
                        --arg en_security_http_host "$en_security_http_host" \
                        'del(.inbounds[-1].streamSettings.realitySettings) |
                        del(.inbounds[-1].streamSettings.tlsSettings) |
                        .inbounds[-1].streamSettings.tlsSettings.header.request.path[0] = $en_security_http_path |
                        .inbounds[-1].streamSettings.tlsSettings.header.request.headers.Host[0] = $en_security_http_host' \
                        "$jsonfile" > temp.json && mv temp.json "$jsonfile"
                    fi

                    # cat $jsonfile 
                    # waitfor ########## 方便调试时使用

                    rd_port=$(jq -r '.inbounds[-1].port' "$jsonfile")
                    rd_protocol=$(jq -r '.inbounds[-1].protocol' "$jsonfile")
                    rd_network=$(jq -r '.inbounds[-1].streamSettings.network' "$jsonfile")
                    rd_security=$(jq -r '.inbounds[-1].streamSettings.security' "$jsonfile")
                    rd_tls_serverName=$(jq -r '.inbounds[-1].streamSettings.tlsSettings.serverName' "$jsonfile")
                    rd_tls_certificateFile=$(jq -r '.inbounds[-1].streamSettings.tlsSettings.certificates[0].certificateFile' "$jsonfile")
                    rd_tls_keyFile=$(jq -r '.inbounds[-1].streamSettings.tlsSettings.certificates[0].keyFile' "$jsonfile")
                    rd_grpc_serviceName=$(jq -r '.inbounds[-1].streamSettings.grpcSettings.serviceName' "$jsonfile")
                    rd_ws_path=$(jq -r '.inbounds[-1].streamSettings.wsSettings.path' "$jsonfile")
                    rd_ws_host=$(jq -r '.inbounds[-1].streamSettings.wsSettings.headers.Host' "$jsonfile")
                    rd_reality_dest=$(jq -r '.inbounds[-1].streamSettings.realitySettings.dest' "$jsonfile")
                    rd_reality_serverNames=$(jq -r '.inbounds[-1].streamSettings.realitySettings.serverNames[0]' "$jsonfile")
                    rd_reality_fingerprint=$(jq -r '.inbounds[-1].streamSettings.realitySettings.fingerprint' "$jsonfile")
                    rd_reality_privateKey=$(jq -r '.inbounds[-1].streamSettings.realitySettings.privateKey' "$jsonfile")
                    rd_reality_publicKey=$(jq -r '.inbounds[-1].streamSettings.realitySettings.publicKey' "$jsonfile")
                    rd_reality_shortIds=$(jq -r '.inbounds[-1].streamSettings.realitySettings.shortIds[0]' "$jsonfile")
                    rd_client_id=$(jq -r '.inbounds[-1].settings.clients[0].id' "$jsonfile")
                    rd_client_flow=$(jq -r '.inbounds[-1].settings.clients[0].flow' "$jsonfile")
                    rd_protocol=$(jq -r '.inbounds[-1].protocol' "$jsonfile")
                    rd_trojan_password=$(jq -r '.inbounds[-1].settings.clients[0].password' "$jsonfile")
                    rd_shadowsocks_method=$(jq -r '.inbounds[-1].settings.method' "$jsonfile")
                    rd_shadowsocks_password=$(jq -r '.inbounds[-1].settings.password' "$jsonfile")
                    rd_dokodemo_door_url=$(jq -r '.inbounds[-1].settings.address' "$jsonfile")
                    rd_dokodemo_door_port=$(jq -r '.inbounds[-1].settings.port' "$jsonfile")
                    rd_dokodemo_door_network=$(jq -r '.inbounds[-1].settings.network' "$jsonfile")
                    rd_socks_user=$(jq -r '.inbounds[-1].settings.accounts[0].user' "$jsonfile")
                    rd_socks_password=$(jq -r '.inbounds[-1].settings.accounts[0].pass' "$jsonfile")
                    rd_socks_udp=$(jq -r '.inbounds[-1].settings.udp' "$jsonfile")
                    rd_socks_udp_ip=$(jq -r '.inbounds[-1].settings.ip' "$jsonfile")
                    rd_http_user=$(jq -r '.inbounds[-1].settings.accounts[0].user' "$jsonfile")
                    rd_http_password=$(jq -r '.inbounds[-1].settings.accounts[0].pass' "$jsonfile")
                    rd_security_http_path=$(jq -r '.inbounds[-1].streamSettings.tlsSettings.header.request.path[0]' "$jsonfile")
                    rd_security_http_host=$(jq -r '.inbounds[-1].streamSettings.tlsSettings.header.request.headers.Host[0]' "$jsonfile")

                    #################由于需要联网速度太慢暂时只使用IPv4
                    # IPv4_address=$(curl -4 ip.sb 2> /dev/null) > /dev/null
                    # IPv6_address=$(curl -6 ip.sb 2> /dev/null) > /dev/null
                    # ifconfig_output=$(ifconfig)
                    # if [[ $ifconfig_output =~ $IPv4_address ]]; then
                    #     IP_address=$IPv4_address
                    # elif [[ $ifconfig_output =~ $IPv6_address ]]; then
                    #     IP_address=$IPv6_address
                    # else
                    # IP_address=$IPv4_address
                    # fi
                    ############################################
                    ipv4_addresses=($(ifconfig | grep -oP 'inet \K[\d.]+' | grep -v '^127\.'))
                    ipv6_addresses=($(ifconfig | grep -oP 'inet6 \K[\da-f:]+' | grep -vE '^:|^(fe80)'))

                    all46_addresses=("${ipv4_addresses[@]}" "${ipv6_addresses[@]}")
                    echo -e "${colored_text1}${NC}"
                    echo "请选择一个 IP 地址："
                    for ((i=0; i<${#all46_addresses[@]}; i++)); do
                        echo "[$(($i+1))]     ${all46_addresses[$i]}"
                    done
                    remind1p
                    read -p "输入序号以选择链接所使用的 IP 地址: " selected_index
                    adjusted_index=$(($selected_index - 1))
                    if [ "$adjusted_index" -ge 0 ] && [ "$adjusted_index" -lt "${#all46_addresses[@]}" ]; then
                        IP_address=${all46_addresses[$adjusted_index]}
                    else
                        echo "无效的选择。"
                        IP_address=""
                    fi
                    ############################################

                    # cat $jsonfile | jq '.inbounds as $in | .outbounds | select(. != null) as $out | $in, $out' ########## 方便调试时关闭
                    # cat $jsonfile 
                    # clear_screen ########## 方便调试时关闭

                    echo -e "${GR}▼▼${NC}"
                    check_and_echo "${GR}协议类型${NC}:" "$rd_protocol"
                    check_and_echo "${GR}端口号${NC}:" "$rd_port"
                    check_and_echo "${GR}UUID${NC}:" "$rd_client_id"
                    check_and_echo "${GR}流控Flow方式${NC}:" "$rd_client_flow"
                    check_and_echo "${GR}Trojan密码${NC}:" "$rd_trojan_password"
                    check_and_echo "${GR}Shadowsocks加密方式${NC}:" "$rd_shadowsocks_method"
                    check_and_echo "${GR}Shadowsocks密码${NC}:" "$rd_shadowsocks_password"
                    check_and_echo "${GR}网络类型${NC}:" "$rd_network"
                    check_and_echo "${GR}安全性设置${NC}:" "$rd_security"
                    check_and_echo "${GR}WS路径${NC}:" "$rd_ws_path"
                    check_and_echo "${GR}WS主机${NC}:" "$rd_ws_host"
                    check_and_echo "${GR}HTTP路径${NC}:" "$rd_security_http_path"
                    check_and_echo "${GR}HTTP主机${NC}:" "$rd_security_http_host"
                    check_and_echo "${GR}QUIC加密方式${NC}:" "$rd_quic_method"
                    check_and_echo "${GR}QUIC密码${NC}:" "$rd_quic_password"
                    check_and_echo "${GR}QUIC伪装类型${NC}:" "$rd_quic_fake"
                    check_and_echo "${GR}gRPC服务名${NC}:" "$rd_grpc_serviceName"
                    check_and_echo "${GR}TLS服务器名${NC}:" "$rd_tls_serverName"
                    check_and_echo "${GR}TLS证书文件路径${NC}:" "$rd_tls_certificateFile"
                    check_and_echo "${GR}TLS私钥文件路径${NC}:" "$rd_tls_keyFile"
                    check_and_echo "${GR}Reality目标地址${NC}:" "$rd_reality_dest"
                    check_and_echo "${GR}Reality服务器名${NC}:" "$rd_reality_serverNames"
                    check_and_echo "${GR}Reality指纹${NC}:" "$rd_reality_fingerprint"
                    check_and_echo "${GR}Reality私钥${NC}:" "$rd_reality_privateKey"
                    check_and_echo "${GR}Reality公钥${NC}:" "$rd_reality_publicKey"
                    check_and_echo "${GR}Reality-ShortIds${NC}:" "$rd_reality_shortIds"
                    check_and_echo "${GR}Dokodemo-Door目标地址${NC}:" "$rd_dokodemo_door_url"
                    check_and_echo "${GR}Dokodemo-Door目标端口${NC}:" "$rd_dokodemo_door_port"
                    check_and_echo "${GR}Dokodemo-Door网络模式${NC}:" "$rd_dokodemo_door_network"
                    check_and_echo "${GR}SOCKS用户名${NC}:" "$rd_socks_user"
                    check_and_echo "${GR}SOCKS密码${NC}:" "$rd_socks_password"
                    check_and_echo "${GR}SOCKS-UDP-IP${NC}:" "$rd_socks_udp_ip"
                    check_and_echo "${GR}HTTP用户名${NC}:" "$rd_http_user"
                    check_and_echo "${GR}HTTP密码${NC}:" "$rd_http_password"
                    if [[ $en_protocol == "vmess" || $en_protocol == "vless" || $en_protocol == "trojan" || $en_protocol == "shadowsocks" ]]; then
                    if [[ $en_network == "ws" ]]; then
                        URL="$rd_protocol://$rd_client_id@$IP_address:$rd_port?security=$rd_security&encryption=none&type=$rd_network&path=$rd_ws_path#$rd_protocol"
                    else
                        URL="$rd_protocol://$rd_client_id@$IP_address:$rd_port?security=$rd_security&encryption=none&type=$rd_network#$rd_protocol"
                    fi
                    qrencode -t ANSIUTF8 "$URL"
                    echo "$URL"
                    fi
                    echo
                    systemctl restart xray.service
                    waitfor
                    break
                elif [[ $choice == "C" || $choice == "c" ]]; then
                    break
                fi
                done
                break
                done
                ;;
            2|22)
                if [ ! -e "$jsonfile" ]; then
                    echo -e "未发现config.json配置文件."
                    waitfor
                    continue
                fi
                if [[ $(cat $jsonfile | wc -l) -eq 1 ]]; then
                    echo -e "未初始化config.json配置文件."
                    waitfor
                    continue
                fi
                echo "系统查询中..."
                mapfile -t rd_port < <(jq -r '.inbounds[].port' "$jsonfile")
                mapfile -t rd_protocol < <(jq -r '.inbounds[].protocol' "$jsonfile")
                mapfile -t rd_network < <(jq -r '.inbounds[].streamSettings.network' "$jsonfile")
                mapfile -t rd_security < <(jq -r '.inbounds[].streamSettings.security' "$jsonfile")
                mapfile -t rd_tls_serverName < <(jq -r '.inbounds[].streamSettings.tlsSettings.serverName' "$jsonfile")
                mapfile -t rd_tls_certificateFile < <(jq -r '.inbounds[].streamSettings.tlsSettings.certificates[0].certificateFile' "$jsonfile")
                mapfile -t rd_tls_keyFile < <(jq -r '.inbounds[].streamSettings.tlsSettings.certificates[0].keyFile' "$jsonfile")

                mapfile -t rd_dokodemo_door_url < <(jq -r '.inbounds[].settings.address' "$jsonfile")
                mapfile -t rd_dokodemo_door_port < <(jq -r '.inbounds[].settings.port' "$jsonfile")
                mapfile -t rd_dokodemo_door_network < <(jq -r '.inbounds[].settings.network' "$jsonfile")
                mapfile -t rd_socks_user < <(jq -r '.inbounds[].settings.accounts[0].user' "$jsonfile")
                mapfile -t rd_socks_password < <(jq -r '.inbounds[].settings.accounts[0].pass' "$jsonfile")
                mapfile -t rd_socks_udp < <(jq -r '.inbounds[].settings.udp' "$jsonfile")
                mapfile -t rd_socks_udp_ip < <(jq -r '.inbounds[].settings.ip' "$jsonfile")
                mapfile -t rd_http_user < <(jq -r '.inbounds[].settings.accounts[0].user' "$jsonfile")
                mapfile -t rd_http_password < <(jq -r '.inbounds[].settings.accounts[0].pass' "$jsonfile")
                mapfile -t rd_grpc_serviceName < <(jq -r '.inbounds[].streamSettings.grpcSettings.serviceName' "$jsonfile")
                mapfile -t rd_ws_path < <(jq -r '.inbounds[].streamSettings.wsSettings.path' "$jsonfile")
                mapfile -t rd_ws_host < <(jq -r '.inbounds[].streamSettings.wsSettings.headers.Host' "$jsonfile")

                mapfile -t rd_security_http_path < <(jq -r '.inbounds[].streamSettings.tlsSettings.header.request.path[0]' "$jsonfile")
                mapfile -t rd_security_http_host < <(jq -r '.inbounds[].streamSettings.tlsSettings.header.request.headers.Host[0]' "$jsonfile")
                mapfile -t rd_reality_dest < <(jq -r '.inbounds[].streamSettings.realitySettings.dest' "$jsonfile")
                mapfile -t rd_reality_serverNames < <(jq -r '.inbounds[].streamSettings.realitySettings.serverNames[0]' "$jsonfile")
                mapfile -t rd_reality_fingerprint < <(jq -r '.inbounds[].streamSettings.realitySettings.fingerprint' "$jsonfile")
                mapfile -t rd_reality_privateKey < <(jq -r '.inbounds[].streamSettings.realitySettings.privateKey' "$jsonfile")
                mapfile -t rd_reality_publicKey < <(jq -r '.inbounds[].streamSettings.realitySettings.publicKey' "$jsonfile")
                mapfile -t rd_reality_shortIds < <(jq -r '.inbounds[].streamSettings.realitySettings.shortIds[0]' "$jsonfile")
                mapfile -t rd_tag < <(jq -r '.inbounds[].tag' "$jsonfile")
                mapfile -t rd_client_id < <(jq -r '.inbounds[].settings.clients[0].id' "$jsonfile")
                mapfile -t rd_client_flow < <(jq -r '.inbounds[].settings.clients[0].flow' "$jsonfile")

                #################由于需要联网速度太慢暂时只使用IPv4
                # IPv4_address=$(curl -4 ip.sb 2> /dev/null) > /dev/null
                # IPv6_address=$(curl -6 ip.sb 2> /dev/null) > /dev/null
                # ifconfig_output=$(ifconfig)
                # if [[ $ifconfig_output =~ $IPv4_address ]]; then
                #     IP_address=$IPv4_address
                # elif [[ $ifconfig_output =~ $IPv6_address ]]; then
                #     IP_address=$IPv6_address
                # else
                # IP_address=$IPv4_address
                # fi
                ############################################
                ipv4_addresses=($(ifconfig | grep -oP 'inet \K[\d.]+' | grep -v '^127\.'))
                ipv6_addresses=($(ifconfig | grep -oP 'inet6 \K[\da-f:]+' | grep -vE '^:|^(fe80)'))
                all46_addresses=("${ipv4_addresses[@]}" "${ipv6_addresses[@]}")
                echo -e "${colored_text1}${NC}"
                echo "请选择一个 IP 地址："
                for ((i=0; i<${#all46_addresses[@]}; i++)); do
                    echo "[$(($i+1))]     ${all46_addresses[$i]}"
                done
                remind1p
                read -p "输入序号以选择链接所使用的 IP 地址: " selected_index
                adjusted_index=$(($selected_index - 1))
                if [ "$adjusted_index" -ge 0 ] && [ "$adjusted_index" -lt "${#all46_addresses[@]}" ]; then
                    IP_address=${all46_addresses[$adjusted_index]}
                else
                    echo "无效的选择。"
                    IP_address=""
                fi
                ############################################

                clear_screen
                echo -e "${GR}▼▼${NC}"
                for ((i=0; i<${#rd_port[@]}; i++)); do
                    echo -e "${colored_text1}${NC}${colored_text1}${NC}"
                    echo -e "${MA}节点${NC} $((i+1))"
                    check_and_echo "${GR}协议类型${NC}:" "${rd_protocol[i]}"
                    check_and_echo "${GR}端口号${NC}:" "${rd_port[i]}"
                    check_and_echo "${GR}Trojan密码${NC}:" "${rd_trojan_password[i]}"
                    check_and_echo "${GR}Shadowsocks加密方式${NC}:" "${rd_shadowsocks_method[i]}"
                    check_and_echo "${GR}Shadowsocks密码${NC}:" "${rd_shadowsocks_password[i]}"
                    check_and_echo "${GR}网络类型${NC}:" "${rd_network[i]}"
                    check_and_echo "${GR}安全性设置${NC}:" "${rd_security[i]}"
                    check_and_echo "${GR}UUID${NC}:" "${rd_client_id[i]}"
                    check_and_echo "${GR}流控Flow方式${NC}:" "${rd_client_flow[i]}"
                    check_and_echo "${GR}WS路径${NC}:" "${rd_ws_path[i]}"
                    check_and_echo "${GR}WS主机${NC}:" "${rd_ws_host[i]}"
                    check_and_echo "${GR}HTTP路径${NC}:" "${rd_security_http_path[i]}"
                    check_and_echo "${GR}HTTP主机${NC}:" "${rd_security_http_host[i]}"
                    check_and_echo "${GR}QUIC加密方式${NC}:" "${rd_quic_method[i]}"
                    check_and_echo "${GR}QUIC密码${NC}:" "${rd_quic_password[i]}"
                    check_and_echo "${GR}QUIC伪装类型${NC}:" "${rd_quic_fake[i]}"
                    check_and_echo "${GR}gRPC服务名${NC}:" "${rd_grpc_serviceName[i]}"
                    check_and_echo "${GR}TLS服务器名${NC}:" "${rd_tls_serverName[i]}"
                    check_and_echo "${GR}TLS证书文件路径${NC}:" "${rd_tls_certificateFile[i]}"
                    check_and_echo "${GR}TLS私钥文件路径${NC}:" "${rd_tls_keyFile[i]}"
                    check_and_echo "${GR}Reality目标地址${NC}:" "${rd_reality_dest[i]}"
                    check_and_echo "${GR}Reality服务器名${NC}:" "${rd_reality_serverNames[i]}"
                    check_and_echo "${GR}Reality指纹${NC}:" "${rd_reality_fingerprint[i]}"
                    check_and_echo "${GR}Reality私钥${NC}:" "${rd_reality_privateKey[i]}"
                    check_and_echo "${GR}Reality公钥${NC}:" "${rd_reality_publicKey[i]}"
                    check_and_echo "${GR}Reality-ShortIds${NC}:" "${rd_reality_shortIds[i]}"
                    check_and_echo "${GR}Dokodemo-Door目标地址${NC}:" "${rd_dokodemo_door_url[i]}"
                    check_and_echo "${GR}Dokodemo-Door目标端口${NC}:" "${rd_dokodemo_door_port[i]}"
                    check_and_echo "${GR}Dokodemo-Door网络模式${NC}:" "${rd_dokodemo_door_network[i]}"
                    check_and_echo "${GR}SOCKS用户名${NC}:" "${rd_socks_user[i]}"
                    check_and_echo "${GR}SOCKS密码${NC}:" "${rd_socks_password[i]}"
                    check_and_echo "${GR}SOCKS-UDP-IP${NC}:" "${rd_socks_udp_ip[i]}"
                    check_and_echo "${GR}HTTP用户名${NC}:" "${rd_http_user[i]}"
                    check_and_echo "${GR}HTTP密码${NC}:" "${rd_http_password[i]}"
                    if [[ ${rd_protocol[i]} == "vmess" || ${rd_protocol[i]} == "vless" || ${rd_protocol[i]} == "trojan" || ${rd_protocol[i]} == "shadowsocks" ]]; then
                    if [[ $en_network == "ws" ]]; then
                        URL="${rd_protocol[i]}://${rd_client_id[i]}@$IP_address:${rd_port[i]}?security=${rd_security[i]}&encryption=none&type=${rd_network[i]}&path=${rd_ws_path[i]}#${rd_protocol[i]}"
                    else
                        URL="${rd_protocol[i]}://${rd_client_id[i]}@$IP_address:${rd_port[i]}?security=${rd_security[i]}&encryption=none&type=${rd_network[i]}#${rd_protocol[i]}"
                    fi
                    qrencode -t ANSIUTF8 "$URL"
                    echo "$URL"
                    fi
                done
                echo -e "${colored_text2}${NC}${colored_text2}${NC}"
                waitfor
                ;;
            3|33)
                if [ ! -e "$jsonfile" ]; then
                    echo -e "未发现config.json配置文件."
                    waitfor
                    continue
                fi
                if [[ $(cat $jsonfile | wc -l) -eq 1 ]]; then
                    echo -e "未初始化config.json配置文件."
                    waitfor
                    continue
                fi
                echo -e "${colored_text1}${NC}"
                echo -e "${CY}节点${NC}    ${CY}协议${NC}            ${CY}端口${NC}"
                protocols=( $(jq -r '.inbounds[].protocol' "$jsonfile") )
                ports=( $(jq -r '.inbounds[].port' "$jsonfile") )
                for ((i=0; i<${#protocols[@]}; i++)); do
                    printf "▶ %s\t%s\t\t%s\n" "$((i+1))" "${protocols[i]}" "${ports[i]}"
                done
                echo -e "${colored_text1}${NC}"
                echo "制作中..."
                waitfor
                ;;
            4|44)
                if [ ! -e "$jsonfile" ]; then
                    echo -e "未发现config.json配置文件."
                    waitfor
                    continue
                fi
                if [[ $(cat $jsonfile | wc -l) -eq 1 ]]; then
                    echo -e "未初始化config.json配置文件."
                    waitfor
                    continue
                fi
                echo -e "${colored_text1}${NC}"
                echo -e "${CY}节点${NC}    ${CY}协议${NC}            ${CY}端口${NC}"
                protocols=( $(jq -r '.inbounds[].protocol' "$jsonfile") )
                ports=( $(jq -r '.inbounds[].port' "$jsonfile") )
                for ((i=0; i<${#protocols[@]}; i++)); do
                    printf "▶ %s\t%s\t\t%s\n" "$((i+1))" "${protocols[i]}" "${ports[i]}"
                done
                echo -e "${colored_text1}${NC}"
                read -e -p "请输入要删除的节点序号: " choice
                if [[ $choice != "" ]]; then
                    length=$(jq '.inbounds | length' "$jsonfile")
                    jq "del(.inbounds[$choice-1])" "$jsonfile" > temp.json && mv temp.json "$jsonfile"
                    new_length=$(jq '.inbounds | length' "$jsonfile")
                    if [[ $new_length -eq $((length - 1)) ]]; then
                        echo "节点已删除成功."
                        waitfor
                    else
                        echo -e "节点删除${MA}失败${NC}."
                        waitfor
                    fi
                else
                etag=1
                fi
                ;;
            5|55)
                nano $jsonfile
                waitfor
                ;;
            8|88)
                systemctl restart xray.service
                waitfor
                ;;
            9|99)
                systemctl stop xray.service
                waitfor
                ;;
            v|vv|V|VV)
                systemctl status xray.service
                waitfor
                ;;
            l|ll|L|LL)
                journalctl -u xray
                waitfor
                ;;
            i|ii|I|II)
                bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
                # ====================================================
                # V2RAY设置，XRAY似乎不需要
                #
                # sed -i "s/User=.*/User=$(whoami)/" "/etc/systemd/system/xray.service"
                # systemctl daemon-reload
                # mkdir -p /usr/local/etc/xray
                # mkdir -p /var/log/xray
                # if [ ! -e "/var/log/xray/access.log" ]; then
                #     touch /var/log/xray/access.log
                # fi
                # if [ ! -e "/var/log/xray/error.log" ]; then
                #     touch /var/log/xray/error.log
                # fi
                # chown -R nobody /var/log/xray
                # ====================================================
                if ! command -v jq &>/dev/null; then
                    $pm -y install jq
                fi
                waitfor
                ;;
            u|U|uu|UU)
                bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install-geodata
                waitfor
                ;;
            d|D|dd|DD)
                bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ remove
                read -e -p "是否要删除所有残留(包括配置文件)? (Y/其它跳过): " choice
                if [[ $choice == "Y" || $choice == "y" ]]; then
                    rm -rf /usr/local/etc/xray
                    rm -rf /var/log/xray
                    waitfor
                fi
                # ====================================================
                # 洁癖患者
                #
                ### 以下两行为删除/tmp下所有带xray关健定的文件或文件夹 (额外添加, 可以去除)
                # find /tmp -type f -name "*xray*" -exec rm -f {} +
                # find /tmp -type d -name "*xray*" -exec rm -rf {} +
                # ====================================================
                ;;
            r|R|rr|RR)
                break
                ;;
            x|X|xx|XX)
                exit 0
                ;;
            *)
                etag=1
                ;;
        esac
        done
        onlyone=0
        ;;
    2|22)
        ipv4_regex="^([0-9]{1,3}\.){3}[0-9]{1,3}$"
        ipv6_regex="^[0-9a-fA-F:]*$"

        while true; do
        acmetag=""
        if [ -e "$user_path/.acme.sh/acme.sh" ]; then
            acmever=$($user_path/.acme.sh/acme.sh --version | sed -n '2p' | awk '{print $1}')
        else
            acmever="未安装"
            acmetag="*"
        fi
        clear_screen
        echo -e "${GR}▼▼${NC}"
        echo -e "${GR}ACME${NC}          ${MA}$acmever${NC}"
        echo -e "${colored_text2}${NC}"
        echo -e "1.  申请证书"
        echo -e "2.  查询证书"
        echo -e "3.  更新证书"
        echo -e "4.  删除证书"
        echo -e "${colored_text1}${NC}"
        echo -e "i.  安装/更新 ACME 官方脚本 ${MA}$acmetag${NC}"
        echo -e "d.  删除 ACME 官方脚本"
        echo -e "${colored_text1}${NC}"
        echo -e "r.  返回主菜单"
        echo -e "x.  退出脚本"
        echo -e "${colored_text1}${NC}"
        remind3p
        read -e -p "请输入你的选择: " -n 2 -r choice && echoo
        case $choice in
            1|11)
                if [[ $acmetag == *"*"* ]]; then
                    echo -e "检测到系统未安装ACME, 请先选择第 ${MA}i${NC} 项进行安装."
                    waitfor
                    continue
                fi
                if [ ! -d $user_path/cert ]; then
                    mkdir $user_path/cert
                fi
                while true; do
                random=$((100000 + RANDOM % 900000))
                clear_screen
                echo -e "${GR}▼▼▼${NC}"
                echo -e "${GR}ACME - 申请证书${NC}"
                echo -e "${colored_text2}${NC}"
                echo -e "1.  方法一: 采用端口 80 验证方式申请"
                echo -e "2.  方法二: 采用 Nginx 验证方式申请 (需要安装Nginx)"
                echo -e "3.  方法三: 采用 http 绝对路径方式验证申请"
                echo -e "4.  方法四: 采用 cloudflare 的 API 验证方式申请"
                echo -e "${colored_text1}${NC}"
                echo -e "c.  切换申请服务器"
                echo -e "${colored_text1}${NC}"
                echo -e "r.  返回上层菜单"
                echo -e "x.  退出脚本"
                echo -e "${colored_text1}${NC}"
                echo -e "${MA}注${NC}: 证书申请成功后将自动保存至: ${GR}$user_path/cert${NC} 文件夹中"
                echo -e "${colored_text1}${NC}"
                remind3p
                read -e -p "请输入你的选择: " -n 2 -r choice && echoo
                case $choice in
                    1|11)
                        while true; do
                            read -e -p "请输入申请证书的域名: " domain
                            if [[ $domain == *.* ]]; then
                                ipaddress=$(ping -c 1 "$domain" 2> /dev/null | awk '/^PING/{print $3}' | awk -F'[()]' '{print $2}')
                                if [ -z "$ipaddress" ]; then
                                    echo -e "未检测到 ${GR}$domain${NC} 指定的 IP 地址!"
                                    echo -en "请选择: ${GR}4${NC}.继续以IPv4申请  ${GR}6${NC}.继续以IPv6申请  ${GR}回车${NC}.中止 : "
                                    read -er input_address
                                    if [ -z "$input_address" ]; then echo; fi
                                    if [ "$input_address" == "4" ]; then
                                        IPType="4"
                                        echo -e "IPType: IPv${GR}$IPType${NC}"
                                    elif [ "$input_address" == "6" ]; then
                                        IPType="6"
                                        echo -e "IPType: IPv${GR}$IPType${NC}"
                                    else
                                        break
                                    fi
                                else
                                    echo "检测到 $domain 指定的 IP 地址: $ipaddress"
                                    if [[ $ipaddress =~ $ipv4_regex ]]; then
                                        IPType="4"
                                        echo -e "IPType: IPv${GR}$IPType${NC}"
                                    elif [[ $ipaddress =~ $ipv6_regex ]]; then
                                        IPType="6"
                                        echo -e "IPType: IPv${GR}$IPType${NC}"
                                    else
                                        echo -e "IP 地址: $ipaddress  检测到 IP 类型有误!"
                                        echo -en "请选择: ${GR}4${NC}.继续以IPv4申请  ${GR}6${NC}.继续以IPv6申请  ${GR}回车${NC}.中止 : "
                                        read -er input_address
                                        if [ -z "$input_address" ]; then echo; fi
                                        if [ "$input_address" == "4" ]; then
                                            IPType="4"
                                        elif [ "$input_address" == "6" ]; then
                                            IPType="6"
                                        else
                                            break
                                        fi
                                    fi
                                fi
                                pids=$(lsof -t -i :80)
                                if [ -n "$pids" ]; then
                                    for pid in $pids; do
                                        kill -9 $pid &>/dev/null
                                    done
                                fi
                                stopfire
                                $user_path/.acme.sh/acme.sh --register-account -m $random@gmail.com
                                if [ "$IPType" == "4" ]; then
                                    $user_path/.acme.sh/acme.sh --issue -d $domain --standalone
                                elif [ "$IPType" == "6" ]; then
                                    $user_path/.acme.sh/acme.sh --issue -d $domain --standalone --listen-v6
                                else
                                    echo "请检查 IPType !"
                                    # return 1
                                    break
                                fi
                                $user_path/.acme.sh/acme.sh --installcert -d $domain --key-file $user_path/cert/$domain.key --fullchain-file $user_path/cert/$domain.cer
                                recoverfire
                                if [[ -f "$user_path/cert/$domain.key" && -f "$user_path/cert/$domain.cer" ]]; then
                                    if [[ -s "$user_path/cert/$domain.key" && -s "$user_path/cert/$domain.cer" ]]; then
                                        echo "证书申请成功！"
                                        echo "证书已生成并保存到 $user_path/cert 目录下."
                                        break
                                    else
                                        rm $user_path/cert/$domain.key &>/dev/null
                                        rm $user_path/cert/$domain.cer &>/dev/null
                                        rm -rf $user_path/.acme.sh/${domain}_ecc &>/dev/null
                                        echo "申请失败：存在文件但文件大小为0，已删除空文件。"
                                        break
                                    fi
                                else
                                    echo "申请失败：缺少证书文件。"
                                    break
                                fi
                            else
                                if [[ $domain == "" ]]; then
                                    break
                                fi
                                echo "输入的域名不合法, 请重新输入."
                            fi
                        done
                        waitfor
                        ;;
                    2|22)
                        while true; do
                            read -e -p "请输入申请证书的域名: " domain
                            if [[ $domain == *.* ]]; then
                                ipaddress=$(ping -c 1 "$domain" 2> /dev/null | awk '/^PING/{print $3}' | awk -F'[()]' '{print $2}')
                                if [ -z "$ipaddress" ]; then
                                    echo -e "未检测到 ${GR}$domain${NC} 指定的 IP 地址!"
                                    echo -en "请选择: ${GR}4${NC}.继续以IPv4申请  ${GR}6${NC}.继续以IPv6申请  ${GR}回车${NC}.中止 : "
                                    read -er input_address
                                    if [ -z "$input_address" ]; then echo; fi
                                    if [ "$input_address" == "4" ]; then
                                        IPType="4"
                                        echo -e "IPType: IPv${GR}$IPType${NC}"
                                    elif [ "$input_address" == "6" ]; then
                                        IPType="6"
                                        echo -e "IPType: IPv${GR}$IPType${NC}"
                                    else
                                        break
                                    fi
                                else
                                    echo "检测到 $domain 指定的 IP 地址: $ipaddress"
                                    if [[ $ipaddress =~ $ipv4_regex ]]; then
                                        IPType="4"
                                    elif [[ $ipaddress =~ $ipv6_regex ]]; then
                                        IPType="6"
                                    else
                                        echo -e "IP 地址: $ipaddress  检测到 IP 类型有误!"
                                        echo -en "请选择: ${GR}4${NC}.继续以IPv4申请  ${GR}6${NC}.继续以IPv6申请  ${GR}回车${NC}.中止 : "
                                        read -er input_address
                                        if [ -z "$input_address" ]; then echo; fi
                                        if [ "$input_address" == "4" ]; then
                                            IPType="4"
                                        elif [ "$input_address" == "6" ]; then
                                            IPType="6"
                                        else
                                            break
                                        fi
                                    fi
                                fi
                                echo -en "是否自定义端口? ${GR}输入${NC}.端口号  ${GR}回车${NC}.80 (默认) : "
                                read -er input_port
                                if [ -z "$input_port" ]; then
                                    echo
                                    port_ssl=80
                                else
                                    if [[ $input_port =~ ^[0-9]+$ ]]; then
                                        port_ssl="$input_port"
                                    else
                                        echo "$input_port 端口输入有误."
                                        break
                                    fi
                                fi
                                echo "=================================================="
                                echo -e "IPType: IPv${GR}$IPType${NC}"
                                echo -e "Prot: ${GR}$port_ssl${NC}"
                                # echo -e "如果中途中止脚本可采用以下指令恢复 ${GR}nginx.conf${NC}"
                                # echo -e "${GR}mv /etc/nginx/nginx_ssl.conf /etc/nginx/nginx.conf${NC}"
                                echo "=================================================="
                                pids=$(lsof -t -i :$port_ssl)
                                if [ -n "$pids" ]; then
                                    for pid in $pids; do
                                        kill -9 $pid &> /dev/null
                                    done
                                fi
                                if ! command -v nginx &>/dev/null; then
                                    read -e -p "系统未检测到Nginx, 是否进行Nginx安装 (Y/其它跳过): " choice
                                    if [[ ! $choice == "Y" && ! $choice == "y" ]]; then
                                        break
                                    fi
                                    $pm -y install nginx
                                fi
                                if [[ ! -f "/etc/nginx/nginx.redx" ]]; then
                                    cp /etc/nginx/nginx.conf /etc/nginx/nginx.redx
                                fi
                                registerSSL() {
                                    local IPType="${1}"
                                    systemctl stop nginx.service > /dev/null 2>&1
                                    pkill nginx > /dev/null 2>&1
                                    # cp /etc/nginx/nginx.conf /etc/nginx/nginx_ssl.conf
                                    echo "user www-data;
                                    events {
                                        worker_connections 768;
                                    }
                                    http {
                                        server {
                                        listen $port_ssl default_server;
                                        listen [::]:$port_ssl default_server;
                                        root /var/www/html;
                                        index index.html index.htm index.nginx-debian.html;
                                        server_name $domain;
                                        }
                                    }" > /etc/nginx/nginx_ssl.conf
                                    # cat /etc/nginx/nginx.conf
                                    # systemctl restart nginx > /dev/null 2>&1
                                    nginx -c /etc/nginx/nginx_ssl.conf
                                    sleep 1
                                    ss -untlp
                                    stopfire
                                    $user_path/.acme.sh/acme.sh --register-account -m $random@gmail.com
                                    if [ "$IPType" == "4" ]; then
                                        $user_path/.acme.sh/acme.sh --issue -d $domain --nginx /etc/nginx/nginx_ssl.conf
                                    elif [ "$IPType" == "6" ]; then
                                        $user_path/.acme.sh/acme.sh --issue -d $domain --nginx /etc/nginx/nginx_ssl.conf --listen-v6
                                    else
                                        echo "请检查 IPType !"
                                        # return 1
                                        break
                                    fi
                                    # mv /etc/nginx/nginx_ssl.conf /etc/nginx/nginx.conf
                                    $user_path/.acme.sh/acme.sh --installcert -d $domain --key-file $user_path/cert/$domain.key --fullchain-file $user_path/cert/$domain.cer
                                    recoverfire
                                    if [[ -f "$user_path/cert/$domain.key" && -f "$user_path/cert/$domain.cer" ]]; then
                                        if [[ -s "$user_path/cert/$domain.key" && -s "$user_path/cert/$domain.cer" ]]; then
                                            echo "证书申请成功！"
                                            echo "==========================================================="
                                            ls -l /root/cert
                                            echo "==========================================================="
                                            echo "证书已生成并保存到 $user_path/cert 目录下."
                                        else
                                            rm $user_path/cert/$domain.key &>/dev/null
                                            rm $user_path/cert/$domain.cer &>/dev/null
                                            rm -rf $user_path/.acme.sh/${domain}_ecc &>/dev/null
                                            echo "申请失败：存在文件但文件大小为0，已删除空文件。"
                                        fi
                                    else
                                        echo "申请失败：缺少证书文件。"
                                    fi
                                    # mv /etc/nginx/nginx_ssl.conf /etc/nginx/nginx.conf
                                }
                                # if systemctl is-active --quiet nginx; then
                                #     systemctl stop nginx
                                #     registerSSL "$IPType"
                                #     systemctl restart nginx
                                # else
                                #     registerSSL "$IPType"
                                #     systemctl stop nginx
                                # fi
                                # systemctl restart nginx > /dev/null 2>&1
                                # sleep 1
                                donetag="false"
                                for ((i=1; i<=3; i++)); do
                                    if systemctl is-active --quiet nginx; then
                                        echo "申请中..."
                                        registerSSL "$IPType"
                                        donetag="true"
                                        break
                                    else
                                        systemctl restart nginx > /dev/null 2>&1
                                        sleep 1
                                    fi
                                done
                                if [ ! "$donetag" == "true" ]; then
                                    echo "请检查 Nginx 是否正常运行."
                                fi
                                break
                            else
                                if [[ $domain == "" ]]; then
                                    break
                                fi
                                echo "输入的域名不合法, 请重新输入."
                            fi
                        done
                        systemctl stop nginx.service > /dev/null 2>&1
                        pkill nginx > /dev/null 2>&1
                        systemctl restart nginx > /dev/null 2>&1
                        waitfor
                        ;;
                    3|33)
                        noloop=0
                        while true; do
                            echo -e "请输入申请证书的域名, 主体名和可选主体名, 以空格格开, (如: do1.com do2.com)"
                            read -e -p "请输入域名: " domain1 domain2
                            if [[ -n "$domain1" && -z "${domain1##*.*}" ]]; then
                                if [[ -z "$domain2" || (-n "$domain2" && -z "${domain2##*.*}") ]]; then
                                    break
                                else
                                    echo "请输入有效的第二个域名."
                                fi
                            else
                                if [[ $domain1 == "" ]]; then
                                    noloop=1
                                    break
                                fi
                                echo "请输入有效的域名."
                            fi
                        done
                        if [[ $noloop != 1 ]]; then
                        while true; do
                            read -e -p "请输入网站根路径 (如: /home/webroot): " webroot
                            if [[ -d "$webroot" ]]; then
                                break
                            else
                                if [[ $webroot == "" ]]; then
                                    noloop=1
                                    break
                                fi
                                echo "路径 $webroot 不存在，请重新输入。"
                            fi
                        done
                        if [[ $noloop != 1 ]]; then
                        stopfire
                        if [[ -n "$domain2" ]]; then
                            $user_path/.acme.sh/acme.sh --register-account -m $random@gmail.com
                            $user_path/.acme.sh/acme.sh --issue -d "$domain1" -d "$domain2" -w "$webroot"
                            $user_path/.acme.sh/acme.sh --installcert -d $domain1 --key-file $user_path/cert/$domain1.key --fullchain-file $user_path/cert/$domain1.cer

                            if [[ -f "$user_path/cert/$domain1.key" && -f "$user_path/cert/$domain1.cer" ]]; then
                                if [[ -s "$user_path/cert/$domain1.key" && -s "$user_path/cert/$domain1.cer" ]]; then
                                    echo "证书申请成功！"
                                    echo "证书已生成并保存到 $user_path/cert 目录下."
                                else
                                    rm $user_path/cert/$domain1.key &>/dev/null
                                    rm $user_path/cert/$domain1.cer &>/dev/null
                                    rm -rf $user_path/.acme.sh/${domain1}_ecc &>/dev/null
                                    echo "申请失败：存在文件但文件大小为0，已删除空文件。"
                                fi
                            else
                                echo "申请失败：缺少证书文件。"
                            fi

                        else
                            $user_path/.acme.sh/acme.sh --register-account -m $random@gmail.com
                            $user_path/.acme.sh/acme.sh --issue -d "$domain1" -w "$webroot"
                            $user_path/.acme.sh/acme.sh --installcert -d $domain1 --key-file $user_path/cert/$domain1.key --fullchain-file $user_path/cert/$domain1.cer

                            if [[ -f "$user_path/cert/$domain1.key" && -f "$user_path/cert/$domain1.cer" ]]; then
                                if [[ -s "$user_path/cert/$domain1.key" && -s "$user_path/cert/$domain1.cer" ]]; then
                                    echo "证书申请成功！"
                                    echo "证书已生成并保存到 $user_path/cert 目录下."
                                else
                                    rm $user_path/cert/$domain1.key &>/dev/null
                                    rm $user_path/cert/$domain1.cer &>/dev/null
                                    rm -rf $user_path/.acme.sh/${domain1}_ecc &>/dev/null
                                    echo "申请失败：存在文件但文件大小为0，已删除空文件。"
                                fi
                            else
                                echo "申请失败：缺少证书文件。"
                            fi
                        fi
                        recoverfire
                        fi
                        fi
                        waitfor
                        ;;
                    4|44)
                        while true; do
                            echo -e "请输入申请证书的域名, 输入子域名, 自动添加泛域名"
                            read -e -p "请输入域名: " domain
                            if [[ $domain == *.* ]]; then
                                read -e -p "请输入Cloudflare API Key: " cf_key
                                read -e -p "请输入Cloudflare 邮箱: " cf_email
                                if [ -z "$cf_key" ] || [ -z "$cf_email" ]; then
                                    echo "输入有误，请确保API Key和邮箱都已经输入"
                                    break
                                fi
                                stopfire
                                export CF_Key="$cf_key"
                                export CF_Email="$cf_email"
                                wildcard_domain="*.${domain#*.}"
                                $user_path/.acme.sh/acme.sh --register-account -m $random@gmail.com
                                $user_path/.acme.sh/acme.sh --issue -d "$domain" -d "$wildcard_domain" --dns dns_cf \
                                --key-file       $user_path/cert/"$domain.key"  \
                                --fullchain-file $user_path/cert/"$domain.pem"
                                recoverfire
                                if [[ -f "$user_path/cert/$domain.key" && -f "$user_path/cert/$domain.cer" ]]; then
                                    if [[ -s "$user_path/cert/$domain.key" && -s "$user_path/cert/$domain.cer" ]]; then
                                        echo "证书申请成功！"
                                        echo "证书已生成并保存到 $user_path/cert 目录下."
                                        break
                                    else
                                        rm $user_path/cert/$domain.key &>/dev/null
                                        rm $user_path/cert/$domain.cer &>/dev/null
                                        rm -rf $user_path/.acme.sh/${domain}_ecc &>/dev/null
                                        echo "申请失败：存在文件但文件大小为0，已删除空文件。"
                                        break
                                    fi
                                else
                                    echo "申请失败：缺少证书文件。"
                                    break
                                fi

                            else
                                if [[ $domain == "" ]]; then
                                    break
                                fi
                                echo "输入的域名不合法，请重新输入."
                            fi
                        done
                        waitfor
                        ;;
                    c|C|cc|CC)
                        echo -e "${GR}1${NC}.ZeroSSL 服务器  ${GR}2${NC}.Let's Encrypt 服务器  ${GR}3${NC}.Buypass 服务器"
                        read -e -p "请选择申请服务器 ( 回车默认 1 ): " choice_num
                        if [ -z "$choice_num" ] || [ "$choice_num" == "1" ]; then
                            $user_path/.acme.sh/acme.sh --set-default-ca --server zerossl
                            echo "已经切换 ZeroSSL 服务器."
                        elif [ "$choice_num" == "2" ]; then
                            $user_path/.acme.sh/acme.sh --set-default-ca --server letsencrypt
                            echo "已经切换 Let's Encrypt 服务器."
                        elif [ "$choice_num" == "3" ]; then
                            $user_path/.acme.sh/acme.sh --set-default-ca --server buypass
                            echo "已经切换 Buypass 服务器."
                        else
                            echo "输入有误."
                        fi
                        waitfor
                        ;;
                    v|V|vv|VV)
                        echo "==========================================================="
                        cat /etc/nginx/nginx.conf
                        echo "==========================================================="
                        ls -l /root/cert
                        echo "==========================================================="
                        waitfor
                        ;;
                    r|R|rr|RR)
                        break
                        ;;
                    x|X|xx|XX)
                        exit 0
                        ;;
                    *)
                        etag=1
                        ;;
                esac
                done
                ;;
            2|22)
                if [[ $acmetag == *"*"* ]]; then
                    echo -e "检测到系统未安装ACME, 请先选择第 ${MA}i${NC} 项进行安装."
                    waitfor
                    continue
                fi
                if [[ $($user_path/.acme.sh/acme.sh --list | wc -l) -eq 1 ]]; then
                    echo "未查询到证书."
                else
                    $user_path/.acme.sh/acme.sh --list
                fi
                waitfor
                ;;
            3|33)
                if [[ $acmetag == *"*"* ]]; then
                    echo -e "检测到系统未安装ACME, 请先选择第 ${MA}i${NC} 项进行安装."
                    waitfor
                    continue
                fi
                while true; do
                clear_screen
                echo -e "${GR}▼▼▼${NC}"
                echo -e "${GR}ACME - 更新证书${NC}"
                echo -e "${colored_text2}${NC}"
                if [[ $($user_path/.acme.sh/acme.sh --list | wc -l) -eq 1 ]]; then
                    echo "未查询到证书."
                else
                    $user_path/.acme.sh/acme.sh --list
                fi
                echo -e "${colored_text1}${NC}"
                echo -e "1.  更新指定证书"
                echo -e "2.  方法一: 更新全部证书"
                echo -e "3.  方法二: 强制更新全部证书"
                echo -e "${colored_text1}${NC}"
                echo -e "4.  设置定时更新证书"
                echo -e "${colored_text1}${NC}"
                echo -e "r.  返回上层菜单"
                echo -e "x.  退出脚本"
                echo -e "${colored_text1}${NC}"
                remind3p
                read -e -p "请输入你的选择: " -n 2 -r choice && echoo
                case $choice in
                    1|11)
                        read -e -p "请输请输入要更新的证书的域名: " domain
                        if [[ $domain != "" ]]; then
                            $user_path/.acme.sh/acme.sh --renew -d $domain
                            if [[ $? -eq 0 ]]; then
                                echo "证书更新成功."
                            else
                                echo -e "证书更新${MA}失败${NC}."
                            fi
                        fi
                        echo "操作取消."
                        waitfor
                        ;;
                    2|22)
                        if [[ $($user_path/.acme.sh/acme.sh --list | wc -l) -eq 1 ]]; then
                            echo "未查询到证书."
                            waitfor
                        else
                            $user_path/.acme.sh/acme.sh --renew-all
                            echo "更新证书完成."
                            waitfor
                        fi
                        ;;
                    3|33)
                        if [[ $($user_path/.acme.sh/acme.sh --list | wc -l) -eq 1 ]]; then
                            echo "未查询到证书."
                            waitfor
                        else
                            $user_path/.acme.sh/acme.sh --cron --home $user_path/.acme.sh --force
                        echo "强制更新证书完成."
                        waitfor
                        fi
                        ;;
                    4|44)
                        echo -e "${colored_text1}${NC}"
                        echo "当前Cron表中的acme.sh定时任务："
                        crontab -l | grep 'acme.sh'
                        echo -e "${colored_text1}${NC}"
                        echo "请选择操作: "
                        echo "1.  添加新的 ACME 定时任务"
                        echo "2.  删除所有 ACME 定时任务"
                        echo "3.  手动修改 ACME 定时任务"
                        echo -e "${colored_text1}${NC}"
                        remind3p
                        read -e -p "请输入操作编号 (1/2/3/其它退出操作): " choice
                        case "$choice" in
                            1|11)
                                read -e -p "请输入新的定时任务时间表达式 (例如：* * * * * 表示每分钟执行一次): " schedule
                                if [[ $schedule != "" ]]; then
                                    (crontab -l ; echo "$schedule $user_path/.acme.sh/acme.sh --cron --home $user_path/.acme.sh --force > /dev/null") | crontab -
                                    if [[ $? -eq 0 ]]; then
                                        echo "新的 ACME 定时任务已添加."
                                        crontab -l | grep 'acme.sh'
                                    else
                                        echo -e "定时任务添加${MA}失败${NC}."
                                    fi
                                    waitfor
                                else
                                    echo "操作取消."
                                    waitfor
                                fi
                                ;;
                            2|22)
                                crontab -l | grep -v 'acme.sh' | crontab -
                                echo "所有 ACME 定时任务已删除."
                                waitfor
                                ;;
                            3|33)
                                crontab -e
                                waitfor
                                ;;
                            *)
                                echo "操作取消."
                                waitfor
                                ;;
                        esac
                        ;;
                    r|R|rr|RR)
                        break
                        ;;
                    x|X|xx|XX)
                        exit 0
                        ;;
                    *)
                        etag=1
                        ;;
                esac
                done
                ;;
            4|44)
                if [[ $acmetag == *"*"* ]]; then
                    echo -e "检测到系统未安装ACME, 请先选择第 ${MA}i${NC} 项进行安装."
                    waitfor
                    continue
                fi
                while true; do
                clear_screen
                echo -e "${GR}▼▼▼${NC}"
                echo -e "${GR}ACME - 删除证书${NC}"
                echo -e "${colored_text2}${NC}"
                if [[ $($user_path/.acme.sh/acme.sh --list | wc -l) -eq 1 ]]; then
                    echo "未查询到证书."
                else
                    $user_path/.acme.sh/acme.sh --list
                fi
                echo -e "${colored_text2}${NC}"
                echo -e "1.  删除指定证书"
                echo -e "2.  删除全部证书"
                echo -e "${colored_text1}${NC}"
                echo -e "r.  返回上层菜单"
                echo -e "x.  退出脚本"
                echo -e "${colored_text1}${NC}"
                remind3p
                read -e -p "请输入你的选择: " -n 2 -r choice && echoo
                case $choice in
                    1|11)
                        read -e -p "请输请输入要删除的证书的域名: " domain
                        if [[ $domain != "" ]]; then
                            $user_path/.acme.sh/acme.sh --remove -d $domain
                            if [[ $? -eq 0 ]]; then
                                echo "证书删除成功."
                            else
                                echo -e "证书删除${MA}失败${NC}."
                            fi
                            waitfor
                        else
                            echo "操作取消."
                            waitfor
                        fi
                        ;;
                    2|22)
                        list_output=$($user_path/.acme.sh/acme.sh --list)
                        readarray -t domain_array <<< "$(echo "$list_output" | sed -n '2,$p' | awk '{print $1}')"
                        echo "${domain_array[@]}"
                        for domain in "${domain_array[@]}"; do
                            $user_path/.acme.sh/acme.sh --remove -d "$domain"
                            echo "已删除域名: $domain"
                        done
                        waitfor
                        ;;
                    r|R|rr|RR)
                        break
                        ;;
                    x|X|xx|XX)
                        exit 0
                        ;;
                    *)
                        etag=1
                        ;;
                esac
                done
                ;;
            i|I|ii|II)
                $pm install -y socat openssl
                curl https://get.acme.sh | sh
                ;;
            d|D|dd|DD)
                $user_path/.acme.sh/acme.sh --uninstall
                rm -rf $user_path/.acme.sh
                ;;
            r|R|rr|RR)
                break
                ;;
            x|X|xx|XX)
                exit 0
                ;;
            *)
                etag=1
                ;;
        esac
        done
        onlyone=0
        ;;
    3|33)
        wget --no-check-certificate -O tcpx.sh https://raw.githubusercontent.com/ylx2016/Linux-NetSpeed/master/tcpx.sh
        chmod +x tcpx.sh
        bash tcpx.sh
        rm -f tcpx.sh
        onlyone=0
        waitfor
        ;;
    4|44)
        wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh
        bash menu.sh [option] [lisence/url/token]
        rm -f menu.sh
        onlyone=0
        waitfor
        ;;
    5|55)
        wgfname="wg0"
        config_file="/etc/wireguard/$wgfname.conf"
        extract_allowed_ips() {
            local config_file="$1"
            local allowed_ips_array=()
            while IFS= read -r line; do
                if [[ "$line" =~ ^AllowedIPs[[:space:]]*=[[:space:]]*([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+) ]]; then
                    ip_only=$(echo "${BASH_REMATCH[1]}" | cut -d'/' -f1)
                    allowed_ips_array+=("$ip_only")
                fi
            done < "$config_file"
            echo "${allowed_ips_array[@]}"
        }
        # allowed_ips_array=($(awk -F= '/^AllowedIPs/ {gsub(/[ \t\/]+/, "", $2); print $2}' $config_file)) 第二种方法读取数组(上面是系统内置法，此条是采用外部工具)
        extract_public_keys() {
            local config_file="$1"
            local public_keys_array=()
            while IFS= read -r line; do
                if [[ "$line" =~ ^PublicKey[[:space:]]*=[[:space:]]*(.+) ]]; then
                    public_key=$(echo "${BASH_REMATCH[1]}")
                    public_keys_array+=("$public_key")
                fi
            done < "$config_file"
            echo "${public_keys_array[@]}"
        }
        ipv4=($(ip -4 address show | grep inet | grep -v 127.0.0 | awk '{print $2}' | cut -d'/' -f1))
        ipv6=($(ip -6 address show | grep inet6 | awk '{print $2}' | cut -d'/' -f1))
        ip_all_array=("${ipv4[@]}" "${ipv6[@]}")
        check_ipv4_or_ipv6() {
            local ip="$1"
            local result=""
            if [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                result="$ip"
            else
                result="[$ip]"
            fi
            echo "$result"
        }
        while true; do
        wgtag=""
        if command -v wg &>/dev/null; then
            wgver=$(wg -v | head -n 1 | awk '{print $2}')
        else
            wgver="未安装"
            wgtag="${MA}*${NC}"
        fi
        wginterfaces=$(wg show all | grep -E '^\s*interface:' | awk '{print $2}' | paste -sd ' ')
        if [ -z "$wginterfaces" ]; then
            wgactive="${MA}未启动${NC}"
        else
            wgactive="${CY}$wginterfaces${NC}"
        fi
        clear_screen
        echo -e "${GR}▼▼${NC}"
        echo -e "${GR}WIREGUARD${NC} ${MA}$wgver${NC}"
        echo -e "运行状态: $wgactive"
        echo -e "${colored_text2}${NC}"
        echo -e "1.  配置 WIREGUARD 服务"
        echo -e "2.  查询 WIREGUARD 信息(配置文件)"
        echo -e "3.  增加 WIREGUARD PEER 节点"
        echo -e "${colored_text1}${NC}"
        echo -e "4.  开启/关闭/删除 WIREGUARD 服务"
        echo -e "${colored_text1}${NC}"
        echo -e "5.  手动修改 WIREGUARD 配置"
        echo -e "${colored_text1}${NC}"
        echo -e "i.  安装/更新 WIREGUARD 官方脚本 ${MA}$wgtag${NC}"
        echo -e "d.  删除 WIREGUARD 官方脚本 (暂时不要使用)"
        echo -e "${colored_text1}${NC}"
        echo -e "r.  返回上层菜单"
        echo -e "x.  退出脚本"
        echo -e "${colored_text1}${NC}"
        remind3p
        read -e -p "请输入你的选择: " -n 2 -r choice && echoo
        case $choice in
            1|11)
                if [[ $wgtag == *"*"* ]]; then
                    echo -e "检测到系统未安装WIREGUARD, 请先选择第 ${MA}i${NC} 项进行安装."
                    waitfor
                    continue
                fi
                if [ -e "$config_file" ]; then
                    echo -e "配置文件 $config_file 已经存在, 重新配置将${MA}删除${NC}之前的所有配置文件?"
                    read -e -p "是否要重新配置文件? (Y/其它)" choice
                    if [[ ! ($choice = "y" || $choice = "Y") ]]; then
                    continue
                fi
                fi
                loop=0
                while true; do
                if [[ $loop -eq 0 ]]; then
                    echo -e "${colored_text1}${NC}"
                    remind1p
                    read -e -p "请输入 Wireguard 服务IP地址 (回车默认: 10.0.8.1,fe00::1): " server_address
                    wgserver_ip="10.0.8.1,fe80::1"
                    if [ -n "$server_address" ]; then
                        wgserver_ip="$server_address"
                    fi
                    wgserver_ip_prefix=$(echo "$wgserver_ip" | awk -F'.' '{print $1"."$2"."$3"."}')
                    mapfile -t network_interface_array < <(ifconfig | grep -v '^$' | grep -v '^\s' | awk '{print $1}' | sed 's/:$//')
                    echo "检查到网卡如下:"
                    for ((i=0; i<${#network_interface_array[@]}; i++)); do
                        echo "$((i+1)). ${network_interface_array[i]}"
                    done
                    default_choice=1
                    if [[ " ${network_interface_array[@]} " =~ " eth0 " ]]; then
                        read -e -p "请选择服务器网卡 (回车默认为: eth0): " choice
                    else
                        read -e -p "请选择服务器网卡: " choice
                    fi
                    if [[ -z "$choice" ]]; then
                        choice=$default_choice
                    fi
                    if [[ $choice -ge 1 && $choice -le ${#network_interface_array[@]} ]]; then
                        wgnetwork_interface="${network_interface_array[$((choice-1))]}"
                    else
                        wgnetwork_interface="请重新选择"
                        echo "错误：选择的数字无效。"
                    fi
                    read -e -p "请输入服务监听端口 (回车默认为 50888): " listen_port
                    wglisten_port="50888"
                    if [ -n "$listen_port" ]; then
                        wglisten_port="$listen_port"
                    fi
                    read -e -p "请输入服务DNS地址 (回车默认为 1.1.1.1,8.8.8.8,2001:4860:4860::8888): " dns_address
                    wgdns_address="1.1.1.1,8.8.8.8,2001:4860:4860::8888"
                    if [ -n "$dns_address" ]; then
                        wgdns_address="$dns_address"
                    fi
                    echo -e "${colored_text1}${NC}"
                    echo -e "${GR}服务器网卡${NC}:        $wgnetwork_interface"
                    echo -e "${GR}服务 IP 地址${NC}:      $wgserver_ip"
                    echo -e "${GR}服务监听端口${NC}:      $wglisten_port"
                    echo -e "${GR}服务 DNS 地址${NC}:     $wgdns_address"
                    remind1p
                fi
                read -e -p "请确认以上信息, 是否继续操作? (Y.确定  C.取消)" choice
                    case $choice in
                        y|Y|yy|YY)
                            if grep -q "^net.ipv4.ip_forward\s*=\s*1" /etc/sysctl.conf; then
                                echo "已经存在 net.ipv4.ip_forward = 1"
                            else
                                echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
                                echo "已添加 net.ipv4.ip_forward = 1 到 /etc/sysctl.conf"
                                sysctl -p
                            fi
                            mkdir -p /etc/wireguard
                            chmod 0777 /etc/wireguard
                            umask 077   #调整目录默认权限
                            cd /etc/wireguard/
                            rm *.key &>/dev/null
                            rm *.key.pub &>/dev/null
                            wg genkey > server.key
                            wg pubkey < server.key > server.key.pub
                            wg genkey > client11.key
                            wg pubkey < client11.key > client11.key.pub
                            echo -e "${colored_text1}${NC}"
                            echo -e "${CY}已生成的密钥对${NC}:"
                            echo -e "${GR}服务器私钥${NC}: $(cat server.key)"
                            echo -e "${GR}服务器公钥${NC}: $(cat server.key.pub)"
                            echo -e "${GR}节点1私钥${NC}: $(cat client11.key)"
                            echo -e "${GR}节点1公钥${NC}: $(cat client11.key.pub)"
                            echo "
                            [Interface]
                            PrivateKey = $(cat server.key)
                            Address = $wgserver_ip

                            PostUp   = iptables -A FORWARD -i $wgfname -j ACCEPT; iptables -A FORWARD -o $wgfname -j ACCEPT; iptables -t nat -A POSTROUTING -o $wgnetwork_interface -j MASQUERADE
                            PostDown = iptables -D FORWARD -i $wgfname -j ACCEPT; iptables -D FORWARD -o $wgfname -j ACCEPT; iptables -t nat -D POSTROUTING -o $wgnetwork_interface -j MASQUERADE

                            ListenPort = $wglisten_port
                            DNS = $wgdns_address
                            MTU = 1420

                            [Peer]
                            PublicKey =  $(cat client11.key.pub)
                            AllowedIPs = ${wgserver_ip_prefix}11/32,fe80::11/128
                            " > $wgfname.conf
                            sed -i 's/^[ \t]*//;s/[ \t]*$//' $wgfname.conf

                            cat $wgfname.conf
                            systemctl enable wg-quick@$wgfname.service &>/dev/null
                            wg-quick down $wgfname &>/dev/null
                            wg-quick up $wgfname &>/dev/null
                            ip address show $wgfname
                            if [[ ! "${wgactive}" = "active" ]]; then
                                read -e -p "重启后生效, 是否重启服务器? (Y/其它)" choice
                                    if [[ $choice == "Y" || $choice == "y" ]]; then
                                        reboot
                                    fi
                            else
                                echo -e "${MA}WIREGUARD 服务已重新启动...${NC}:"
                            fi
                            waitfor
                            break
                            ;;
                        c|C|cc|CC)
                            break
                            ;;
                        *)
                            etag=1
                            ;;
                    esac
                    loop=1
                done
                echo "break 1"
                ;;
            2|22)
                if [[ $wgtag == *"*"* ]]; then
                    echo -e "检测到系统未安装WIREGUARD, 请先选择第 ${MA}i${NC} 项进行安装."
                    waitfor
                    continue
                fi
                if [ ! -f "$config_file" ]; then
                    echo -e "未发现配置文件, 请先进行配置服务."
                    waitfor
                    continue
                fi
                allowed_ips_array=($(extract_allowed_ips "$config_file"))
                # public_keys_array=($(extract_public_keys "$config_file"))
                ############## 用于验证
                # allowed_ips_array=($(extract_allowed_ips "$config_file"))
                # public_keys_array=($(extract_public_keys "$config_file"))
                # echo "Allowed IPs:"
                # for ip in "${allowed_ips_array[@]}"; do
                #     echo "  $ip"
                # done
                # echo "Public Keys:"
                # for key in "${public_keys_array[@]}"; do
                #     echo "  $key"
                # done
                #######################################
                echo -e "${colored_text1}${NC}"
                # wg show all
                wg show $wgfname
                allowed_ips_array2=($(awk -F= '/^AllowedIPs/ {gsub(/[ \t\/]+/, "", $2); sub(/\/[0-9]+$/, "", $2); print $2}' $config_file))
                echo -e "${colored_text1}${NC}"
                echo -e "${CY}PEER 列表${NC}:"
                for i in "${!allowed_ips_array[@]}"; do
                    echo " $((i+1)):   ${allowed_ips_array[i]}"
                done
                remind1p
                # read -e -p "查询客户端具体配置, 请输入序号 (C.取消): " -n 2 -r choice && echoo
                # if [[ $choice == "c" || $choice == "C" || $choice == "cc" || $choice == "CC" ]]; then
                read -e -p "查询客户端具体配置, 请输入序号 (C.取消): " choice
                if [[ $choice == "c" || $choice == "C" ]]; then
                    continue
                fi
                if [[ $choice =~ ^[0-9]+$ ]]; then
                    if ((choice >= 1 && choice <= ${#allowed_ips_array[@]})); then
                        selected_ip="${allowed_ips_array[$((choice-1))]}"
                        ######################
                        allowed_ips_no="0.0.0.0/0, ::/0"
                        allowed_ips_plan1="1.0.0.0/8, 2.0.0.0/8, 3.0.0.0/8, 4.0.0.0/6, 8.0.0.0/7, 10.0.8.0/24, 11.0.0.0/8, 12.0.0.0/6, 16.0.0.0/4, 32.0.0.0/3, 64.0.0.0/2, 128.0.0.0/3, 160.0.0.0/5, 168.0.0.0/6, 172.0.0.0/12, 172.32.0.0/11, 172.64.0.0/10, 172.128.0.0/9, 173.0.0.0/8, 174.0.0.0/7, 176.0.0.0/4, 192.0.0.0/9, 192.128.0.0/11, 192.160.0.0/13, 192.169.0.0/16, 192.170.0.0/15, 192.172.0.0/14, 192.176.0.0/12, 192.192.0.0/10, 193.0.0.0/8, 194.0.0.0/7, 196.0.0.0/6, 200.0.0.0/5, 208.0.0.0/4, 1.1.1.1/32, 8.8.8.8/32, 2001:4860:4860::8888/128, ::/0"
                        # allowed_ips_plan2=""
                        remind1p
                        read -e -p "选择路由模式: (1/回车默认.无排除,代理所有流量  2.排除局域网IP): " choicemode
                        if [[ $choicemode == "2" ]]; then
                            allowed_ips_final="$allowed_ips_plan1"
                        else
                            allowed_ips_final="$allowed_ips_no"
                        fi
                        ######################
                        IP_address=$(curl ipinfo.io/ip 2> /dev/null) > /dev/null
                        echo -e "${colored_text1}${NC}"
                        echo -e "${CY}检查到 IP 地址列表${NC}:"
                        echo " 1:   $IP_address"
                        for i in "${!ip_all_array[@]}"; do
                            echo " $((i+2)):   ${ip_all_array[i]}"
                        done
                        remind1p
                        read -e -p "选择 Endpoint 对端IP, 回车默认选择公网IP (A.手动输入): " selected_index
                        selected_ip_inall=""
                        if ((selected_index > 1 && selected_index <= ${#ip_all_array[@]} + 1)); then
                            selected_ip_inall="${ip_all_array[selected_index-2]}"
                        else
                            if [[ $selected_index == "a" || $selected_index == "A" ]]; then
                                read -e -p "输入 Endpoint 对端IP: " EndpointIP
                                selected_ip_inall="$EndpointIP"
                            elif [[ "$selected_index" != "1" && "$selected_index" != "" ]]; then
                                echo -e "无效的序号，系统默认选择${MA}公网IP${NC}地址."
                            fi
                        fi
                        ##########################
                        if [ -f "/etc/wireguard/client$((choice+10)).key" ]; then
                            private_key=$(cat /etc/wireguard/client$((choice+10)).key)
                        else
                            private_key="未检测到, 请手动查阅文件(/etc/wireguard/...)..."
                        fi
                        # wgserver_ip=$(grep "Address" $config_file | awk '{print $3}')
                        # wgserver_ip_prefix0=$(echo $wgserver_ip | cut -d ',' -f 1 | cut -d '.' -f 1-3)
                        # fourth_octet=$(echo $wgserver_ip | cut -d ',' -f 1 | cut -d '.' -f 4) # 取IP第四位
                        # address=$(awk -v ip="$selected_ip" -v RS= '/\[Peer\]/ && $0 ~ ip {getline; print $2}' $config_file)
                        wg_dns=$(awk '/^DNS/{gsub(/[ \t]+/, "", $3); print $3}' $config_file)
                        # wg_mtu=$(awk '/^MTU/{gsub(/[ \t]+/, "", $3); print $3}' $config_file)
                        server_public_key=$(cat /etc/wireguard/server.key.pub)
                        allowed_ips=$(awk -v ip="$selected_ip" -v RS= '/\[Peer\]/ && $0 ~ ip {getline; print $2}' $config_file)
                        server_port=$(awk '/^ListenPort/{gsub(/[ \t]+/, "", $3); print $3}' $config_file)
                        echo -e "${colored_text1}${NC}"
                        echo -e "以下为[ ${MA}PEER $choice${NC} ]配置文件信息:"
                        echo
                        ##################### 用于验证
                        # echo
                        # ls /etc/wireguard
                        # cat /etc/wireguard/client*.key
                        # echo
                        #####################
                        echo "[Interface]"
                        # echo -e "PrivateKey = ${public_keys_array[$((choice-1))]} ${GR}# 此处为client的私钥${NC}"  ####此处错误，留着备用
                        echo -e "PrivateKey = $private_key"
                        echo -e "Address = ${allowed_ips_array[$((choice-1))]}/32,fe80::$((choice+10))/128"
                        echo -e "DNS = $wg_dns"
                        echo -e "MTU = 1500"
                        # echo -e "MTU = $wg_mtu" # 默认让它 1500
                        echo
                        echo "[Peer]"
                        echo -e "PublicKey = $server_public_key"
                        #echo -e "AllowedIPs = ${wgserver_ip_prefix0}.0/24,fe80::0/112 ${GR}# 此处为允许访问的IP或IP段${NC}"
                        echo -e "AllowedIPs = $allowed_ips_final"
                        if [[ ! $selected_ip_inall == "" ]]; then
                            selected_ip_inall_checked=$(check_ipv4_or_ipv6 "$selected_ip_inall")
                            echo "Endpoint = $selected_ip_inall_checked:$server_port"
                        else
                            echo "Endpoint = $IP_address:$server_port"
                        fi
                        echo -e "${colored_text1}${NC}"
                        echo -e "${CY}二维码生成:${NC}"
                        echo -e "将配置文件信息粘贴至: https://zh.qr-code-generator.com ${GR}->${NC} 文本 ${GR}->${NC} 创建二维码"
                        ################### 生成QRCODE, 由于画面过大，暂时放弃
                        # qrencode -t ANSIUTF8 '
                        # echo "[Interface]"
                        # # echo -e "PrivateKey = ${public_keys_array[$((choice-1))]} ${GR}# 此处为client的私钥${NC}"  ####此处错误，留着备用
                        # echo -e "PrivateKey = $private_key ${GR}# 此处为client的私钥${NC}"
                        # echo -e "Address = ${allowed_ips_array[$((choice-1))]}/32,fe80::$((choice+10))/128 ${GR}# 此处为peer的客户端IP${NC}"
                        # echo -e "DNS = $wg_dns"
                        # echo -e "MTU = 1500"
                        # # echo -e "MTU = $wg_mtu" # 默认让它 1500
                        # echo
                        # echo "[Peer]"
                        # echo -e "PublicKey = $server_public_key ${GR}# 此处为server的公钥${NC}"
                        # #echo -e "AllowedIPs = ${wgserver_ip_prefix0}.0/24,fe80::0/112 ${GR}# 此处为允许访问的IP或IP段${NC}"
                        # echo -e "AllowedIPs = $allowed_ips_final ${GR}# 此处为允许路由的IP或IP段${NC}"
                        # if [[ ! $selected_ip_inall == "" ]]; then
                        #     selected_ip_inall_checked=$(check_ipv4_or_ipv6 "$selected_ip_inall")
                        #     echo "Endpoint = $selected_ip_inall_checked:$server_port"
                        # else
                        #     echo "Endpoint = $IP_address:$server_port"
                        # fi'
                        ###################
                        echo -e "${colored_text1}${NC}"
                    else
                        echo "无效的序号."
                    fi
                else
                    echo "请输入有效的数字."
                fi
                waitfor
                ;;
            3|33)
                if [[ $wgtag == *"*"* ]]; then
                    echo -e "检测到系统未安装WIREGUARD, 请先选择第 ${MA}i${NC} 项进行安装."
                    waitfor
                    continue
                fi
                if [ ! -f "$config_file" ]; then
                    echo -e "未发现配置文件, 请先进行配置服务."
                    waitfor
                    continue
                fi
                read -e -p "是否确定增加一个节点? (Y/其它)" choice
                if [[ ! ($choice = "y" || $choice = "Y") ]]; then
                    continue
                fi

                allowed_ips=$(extract_allowed_ips "$config_file")
                allowed_ips_array=($allowed_ips)
                wgserver_ip_add="${allowed_ips_array[-1]}"
                while [[ " ${allowed_ips_array[@]} " =~ " ${wgserver_ip_add} " ]]; do
                    IFS='.' read -r -a ip_parts <<< "$wgserver_ip_add"
                    ((ip_parts[3]++))
                    wgserver_ip_add="${ip_parts[0]}.${ip_parts[1]}.${ip_parts[2]}.${ip_parts[3]}"
                    wgserver_ip6_add="fe80::${ip_parts[3]}"
                done

                last_octet=$(echo "$wgserver_ip_add" | awk -F'.' '{print $NF}')
                # echo "$last_octet"
                # echo "AllowedIPs values: ${allowed_ips_array[@]}" ####用于验证数组
                mkdir -p /etc/wireguard
                cd /etc/wireguard/
                wg genkey > client${last_octet}.key
                wg pubkey < client${last_octet}.key > client${last_octet}.key.pub
                echo "[Peer]
                PublicKey =  $(cat client${last_octet}.key.pub)
                AllowedIPs = ${wgserver_ip_add}/32,${wgserver_ip6_add}/128
                " >> $wgfname.conf
                sed -i 's/^[ \t]*//;s/[ \t]*$//' $wgfname.conf
                cat $wgfname.conf
                wg-quick down $wgfname &>/dev/null
                wg-quick up $wgfname &>/dev/null
                echo -e "${MA}WIREGUARD 服务已重启...${NC}:"
                waitfor
                ;;
            4|44)
                conf_files=()
                conf_file_value=""
                while IFS= read -r -d '' file; do
                    filename=$(basename "$file")
                    conf_files+=("${filename%.conf}")  # 去除文件名后缀，只保留前缀部分
                    conf_file_value="${filename%.conf}" # 保存 conf_file 的值
                done < <(find /etc/wireguard/ -type f -name "*.conf" -print0)
                # echo "所有.conf文件名前缀："
                # for conf_file in "${conf_files[@]}"; do
                #     echo "$conf_file"
                # done
                wginterfaces=($(wg show all | grep -E '^\s*interface:' | awk '{print $2}'))
                # echo "可用接口列表："
                # for ((i = 0; i < ${#wginterfaces[@]}; i++)); do
                #     echo "$((i + 1)): ${wginterfaces[i]}"
                # done
                if [[ ! $conf_file_value == "" ]]; then
                    i=0
                    echo -e "${colored_text1}${NC}"
                    echo "所有服务名称:"
                    for conf_file in "${conf_files[@]}"; do
                        ((i++))
                        found=false
                        for interface in "${wginterfaces[@]}"; do
                            if [ "$conf_file" == "$interface" ]; then
                                echo -e "$i    ${CY}$conf_file${NC}            ${MA}已开启${NC}"
                                found=true
                                break
                            fi
                        done
                        if ! $found; then
                            echo -e "$i    ${CY}$conf_file${NC}"
                        fi
                    done
                    remind1p
                    echo -n -e "请输入要选择的接口序号 (${MA}1-${#conf_files[@]}${NC}): "
                    read -e selection
                    if (( selection >= 1 && selection <= ${#conf_files[@]} )); then
                        index=$((selection - 1))
                        selected_conf_files=${conf_files[index]}
                        echo -e "选择的接口是：${CY}$selected_conf_files${NC}"
                        echo -e "操作序号: 1.开启  2.关闭  3.${MA}删除${NC}"
                        remind1p
                        read -e -p "请输入操作序号:" choice
                        echo -e "${colored_text1}${NC}"
                        if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
                            echo "选择不是有效的数字"
                        else
                            if [ $choice -eq 1 ]; then
                                wg-quick up $selected_conf_files
                                echo -e "$selected_conf_files 服务已经${MA}开启${NC}"
                            elif [ $choice -eq 2 ]; then
                                wg-quick down $selected_conf_files
                                echo -e "$selected_conf_files 服务已经${MA}关闭${NC}"
                            elif [ $choice -eq 3 ]; then
                                read -e -p "是否确定要删除 $selected_conf_files 服务? (Y/其它.取消)" delete_choice
                                if [[ $delete_choice = "y" || $delete_choice = "Y" ]]; then
                                    wg-quick down $selected_conf_files
                                    rm -f /etc/wireguard/$selected_conf_files.conf
                                    echo -e "$selected_conf_files 服务已经${MA}删除${NC}."
                                else 
                                    echo "取消删除."
                                fi
                            else
                                echo "无效的选择."
                            fi
                        fi
                    elif [[ $selection == "" ]]; then
                        echo
                        echo "无效的选择."
                    else
                        echo "无效的选择."
                    fi
                else
                    remind1p
                    echo "未发现服务."
                fi
                waitfor
                ;;
            5|55)
                if [[ $wgtag == *"*"* ]]; then
                    echo -e "检测到系统未安装WIREGUARD, 请先选择第 ${MA}i${NC} 项进行安装."
                    waitfor
                    continue
                fi
                if [ ! -f "$config_file" ]; then
                    echo -e "未发现配置文件, 请先进行配置服务."
                    waitfor
                    continue
                fi
                nano /etc/wireguard/$wgfname.conf
                ;;
            i|I|ii|II)
                if [ "$virtual" = "OpenVZ" ]; then
                    echo "检测到系统为: $virtual"
                    curl -fsSL git.io/wireguard-go.sh | sudo bash
                elif [ "$virtual" = "Lxc" ]; then
                    echo "检测到系统为: $virtual"
                    curl -fsSL git.io/wireguard-go.sh | sudo bash
                else
                    if command -v apt &>/dev/null; then
                        echo "检测到系统为: $virtual"
                        source /etc/os-release
                        if grep -q 'lunar' /etc/os-release && grep -q 'bullseye' /etc/apt/sources.list /etc/apt/sources.list.d/* &>/dev/null; then
                            # echo "系统版本是 Ubuntu 23.04 (Lunar Lobster) 或 Debian Bullseye"
                            apt install -y wireguard resolvconf
                        elif grep -q 'lunar' /etc/os-release; then
                            # echo "系统版本是 Ubuntu 23.04 (Lunar Lobster)"
                            apt install -y wireguard resolvconf
                        elif grep -q 'bullseye' /etc/apt/sources.list /etc/apt/sources.list.d/* &>/dev/null; then
                            # echo "系统版本是 Debian Bullseye"
                            apt install -y wireguard resolvconf
                        else
                            # echo "系统版本可能不是 Ubuntu 23.04 (Lunar Lobster) 或 Debian Bullseye"
                            apt-get install gnupg
                            apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0E98404D386FA1D9 6ED0E7B82643E131
                            apt update
                            apt install -y wireguard resolvconf
                        fi
                    fi
                    if command -v yum &>/dev/null; then
                        echo "检测到系统为: $virtual"
                        yum install -y yum-utils epel-release
                        yum-config-manager --setopt=centosplus.includepkgs=kernel-plus --enablerepo=centosplus --save
                        sed -e 's/^DEFAULTKERNEL=kernel$/DEFAULTKERNEL=kernel-plus/' -i /etc/sysconfig/kernel
                        yum install -y kernel-plus wireguard-tools
                        read -e -p "重启后生效, 是否重启服务器? (Y/其它)" choice
                        if [[ $choice == "Y" || $choice == "y" ]]; then
                            reboot
                        fi
                    fi
                fi
                waitfor
                ;;
            d|D|dd|DD)
                read -e -p "是否确定要卸载 WIREGUARD 并删除所有相关文件: (Y/其它)" choice
                if [[ ! ($choice = "y" || $choice = "Y") ]]; then
                    continue
                fi
                systemctl disable wg-quick@$wgfname
                systemctl stop wg-quick@$wgfname
                # modprobe -r wireguard
                # rm -f /etc/wireguard/$wgfname.conf
                # rm -f /etc/wireguard/*.key
                # rm -f /etc/wireguard/*.pub
                # rm -f /etc/systemd/system/wg-quick@$wgfname.service
                # rm -f /usr/bin/wg
                # rm -f /usr/bin/wg-quick
                if command -v wg &>/dev/null; then
                    echo -e "${MA}WIREGUARD 卸载失败${NC}！"
                fi
                echo -e "${GR}WIREGUARD 卸载成功${NC}！"
                waitfor
                ;;
            t)
                clear_screen
                allowed_ips_array=($(extract_allowed_ips "$config_file"))
                echo "Allowed IPs:"
                for ip in "${allowed_ips_array[@]}"; do
                    echo "  $ip"
                done
                waitfor
                ;;
            r|R|rr|RR)
                break
                ;;
            x|X|xx|XX)
                exit 0
                ;;
            *)
                etag=1
                ;;
        esac
        done
        onlyone=0
        ;;
    6|66)
        wget -N --no-check-certificate "https://raw.githubusercontent.com/redstarxxx/shell/main/iptables-ie.sh" && chmod +x iptables-ie.sh && bash iptables-ie.sh
        exit 0
        ;;
    v|vv)
        clear_screen
        echo -e "${GR}▼▼${NC}"
        echo -e "${colored_text2}${NC}${colored_text2}${NC}"
        echo -e "                    >>>>>   ${MA}声  明${NC}  <<<<<"
        echo
        echo -e "★ 1. ${GR}本脚本开源.${NC}"
        echo -e "★ 2. ${GR}本脚本引用XRAY脚本地址:${NC}"
        echo -e "     ${GR}URL: https://github.com/XTLS/${NC}"
        echo -e "★ 3. ${GR}本脚本引用的ACME脚本地址:${NC}"
        echo -e "     ${GR}URL: https://github.com/acmesh-official/${NC}"
        echo -e "★ 4. ${GR}本脚本所使用依赖工具如下:${NC}"
        echo -e "     a. ${GR}CURL下载工具.${NC}"
        echo -e "     b. ${GR}WGET下载工具.${NC}"
        echo -e "     c. ${GR}NANO文本编辑工具.${NC}"
        echo -e "     d. ${GR}JQ工具, 用以对JSON配置文件的读写处理.${NC}"
        echo -e "     e. ${GR}QRENCODE工具, 用以生成二维码.${NC}"
        echo -e "★ 5. ${GR}本脚本临时文件处理如下:${NC}"
        echo -e "     a. ${GR}采用Nginx申请证书时系统会把原nginx.conf文件备份成nginx.redx文件,${NC}"
        echo -e "        ${GR}除了上述备份, 系统会将nginx.conf文件临时改为nginx_ssl.conf文件,${NC}"
        echo -e "        ${GR}等待证书申请后, 不管成功与否, 系统都会将nginx_ssl.conf文件改回nginx.conf文件.${NC}"
        echo -e "     b. ${GR}如果使用ACME申请证书失败时会产生0字节的.cer和.key或.pem文件, 本脚本会自动将其删除.${NC}"
        echo -e "★ 6. ${GR}本脚本仅供学习与研究, 如果由本脚本造成的各种法律问题由使用者个人承担.${NC}"
        echo
        echo -e "${CY}2023.11.11${NC}"
        echo -e "${MA}end.${NC}"
        echo -e "${colored_text2}${NC}${colored_text2}${NC}"
        waitfor
        ;;
    -)
        rm -f /$user_path/.redx/redx_*.sh
        echo ".sh子文件已全部删除."
        waitfor
        ;;
    o|O|oo|OO)
        echo "调试阶段停用."
        waitfor
        # curl -o redx.sh https://raw.githubusercontent.com/ieiian/Shell/dev/redx.sh && chmod +x redx.sh && ./redx.sh
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
