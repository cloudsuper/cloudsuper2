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
    cat > /usr/local/heixrayr/config.yml << EOF
Log:
  Level: none # Log level: none, error, warning, info, debug 
  AccessPath: # /etc/XrayR/access.Log
  ErrorPath: # /etc/XrayR/error.log
DnsConfigPath: # /etc/XrayR/dns.json # Path to dns config, check https://xtls.github.io/config/base/dns/ for help
RouteConfigPath: # /etc/XrayR/route.json # Path to route config, check https://xtls.github.io/config/base/route/ for help
OutboundConfigPath: # /etc/XrayR/custom_outbound.json # Path to custom outbound config, check https://xtls.github.io/config/base/outbound/ for help
ConnetionConfig:
  Handshake: 4 # Handshake time limit, Second
  ConnIdle: 10 # Connection idle time limit, Second
  UplinkOnly: 10 # Time limit when the connection downstream is closed, Second
  DownlinkOnly: 10 # Time limit when the connection is closed after the uplink is closed, Second
  BufferSize: 64 # The internal cache size of each connection, kB 
Nodes:
  -
    PanelType: "V2board" # Panel type: SSpanel, V2board, PMpanel, , Proxypanel
    ApiConfig:
      ApiHost: "https://heimayun.top"
      ApiKey: "heimayunheimayun"
      NodeID: $node_id
      NodeType: Trojan # Node type: V2ray, Shadowsocks, Trojan, Shadowsocks-Plugin
      Timeout: 30 # Timeout for the api request
      EnableVless: false # Enable Vless for V2ray Type
      EnableXTLS: false # Enable XTLS for V2ray and Trojan
      SpeedLimit: 0 # Mbps, Local settings will replace remote settings, 0 means disable
      DeviceLimit: 0 # Local settings will replace remote settings, 0 means disable
      RuleListPath: /etc/XrayR/rulelist #Path to local rulelist file
    ControllerConfig:
      ListenIP: 0.0.0.0 # IP address you want to listen
      SendIP: 0.0.0.0 # IP address you want to send pacakage
      UpdatePeriodic: 60 # Time to update the nodeinfo, how many sec.
      EnableDNS: false # Use custom DNS config, Please ensure that you set the dns.json well
      DNSType: AsIs # AsIs, UseIP, UseIPv4, UseIPv6, DNS strategy
      EnableProxyProtocol: false # Only works for WebSocket and TCP
      EnableFallback: true # Only support for Trojan and Vless
      FallBackConfigs:  # Support multiple fallbacks
        -
          SNI: # TLS SNI(Server Name Indication), Empty for any
          Alpn: "h2" # Alpn, Empty for any
          Path: # HTTP PATH, Empty for any
          Dest: 8080 # Required, Destination of fallback, check https://xtls.github.io/config/fallback/ for details.
          ProxyProtocolVer: 0 # Send PROXY protocol version, 0 for dsable
      CertConfig:
        CertMode: file # Option about how to get certificate: none, file, http, dns. Choose "none" will forcedly disable the tls config.
        CertDomain: "wp.heimayun.top" # Domain to cert
        CertFile: /etc/XrayR/1.cert # Provided if the CertMode is file
        KeyFile: /etc/XrayR/1.key
        Provider: cloudflare # DNS cert provider, Get the full support list here: https://go-acme.github.io/lego/dns/
        Email: heimacloud@gmail.com
        DNSEnv: # DNS ENV option used by DNS provider
          CLOUDFLARE_EMAIL: 777
          CLOUDFLARE_API_KEY: 777

