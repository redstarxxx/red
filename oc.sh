#!/bin/bash

# 检查是否为root用户，如果不是则提示切换
if [ "$(id -u)" != "0" ]; then
    echo "请使用 sudo -i 切换至 root 用户后再次运行此脚本"
    exit 1
fi

# 检查参数是否提供正确
if [ $# -ne 3 ]; then
    echo "请提供正确的参数:"
    echo '格式: oc.sh <主机名> <密码> <端口>  如果有特殊符号用双引号("")括起'
    echo "例如: oc.sh NAME pw123 8888"
    echo '例如: bash -c "$(curl -L https://raw.githubusercontent.com/redstarxxx/shell/main/oc.sh)" @ NAME pw123 8888'
    exit 1
fi

# 检查并安装依赖
echo "检查并安装依赖..."
declare -a dependencies=("sed" "passwd" "hostnamectl" "net-tools" "grep" "iptables")
missing_dependencies=()

for dep in "${dependencies[@]}"; do
    if ! command -v "$dep" &>/dev/null; then
        missing_dependencies+=("$dep")
    fi
done

if [ ${#missing_dependencies[@]} -gt 0 ]; then
    echo "以下依赖未安装: ${missing_dependencies[*]}"
    echo "正在安装缺失的依赖..."
    if [ -x "$(command -v apt)" ]; then
        apt install -y "${missing_dependencies[@]}"
    elif [ -x "$(command -v yum)" ]; then
        yum install -y "${missing_dependencies[@]}"
    else
        echo "未知的包管理器，无法安装依赖。请手动安装所需依赖后再运行脚本。"
        exit 1
    fi
else
    echo "所有依赖已安装，无需执行安装操作。"
fi

# 修改 hosts 和 hostname
echo "修改 hosts 和 hostname..."
sed -i "s/$(hostname)/$1/g" /etc/hosts
echo "$1" > /etc/hostname
hostnamectl set-hostname $1

# 更改 root 用户密码
echo "更改 root 用户密码..."
echo "root:$2" | chpasswd

# 检查端口是否被占用
if netstat -tuln | grep -q ":$3\b"; then
    echo -e "\e[31m端口 $3 正在使用中...\e[0m"
    
    # 询问是否重启系统
    read -p "是否断续? (按Y继续, 其它退出): " choice
    if [ "$choice" != "Y" ] && [ "$choice" != "y" ]; then
        echo "退出脚本..."
        exit 0
    fi
fi

# 编辑 /etc/ssh/sshd_config
echo "编辑 /etc/ssh/sshd_config..."
sed -i -e "s/^#\?Port .*/Port $3/g" \
       -e 's/^#\?PermitRootLogin .*/PermitRootLogin yes/g' \
       -e 's/^#\?MaxSessions .*/MaxSessions 1/g' \
       -e 's/^#\?PasswordAuthentication .*/PasswordAuthentication yes/g' \
       -e 's/^#\?ClientAliveInterval .*/ClientAliveInterval 30/g' \
       /etc/ssh/sshd_config

# 重启SSH服务
echo "重启 SSH 服务..."
systemctl restart ssh

# 验证端口是否打开
if lsof -i :$3 >/dev/null; then
    echo -e "\e[32m端口 $3 已经打开, 更改端口成功.\e[0m"

    # 停止和禁用系统服务
    echo "停止和禁用系统服务..."
    systemctl stop rpcbind &&
    systemctl stop rpcbind.socket &&
    systemctl disable rpcbind &&
    systemctl disable rpcbind.socket &&
    systemctl stop oracle-cloud-agent &&
    systemctl disable oracle-cloud-agent &&
    systemctl stop oracle-cloud-agent-updater &&
    systemctl disable oracle-cloud-agent-updater &&
    systemctl stop firewalld &&
    systemctl disable firewalld
    
    # 删除防火墙规则
    echo "删除防火墙规则..."
    rm -f /etc/iptables/rules.v4
    rm -f /etc/iptables/rules.v6

    # 询问是否重启系统
    read -p "是否重启系统? (按Y重启, 其它退出): " choice
    if [ "$choice" == "Y" ] || [ "$choice" == "y" ]; then
        echo "正在重启系统..."
        reboot
    else
        echo "退出脚本..."
        exit 0
    fi
else
    echo -e "\e[31m端口 $3 没有打开, 更改端口失败.\e[0m"
fi
