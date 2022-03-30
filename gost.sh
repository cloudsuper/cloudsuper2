#! /bin/bash
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"
gost_conf_path="/etc/xiandan/gost/config.json"
raw_conf_path="/etc/xiandan/gost/rawconf"
function checknew(){
    checknew=$(gost -V 2>&1|awk '{print $2}')
    check_new_ver
    echo "你的gost版本为:"$checknew""
    `cp -r /etc/xiandan/gost /tmp/`
    Install_ct
    `rm -rf /etc/xiandan/gost`
    `mv /tmp/gost /etc/xiandan`
}
function check_sys()
{
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
    bit=$(uname -m)
        if test "$bit" != "x86_64"; then
            bit="armv8"
        else bit="amd64"
    fi
}
function Installation_dependency()
{
    gzip_ver=$(gzip -V)
    if [[ -z ${gzip_ver} ]]; then
        if [[ ${release} == "centos" ]]; then
            yum update
            yum install -y gzip
            yum -y install lsof
        else
            apt-get update
            apt-get install -y gzip
            apt-get install -y lsof
        fi
    fi
}
function check_root()
{
    [[ $EUID != 0 ]] && echo -e "${Error} 当前非ROOT账号(或没有ROOT权限)，无法继续操作，请更换ROOT账号或使用 ${Green_background_prefix}sudo su${Font_color_suffix} 命令获取临时ROOT权限（执行后可能会提示输入当前账号的密码）。" && exit 1
}
function check_new_ver()
{
    ct_new_ver=$(wget --no-check-certificate -qO- -t2 -T3 https://api.github.com/repos/ginuerzh/gost/releases/latest| grep "tag_name"| head -n 1| awk -F ":" '{print $2}'| sed 's/\"//g;s/,//g;s/ //g;s/v//g')
    if [[ -z ${ct_new_ver} ]]; then
        ct_new_ver="2.11.1"
        echo -e "${Error} gost 最新版本获取失败，正在下载v${ct_new_ver}版"
    else
        echo -e "${Info} gost 目前最新版本为 ${ct_new_ver}"
    fi
}
function check_file()
{
    if [ -f /etc/xiandan/gost ];then
        `chmod -R 777 /etc/xiandan/gost`
    fi
}
function check_nor_file()
{
    `rm -rf "$(pwd)"/gost`
    `rm -rf "$(pwd)"/gost.service`
    `rm -rf "$(pwd)"/config.json`
    `rm -rf /etc/xiandan/gost`
}
function Install_ct()
{
    check_root
    check_nor_file
    Installation_dependency
    check_file
    check_sys
    check_new_ver
    `rm -rf gost-linux-"$bit"-"$ct_new_ver".gz`
    `wget --no-check-certificate https://sh.xdmb.xyz/xiandan/gost/gost-linux-"$bit"-"$ct_new_ver".gz`
    `gunzip gost-linux-"$bit"-"$ct_new_ver".gz`
    `mv gost-linux-"$bit"-"$ct_new_ver" gost`
     if [ ! -d "/etc/xiandan" ]; then
	  mkdir /etc/xiandan
	fi
     if [ ! -d "/etc/xiandan/gost" ]; then
	  mkdir /etc/xiandan/gost
	fi
    `cp gost /etc/xiandan/gost/gost`
    `chmod -R 777 /etc/xiandan/gost/gost`
    `mv gost /usr/bin/gost`
    `chmod -R 777 /usr/bin/gost`
    `wget --no-check-certificate https://sh.xdmb.xyz/xiandan/gost.service && chmod -R 777 gost.service && mv gost.service /usr/lib/systemd/system`
}
function Uninstall_ct()
{
    `rm -rf /etc/xiandan/gost`
    `rm -rf /usr/lib/systemd/system/gost.service`
    `rm -rf /usr/bin/gost`
    echo "gost已经成功删除"
}

function startGostService() {
    # if [ $6 == "true" ] && [ $5 == "true" ];then
    #     getCert $4
    # fi
    
    if [ ! -f /etc/xiandan/flowRule.sh ];then
        wget -P /etc/xiandan -N --no-check-certificate "https://sh.xdmb.xyz/xiandan/flowRule.sh"
        chmod +x /etc/xiandan/flowRule.sh
    fi
    service xiandan${2}xiandan stop
    rm -f /etc/systemd/system/xiandan${2}xiandan.service
    echo "
[Unit]
Description=xiandan${2}xiandan
After=network.target
Wants=network.target

[Service]
Type=simple
StandardError=journal
User=root
#ExecStart=
ExecReload=/bin/kill -HUP $MAINPID
ExecStop=/bin/kill $MAINPID
Restart=always

[Install]
WantedBy=multi-user.target
    " >> /etc/systemd/system/xiandan${2}xiandan.service
	if [ ${5} == "false" ];then
		if [ $1 == "none" ]; then
			sed -i "/#ExecStart/c\ExecStart=/etc/xiandan/gost/gost -L tcp://:${2}/${4}:${3} -L udp://:${2}/${4}:${3}" /etc/systemd/system/xiandan${2}xiandan.service
		elif [ $1 == "tls" ]; then
		    if [ $6 == "true" ];then
	    		sed -i "/#ExecStart/c\ExecStart=/etc/xiandan/gost/gost -L tcp://:${2} -L udp://:${2} -F relay+tls://${4}:${3}?secure=true" /etc/systemd/system/xiandan${2}xiandan.service
    		else
    		    sed -i "/#ExecStart/c\ExecStart=/etc/xiandan/gost/gost -L tcp://:${2} -L udp://:${2} -F relay+tls://${4}:${3}" /etc/systemd/system/xiandan${2}xiandan.service
		    fi
		elif [ $1 == "ws" ]; then
	    		sed -i "/#ExecStart/c\ExecStart=/etc/xiandan/gost/gost -L tcp://:${2} -L udp://:${2} -F relay+ws://${4}:${3}" /etc/systemd/system/xiandan${2}xiandan.service
		elif [ $1 == "wss" ]; then
		    if [ $6 == "true" ];then
	    		sed -i "/#ExecStart/c\ExecStart=/etc/xiandan/gost/gost -L tcp://:${2} -L udp://:${2} -F relay+wss://${4}:${3}?secure=true" /etc/systemd/system/xiandan${2}xiandan.service
    		else
    		    sed -i "/#ExecStart/c\ExecStart=/etc/xiandan/gost/gost -L tcp://:${2} -L udp://:${2} -F relay+wss://${4}:${3}" /etc/systemd/system/xiandan${2}xiandan.service
		    fi
		fi
		sed -i '/flowRule.sh/d' /etc/systemd/system/xiandan${2}xiandan.service
	else
		if [ $1 == "none" ]; then
			sed -i "/#ExecStart/c\ExecStart=/etc/xiandan/gost/gost -L tcp://:${2}/${4}:${3} -L udp://:${2}/${4}:${3}" /etc/systemd/system/xiandan${2}xiandan.service
		elif [ $1 == "tls" ]; then
		    if [ $6 == "true" ];then
        		sed -i "/#ExecStart/c\ExecStart=/etc/xiandan/gost/gost -L relay+tls://:${2}/${4}:${3}?cert=/etc/xiandan/gost/${2}/cert.pem&key=/etc/xiandan/gost/${2}/key.pem" /etc/systemd/system/xiandan${2}xiandan.service
        		mkdir /etc/xiandan/gost/${2}
    		else
    		    sed -i "/#ExecStart/c\ExecStart=/etc/xiandan/gost/gost -L relay+tls://:${2}/${4}:${3}" /etc/systemd/system/xiandan${2}xiandan.service
		    fi
		elif [ $1 == "ws" ]; then
    		sed -i "/#ExecStart/c\ExecStart=/etc/xiandan/gost/gost -L relay+ws://:${2}/${4}:${3}" /etc/systemd/system/xiandan${2}xiandan.service
		elif [ $1 == "wss" ]; then
		    if [ $6 == "true" ];then
        		sed -i "/#ExecStart/c\ExecStart=/etc/xiandan/gost/gost -L relay+wss://:${2}/${4}:${3}?cert=/etc/xiandan/gost/${2}/cert.pem&key=/etc/xiandan/gost/${2}/key.pem" /etc/systemd/system/xiandan${2}xiandan.service
        		mkdir /etc/xiandan/gost/${2}
    		else
    		    sed -i "/#ExecStart/c\ExecStart=/etc/xiandan/gost/gost -L relay+wss://:${2}/${4}:${3}" /etc/systemd/system/xiandan${2}xiandan.service
		    fi
		fi
		sed -i '/flowRule.sh/d' /etc/systemd/system/xiandan${2}xiandan.service
	fi
	systemctl daemon-reload
	service xiandan${2}xiandan start
	if [ $isAutoStart == "Y" ] || [ $isAutoStart == "y" ];then
		echo "已设置开机自启动！"
 		systemctl enable xiandan${2}xiandan
	fi
	echo '指令发送成功！服务运行状态如下'
	echo ' '
	systemctl status xiandan${2}xiandan --no-pager
	exit 1
}
function stopGostService(){
	service xiandan${1}xiandan stop
	systemctl disable xiandan${1}xiandan
	rm -f /etc/systemd/system/xiandan${1}xiandan.service
	systemctl daemon-reload
}
function read_port() {
	echo -e "请输入代理端口（ssr、ss、socks5等）"
	read -p "请输入: " port
	if [[ ! -n $port ]];then
		port=80
	fi
	if [ "$port" -gt 0 ] 2>/dev/null;then
		if [[ $port -lt 0 || $port -gt 65535 ]];then
		 echo -e "端口号不正确"
		 read_port
		 exit 0
		fi
		echo -e "是否开机自启动？"
		read -p "请输入：Y 是 N 否" isAutoStart
		if [[ ! -n $isAutoStart ]];then
			isAutoStart="Y"
		fi
		if [ ! -x "/etc/xiandan/gost/gost" ];then
            Install_ct
            mkdir /etc/xiandan/gost/$localPort/
        fi
		if [ $secure == "true" ];then
            testCert    		    
        else 
            startGostService $protocol $localPort $port $remoteHost "true" $secure
		fi
	else
 		read_port
 		exit 0
	fi
}

function testCert() {
    certExit=`ls -l /etc/xiandan/gost/$localPort |grep pem |wc -l`
    if [ ! $certExit == 2 ];then
        echo "此转发采用了自定义tls证书，需要处理证书"
        echo "请将${localHost}域名证书cert.pem、key.pem文件放置于/etc/xiandan/gost/${localPort}/ 目录下,然后再次运行脚本"
        exit 0
    fi
    startGostService $protocol $localPort $port $remoteHost "true" $secure
}

function getCert(){
    check_sys
    if [[ ${release} == "centos" ]]; then
        cmd="yum"
    else
        cmd="apt-get"
    fi
    if [ ! -f /etc/xiandan/gost/${1}_cert.pem ] || [ ! -f /etc/xiandan/gost/${1}_key.pem ];then
        echo "证书文件不存在,申请证书文件!"
        echo $cmd
        if ! type socat >/dev/null 2>&1; then
            echo '未安装socat，安装之...'
            `${cmd} install -y socat`
        fi
        if ! type curl >/dev/null 2>&1; then
            echo '未安装curl，安装之...'
            `${cmd} install -y curl`
        fi
        curl https://get.acme.sh | sh
        echo -e "acme 安装成功！"
        if /root/.acme.sh/acme.sh --issue -d "${1}" --standalone -k ec-256 --force; then
          if [ ! -d "/etc/xiandan/gost" ]; then
            mkdir /etc/xiandan/gost
          fi
          if /root/.acme.sh/acme.sh --installcert -d "${1}" --fullchainpath /etc/xiandan/gost/${4}_cert.pem --keypath /etc/xiandan/gost/${1}_key.pem --ecc --force; then
            echo -e "SSL 证书配置成功，且会自动续签!"
          fi
        else
          echo -e "SSL 证书生成失败"
          exit 1
        fi
    fi
}
function read_remote_host() {
    echo -e "请输入代理节点地址"
	read -p "请输入ip或者域名（默认127.0.0.1）: " remoteHost
	if [[ ! -n $remoteHost ]];then
		remoteHost='127.0.0.1'
	fi
}
if [ $# -gt 0 ] ; then
  if [ "$1" == "install" ]; then
    Install_ct
  elif [ "$1" == "update" ]; then
    checknew
  elif [ "$1" == "uninstall" ]; then
    Uninstall_ct
  elif [ "$1" == "start" ]; then
    if [ "${6}x" == "x" ];then
        secure="false"
    else
        secure=$6
    fi
    startGostService $2 $3 $4 $5 $secure $7
  elif [ "$1" == "stop" ]; then
    stopGostService $2
  elif [ "$1" == "decrypt" ]; then
    echo $1
    protocol=$2
    localPort=$3
    localHost=$5
    secure=$4
    read_remote_host
    read_port
  fi
fi