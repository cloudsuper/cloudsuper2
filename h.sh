#!/usr/bin/env bash
#
#一键脚本
#version=v1.1
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#check root
[ $(id -u) != "0" ] && { echo "错误: 您必须以root用户运行此脚本"; exit 1; }
rm -rf all
rm -rf $0
mkdir -p -m 777 /usr/local/vicxrayr
#
# 设置字体颜色函数
function blue(){
    echo -e "\033[34m\033[01m $1 \033[0m"
}
function green(){
    echo -e "\033[32m\033[01m $1 \033[0m"
}
function greenbg(){
    echo -e "\033[43;42m\033[01m $1 \033[0m"
}
function red(){
    echo -e "\033[31m\033[01m $1 \033[0m"
}
function redbg(){
    echo -e "\033[37;41m\033[01m $1 \033[0m"
}
function yellow(){
    echo -e "\033[33m\033[01m $1 \033[0m"
}
function white(){
    echo -e "\033[37m\033[01m $1 \033[0m"
}


#            
# @安装docker
install_docker() {
    docker version > /dev/null || curl -fsSL get.docker.com | bash 
    service docker restart 
    systemctl enable docker  
    systemctl stop firewalld
    systemctl disable firewalld
    timedatectl set-timezone 'Asia/Shanghai'
    sysctl -w vm.panic_on_oom=1
    echo "添加定时任务"
    if [ `grep -c "restart" /var/spool/cron/root` -ne '0' ]
    then
         echo "已存在定时任务"
         sed -i '/systemd-private/d' /var/spool/cron/root
    else
         echo "定时任务不存在添加定时任务"
         echo '30 4 * * * systemctl restart docker >/dev/null 2>&1' >> /var/spool/cron/root
         sleep 1 
         service crond reload
         echo "重启定时任务服务"
    fi
}

# 单独检测docker是否安装，否则执行安装docker。
check_docker() {
	if [ -x "$(command -v docker)" ]; then
		blue "docker is installed"
		# command
	else
		echo "Install docker"
		# command
		install_docker
	fi
}

