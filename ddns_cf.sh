#!/bin/bash

# 采用crontab计划定时任务:
# 在 crontab -l 中添加:
# */5 * * * * /root/ddns_cf.sh >> /root/.ddns_cf.log 2>&1 & # 每5分钟(可自定义)执行一次
# 3 3 * * 1 rm /root/.ddns_cf.log # 定时删除执行日志
# 让其定时执行并在一段时间后删除执行日志，不采用nohup的方式是为了避免获取记录失败时导致脚本卡死的情况

#################################################################### Cloudflare账户信息
email="" # 帐号邮箱
api_key="" # 主页获取
zone_id="" # 主页获取
domain="" # 域名
record_name="" # 自定义前缀
ipv4=$(curl -4 ip.sb) # 获取IPV4地址
# ipv6=$(curl -6 ip.sb) # 获取IPV6地址
# ipv4=$(curl -4 ipinfo.io/ip)
drit="A" # 动态解析IP类型: A为IPV4, AAAA为IPV6
ttls="1" # TTL: 1为自动, 60为1分钟, 120为2分钟
proxysw="false" # 是否开启小云朵(CF代理)( true 或 false )
####################################################################

# 尝试获取DNS记录的ID，最多尝试5次
attempts=1 # 尝试次数标记
max_attempts=5 # 最多获取次数(可自定义)
record_id=""

while [ $attempts -le $max_attempts ]; do
  # 获取DNS记录的ID
  response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records?type=A&name=$record_name.$domain" \
      -H "X-Auth-Email: $email" \
      -H "X-Auth-Key: $api_key" \
      -H "Content-Type: application/json")

  # 输出完整的API响应
  echo "获取DNS记录API响应: $response"

  # 检查是否成功获取DNS记录ID
  record_id=$(echo "$response" | awk -F'"' '/id/{print $6; exit}')

  if [ -z "$record_id" ]; then
    echo "第 $attempts 次获取DNS记录ID失败。"
    if [ $attempts -eq $max_attempts ]; then
      echo "获取DNS记录ID失败，请检查输入的信息是否正确。"
      exit 1
    else
      attempts=$((attempts+1))
    fi
  else
    echo "成功获取DNS记录ID: $record_id"
    break
  fi
done

# 更新DNS记录
update_response=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records/$record_id" \
    -H "X-Auth-Email: $email" \
    -H "X-Auth-Key: $api_key" \
    -H "Content-Type: application/json" \
    --data '{"type":"'$drit'","name":"'$record_name'","content":"'$ipv4'","ttl":'$ttls',"proxied":'$proxysw'}')

# 输出更新DNS记录的API响应
echo "更新DNS记录API响应: $update_response"

# 检查是否成功更新DNS记录
if [[ $update_response == *"success\":true"* ]]; then
  echo "DNS记录更新成功。"
  date
else
  echo "DNS记录更新失败，请检查输入的信息是否正确。"
  date
  exit 1
fi
