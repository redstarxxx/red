#!/bin/bash

# 检查是否为root用户，如果不是则提示切换
if [ "$(id -u)" != "0" ]; then
    echo "请使用 sudo -i 切换至 root 用户后再次运行此脚本"
    exit 1
fi

# 检查参数是否提供正确
if [ $# -ne 2 ]; then
    echo "请提供正确的参数:"
    echo "格式: oc.sh <密码> <主机名>"
    echo "例如: oc.sh pw123 NAME"
    echo '例如: bash -c "$(curl -L https://raw.githubusercontent.com/redstarxxx/shell/main/oc.sh)" pw123 NAME'
    exit 1
fi

# 更改 root 用户密码
echo "更改 root 用户密码..."
echo "root:$1" | chpasswd

# 修改 hosts 和 hostname
echo "修改 hosts 和 hostname..."
sed -i "s/$(hostname)/$2/g" /etc/hosts
echo "$2" > /etc/hostname
hostnamectl set-hostname $2

# 编辑 /etc/ssh/sshd_config
echo "编辑 /etc/ssh/sshd_config..."
sed -i -e 's/#Port 22/Port 8022/g' \
       -e 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' \
       -e 's/#MaxSessions 10/MaxSessions 1/g' \
       -e 's/PasswordAuthentication no/PasswordAuthentication yes/g' \
       -e 's/#ClientAliveInterval 0/ClientAliveInterval 30/g' \
       /etc/ssh/sshd_config

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
read -p "是否重启系统？(按Y重启，其它退出): " choice
if [ "$choice" == "Y" ] || [ "$choice" == "y" ]; then
    echo "正在重启系统..."
    reboot
else
    echo "退出脚本..."
    exit 0
fi
