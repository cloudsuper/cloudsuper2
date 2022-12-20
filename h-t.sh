#!/usr/bin/env bash
#
#一键脚本
#version=v1.1
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#check root
[ $(id -u) != "0" ] && { echo "错误: 您必须以root用户运行此脚本"; exit 1; }
mkdir -p -m 777 /usr/local/heixrayr
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
  UplinkOnly: 2 # Time limit when the connection downstream is closed, Second
  DownlinkOnly: 4 # Time limit when the connection is closed after the uplink is closed, Second
  BufferSize: 64 # The internal cache size of each connection, kB 
Nodes:
  -
    PanelType: "V2board" # Panel type: SSpanel, V2board, PMpanel, , Proxypanel
    ApiConfig:
      ApiHost: "https://kilcdn1q2.heimayun.xyz"
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
      EnableFallback: false # Only support for Trojan and Vless
      FallBackConfigs:  # Support multiple fallbacks
        -
          SNI: # TLS SNI(Server Name Indication), Empty for any
          Alpn: "h2" # Alpn, Empty for any
          Path: # HTTP PATH, Empty for any
          Dest: 8080 # Required, Destination of fallback, check https://xtls.github.io/config/fallback/ for details.
          ProxyProtocolVer: 0 # Send PROXY protocol version, 0 for dsable
      CertConfig:
        CertMode: file # Option about how to get certificate: none, file, http, dns. Choose "none" will forcedly disable the tls config.
        CertDomain: "146-190-102-199.nhost.00cdn.com" # Domain to cert
        CertFile: /etc/XrayR/1.cert # Provided if the CertMode is file
        KeyFile: /etc/XrayR/1.key
        Provider: cloudflare # DNS cert provider, Get the full support list here: https://go-acme.github.io/lego/dns/
        Email: heimacloud@gmail.com
        DNSEnv: # DNS ENV option used by DNS provider
          CLOUDFLARE_EMAIL: 777
          CLOUDFLARE_API_KEY: 777
  -
    PanelType: "V2board" # Panel type: SSpanel, V2board, PMpanel, , Proxypanel
    ApiConfig:
      ApiHost: "https://kilcdn1q2.heimayun.xyz"
      ApiKey: "heimayunheimayun"
      NodeID: $node_id2
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
      EnableFallback: false # Only support for Trojan and Vless
      FallBackConfigs:  # Support multiple fallbacks
        -
          SNI: # TLS SNI(Server Name Indication), Empty for any
          Alpn: "h2" # Alpn, Empty for any
          Path: # HTTP PATH, Empty for any
          Dest: 8080 # Required, Destination of fallback, check https://xtls.github.io/config/fallback/ for details.
          ProxyProtocolVer: 0 # Send PROXY protocol version, 0 for dsable
      CertConfig:
        CertMode: file # Option about how to get certificate: none, file, http, dns. Choose "none" will forcedly disable the tls config.
        CertDomain: "146-190-102-199.nhost.00cdn.com" # Domain to cert
        CertFile: /etc/XrayR/1.cert # Provided if the CertMode is file
        KeyFile: /etc/XrayR/1.key
        Provider: cloudflare # DNS cert provider, Get the full support list here: https://go-acme.github.io/lego/dns/
        Email: heimacloud@gmail.com
        DNSEnv: # DNS ENV option used by DNS provider
          CLOUDFLARE_EMAIL: 777
          CLOUDFLARE_API_KEY: 777
