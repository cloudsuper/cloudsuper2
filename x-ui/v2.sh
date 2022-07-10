echo -e "y" | apt install curl
bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)
rm /usr/local/etc/v2ray/config.json
wget gx.acys.cf/x-ui/config.json -P /usr/local/etc/v2ray
systemctl start v2ray
wget gx.acys.cf/bbr.sh --no-check-certificate
echo -e "4" | bash bbr.sh
wget gx.acys.cf/gost.sh
echo -e "1" | bash gost.sh
echo -e "7\n3\n2\n666\n127.0.0.1\n888" | bash gost.sh
wget git.io/warp.sh --no-check-certificate
echo -e "5" | bash warp.sh menu
