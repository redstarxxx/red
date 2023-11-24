#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: iptables Port forwarding
#	Version: 1.1.1
#	Author: Toyo
#	Blog: https://doub.io/wlzy-20/
#=================================================
sh_ver="1.1.1"

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"

clear_screen() {
    if command -v apt &>/dev/null; then
        clear
    elif command -v yum &>/dev/null; then
        printf "\033c"
    else
        echo
    fi
}
waitfor() {
    echo -e "${Info} 执行完成, 按任意键继续..."
    read -n 1 -s -r -p ""
}
check_iptables(){
	iptables_exist=$(iptables -V)
	[[ ${iptables_exist} = "" ]] && echo -e "${Error} 没有安装iptables，请检查 !" && return 1
}
check_sys(){
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
install_iptables(){
	iptables_exist=$(iptables -V)
	if [[ ${iptables_exist} != "" ]]; then
		echo -e "${Info} 已经安装iptables，继续..."
	else
		echo -e "${Info} 检测到未安装 iptables，开始安装..."
		if [[ ${release}  == "centos" ]]; then
			yum update
			yum install -y iptables
		else
			apt-get update
			apt-get install -y iptables
		fi
		iptables_exist=$(iptables -V)
		if [[ ${iptables_exist} = "" ]]; then
			echo -e "${Error} 安装iptables失败，请检查 !" && return 1
		else
			echo -e "${Info} iptables 安装完成 !"
		fi
	fi
	echo -e "${Info} 开始配置 iptables !"
	Set_iptables
	echo -e "${Info} iptables 配置完毕 !"
}
Set_forwarding_port(){
	read -e -p "请输入 iptables 欲转发至的 远程端口 [1-65535] (支持端口段 如 2333-6666, 被转发服务器):" forwarding_port
	[[ -z "${forwarding_port}" ]] && echo "取消..." && return 1
	echo && echo -e "	欲转发端口 : ${Red_font_prefix}${forwarding_port}${Font_color_suffix}" && echo
}
Set_forwarding_ip(){
		read -e -p "请输入 iptables 欲转发至的 域名或远程IP(被转发服务器):" forwarding_ip
		[[ -z "${forwarding_ip}" ]] && echo "取消..." && return 1
		if [[ ! $forwarding_ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
			host_ip=$(host -t a $forwarding_ip | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -1)
			if [ -n "$host_ip" ]; then
				forwarding_ip="$host_ip"
				echo "域名解析成功，获取到的 IP 地址为: $forwarding_ip"
			else
				echo "域名解析失败，无法获取 IP 地址"
			fi
		fi
		echo && echo -e "	欲转发服务器IP : ${Red_font_prefix}${forwarding_ip}${Font_color_suffix}" && echo
}
Set_local_port(){
	echo -e "请输入 iptables 本地监听端口 [1-65535] (支持端口段 如 2333-6666)"
	read -e -p "(默认端口: ${forwarding_port}):" local_port
	[[ -z "${local_port}" ]] && local_port="${forwarding_port}"
	echo && echo -e "	本地监听端口 : ${Red_font_prefix}${local_port}${Font_color_suffix}" && echo
}
Set_local_ip(){
	read -e -p "请输入 本服务器的 域名或网卡IP(注意是网卡绑定的IP，而不仅仅是公网IP，回车自动检测外网IP):" local_ip
	if [[ -z "${local_ip}" ]]; then
		local_ip=$(wget -qO- -t1 -T2 ipinfo.io/ip)
		if [[ -z "${local_ip}" ]]; then
			echo "${Error} 无法检测到本服务器的公网IP，请手动输入"
			read -e -p "请输入 本服务器的 网卡IP(注意是网卡绑定的IP，而不仅仅是公网IP):" local_ip
			[[ -z "${local_ip}" ]] && echo "取消..." && return 1
		fi
	elif [[ ! $local_ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
		host_ip=$(host -t a $local_ip | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -1)
		if [ -n "$host_ip" ]; then
			local_ip="$host_ip"
			echo "域名解析成功，获取到的 IP 地址为: $local_ip"
		else
			echo "域名解析失败，无法获取 IP 地址"
		fi

	fi
	echo && echo -e "	本服务器IP : ${Red_font_prefix}${local_ip}${Font_color_suffix}" && echo
}
Set_forwarding_type(){
	echo -e "请输入数字 来选择 iptables 转发类型:
 1. TCP
 2. UDP
 3. TCP+UDP\n"
	read -e -p "(默认: TCP+UDP):" forwarding_type_num
	[[ -z "${forwarding_type_num}" ]] && forwarding_type_num="3"
	if [[ ${forwarding_type_num} == "1" ]]; then
		forwarding_type="TCP"
	elif [[ ${forwarding_type_num} == "2" ]]; then
		forwarding_type="UDP"
	elif [[ ${forwarding_type_num} == "3" ]]; then
		forwarding_type="TCP+UDP"
	else
		forwarding_type="TCP+UDP"
	fi
}
Set_Config(){
	while true; do
	Set_forwarding_port
	if [ $? -eq 1 ]; then
        break
    fi
	Set_forwarding_ip
	if [ $? -eq 1 ]; then
        break
    fi
	Set_local_port
	Set_local_ip
	Set_forwarding_type
	echo && echo -e "——————————————————————————————
	请检查 iptables 端口转发规则配置是否有误 !\n
	本地监听端口    : ${Green_font_prefix}${local_port}${Font_color_suffix}
	服务器 IP\t: ${Green_font_prefix}${local_ip}${Font_color_suffix}\n
	欲转发的端口    : ${Green_font_prefix}${forwarding_port}${Font_color_suffix}
	欲转发 IP\t: ${Green_font_prefix}${forwarding_ip}${Font_color_suffix}
	转发类型\t: ${Green_font_prefix}${forwarding_type}${Font_color_suffix}
——————————————————————————————\n"
	read -e -p "请按任意键继续，如有配置错误请使用 Ctrl+C 退出。" var
	break
	done
}
Add_forwarding(){
	check_iptables
	Set_Config
	if [ -z "$forwarding_port" ] || [ -z "$forwarding_ip" ]; then
		return 1
	fi
	local_port=$(echo ${local_port} | sed 's/-/:/g')
	forwarding_port_1=$(echo ${forwarding_port} | sed 's/-/:/g')
	if [[ ${forwarding_type} == "TCP" ]]; then
		Add_iptables "tcp"
	elif [[ ${forwarding_type} == "UDP" ]]; then
		Add_iptables "udp"
	elif [[ ${forwarding_type} == "TCP+UDP" ]]; then
		Add_iptables "tcp"
		Add_iptables "udp"
	fi
	Save_iptables
	clear && echo && echo -e "——————————————————————————————
	iptables 端口转发规则配置完成 !\n
	本地监听端口    : ${Green_font_prefix}${local_port}${Font_color_suffix}
	服务器 IP\t: ${Green_font_prefix}${local_ip}${Font_color_suffix}\n
	欲转发的端口    : ${Green_font_prefix}${forwarding_port_1}${Font_color_suffix}
	欲转发 IP\t: ${Green_font_prefix}${forwarding_ip}${Font_color_suffix}
	转发类型\t: ${Green_font_prefix}${forwarding_type}${Font_color_suffix}
——————————————————————————————\n"
}
View_forwarding(){
	check_iptables
	forwarding_text=$(iptables -t nat -vnL PREROUTING|tail -n +3)
	[[ -z ${forwarding_text} ]] && echo -e "${Error} 没有发现 iptables 端口转发规则，请检查 !" && return 1
	forwarding_total=$(echo -e "${forwarding_text}"|wc -l)
	forwarding_list_all=""
	for((integer = 1; integer <= ${forwarding_total}; integer++))
	do
		forwarding_type=$(echo -e "${forwarding_text}"|awk '{print $4}'|sed -n "${integer}p")
		forwarding_listen=$(echo -e "${forwarding_text}"|awk '{print $11}'|sed -n "${integer}p"|awk -F "dpt:" '{print $2}')
		[[ -z ${forwarding_listen} ]] && forwarding_listen=$(echo -e "${forwarding_text}"| awk '{print $11}'|sed -n "${integer}p"|awk -F "dpts:" '{print $2}')
		forwarding_fork=$(echo -e "${forwarding_text}"| awk '{print $12}'|sed -n "${integer}p"|awk -F "to:" '{print $2}')
		forwarding_list_all=${forwarding_list_all}"${Green_font_prefix}"${integer}".${Font_color_suffix} 类型: ${Green_font_prefix}"${forwarding_type}"${Font_color_suffix} 监听端口: ${Red_font_prefix}"${forwarding_listen}"${Font_color_suffix} 转发IP和端口: ${Red_font_prefix}"${forwarding_fork}"${Font_color_suffix}\n"
	done
	echo && echo -e "当前有 ${Green_background_prefix} "${forwarding_total}" ${Font_color_suffix} 个 iptables 端口转发规则。"
	echo -e ${forwarding_list_all}
}
Del_forwarding(){
	check_iptables
	while true
	do
	View_forwarding
	read -e -p "请输入数字 来选择要删除的 iptables 端口转发规则(默认回车取消):" Del_forwarding_num
	[[ -z "${Del_forwarding_num}" ]] && Del_forwarding_num="0"
	echo $((${Del_forwarding_num}+0)) &>/dev/null
	if [[ $? -eq 0 ]]; then
		if [[ ${Del_forwarding_num} -ge 1 ]] && [[ ${Del_forwarding_num} -le ${forwarding_total} ]]; then
			forwarding_type=$(echo -e "${forwarding_text}"| awk '{print $4}' | sed -n "${Del_forwarding_num}p")
			forwarding_listen=$(echo -e "${forwarding_text}"| awk '{print $11}' | sed -n "${Del_forwarding_num}p" | awk -F "dpt:" '{print $2}' | sed 's/-/:/g')
			[[ -z ${forwarding_listen} ]] && forwarding_listen=$(echo -e "${forwarding_text}"| awk '{print $11}' |sed -n "${Del_forwarding_num}p" | awk -F "dpts:" '{print $2}')
			Del_iptables "${forwarding_type}" "${Del_forwarding_num}"
			Save_iptables
			echo && echo -e "${Info} iptables 端口转发规则删除完成 !" && echo
		else
			echo -e "${Error} 请输入正确的数字 !"
			break
		fi
	else
		break && echo "取消..."
	fi
	done
}
Uninstall_forwarding(){
	check_iptables
	echo -e "确定要清空 iptables 所有端口转发规则 ? [y/N]"
	read -e -p "(默认: n):" unyn
	[[ -z ${unyn} ]] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
		forwarding_text=$(iptables -t nat -vnL PREROUTING|tail -n +3)
		[[ -z ${forwarding_text} ]] && echo -e "${Error} 没有发现 iptables 端口转发规则，请检查 !" && return 1
		forwarding_total=$(echo -e "${forwarding_text}"|wc -l)
		for((integer = 1; integer <= ${forwarding_total}; integer++))
		do
			forwarding_type=$(echo -e "${forwarding_text}"|awk '{print $4}'|sed -n "${integer}p")
			forwarding_listen=$(echo -e "${forwarding_text}"|awk '{print $11}'|sed -n "${integer}p"|awk -F "dpt:" '{print $2}')
			[[ -z ${forwarding_listen} ]] && forwarding_listen=$(echo -e "${forwarding_text}"| awk '{print $11}'|sed -n "${integer}p"|awk -F "dpts:" '{print $2}')
			# echo -e "${forwarding_text} ${forwarding_type} ${forwarding_listen}"
			Del_iptables "${forwarding_type}" "${integer}"
		done
		Save_iptables
		echo && echo -e "${Info} iptables 已清空 所有端口转发规则 !" && echo
	else
		echo && echo "清空已取消..." && echo
	fi
}
Add_iptables(){
	iptables -t nat -A PREROUTING -p "$1" --dport "${local_port}" -j DNAT --to-destination "${forwarding_ip}":"${forwarding_port}"
	iptables -t nat -A POSTROUTING -p "$1" -d "${forwarding_ip}" --dport "${forwarding_port_1}" -j SNAT --to-source "${local_ip}"
	echo "iptables -t nat -A PREROUTING -p $1 --dport ${local_port} -j DNAT --to-destination ${forwarding_ip}:${forwarding_port}"
	echo "iptables -t nat -A POSTROUTING -p $1 -d ${forwarding_ip} --dport ${forwarding_port_1} -j SNAT --to-source ${local_ip}"
	echo "${local_port}"
	iptables -I INPUT -m state --state NEW -m "$1" -p "$1" --dport "${local_port}" -j ACCEPT
}
Del_iptables(){
	iptables -t nat -D POSTROUTING "$2"
	iptables -t nat -D PREROUTING "$2"
	iptables -D INPUT -m state --state NEW -m "$1" -p "$1" --dport "${forwarding_listen}" -j ACCEPT
}
Save_iptables(){
	if [[ ${release} == "centos" ]]; then
		service iptables save
	else
		iptables-save > /etc/iptables.up.rules
	fi
}
Set_iptables(){
	if ! grep -qE "^\s*net\.ipv4\.ip_forward=1" /etc/sysctl.conf; then
		echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
	fi
	sysctl -p
	if [[ ${release} == "centos" ]]; then
		service iptables save
		chkconfig --level 2345 iptables on
	else
		iptables-save > /etc/iptables.up.rules
		echo -e '#!/bin/bash\n/sbin/iptables-restore < /etc/iptables.up.rules' > /etc/network/if-pre-up.d/iptables
		chmod +x /etc/network/if-pre-up.d/iptables
	fi
}
Update_Shell(){
	sh_new_ver=$(wget --no-check-certificate -qO- -t1 -T3 "https://raw.githubusercontent.com/redstarxxx/shell/main/iptables-ie.sh"|grep 'sh_ver="'|awk -F "=" '{print $NF}'|sed 's/\"//g'|head -1)
	[[ -z ${sh_new_ver} ]] && echo -e "${Error} 无法链接到 Github !" && return 0
	wget -N --no-check-certificate "https://raw.githubusercontent.com/redstarxxx/shell/main/iptables-ie.sh" && chmod +x iptables-ie.sh
	echo -e "脚本已更新为最新版本[ ${sh_new_ver} ] !(注意：因为更新方式为直接覆盖当前运行的脚本，所以可能下面会提示一些报错，无视即可)" && return 0
}
check_sys
while true; do
clear_screen
echo && echo -e " iptables 端口转发一键管理脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  -- Toyo | doub.io/wlzy-20 - Revised by TSE --
  
 ${Green_font_prefix}0.${Font_color_suffix} 升级脚本
————————————
 ${Green_font_prefix}1.${Font_color_suffix} 安装 iptables
 ${Green_font_prefix}2.${Font_color_suffix} 清空 iptables 端口转发
————————————
 ${Green_font_prefix}3.${Font_color_suffix} 查看 iptables 端口转发
 ${Green_font_prefix}4.${Font_color_suffix} 添加 iptables 端口转发
 ${Green_font_prefix}5.${Font_color_suffix} 删除 iptables 端口转发
————————————
 ${Green_font_prefix}x.${Font_color_suffix} 退出脚本
————————————
注意：初次使用前请请务必执行 ${Green_font_prefix}1. 安装 iptables${Font_color_suffix}(不仅仅是安装)" && echo
read -e -p " 请输入数字 [0-5]:" num
case "$num" in
	0)
	Update_Shell
	waitfor
	;;
	1)
	install_iptables
	waitfor
	;;
	2)
	Uninstall_forwarding
	waitfor
	;;
	3)
	View_forwarding
	waitfor
	;;
	4)
	Add_forwarding
	waitfor
	;;
	5)
	Del_forwarding
	;;
	x|X)
	exit 0
	;;
	*)
	echo "请输入正确数字 [0-5]"
	;;
esac
done
