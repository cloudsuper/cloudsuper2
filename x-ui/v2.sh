echo -e "y" | apt install curl
bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)
rm /usr/local/etc/v2ray/config.json
wget gx.acys.cf/x-ui/config.json -P /usr/local/etc/v2ray
systemctl start v2ray
