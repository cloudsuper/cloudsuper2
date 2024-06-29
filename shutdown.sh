#!/bin/bash
# 网卡名称
interface_name="ens5"
# 流量阈值上限
traffic_limit=950
#更新网卡记录
vnstat -i "$interface_name"
#获取每月用量 $11:进站+出站;$10是:出站;$9是:进站              
ax=`vnstat --oneline | awk -F ";" '{print $11}'`
#如果每月用量单位是GB则进入
if [[ "$ax" == *GB* ]]; then
  #每月实际流量数除以流量阈值，大于或等于1，则执行关机命令
    if [ $(echo "$(echo "$ax" | sed 's/ GB//g') / $traffic_limit"|bc) -ge 1 ]; then
      sudo /usr/sbin/shutdown -h now
    fi
fi