EOF
}
#写入证书文件
crt_file(){
    cat > /usr/local/heixrayr/1.cert << EOF
-----BEGIN CERTIFICATE-----
MIIFRTCCBC2gAwIBAgISA+neHFoe9T1UuJTpTn0bN/6PMA0GCSqGSIb3DQEBCwUA
MDIxCzAJBgNVBAYTAlVTMRYwFAYDVQQKEw1MZXQncyBFbmNyeXB0MQswCQYDVQQD
EwJSMzAeFw0yMjExMzAwMjM5MzJaFw0yMzAyMjgwMjM5MzFaMCoxKDAmBgNVBAMT
HzE0Ni0xOTAtMTAyLTE5OS5uaG9zdC4wMGNkbi5jb20wggEiMA0GCSqGSIb3DQEB
AQUAA4IBDwAwggEKAoIBAQCnh7hKABGm7DZJiu8q1KqhwlrqVMnSCrFufvCcAI8V
6eIayIzdEtKHMDp683tnFWXqTtgiQAe6nQvlEO3LR2MEmNgYDz0fSoL8BmdL+ToU
kYMgoCU7PsSw71am+7YgHSL8ldriF6K49obsW5zM22LggNDnQuyhIJAobnNFDFrp
Uy98VUNnSnBgX8ziUML2aMhOg8YETOH3KUdlaz144n/SsgiW/egf+ciD6/F6eQoa
NCgKOMB2WC5kA1ZrwDiakAuOAcEX8yK5GVfZx8WV23pday84btpi5EWo13QG3qf1
UykHtm8j3kUumBaX0U8RroyCpD7PUF+bk9zMy8rFwaDnAgMBAAGjggJbMIICVzAO
BgNVHQ8BAf8EBAMCBaAwHQYDVR0lBBYwFAYIKwYBBQUHAwEGCCsGAQUFBwMCMAwG
A1UdEwEB/wQCMAAwHQYDVR0OBBYEFNj2lawoNwDkHrfScGqzRw+5W/RcMB8GA1Ud
IwQYMBaAFBQusxe3WFbLrlAJQOYfr52LFMLGMFUGCCsGAQUFBwEBBEkwRzAhBggr
BgEFBQcwAYYVaHR0cDovL3IzLm8ubGVuY3Iub3JnMCIGCCsGAQUFBzAChhZodHRw
Oi8vcjMuaS5sZW5jci5vcmcvMCoGA1UdEQQjMCGCHzE0Ni0xOTAtMTAyLTE5OS5u
aG9zdC4wMGNkbi5jb20wTAYDVR0gBEUwQzAIBgZngQwBAgEwNwYLKwYBBAGC3xMB
AQEwKDAmBggrBgEFBQcCARYaaHR0cDovL2Nwcy5sZXRzZW5jcnlwdC5vcmcwggEF
BgorBgEEAdZ5AgQCBIH2BIHzAPEAdgC3Pvsk35xNunXyOcW6WPRsXfxCz3qfNcSe
HQmBJe20mQAAAYTGnkd4AAAEAwBHMEUCIEZCEr0XuOd1QL9Iz7FWsdfSElhuuVF7
NE7mHouMcVZWAiEAvyOQqA6FgOJ+5sU5CGmlzzVp+Ha/aFdzKnlvBTdWAPwAdwB6
MoxU2LcttiDqOOBSHumEFnAyE4VNO9IrwTpXo1LrUgAAAYTGnkeQAAAEAwBIMEYC
IQCe0c73Yr2epRknPFYRVtvnfVMZfH8MNmDujj0ceVtjiQIhAMJR2Q51RcDK8Dza
HJHljPPQ6A8wY8NrONB0aT8w50wXMA0GCSqGSIb3DQEBCwUAA4IBAQAwD4NwLU9B
T9phkXLYbl088qMVexn3v3Ky6QNQ8/HU2jvu51cs8jYc1C0U+z+4lnraP+ai3cDe
+EacqpiGEcfS0m2gwgi85NeNWsEfah9pD31USARUXBKDvug1jLtd6Y6Ue2f5sFVu
OF04DlPUEvAn8rNx0TfpgoUMaugCwo5k3sTcWF6jARfFqKh9GsQBbmbRIgWPhnDn
FlGKYabPxacyf7fbYZokUK2vvB5fQWM5t4oSp0sC41+5CWxjfvzRbSNnLMomQCQW
okuNELSunie9rNp7AHBcULWFKY8QZ9vT6p404LWptena9um1lkOyRS6I7qAU1w68
pK24X+k/CRmB
-----END CERTIFICATE-----

-----BEGIN CERTIFICATE-----
MIIFFjCCAv6gAwIBAgIRAJErCErPDBinU/bWLiWnX1owDQYJKoZIhvcNAQELBQAw
TzELMAkGA1UEBhMCVVMxKTAnBgNVBAoTIEludGVybmV0IFNlY3VyaXR5IFJlc2Vh
cmNoIEdyb3VwMRUwEwYDVQQDEwxJU1JHIFJvb3QgWDEwHhcNMjAwOTA0MDAwMDAw
WhcNMjUwOTE1MTYwMDAwWjAyMQswCQYDVQQGEwJVUzEWMBQGA1UEChMNTGV0J3Mg
RW5jcnlwdDELMAkGA1UEAxMCUjMwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK
AoIBAQC7AhUozPaglNMPEuyNVZLD+ILxmaZ6QoinXSaqtSu5xUyxr45r+XXIo9cP
R5QUVTVXjJ6oojkZ9YI8QqlObvU7wy7bjcCwXPNZOOftz2nwWgsbvsCUJCWH+jdx
sxPnHKzhm+/b5DtFUkWWqcFTzjTIUu61ru2P3mBw4qVUq7ZtDpelQDRrK9O8Zutm
NHz6a4uPVymZ+DAXXbpyb/uBxa3Shlg9F8fnCbvxK/eG3MHacV3URuPMrSXBiLxg
Z3Vms/EY96Jc5lP/Ooi2R6X/ExjqmAl3P51T+c8B5fWmcBcUr2Ok/5mzk53cU6cG
/kiFHaFpriV1uxPMUgP17VGhi9sVAgMBAAGjggEIMIIBBDAOBgNVHQ8BAf8EBAMC
AYYwHQYDVR0lBBYwFAYIKwYBBQUHAwIGCCsGAQUFBwMBMBIGA1UdEwEB/wQIMAYB
Af8CAQAwHQYDVR0OBBYEFBQusxe3WFbLrlAJQOYfr52LFMLGMB8GA1UdIwQYMBaA
FHm0WeZ7tuXkAXOACIjIGlj26ZtuMDIGCCsGAQUFBwEBBCYwJDAiBggrBgEFBQcw
AoYWaHR0cDovL3gxLmkubGVuY3Iub3JnLzAnBgNVHR8EIDAeMBygGqAYhhZodHRw
Oi8veDEuYy5sZW5jci5vcmcvMCIGA1UdIAQbMBkwCAYGZ4EMAQIBMA0GCysGAQQB
gt8TAQEBMA0GCSqGSIb3DQEBCwUAA4ICAQCFyk5HPqP3hUSFvNVneLKYY611TR6W
PTNlclQtgaDqw+34IL9fzLdwALduO/ZelN7kIJ+m74uyA+eitRY8kc607TkC53wl
ikfmZW4/RvTZ8M6UK+5UzhK8jCdLuMGYL6KvzXGRSgi3yLgjewQtCPkIVz6D2QQz
CkcheAmCJ8MqyJu5zlzyZMjAvnnAT45tRAxekrsu94sQ4egdRCnbWSDtY7kh+BIm
lJNXoB1lBMEKIq4QDUOXoRgffuDghje1WrG9ML+Hbisq/yFOGwXD9RiX8F6sw6W4
avAuvDszue5L3sz85K+EC4Y/wFVDNvZo4TYXao6Z0f+lQKc0t8DQYzk1OXVu8rp2
yJMC6alLbBfODALZvYH7n7do1AZls4I9d1P4jnkDrQoxB3UqQ9hVl3LEKQ73xF1O
yK5GhDDX8oVfGKF5u+decIsH4YaTw7mP3GFxJSqv3+0lUFJoi5Lc5da149p90Ids
hCExroL1+7mryIkXPeFM5TgO9r0rvZaBFOvV2z0gp35Z0+L4WPlbuEjN/lxPFin+
HlUjr8gRsI3qfJOQFy/9rKIJR0Y/8Omwt/8oTWgy1mdeHmmjk7j1nYsvC9JSQ6Zv
MldlTTKB3zhThV1+XWYp6rjd5JW1zbVWEkLNxE7GJThEUG3szgBVGP7pSWTUTsqX
nLRbwHOoq7hHwg==
-----END CERTIFICATE-----

-----BEGIN CERTIFICATE-----
MIIFYDCCBEigAwIBAgIQQAF3ITfU6UK47naqPGQKtzANBgkqhkiG9w0BAQsFADA/
MSQwIgYDVQQKExtEaWdpdGFsIFNpZ25hdHVyZSBUcnVzdCBDby4xFzAVBgNVBAMT
DkRTVCBSb290IENBIFgzMB4XDTIxMDEyMDE5MTQwM1oXDTI0MDkzMDE4MTQwM1ow
TzELMAkGA1UEBhMCVVMxKTAnBgNVBAoTIEludGVybmV0IFNlY3VyaXR5IFJlc2Vh
cmNoIEdyb3VwMRUwEwYDVQQDEwxJU1JHIFJvb3QgWDEwggIiMA0GCSqGSIb3DQEB
AQUAA4ICDwAwggIKAoICAQCt6CRz9BQ385ueK1coHIe+3LffOJCMbjzmV6B493XC
ov71am72AE8o295ohmxEk7axY/0UEmu/H9LqMZshftEzPLpI9d1537O4/xLxIZpL
wYqGcWlKZmZsj348cL+tKSIG8+TA5oCu4kuPt5l+lAOf00eXfJlII1PoOK5PCm+D
LtFJV4yAdLbaL9A4jXsDcCEbdfIwPPqPrt3aY6vrFk/CjhFLfs8L6P+1dy70sntK
4EwSJQxwjQMpoOFTJOwT2e4ZvxCzSow/iaNhUd6shweU9GNx7C7ib1uYgeGJXDR5
bHbvO5BieebbpJovJsXQEOEO3tkQjhb7t/eo98flAgeYjzYIlefiN5YNNnWe+w5y
sR2bvAP5SQXYgd0FtCrWQemsAXaVCg/Y39W9Eh81LygXbNKYwagJZHduRze6zqxZ
Xmidf3LWicUGQSk+WT7dJvUkyRGnWqNMQB9GoZm1pzpRboY7nn1ypxIFeFntPlF4
FQsDj43QLwWyPntKHEtzBRL8xurgUBN8Q5N0s8p0544fAQjQMNRbcTa0B7rBMDBc
SLeCO5imfWCKoqMpgsy6vYMEG6KDA0Gh1gXxG8K28Kh8hjtGqEgqiNx2mna/H2ql
PRmP6zjzZN7IKw0KKP/32+IVQtQi0Cdd4Xn+GOdwiK1O5tmLOsbdJ1Fu/7xk9TND
TwIDAQABo4IBRjCCAUIwDwYDVR0TAQH/BAUwAwEB/zAOBgNVHQ8BAf8EBAMCAQYw
SwYIKwYBBQUHAQEEPzA9MDsGCCsGAQUFBzAChi9odHRwOi8vYXBwcy5pZGVudHJ1
c3QuY29tL3Jvb3RzL2RzdHJvb3RjYXgzLnA3YzAfBgNVHSMEGDAWgBTEp7Gkeyxx
+tvhS5B1/8QVYIWJEDBUBgNVHSAETTBLMAgGBmeBDAECATA/BgsrBgEEAYLfEwEB
ATAwMC4GCCsGAQUFBwIBFiJodHRwOi8vY3BzLnJvb3QteDEubGV0c2VuY3J5cHQu
b3JnMDwGA1UdHwQ1MDMwMaAvoC2GK2h0dHA6Ly9jcmwuaWRlbnRydXN0LmNvbS9E
U1RST09UQ0FYM0NSTC5jcmwwHQYDVR0OBBYEFHm0WeZ7tuXkAXOACIjIGlj26Ztu
MA0GCSqGSIb3DQEBCwUAA4IBAQAKcwBslm7/DlLQrt2M51oGrS+o44+/yQoDFVDC
5WxCu2+b9LRPwkSICHXM6webFGJueN7sJ7o5XPWioW5WlHAQU7G75K/QosMrAdSW
9MUgNTP52GE24HGNtLi1qoJFlcDyqSMo59ahy2cI2qBDLKobkx/J3vWraV0T9VuG
WCLKTVXkcGdtwlfFRjlBz4pYg1htmf5X6DYO8A4jqv2Il9DjXA6USbW1FzXSLr9O
he8Y4IWS6wY7bCkjCWDcRQJMEhg76fsO3txE+FiYruq9RUWhiF1myv4Q6W+CyBFC
Dfvp7OOGAN6dEOM4+qR9sdjoSYKEBpsr6GtPAQw4dy753ec5
-----END CERTIFICATE-----
EOF
cat > /usr/local/heixrayr/1.key << EOF
-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCnh7hKABGm7DZJ
iu8q1KqhwlrqVMnSCrFufvCcAI8V6eIayIzdEtKHMDp683tnFWXqTtgiQAe6nQvl
EO3LR2MEmNgYDz0fSoL8BmdL+ToUkYMgoCU7PsSw71am+7YgHSL8ldriF6K49obs
W5zM22LggNDnQuyhIJAobnNFDFrpUy98VUNnSnBgX8ziUML2aMhOg8YETOH3KUdl
az144n/SsgiW/egf+ciD6/F6eQoaNCgKOMB2WC5kA1ZrwDiakAuOAcEX8yK5GVfZ
x8WV23pday84btpi5EWo13QG3qf1UykHtm8j3kUumBaX0U8RroyCpD7PUF+bk9zM
y8rFwaDnAgMBAAECggEAD0r53TN1aQ3uBLecjoXcT6jcwMBdrgFQ4hvPXgZFCYSQ
oc5F4ZZqxnF2HSwlyyquY32wCCxdKEFWySHK+z/4f35uV3/onfcgzt3Mxygoj6Ea
3bsQuwBHVzl56QNYREU0oOcTFImAzq6ecWwJe7/ZHlJT/5Bh5nGBB1fRyO9QSzUp
QRoFMQ9AARBExNCCPIelW4U5UvkYDxjtH60ITcFwmvcUcLOfTxhcqrwSGR/FebZT
LGG2blUSUYBTV+Nfk0NerTfjOEliUD86zDycqhu4BOrBe1D4ZQAXobNPjAOGkquT
tDL9ol7r0NiKitLBXJjhRToBplA65bifjFOT/x+1pQKBgQDlpHpZltSox+Fa9Kai
DH876f97rlmLPCaLa6N1uAs6HdYoRd7peUoM9U1I+yK42SMxR8eTeb7/Q+ODQ5VZ
fQeU7jMG0NqwKH3UM0vSyij9ZxMUa52CEUs6tNDKyBKC10+xsUD7fmIa3jB3KbW8
x4qHfEHwyp/jikBhaeQhBFY+ewKBgQC6wjZYnpFVq93mChvorx8xPVvsW3Pnh1cx
+ATuH/oyMpf92jNtXWCZmRJ1hkDq2tiR07ac5+iZPsc7Ute6sah5VnXPQm1BhS4o
omFLJpHln9nPWwmK5kcBgVNwmM5jSO1OOYX/bkKfyWHkvJiOs5GM0bIjNpFotOVI
S6Rx/VcRhQKBgQDL7+K8Fyfqb//g/63P8Zs4wRkjZHWfIh705/V1QKmvxfl/MHXD
D/TER0CIVIbEdAk95YoGnTMSjN7KnsVOgKuwBk4IeogLsxnzzk5C90epqtUV6HAr
p2IQ060suLs/uSjMHCcicV18kN+no8IC0Y5jveTti3Ss5QVBvYFcFPbmawKBgCjF
5d+LHue5UgS7CETQltrFLqB3huJxZdP+9fSW/qSe7xf432ltDX37MVB/MwUTKl0L
/75Z0ypBznVhLMARsVpsSeQp+Hhpfx5X9S3XCds7/u2KTpcIl0/40CKw+b4rWcPO
Qzb0946zBLBPjG77PTelQGL3st9NPxF9kjVgvfWRAoGAArz833A2+ei70LqoT/hP
twLNLF+MeZxsQkY00KOog+VCChGYMlpjxtAe1qxP08de+cSevItp+hJ9MklWKwLx
Mg4Ymwey01faXPDTvvOi05hk3m2Jp+pIyy2OAQaXCrzisAgMFq8P2iiRB9etXK9d
2H1TW7YMphDLvM9wvHj5Ua4=
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
        read -p "请输入节点ID1:" node_id
        read -p "请输入节点ID2:" node_id2
        yellow "配置已完成，正在部署后端。。。。"
        start=$(date "+%s")
        install_tool
        check_docker
	xrayr_file
	crt_file
	rulelist_file
	docker run --restart=always --name heixrayr -d -v /usr/local/heixrayr/config.yml:/etc/XrayR/config.yml -v /usr/local/heixrayr/1.cert:/etc/XrayR/1.cert -v /usr/local/heixrayr/1.key:/etc/XrayR/1.key -v /usr/local/heixrayr/config.yml:/etc/XrayR/config.yml -v /usr/local/heixrayr/rulelist:/etc/XrayR/rulelist --network=host crackair/xrayr:latest
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
    docker rm -f heixrayrtrojan
    docker rm -f heixrayr
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
    echo -e "7\n2\n2\n7771\n127.0.0.1\n9991" | bash gost.sh && echo -e "7\n3\n2\n9991\n127.0.0.1\n8881" | bash gost.sh
    echo -e "7\n2\n2\n7772\n127.0.0.1\n9992" | bash gost.sh && echo -e "7\n3\n2\n9992\n127.0.0.1\n8882" | bash gost.sh
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
