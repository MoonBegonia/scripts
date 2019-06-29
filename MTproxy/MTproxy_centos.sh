#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

get_char() {
    SAVEDSTTY=`stty -g`
    stty -echo
    stty cbreak
    dd if=/dev/tty bs=1 count=1 2> /dev/null
    stty -raw
    stty echo
    stty $SAVEDSTTY
}

echo ""
echo "#############################################################"
echo "                                                            #"
echo "                  MTProxy 代理一键安装脚本                  #"
echo "                                                            #"
echo "#############################################################"
echo ""
echo ""
echo "Press any key to start...or press Ctrl+C to cancel"

char=`get_char`

# get vps ip
serverip=`wget http://ipecho.net/plain -O - -q ; echo`

# Set MTproxy local port
while true
do
    dlport=8888
    echo -e "请输入本地端口"
    read -p "(默认本地端口: ${dlport}):" mtlocalport
    [ -z "$mtlocalport" ] && mtlocalport=${dlport}
    expr ${mtlocalport} + 1 &>/dev/null
    if [ $? -eq 0 ]; then
        if [ ${mtlocalport} -ge 1 ] && [ ${mtlocalport} -le 65535 ] && [ ${mtlocalport:0:1} != 0 ]; then
            echo
            echo "---------------------------"
            echo "   port = ${mtlocalport}   "
            echo "---------------------------"
            echo
            break
        fi
    fi
    echo -e "请输入正确的端口 [1-65535]"
done

# Set MTproxy client port
while true
do
    dcport=443
    echo -e "请输入客户端端口"
    read -p "(默认客户端端口: ${dcport}):" mtclientport
    [ -z "$mtclientport" ] && mtclientport=${dcport}
    expr ${mtclientport} + 1 &>/dev/null
    if [ $? -eq 0 ]; then
        if [ ${mtclientport} -ge 1 ] && [ ${mtclientport} -le 65535 ] && [ ${mtclientport:0:1} != 0 ]; then
            echo
            echo "---------------------------"
            echo "   port = ${mtclientport}  "
            echo "---------------------------"
            echo
            break
        fi
    fi
    echo -e "请输入正确的端口 [1-65535]"
done

echo "Press any key to start...or press Ctrl+C to cancel"
char=`get_char`

#Install dependencies
yum install openssl-devel zlib-devel
yum groupinstall "Development Tools"

#Clone the repo:
git clone https://github.com/TelegramMessenger/MTProxy
cd MTProxy

#To build, simply run make, the binary will be in objs/bin/mtproto-proxy:
make clean
make
cd objs/bin

#runnig
curl -s https://core.telegram.org/getProxySecret -o proxy-secret

curl -s https://core.telegram.org/getProxyConfig -o proxy-multi.conf

secert=`head -c 16 /dev/urandom | xxd -ps`

cat > /etc/systemd/system/MTProxy.service<<-EOF
[Unit]
Description=MTProxy
After=network.target

[Service]
Type=simple
WorkingDirectory=/root/MTProxy
ExecStart=/root/MTProxy/objs/bin/mtproto-proxy -u nobody -p ${mtlocalport} -H ${mtclientport} -S ${secert} --aes-pwd /root/MTProxy/objs/bin/proxy-secret /root/MTProxy/objs/bin/proxy-multi.conf -M 1
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

systemctl restart MTProxy.service

systemctl enable MTProxy.service

clear
echo -e "##########################################################################"
echo
echo
echo -e "您的密钥为：${secert}"
echo
echo -e "您的 tg MTproxy 代理应用内链接为："
echo
echo -e "tg://proxy?server=${serverip}&port=${mtclientport}&secret=${secert}"
echo
echo -e "您的 tg MTproxy 代理外部链接为："
echo
echo -e "https://t.me/proxy?server=${serverip}&port=${mtclientport}&secret=${secert}"
echo
echo
echo -e "###########################################################################"