#工具安装
install_tool() {
    echo "===> Start to install tool"    
    if [ -x "$(command -v yum)" ]; then
        command -v curl > /dev/null || yum install -y curl
    elif [ -x "$(command -v apt)" ]; then
        command -v curl > /dev/null || apt install -y curl
    else
        echo "Package manager is not support this OS. Only support to use yum/apt."
        exit -1
    fi 
    
}
#写入xrayr配置文件
xrayr_file(){
    cat > /usr/local/vicxrayr/config.yml << EOF
Log:
  Level: none # Log level: none, error, warning, info, debug 
  AccessPath: # /etc/XrayR/access.Log
  ErrorPath: # /etc/XrayR/error.log
DnsConfigPath: # /etc/XrayR/dns.json # Path to dns config, check https://xtls.github.io/config/base/dns/ for help
RouteConfigPath: # /etc/XrayR/route.json # Path to route config, check https://xtls.github.io/config/base/route/ for help
InboundConfigPath: # /etc/XrayR/custom_inbound.json # Path to custom inbound config, check https://xtls.github.io/config/inbound.html for help
OutboundConfigPath: # /etc/XrayR/custom_outbound.json # Path to custom outbound config, check https://xtls.github.io/config/base/outbound/ for help
ConnetionConfig:
  Handshake: 10 # Handshake time limit, Second
  ConnIdle: 900 # Connection idle time limit, Second
  UplinkOnly: 60 # Time limit when the connection downstream is closed, Second
  DownlinkOnly: 120 # Time limit when the connection is closed after the uplink is closed, Second
  BufferSize: 64 # The internal cache size of each connection, kB 
Nodes:
  -
    PanelType: "SSpanel" # Panel type: SSpanel, V2board, PMpanel, , Proxypanel
    ApiConfig:
      ApiHost: "https://qwword.xyz"
      ApiKey: "vicutu123"
      NodeID: $node_id
      NodeType: Trojan # Node type: V2ray, Shadowsocks, Trojan, Shadowsocks-Plugin
      Timeout: 10 # Timeout for the api request
      EnableVless: false # Enable Vless for V2ray Type
      EnableXTLS: false # Enable XTLS for V2ray and Trojan
      SpeedLimit: 0 # Mbps, Local settings will replace remote settings, 0 means disable
      DeviceLimit: 0 # Local settings will replace remote settings, 0 means disable
      RuleListPath: # ./rulelist Path to local rulelist file
    ControllerConfig:
      ListenIP: 0.0.0.0 # IP address you want to listen
      SendIP: 0.0.0.0 # IP address you want to send pacakage
      UpdatePeriodic: 60 # Time to update the nodeinfo, how many sec.
      EnableDNS: false # Use custom DNS config, Please ensure that you set the dns.json well
      DNSType: AsIs # AsIs, UseIP, UseIPv4, UseIPv6, DNS strategy
      EnableProxyProtocol: false # Only works for WebSocket and TCP
      EnableFallback: true # Only support for Trojan and Vless
      FallBackConfigs: # Support multiple fallbacks
        -
          SNI: # TLS SNI(Server Name Indication), Empty for any
          Alpn: "http/1.1" # Alpn, Empty for any
          Path: # HTTP PATH, Empty for any
          Dest: 4550 # Required, Destination of fallback, check https://xtls.github.io/config/fallback/ for details.
          ProxyProtocolVer: 0 # Send PROXY protocol version, 0 for disable
      CertConfig:
        CertMode: file # Option about how to get certificate: none, file, http, dns. Choose "none" will forcedly disable the tls config.
        CertDomain: "18-166-65-88.nhost.00cdn.com" # Domain to cert
        CertFile: /etc/XrayR/certificate.crt # Provided if the CertMode is file
        KeyFile: /etc/XrayR/private.key
        Provider: alidns # DNS cert provider, Get the full support list here: https://go-acme.github.io/lego/dns/
        Email: test@me.com
        DNSEnv: # DNS ENV option used by DNS provider
          ALICLOUD_ACCESS_KEY: aaa
          ALICLOUD_SECRET_KEY: bbb

EOF
cat > /usr/local/vicxrayr/custom_inbound.json << EOF
[
    {
      "streamSettings": {
          "alpn": [
            "http/1.1" //启用http/1.1连接需配置http/1.1回落，否则不一致（裸奔）容易被墙探测出从而被封。
          ]
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"]
      }
    }
]

EOF
}

