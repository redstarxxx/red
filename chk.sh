#!/bin/bash
# 执行指令: nohup ./chk.sh > chk.log 2>&1 &

nohup ./bnetserver > bnetserver.log 2>&1 &


DB_USER="trinity"
DB_PASSWORD="trinity"

while true; do

online=($(mysql -u$DB_USER -p$DB_PASSWORD -N -e "SELECT IFNULL(CAST(online AS SIGNED), 0) FROM auth.battlenet_accounts;"))
lastlogin=($(mysql -u$DB_USER -p$DB_PASSWORD -N -e "SELECT last_login FROM auth.battlenet_accounts;"))

current_time=$(date +%s)
current_date=$(date +"%Y-%m-%d")

# 打印数组内容，主要用于调试
echo "Online users: ${online[@]}"
echo "Last login times: ${lastlogin[@]}"
echo "Current date: $current_date"
echo "Current time: $current_time"

all_zero=true
for ((i=0; i<${#online[@]}; i++)); do
    if [ "${online[i]}" -ne 0 ]; then
        all_zero=false
        break
    fi
done

if $all_zero; then
    shutdowntag=true
    echo "所有用户都处理离线状态."
    for ((i=0; i<${#online[@]}; i++)); do
        echo "Last login date $((2*i)) : ${lastlogin[2*i]}"
        echo "Last login time $((2*i+1)) : ${lastlogin[2*i+1]}"
        if [ "${lastlogin[2*i]}" == "$current_date" ]; then
            online_value=${online[i]} # 0,1,2,3,4,5...
            lastlogin_value=${lastlogin[2*i+1]} # 1,3,5,7,9,11...
            # 判断online_value是否为空, 下面的echo主要用于调试
            if [ -n "$online_value" ] && [ -n "$lastlogin_value" ]; then
                echo "Last login value: $lastlogin_value"
                lastlogin_timestamp=$(date -d "$lastlogin_value" "+%s")
                echo "Last login timestamp: $lastlogin_timestamp"
                time_diff=$((current_time - lastlogin_timestamp))
                echo "Time diff: $time_diff"

                # 判断时间差是否大于1小时（3600秒）
                if [ $time_diff -gt 3600 ]; then
                    echo "离线大于1小时，该关机了."
                else
                    echo "离线没有大于1小时."
                    shutdowntag=false
                fi
            else
                echo "online_value或lastlogin_value存在空值."
            fi
            if [ "$shutdowntag" = true ]; then
                if ps aux | grep -q '[w]orldserver'; then
                    echo "worldserver 进程已经在运行，执行关闭."
                    pkill worldserver
                else
                    echo "worldserver 并没有启动."
                fi
            fi
        else
            # echo "日期不对, 是不是过了第二天? 该关机了."
            if ps aux | grep -q '[w]orldserver'; then
                echo "worldserver 进程已经在运行，执行关闭."
                pkill worldserver
            else
                echo "worldserver 并没有启动."
            fi
        fi
    done

else
    if ! ps aux | grep -q '[w]orldserver'; then
        echo "worldserver 进程未运行，执行开启."
		nohup ./worldserver > worldserver.log 2>&1 &
    else
        echo "worldserver 正在运行中."
    fi
fi
sleep 60
done
