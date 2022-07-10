echo -e "y" | apt install curl
bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)
cd /usr/local/etc/v2ray
rm config.json
wget gx.acys.cf/x-ui/config.json
systemctl start v2ray