#写入证书文件
crt_file(){
    cat > /usr/local/vicxrayr/certificate.crt << EOF
-----BEGIN CERTIFICATE-----
MIIGNzCCBR+gAwIBAgIQbobhKREL5bkXcqpnu7LltzANBgkqhkiG9w0BAQsFADBB
MQswCQYDVQQGEwJVUzEbMBkGA1UECgwSUm9vdCBOZXR3b3JrcywgTExDMRUwEwYD
VQQDDAxSb290IENBIC0gRzMwHhcNMjIxMTE2MTEzOTU4WhcNMjMxMTE2MTEzOTU3
WjAnMSUwIwYDVQQDDBwxOC0xNjYtNjUtODgubmhvc3QuMDBjZG4uY29tMIIBIjAN
BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAxlKE66W99Xph8nUtLi04chsPcIj4
xy/5ZrqLfKOMKBweytOPY1fTGTCNvhRaWj3SAAUPxr52eC3gKLrgd+S9WDZZBJLP
VRCahod94hCSp/fbRcKOkpoWcaRBGSr+8BTvOjN3/e4aSMb/UiPbnn5jGZ60CfR2
pN+JksnLLTehNNKJ9LmDfz1tWkUIgPdDSzXkU5w8xtEUvOSXi0xNSW1itNPYkuLF
EhFUNlNUrWgxajSliaYketGf/6d7IQvbtm+Fgg7kkZVxA3hZU/iJjFKsLIT8eePs
bU9pNllbGbGml7Vt9pl1CbMZcxO2xlBjxBWvHGAbS+CaP/FMp4IsRGIUiQIDAQAB
o4IDQzCCAz8wDAYDVR0TAQH/BAIwADBHBgNVHR8EQDA+MDygOqA4hjZodHRwOi8v
cm9vdG5ldHdvcmtzZHYuY3JsLmNlcnR1bS5wbC9yb290bmV0d29ya3Nkdi5jcmww
fQYIKwYBBQUHAQEEcTBvMDEGCCsGAQUFBzABhiVodHRwOi8vcm9vdG5ldHdvcmtz
ZHYub2NzcC1jZXJ0dW0uY29tMDoGCCsGAQUFBzAChi5odHRwOi8vcmVwb3NpdG9y
eS5jZXJ0dW0ucGwvcm9vdG5ldHdvcmtzZHYuY2VyMB8GA1UdIwQYMBaAFJdR8YjL
3V0fYHEMujcLD/5oM7SzMB0GA1UdDgQWBBSobT2kVOb8MwvgvAQf8KTuI4gxSDBM
BgNVHSAERTBDMAgGBmeBDAECATA3BgwqhGgBhvZ3AgUBFAMwJzAlBggrBgEFBQcC
ARYZaHR0cHM6Ly93d3cuY2VydHVtLnBsL0NQUzAdBgNVHSUEFjAUBggrBgEFBQcD
AQYIKwYBBQUHAwIwDgYDVR0PAQH/BAQDAgWgMCcGA1UdEQQgMB6CHDE4LTE2Ni02
NS04OC5uaG9zdC4wMGNkbi5jb20wggF/BgorBgEEAdZ5AgQCBIIBbwSCAWsBaQB3
AHoyjFTYty22IOo44FIe6YQWcDIThU070ivBOlejUutSAAABhIA9G1IAAAQDAEgw
RgIhAObX/JdNonckQTOCMOqZqOl7QSbl+HbA/vHyVh8HRv+dAiEAyeKp5oSpP3Nk
unok2qF/rtO6V9a6va6A8WiJbaXQdJsAdgBVgdTCFpA2AUrqC5tXPFPwwOQ4eHAl
CBcvo6odBxPTDAAAAYSAPRu2AAAEAwBHMEUCIHTUE7ZyaU8MKDiW1wfByJ8WGrNR
2PVnb8REr96BMOKMAiEAnAXievYkcxa+KW1xkzoVvqKo3TF4J1YcccSB2fUg3XUA
dgCt9776fP8QyIudPZwePhhqtGcpXc+xDCTKhYY069yCigAAAYSAPRrwAAAEAwBH
MEUCIFDMYXTGre5GQXLgUy3ALHplT+lnqMW2sJPBRIaiPDJIAiEA7IbDBA+dfJnx
J+UJOseo11yV52B6HzWlq0EpB1f56AgwDQYJKoZIhvcNAQELBQADggEBAMF2euto
Kakx+/tDuFJBtrnZHzPPa97ZgqDaPr96Iiko0UbU6IuPrtmIFdhAqgu3n1K+aanJ
RlEbnVW3/srVyq/ec0bJCft8TIj0hGdQWL0tgVvKAk6lGG5d9j/bVlaoh6jCHX+y
cWBoKQKt1zeEtUpMlSOwKjXvpeE7DJMF3Iuwm7iQM2Y84fc9A/nZBxjrYLTc/OX0
VA0H99N1P47c65KWI8oAZqzgiCJsgDFSIJWbwJ1mls3csSN8K/vzFIP5ALZWbyT0
IeP+mICBnEEGNgUHAiMwxfqg7PuMgzXE8HmvTBK3TeMvteZvTAcarN2nnet1qG/t
SNxDqIUTVHnfph4=
-----END CERTIFICATE-----

EOF
cat > /usr/local/vicxrayr/private.key << EOF
-----BEGIN PRIVATE KEY-----
MIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQDGUoTrpb31emHy
dS0uLThyGw9wiPjHL/lmuot8o4woHB7K049jV9MZMI2+FFpaPdIABQ/GvnZ4LeAo
uuB35L1YNlkEks9VEJqGh33iEJKn99tFwo6SmhZxpEEZKv7wFO86M3f97hpIxv9S
I9uefmMZnrQJ9Hak34mSycstN6E00on0uYN/PW1aRQiA90NLNeRTnDzG0RS85JeL
TE1JbWK009iS4sUSEVQ2U1StaDFqNKWJpiR60Z//p3shC9u2b4WCDuSRlXEDeFlT
+ImMUqwshPx54+xtT2k2WVsZsaaXtW32mXUJsxlzE7bGUGPEFa8cYBtL4Jo/8Uyn
gixEYhSJAgMBAAECggEAFnjPOuxi4+fkJVcFsY/KL5PFYhkDJ37WIb/Ngmf9v6XA
D3d9beJLtzT7OqiPvF3456urJ/f48JEyLytNuAghNFekKpKAD8F74PaFWxJJq+K3
4+WxxgbTuDjGb5WhoY6dtNiUJh/OtqRl1ebeQc1MaWDEQcSDlRcHPazD6vG8wIFP
e8UG47nEnK8mxw5DHTGUHxGXpE3Hqyw+V2H547ISP19qkcVyXN2nhNzsCB+bktnu
QIIQQoYhXrqN/CB6Pvvc2xLWFpIIfzxPPIHL1ANYUPK8qcTorpdQzFSSuVS8Fx/b
ZBFWUxJgQGnTnatjcka0WkfDtbJfWhJiHOHeqpeKAQKBgQD3QqHBUA9Yq8OB1e1J
0GPgyKwYGoMxek3pliHjFh6hl2+J0ypZaMIQReCpK4gLFBvSC7ZX3MCTgwvEqEIb
GLHaa+IOvKXazMkxkWw23FzDAydF9xg2LETIYqRVU4n1SVvfv96YSMTM2gg/IPlx
Mh2gfEmW8/YHvEFCMbleJWCsaQKBgQDNVRDXUzdyKHszlHUcuvxwmC+MyVnRBnhK
aULqhaGzEZ0NjZhsr06zVvTy5ntKct1svvFbzMyWjtAWfc4m87bHdeJVINegGSWo
qZ9o5RQHfPZf9w4Xn9f5KQQjJhQzWEeuNTAgpvuPcvu/F5552wwq/15cKno4uuxc
8ipPy12jIQKBgFPUIFkU1o8edMMxDyjmYOZVwprNaks9Bus5vjVqS2pHmEYm9IWp
kZnIxxkzrATthV0aIXD6Y8PfOv8qeHcNUUcXKmYKqURcB54pioGzBjQLfqYm1uuO
6KbzYnmXP/+MJnzeZQ5GJYq6JO+aM1egQREm8iAeh/wpZAqYJxt3GqZ5AoGAUyur
wKxyfwkqrj/qGBMdgbYDPLGqceJ/AxUUB87NKq1twjmijhOMe1Qzr9fwBL32NsA5
H4gbLrj2TMX0pQ5+8NgtL3I4JR9Kg8EBUwnHTSku2rxFtwgGAWS9ykb4U7vkfQoK
To+Uwgw/MK4ugQlbKmd6HzcNfsEoUJW+0cd8TEECgYAPFfMIDVTUhu43YaBdAOiS
Em4DuQpAeQxxNSQqef9YqkoLtsgt1f8RwWZlc6LEigBqpcEbPJ52itk4ATj1YYZo
ZB2Cd/hCLxAoQVW6yDHBVRuhJwhsFFbL5cj6hw/j0kl02JFofnDNe1kLGfr3K3tu
b1JduKerJUdmfZfY6V+zKA==
-----END PRIVATE KEY-----

EOF
}
nginx_az(){
apt-get install nginx -y
rm /etc/nginx/nginx.conf
wget gx.heimayun.tk/xrayr/Nginx.txt -O /etc/nginx/nginx.conf
nginx
}
# 以上步骤完成基础环境配置。
echo "恭喜，您已完成基础环境安装，可执行安装程序。"

