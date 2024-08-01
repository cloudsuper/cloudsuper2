#!/bin/sh

MAINIP=$(ip route get 1 | awk '{print $NF;exit}')
GATEWAYIP=$(ip route | grep default | awk '{print $3}')
SUBNET=$(ip -o -f inet addr show | awk '/scope global/{sub(/[^.]+\//,"0/",$4);print $4}' | head -1 | awk -F '/' '{print $2}')

value=$(( 0xffffffff ^ ((1 << (32 - $SUBNET)) - 1) ))
NETMASK="$(( (value >> 24) & 0xff )).$(( (value >> 16) & 0xff )).$(( (value >> 8) & 0xff )).$(( value & 0xff ))"

wget --no-check-certificate -qO Network-Reinstall-System.sh 'https://yangwenqing.com/files/Source/Onelist-Reinstall-System-Modify.sh' && chmod a+x Network-Reinstall-System.sh


clear
echo "                                                           "
echo "###########################################################"
echo "#                                                         #"
echo "#  Auto network Reinstall System                          #"
echo "#                                                         #"
echo "#  Last Modified: 2023-06-03                              #"
echo "#  Linux默认密码：MoeClub.org/cxthhhhh.com                #"
echo "#  Supported by MoeClub                                   #"
echo "#                                                         #"
echo "###########################################################"
echo "                                                           "
echo "IP: $MAINIP"
echo "网关: $GATEWAYIP"
echo "网络掩码: $NETMASK"
echo ""
echo "请选择您需要的镜像包:"
echo "  1) CentOS 8 x64 用户名：root 密码：cxthhhhh.com"
echo "  2) CentOS 7 x64 用户名：root 密码：cxthhhhh.com"
echo "  3) CentOS 6 x64 用户名：root 密码：MoeClub.org"
echo "  4) Debian 11 x64 用户名：root 密码：MoeClub.org"
echo "  5) Debian 10 x64 用户名：root 密码：MoeClub.org"
echo "  6) Debian 9 x64 用户名：root 密码：MoeClub.org"
echo "  7) Debian 8 x64 用户名：root 密码：MoeClub.org"
echo "  8) Ubuntu 20.04 x64 用户名：root 密码：MoeClub.org"
echo "  9) Ubuntu 18.04 x64 用户名：root 密码：MoeClub.org"
echo "  10) Ubuntu 16.04 x64 用户名：root 密码：MoeClub.org"
echo "  11) Ubuntu 14.04 x64 用户名：root 密码：MoeClub.org"
echo "  12) Windows10_ltsc_21h2 x64 用户名：Administrator 密码：tg@wanglong6"
echo "  13) Windows10_pro_22h2 x64 用户名：Administrator 密码：tg@wanglong6"
echo "  14) Windows10 x64 用户名：Administrator 密码：cxthhhhh.com"
echo "  15) Windows8 x64 用户名：Administrator 密码：Vicer"
echo "  16) Windows7 Vienna 用户名：Administrator 密码：cxthhhhh.com"
echo "  17) Windows7 x32 用户名：Administrator 密码：Vicer"
echo "  18) Windows Server 2019 用户名：Administrator  密码：cxthhhhh.com"
echo "  19) Windows Server 2016 用户名：Administrator  密码：cxthhhhh.com"
echo "  20) Windows Server 2012 R2 用户名：Administrator  密码：cxthhhhh.com"
echo "  21) Windows Server 2008 R2 用户名：Administrator  密码：cxthhhhh.com"
echo "  22) Windows Server 2003 用户名：Administrator  密码：cxthhhhh.com"
echo "  自定义安装请使用：bash Network-Reinstall-System.sh -DD '镜像地址'"
echo ""
echo -n "请输入编号: "
read N
case $N in
  1) bash Network-Reinstall-System.sh -CentOS_8 ;;
  2) bash Network-Reinstall-System.sh -CentOS_7 ;;
  3) bash Network-Reinstall-System.sh -CentOS_6 ;;
  4) bash Network-Reinstall-System.sh -Debian_11 ;;
  5) bash Network-Reinstall-System.sh -Debian_10 ;;
  6) bash Network-Reinstall-System.sh -Debian_9 ;;
  7) bash Network-Reinstall-System.sh -Debian_8 ;;
  8) bash Network-Reinstall-System.sh -Ubuntu_2004 ;;
  9) bash Network-Reinstall-System.sh -Ubuntu_1804 ;;
  10) bash Network-Reinstall-System.sh -Ubuntu_1604 ;;
  11) bash Network-Reinstall-System.sh -Ubuntu_1404 ;;
  12) bash Network-Reinstall-System.sh -Windows_10_ltsc_21h2 ;;
  13) bash Network-Reinstall-System.sh -Windows_10_pro_22h2 ;;
  14) bash Network-Reinstall-System.sh -Windows_10_x64 ;;
  15) bash Network-Reinstall-System.sh -Windows_8_x64 ;;
  16) bash Network-Reinstall-System.sh -Windows_7_Vienna ;;
  17) bash Network-Reinstall-System.sh -Windows_7_x32 ;;
  18) bash Network-Reinstall-System.sh -Windows_Server_2019 ;;
  19) bash Network-Reinstall-System.sh -Windows_Server_2016 ;;
  20) bash Network-Reinstall-System.sh -Windows_Server_2012R2 ;;
  21) bash Network-Reinstall-System.sh -Windows_Server_2008R2 ;;
  22) bash Network-Reinstall-System.sh -Windows_Server_2003 ;;
  23) bash Network-Reinstall-System.sh -DD ;;
  *) echo "Wrong input!" ;;
esac
