
#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=======================================================
#	System Required: CentOS/Debian/Ubuntu/OpenWRT
#	Description: Nginx reverse proxy
#	Version: $sh_ver
#	Author: tse
#	Blog: https://vtse.eu.org
#=======================================================

sh_ver="1.0.0"

# 颜色代码
GR="\033[32m" && RE="\033[31m" && GRB="\033[42;37m" && REB="\033[41;37m" && NC="\033[0m"
Inf="${GR}[信息]${NC}:"
Err="${RE}[错误]${NC}:"
Tip="${GR}[提示]${NC}:"

# 检测系统
check_sys(){
    local checkType=$1
    local value=$2
    release=''
    systemPackage=''
    systemVersion=''
    systemBit=''
    if [[ -f /etc/redhat-release ]]; then
        release="centos"
        systemPackage="yum"
        systemVersion=$(grep -oE  "[0-9.]+" /etc/redhat-release)
        systemBit=$(uname -m)
    elif cat /etc/issue | grep -Eqi "debian"; then
        release="debian"
        systemPackage="apt-get"
        systemVersion=$(grep -oE  "[0-9.]+" /etc/issue)
        systemBit=$(uname -m)
    elif cat /etc/issue | grep -Eqi "ubuntu"; then
        release="ubuntu"
        systemPackage="apt-get"
        systemVersion=$(grep -oE  "[0-9.]+" /etc/issue)
        systemBit=$(uname -m)
    elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
        release="centos"
        systemPackage="yum"
        systemVersion=$(grep -oE  "[0-9.]+" /etc/redhat-release)
        systemBit=$(uname -m)
    elif cat /proc/version | grep -Eqi "debian"; then
        release="debian"
        systemPackage="apt-get"
        systemVersion=$(grep -oE  "[0-9.]+" /etc/issue)
        systemBit=$(uname -m)
    elif cat /proc/version | grep -Eqi "ubuntu"; then
        release="ubuntu"
        systemPackage="apt-get"
        systemVersion=$(grep -oE  "[0-9.]+" /etc/issue)
        systemBit=$(uname -m)
    elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
        release="centos"
        systemPackage="yum"
        systemVersion=$(grep -oE  "[0-9.]+" /etc/redhat-release)
        systemBit=$(uname -m)
    elif cat /etc/openwrt_release | grep -Eqi "openwrt"; then
        release="openwrt"
        systemPackage="opkg"
        systemVersion=$(grep -oE  "[0-9.]+" /etc/openwrt_release)
        systemBit=$(uname -m)
    else
        release="unknow"
    fi
    if [[ ${checkType} == "sysRelease" ]]; then
        if [ "${value}" == "${release}" ]; then
            return 0
        else
            return 1
        fi
    elif [[ ${checkType} == "sysPackage" ]]; then
        if [ "${value}" == "${systemPackage}" ]; then
            return 0
        else
            return 1
        fi
    elif [[ ${checkType} == "sysVersion" ]]; then
        if [ "${value}" == "${systemVersion}" ]; then
            return 0
        else
            return 1
        fi
    elif [[ ${checkType} == "sysBit" ]]; then
        if [ "${value}" == "${systemBit}" ]; then
            return 0
        else
            return 1
        fi
    fi
}