backend_docking_set(){
    white "本脚本支持 green "webapi"的对接方式"
    green "请选择对接方式"
    yellow "1.trojan对接"
    echo
    read -e -p "请输入数字[1~2](默认1)：" vnum
    [[ -z "${vnum}" ]] && vnum="1" 
	if [[ "${vnum}" == "1" ]]; then
        greenbg "当前对接模式：webapi"
        greenbg "使用前请准备好 redbg "节点ID""
        green "节点ID,示例: 6"
        read -p "请输入节点ID:" node_id
        yellow "配置已完成，正在部署后端。。。。"
        start=$(date "+%s")
        install_tool
        check_docker
	nginx_az
        setenforce 0
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
        greenbg "恭喜您，后端节点已搭建成功"
        end=$(date "+%s")
        echo 安装总耗时:$[$end-$start]"秒"           
	fi       
    }



#开始菜单
start_menu(){
    clear
    greenbg "==============================================================="
    greenbg "程序：sspanel后端对接 v1.0                          "
    greenbg "系统：Centos7.x、Ubuntu、Debian等                              "
    greenbg "==============================================================="
    echo
    echo
    green "-------------程序安装-------------"
    green "1.SSPANEL后端对接（默认：支持v2ray,trojan）"
    green "2.节点bbrplus加速"
    green "3.移除旧docker和证书配置文件夹"
    green "4.安装aapanel宝塔"
    green "5.禁用ipv6"
    green "6.安装7.7宝塔"
    green "7.安装7.7宝塔一键开心脚本"
    green "8.安装7.7宝塔优化补丁"
    green "9.安装gost隧道"
    green "10.添加gost规则"
    blue "0.退出脚本"
    echo
    echo
    read -p "请输入数字:" num

    case "$num" in
    1)
    greenbg "您选择了默认对接方式"
    backend_docking_set
	;;
	2)
    yellow "bbr加速脚本"
    wget -O tcp.sh "https://github.com/cx9208/Linux-NetSpeed/raw/master/tcp.sh" && chmod +x tcp.sh && ./tcp.sh
	;;            
	3)
    yellow "移除旧docker和证书配置文件夹"
    docker rm -f xrayrtrojan
    docker rm -f vicxrayrtrojan
    docker rm -f xrayr
    systemctl restart docker
    rm -rf /usr/local/xrayr/
    rm -rf /usr/local/vicxrayr/
	;;    
	4)
    yellow "安装aapanel宝塔"
    yum install -y wget && wget -O install.sh http://www.aapanel.com/script/install_6.0_en.sh && bash install.sh
	;;  
	5)
    yellow "禁用ipv6"
    clear
    sed -i '/net.ipv6.conf.all.disable_ipv6/d' /etc/sysctl.d/99-sysctl.conf
    sed -i '/net.ipv6.conf.default.disable_ipv6/d' /etc/sysctl.d/99-sysctl.conf
    sed -i '/net.ipv6.conf.lo.disable_ipv6/d' /etc/sysctl.d/99-sysctl.conf
    sed -i '/net.ipv6.conf.all.disable_ipv6/d' /etc/sysctl.conf
    sed -i '/net.ipv6.conf.default.disable_ipv6/d' /etc/sysctl.conf
    sed -i '/net.ipv6.conf.lo.disable_ipv6/d' /etc/sysctl.conf

    echo "net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1" >>/etc/sysctl.d/99-sysctl.conf
    sysctl --system
    echo -e "${Info}禁用IPv6结束，可能需要重启！"
	;;  
	6)
    yellow "安装7.7宝塔"
    timedatectl set-timezone 'Asia/Shanghai' && curl -sSO https://raw.githubusercontent.com/zhucaidan/btpanel-v7.7.0/main/install/install_panel.sh && echo -e "y\nn" | bash install_panel.sh
	;;  
	7)
    yellow "安装7.7宝塔一键开心脚本"
    curl -sSO https://raw.githubusercontent.com/ztkink/bthappy/main/one_key_happy.sh && echo -e "y" | bash one_key_happy.sh
	;;  
	8)
    yellow "安装7.7宝塔优化补丁"
    wget -O optimize.sh http://f.cccyun.cc/bt/optimize.sh && bash optimize.sh
	;; 
	9)
    yellow "安装gost隧道"
    wget --no-check-certificate -O gost.sh https://raw.githubusercontent.com/KANIKIG/Multi-EasyGost/master/gost.sh && chmod +x gost.sh && echo -e "1\nn" | bash gost.sh
	;; 
	10)
    yellow "添加gost规则"
    echo -e "7\n2\n2\n7770\n127.0.0.1\n7773" | bash gost.sh && echo -e "7\n3\n2\n7773\n127.0.0.1\n8880" | bash gost.sh
	;; 
	0)
	exit 1
	;;
	*)
	clear
	echo "请输入正确数字[0~2],退出请按0"
	sleep 3s
	start_menu
	;;
    esac
}

start_menu