EOF
cat > /usr/local/heixrayr/custom_inbound.json << EOF
[
    {
      "streamSettings": {
          "alpn": [
            "h2" 
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
    cat > /usr/local/heixrayr/1.cert << EOF
-----BEGIN CERTIFICATE-----
MIIFIzCCBAugAwIBAgISA/XjQxubOxxXKbCsMX9/mhETMA0GCSqGSIb3DQEBCwUA
MDIxCzAJBgNVBAYTAlVTMRYwFAYDVQQKEw1MZXQncyBFbmNyeXB0MQswCQYDVQQD
EwJSMzAeFw0yMjExMjIxNTM3MDRaFw0yMzAyMjAxNTM3MDNaMBoxGDAWBgNVBAMT
D3dwLmhlaW1heXVuLnRvcDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB
AJj9gI9e2l9RaYTz9tp3cIbR8Wn8G7JmfgZIuNCZdBQah3JK+LqhsyIKGwYNmTBh
XWUS2aUWvYDTik4Xbh0GEPIJEY8K82fvJO8GHxVugC1pSA1gOtcSUDsw6lH4Emho
poPJBpNql8SquBguIkRAOaAt/8TvvCMcoTJaoT96ow9wvZXBUaOTWaH7N1f9til/
PjRSq4rcAd8yU8ZX+bJ9/7sMrbxxNn1IGXPBhOkhmPkD42A4O6RJlOByhlFYPJ6s
im5L7D3kgdoXBTwB8duKwNWkKHs8K51V2+u2QyVAn90OYsgm1YI3vS4hEboKXDvQ
SAS3PgoNEYxtKWKXiDuETPsCAwEAAaOCAkkwggJFMA4GA1UdDwEB/wQEAwIFoDAd
BgNVHSUEFjAUBggrBgEFBQcDAQYIKwYBBQUHAwIwDAYDVR0TAQH/BAIwADAdBgNV
HQ4EFgQUYSYTZ8vAVWQMybloiYKfDAkH5rYwHwYDVR0jBBgwFoAUFC6zF7dYVsuu
UAlA5h+vnYsUwsYwVQYIKwYBBQUHAQEESTBHMCEGCCsGAQUFBzABhhVodHRwOi8v
cjMuby5sZW5jci5vcmcwIgYIKwYBBQUHMAKGFmh0dHA6Ly9yMy5pLmxlbmNyLm9y
Zy8wGgYDVR0RBBMwEYIPd3AuaGVpbWF5dW4udG9wMEwGA1UdIARFMEMwCAYGZ4EM
AQIBMDcGCysGAQQBgt8TAQEBMCgwJgYIKwYBBQUHAgEWGmh0dHA6Ly9jcHMubGV0
c2VuY3J5cHQub3JnMIIBAwYKKwYBBAHWeQIEAgSB9ASB8QDvAHUAejKMVNi3LbYg
6jjgUh7phBZwMhOFTTvSK8E6V6NS61IAAAGEoDNDxgAABAMARjBEAiBmkrCxxjeg
7/qW6AcxlOfamiwQmDMosTnNo+N2AjhiDQIgegkO7l/YgoExRGhzD18NI4o2axB9
n6Xh89flo9BTVnoAdgDoPtDaPvUGNTLnVyi8iWvJA9PL0RFr7Otp4Xd9bQa9bgAA
AYSgM0V6AAAEAwBHMEUCICatnZ6+pMrkFYQPYE1tyMynsowILH9Bt0JGSrDOFG5K
AiEA4eULZkmptxHgA3/320S25c/iHt11enACpa8L72RQ8HIwDQYJKoZIhvcNAQEL
BQADggEBAIBCC8d33czwu7/PS0SGmZON/hTsvb1yrnlyPGp1Oaxq918QUFtb9+Cw
uOjxeJ8AdPU7RTPkfBmOZP0yXgA4wk8tK8peZDPMGjO217Ctbb3k/UgrhF1MoJi+
VXUhqljJYUm9R5b4N90Ar8vKJoaU8nLEU3hfVePSl3zhfxTvFKmAiQ6VKIIHXSJt
z7LEfwoAH5IXCGBxxPfprGNtpz3YJeV99HsFEUvXpGqBu1O8EyodwsgP3nFzN3cB
d98SQ/QxJHrKAJ/ZgbEzJa+vSCIY/vDlUePrGSnD3z0fvemlHcrDhoFkXCL0DhRD
GUgQPD/BRiP7H6FJZ1Z6yRcq6Zaqrss=
-----END CERTIFICATE-----

EOF
cat > /usr/local/heixrayr/1.key << EOF
-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQCY/YCPXtpfUWmE
8/bad3CG0fFp/BuyZn4GSLjQmXQUGodySvi6obMiChsGDZkwYV1lEtmlFr2A04pO
F24dBhDyCRGPCvNn7yTvBh8VboAtaUgNYDrXElA7MOpR+BJoaKaDyQaTapfEqrgY
LiJEQDmgLf/E77wjHKEyWqE/eqMPcL2VwVGjk1mh+zdX/bYpfz40UquK3AHfMlPG
V/myff+7DK28cTZ9SBlzwYTpIZj5A+NgODukSZTgcoZRWDyerIpuS+w95IHaFwU8
AfHbisDVpCh7PCudVdvrtkMlQJ/dDmLIJtWCN70uIRG6Clw70EgEtz4KDRGMbSli
l4g7hEz7AgMBAAECggEADCOqn0sEoyU9F7EZ/cTAwi8yFi73GE/x9lgFM3wcTfoQ
PvKRoObIECPizWH9LUMUhjrELUl2zkblcFkt7LyjUekuolMuntPGx6E3NzFLl2Qw
CkD/+jp4Rkdqgwg0QbedZX3pI9UEkjTaTa+KGttJF0Ypx3vJnwmcWs1T18sd2Xwr
s81aC6B28libvF8tF9ETFtPxPl7skTNFc1Ougmv15T/NhHkDzh2kug+oDJV9O/nr
uuYXbdY2zUJRwq9rg55p6QzgiQR16qMMyy66JA4gV0y16SJJBjBhU+W/zl0gS8sr
s1I1aIiG171KKh+M/B+Ai8/67y17exqQLUNYc4uvbQKBgQDNf+19598K8OD7C494
alh6Mpyv8vz1JravRkwGMTr+oCZdrL57cOOUGwUBdd6rV7VUv6+g2PvkV0ysMWso
YBOwto6syAfPpO76EPJH2dwAThZyX1hzAe3VdHiPOfYpfln9kNm//cpnMGRjmzlY
F9We37u24Y1iTWGbSZsds7QB7QKBgQC+li6DxyIZ7WwEgabXECqNf5SFEzC7b+cJ
bn1uuoyxaLq9b12EhUkh8VxfI9xvDitp61A2gFyEZRb3q5J80ElFIR/yvez2H2pI
8HxSVPcbkO3ex6gtyDF2SuogUPPV884cFiIg5Mvi/KOm3x6lMYjCumiCXfMJgw+x
Yxdbyq9NhwKBgQCkdeo6JjRhjC9xmmnio7FVcmXlhmCdTbNMiMTU+9dL6h1qQJJd
NhZb9FfIOG3Q0KvFPHcxEhZdQuSQtigdMu7vMNr0Ok3OByBeLuvHRvqDn/rk45tk
xzlw5/qIHYn84Srh/GfX+CNg++CLurFk6AZFVKblEJPXBTjFT139olDAbQKBgQC2
Rn4wLEiSEX9IhBNkBqMb91O9PlBSQ8DsRU8Tkrkyh55pxNPlBXCfVO5qU6rkT+H3
iEWMCpHxUZl4wA/27WHWCss6Zqj176/AGLheKcK4C5FkiwFu39NmdlmbFLFQA8Ax
Hn3/hbL14XhHBYeSqGBLFOsVG/NwOnfMyJ+ze5LTiwKBgDfvwHH9CSgIFlB6qdMP
61szHXBPkPOiEN6H7FBR2c7ySG9CC0fva6Y3vwiHG2w8NRKn7dpbx6eidmAHXU+U
gYn2mHG7ajK2dH1Yh3A1sBkm3WH5u40zM4UKnMnqrJrbWjUOym3Gw+6dhcY+aXZi
y/v30vrUXhhBeGk43dRVaQG+
-----END PRIVATE KEY-----

EOF
}
rulelist_file(){
cat > /usr/local/heixrayr/rulelist << EOF
BitTorrent protocol
(api|ps|sv|offnavi|newvector|ulog\.imap|newloc)(\.map|)\.(baidu|n\.shifen)\.com
(.+\.|^)(360|so)\.(cn|com)
(Subject|HELO|SMTP)
(torrent|\.torrent|peer_id=|info_hash|get_peers|find_node|BitTorrent|announce_peer|announce\.php\?passkey=)
(^.*\@)(guerrillamail|guerrillamailblock|sharklasers|grr|pokemail|spam4|bccto|chacuo|027168)\.(info|biz|com|de|net|org|me|la)
(.?)(xunlei|sandai|Thunder|XLLiveUD)(.)
(.*\.||)(dafahao|minghui|dongtaiwang|epochtimes|ntdtv|falundafa|wujieliulan|zhengjian)\.(org|com|net)
(.+.|^)(whatismyip|whatismyi­pad­dress|ipip|iplo­ca­tion|myip|whatismy­browser).(cn|com|net|com|net­work)
(.*.||)(netvi­ga­tor|tor­pro­ject).(com|cn|net|org)
(.*.||)(gov|12377|12315|talk.news.pts.org|cread­ers|zhuich­aguoji|efcc.org|cy­ber­po­lice|abolu­owang|tu­idang|epochtimes|ny­times|zhengjian|110.qq|mingjingnews|in­medi­ahk|xin­sheng|banned­book|nt­dtv|12321|se­cretchina|epochweekly|cn.rfi).(cn|com|org|net|club|net|fr|tw|hk)
^esu.|^zhina.|w.esu.|w.zhina.
(.*.||)(gov|12377|12315|talk.news.pts.org|cread­ers|zhuich­aguoji|efcc.org|cy­ber­po­lice|abolu­owang|tu­idang|epochtimes|dafa­hao|falundafa|minghui|falu­naz|zhengjian|110.qq|mingjingnews|in­medi­ahk|xin­sheng|banned­book|nt­dtv|falun­gong|12321|se­cretchina|epochweekly|cn.rfi).(cn|com|org|net|club|net|fr|tw|hk)
(kpzip)(.)
(.*.||)(ris­ing|king­soft|duba|xin­dubawukong|jin­shan­duba).(com|net|org)
(.*.||)(miaozhen|cnzz|talk­ing­data|umeng).(cn|com)
(.*.||)(ad-safe).(com)
.cn­nic.net.cn
(.*.||)(guan­jia.qq.com|qqpcmgr|QQPCMGR)
(ed2k|.tor­rent|peer_id=|an­nounce|in­fo_hash|get_peers|find­_n­ode|Bit­Tor­rent|an­nounce_peer|an­nounce.php?passkey=|mag­net:|xun­lei|sandai|Thun­der|XL­LiveUD|bt_key)
(.*.||)(shenzhoufilm|secretchina|renminbao|aboluowang|mhradio|guangming|zhengwunet|soundofhope|yuanming|shenyunperformingarts).(org|com|net|rocks|fr)
(.*\.||)(ethermine|sigmapool|hashcity|2miners|solo-etc|nanopool|minergate|comining|give-me-coins|hiveon|arsmine|baikalmine|solopool|litecoinpool|mining-dutch|clona|viabtc|beepool|maxhash|bwpool|coinminerz|miningcore|multipools|uupool|minexmr|pandaminer|f2pool|sparkpool|antpool|poolin|slushpool|marathondh|pool.btc)\.(cn|com|org|net|club|net|fr|tw|hk|eu|info|me|io)
(.*.||)(weibo|zhihu|toutiao|bytedance|zijieapi|xiaohongshu|xhscdn).(cn|com)
\b([\w-]+\.)*pincong\.rocks
(.?)(pincong|twreporter|gnews|lihkg)(.) 

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
        wget gx.heimayun.tk/xrayr.sh
        bash xrayr.sh
        touch /etc/XrayR/1.cert
        touch /etc/XrayR/1.key
	      xrayr_file
	      crt_file
	      rulelist_file
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
    docker rm -f heixrayrtrojan
    docker rm -f xrayr
    systemctl restart docker
    rm -rf /usr/local/xrayr/
    rm -rf /usr/local/heixrayr/
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
