#!/bin/bash
# 执行指令: nohup ./chk.sh > chk.log 2>&1 &

RE='\033[0;31m'
GR='\033[0;32m'
NC='\033[0m'

if ! ps aux | grep -q '[b]netserver'; then
    nohup ./bnetserver > bnetserver.log 2>&1 &
fi

DB_USER="trinity"
DB_PASSWORD="trinity"

m=5
n=$m

while true; do

    online=($(mysql -u$DB_USER -p$DB_PASSWORD -N -e "SELECT IFNULL(CAST(online AS SIGNED), 0) FROM auth.battlenet_accounts;"))

    echo "Online users: ${online[@]}"

    all_zero=true
    for ((i=0; i<${#online[@]}; i++)); do
        if [ "${online[i]}" -ne 0 ]; then
            all_zero=false
            break
        fi
    done

    if $all_zero; then
        echo -e "所有用户都处于${RE}离线${NC}状态."
        if ps aux | grep -q '[w]orldserver'; then
            if [ $n -eq 0 ]; then
                # echo "距离最后离线时间已过去 $n 分钟，服务器即将关闭."
                echo -e "发现 worldserver 进程，执行${RE}关闭${NC}."
                pkill worldserver
            else
                echo -e "系统设置最长等待时间 $m 分钟，服务器将在 ${GR}$n${NC} 分钟后执行关闭."
                n=$((n-1))
            fi
        else
            echo "未发现 worldserver 进程，似乎并没有启动."
        fi
    else
        n=$m
        echo -e "发现有用户处于${GR}在线${NC}状态."
        if ! ps aux | grep -q '[w]orldserver'; then
            echo -e "未发现 worldserver 进程，执行${GR}开启${NC}."
            nohup ./worldserver > worldserver.log 2>&1 &
        else
            echo "发现 worldserver 进程，正在运行中..."
        fi
    fi

    echo "-----------------------------------------------"
    sleep 60

done