# 检测系统
check_sys_all(){
    if check_sys sysRelease centos || check_sys sysRelease ubuntu || check_sys sysRelease debian || check_sys sysRelease openwrt; then
        echo -e "${Inf} 检测到系统为 ${release} ${systemVersion} ${systemBit}"
    else
        echo -e "${Err} 脚本不支持当前系统 ${release} ${systemVersion} ${systemBit} !" && exit 1
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

# 检测系统是否安装nginx
check_nginx(){
    if [ ! -f "/usr/sbin/nginx" ]; then
        read "检测到系统未安装Nginx，是否安装? [y/n]" nginx_install
        if [ "${nginx_install}" == "y" ] || [ "${nginx_install}" == "Y" ]; then
            echo "Installing Nginx..."
            $systemPackage -y update
            $systemPackage -y install nginx
        else
            echo "请先安装Nginx后再试！"
            exit 1
        fi
    fi
}

# 检测系统是否安装curl
check_curl(){
    if [ ! -f "/usr/bin/curl" ]; then
        read "检测到系统未安装Curl，是否安装? [y/n]" curl_install
        if [ "${curl_install}" == "y" ] || [ "${curl_install}" == "Y" ]; then
            echo "Installing Curl..."
            $systemPackage -y update
            $systemPackage -y install curl
        else
            echo "请先安装Curl后再试！"
            exit 1
        fi
    fi        
}

# 恢复nginx初始配置
nginx_reset(){
    echo "Resetting Nginx..."
}

# CLS
echo "====================================================="
check_sys_all
check_nginx
check_curl

# 添加nginx反代信息
echo -e "请输入反代域名 ( 不含 http(s) ):"
read -ep "如 abc.tse.com : " domain
if [ -z "${domain}" ]; then echo -e "${Err} 域名不能为空！" && exit 1; fi
echo -e "请输入SSL证书地址:"
read -ep "如 /root/cert/abc.cer : " ceraddress
if [ -z "${ceraddress}" ]; then echo -e "${Err} SSL证书地址不能为空！" && exit 1; fi
if [ ! -f "${ceraddress}" ]; then echo -e "${Err} SSL证书地址不存在！" && exit 1; fi
echo -e "请输入SSL密钥地址:"
read -ep "如 /root/cert/abc.key : " keyaddress
if [ -z "${keyaddress}" ]; then echo -e "${Err} SSL密钥地址不能为空！" && exit 1; fi
if [ ! -f "${keyaddress}" ]; then echo -e "${Err} SSL密钥地址不存在！" && exit 1; fi
echo -e "请输入反代域名路径:"
read -ep "如 "空/[回车]" 或 / 或 /path : " path
# if [ "${path:0:1}" == "/" ]; then path=${path:1}; fi # 去除/
if [ "${path:0:1}" != "/" ]; then path="/$path"; fi # 加上/
echo -e "请输入反代内部地址 ( 含 http(s) ) :"
read -ep "如 http://127.0.0.1:2000 : " address
if [ -z "${address}" ]; then echo -e "${Err} 内部地址不能为空！" && exit 1; fi
if [ "${address:0:4}" != "http" ]; then address="http://${address}"; fi

echo "====================================================="
echo -e "${Inf} 反代域名: \t$domain"
echo -e "${Inf} SSL证书地址: \t$ceraddress"
echo -e "${Inf} SSL密钥地址: \t$keyaddress"
echo -e "${Inf} 反代域名路径: \t$path"
echo -e "${Inf} 反代内部地址: \t$address"
echo "====================================================="
show_domain="${domain}${path}"
if [ "${show_domain: -1}" == "/" ]; then show_domain=${show_domain:0:-1}; fi
echo -e "${GR}[导图]${NC}: https://$show_domain -> ${address}"
echo "====================================================="

# 确认信息
echo -en "请确认信息是否正确? [y/n]" && read -er confirm
if [ ! "${confirm}" == "y" ] && [ ! "${confirm}" == "Y" ]; then
    if [ -z "${confirm}" ]; then echo; fi
    echo -e "${Err} 用户取消操作!" && exit 1
fi

# 添加反代信息
echo "正在配置中..."
if [ -f "/etc/nginx/conf.d/rp_${domain}.conf" ]; then
    echo -e "文件: ${RE}rp_${domain}.conf${NC} 已存在!"
    read -ep "是否继续(覆盖)? [y/n]: " confirm
    if [ ! "${confirm}" == "y" ] && [ ! "${confirm}" == "Y" ]; then
        echo -e "${Err} 用户取消操作!" && exit 1
    fi
fi
cat > /etc/nginx/conf.d/rp_${domain}.conf << EOF
server {
    listen 80;
    server_name ${domain};
    return 301 https://${domain}\$request_uri;
}
server {
    listen 443 ssl;

    gzip on;
    gzip_http_version 1.1;
    gzip_vary on;
    gzip_comp_level 6;
    gzip_proxied any;
    gzip_types text/plain text/css application/json application/javascript application/x-javascript text/javascript;

    ssl_certificate /root/cert/pad.ok360.top.cer;
    ssl_certificate_key /root/cert/pad.ok360.top.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers 'ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256';
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    server_name ${domain};

    location ${path} {
        proxy_pass ${address};
        proxy_redirect off;        
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
        proxy_read_timeout 300s;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF
echo "正在重启 Nginx..."
if systemctl restart nginx &> /dev/null; then
    echo -e "${Tip} 反代网址: https://$show_domain"
else
    echo "执行失败!"
fi
# systemctl restart nginx
# echo -e "${Tip} 反代网址: https://$show_domain"
echo "Done!"
exit 0
# END
