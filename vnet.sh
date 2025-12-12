#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	Vnet-Tunnel一键安装脚本
#	Version: 1.2
#=================================================
sh_ver="1.2"

Green_font_prefix="\033[32m" && hongsewenzi="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
address="${Green_font_prefix}[管理地址]${Font_color_suffix}"
Error="${hongsewenzi}[错误]${Font_color_suffix}"
yunyi_end="重启服务器会导致数据丢失，为了稳定运行请尽可能保证服务器稳定。
执行${Green_font_prefix}vnet${Font_color_suffix}命令会再次启动此脚本"

FIREWALL_SAVE_CMD="service iptables save"
CONFIG_FILE="/root/.vnet.conf"
CLIENT_WEB_PORT=8080
SERVER_WEB_PORT=8081

save_firewall(){
    if command -v netfilter-persistent >/dev/null 2>&1; then
        netfilter-persistent save
    else
        ${FIREWALL_SAVE_CMD} >/dev/null 2>&1 || { mkdir -p /etc/iptables; iptables-save > /etc/iptables/rules.v4; }
    fi
}

load_config(){
    if [ -f "${CONFIG_FILE}" ]; then
        . "${CONFIG_FILE}"
    fi
    CLIENT_WEB_PORT=${CLIENT_WEB_PORT:-8080}
    SERVER_WEB_PORT=${SERVER_WEB_PORT:-8081}
}

save_config(){
    cat > "${CONFIG_FILE}" <<EOF
CLIENT_WEB_PORT=${CLIENT_WEB_PORT}
SERVER_WEB_PORT=${SERVER_WEB_PORT}
EOF
}

get_ipv4(){
    local ip=""
    if command -v curl >/dev/null 2>&1; then
        ip=$(curl -4 -s icanhazip.com || curl -4 -s ipinfo.io/ip || curl -4 -s ifconfig.me)
    fi
    if [ -z "$ip" ]; then
        ip=$(hostname -I | tr ' ' '\n' | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -n1)
    fi
    echo "$ip"
}
refresh_server_ip(){
    SERVER_IP="$(get_ipv4)"
}

require_root(){
    if [ "$(id -u)" != "0" ]; then
        echo -e "${hongsewenzi}请使用root权限运行${Font_color_suffix}"
        exit 1
    fi
}

get_unit_state(){
    local unit="$1"
    local state=""
    if command -v systemctl >/dev/null 2>&1; then
        state="$(systemctl show -p ActiveState --value "$unit" 2>/dev/null | head -n1)"
        if [ -z "$state" ]; then
            state="$(systemctl is-active "$unit" 2>/dev/null | head -n1)"
        fi
    fi
    [ -z "$state" ] && state="unknown"
    echo "$state"
}

setup_systemd_client(){
    if command -v systemctl >/dev/null 2>&1; then
        cat >/etc/systemd/system/vnet-client.service <<'EOF'
[Unit]
Description=Vnet Client
After=network-online.target
Wants=network-online.target

[Service]
WorkingDirectory=/root
ExecStart=/root/client
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
        systemctl daemon-reload
        systemctl enable --now vnet-client.service
        return 0
    fi
    return 1
}

setup_systemd_server(){
    if command -v systemctl >/dev/null 2>&1; then
        cat >/etc/systemd/system/vnet-server.service <<'EOF'
[Unit]
Description=Vnet Server
After=network-online.target
Wants=network-online.target

[Service]
WorkingDirectory=/root
ExecStart=/root/server
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
        systemctl daemon-reload
        systemctl enable --now vnet-server.service
        return 0
    fi
    return 1
}

#开始菜单
start_menu(){
  clear
echo && echo -e " Vnet隧道一键安装脚本(1.2)
  
————————————请选择安装类型————————————
 ${Green_font_prefix}1.${Font_color_suffix} 安装控制端(普通机器)
 ${Green_font_prefix}2.${Font_color_suffix} 安装控制端(NAT机器) 
 ${Green_font_prefix}3.${Font_color_suffix} 安装服务端
————————————其他功能/杂项————————————
 ${Green_font_prefix}4.${Font_color_suffix} 重启控制端
 ${Green_font_prefix}5.${Font_color_suffix} 重启服务端
 ${Green_font_prefix}6.${Font_color_suffix} 启用/停用web管理(防火墙)
 ${Green_font_prefix}7.${Font_color_suffix} 卸载控制端
 ${Green_font_prefix}8.${Font_color_suffix} 卸载服务端
 ${Green_font_prefix}9.${Font_color_suffix} 查看状态
 ${Green_font_prefix}10.${Font_color_suffix} 设置端口
 ${Green_font_prefix}0.${Font_color_suffix} 退出脚本
————————————————————————————————" && echo

 	
echo
read -p " 请输入数字 [0-10]:" num
case "$num" in
	1)
	check_sys_clinet
	;;
	2)
	check_sys_natclinet
	;;
	3)
	install_server
	;;
	4)
	chongqi_client
	;;
	5)
	chongqi_server
	;;
	6)
	onoffweb
	;;
	7)
	xiezai_client
	;;
	8)
	xiezai_server
	;;
	9)
	show_status
	;;
	10)
	set_ports
	;;
	0)
	exit 1
	;;
	*)
	clear
	echo -e "${Error}:请输入正确数字 [0-10]"
	sleep 5s
	start_menu
	;;
esac
}

#安装普通控制端
check_sys_clinet(){
	suidaoanquan
    wget -N --no-check-certificate "https://xlzcloud.oss-cn-beijing.aliyuncs.com/tunnel.zip" 
	unzip tunnel.zip
	chmod -R +x ./*
    setup_systemd_client || nohup ./client >> /dev/null 2>&1 &
    kuaijiemingling
	clear
    refresh_server_ip
    echo -e "控制端安装完成，请使用浏览器打开网址进行配置"
    echo -e ${address}
	echo -e ${Green_font_prefix}"http://${SERVER_IP}:${CLIENT_WEB_PORT}/resources/add_client.html"${Font_color_suffix}
    echo -e $yunyi_end
}

#安装nat控制端
check_sys_natclinet(){
	echo;read -p "请设置管理端口(该端口将被占用):" portzhuanfa
    suidaoanquan
	iptables -t nat -C PREROUTING -p tcp --dport ${portzhuanfa} -j REDIRECT --to-port ${CLIENT_WEB_PORT} >/dev/null 2>&1 || iptables -t nat -A PREROUTING -p tcp --dport ${portzhuanfa} -j REDIRECT --to-port ${CLIENT_WEB_PORT}
	save_firewall
    wget -N --no-check-certificate "https://xlzcloud.oss-cn-beijing.aliyuncs.com/tunnel.zip" 
	unzip tunnel.zip
	chmod -R +x ./*
    setup_systemd_client || nohup ./client >> /dev/null 2>&1 &
	kuaijiemingling
	clear
    refresh_server_ip
    echo -e "控制端安装完成，请使用浏览器打开网址进行配置"
	echo -e ${address}
    echo -e ${Green_font_prefix}"http://${SERVER_IP}:${portzhuanfa}/resources/add_client.html"${Font_color_suffix}
	echo -e $yunyi_end
}

#安装服务端
install_server(){
	suidaoanquan
    wget -N --no-check-certificate "https://xlzcloud.oss-cn-beijing.aliyuncs.com/tunnel.zip" && unzip tunnel.zip && chmod -R +x ./*
    setup_systemd_server || nohup ./server >> /dev/null 2>&1 &
    kuaijiemingling
	clear
    refresh_server_ip
	echo -e "服务端安装完成，请使用浏览器打开网址进行配置"
	echo -e ${address}
    echo -e ${Green_font_prefix}"http://${SERVER_IP}:${SERVER_WEB_PORT}/resources/add_server.html"${Font_color_suffix}
	echo -e $yunyi_end
}

#重启客户端
chongqi_client(){
    cd /root
    if command -v systemctl >/dev/null 2>&1 && systemctl status vnet-client.service >/dev/null 2>&1; then
        systemctl restart vnet-client.service
    else
        if command -v killall >/dev/null 2>&1; then killall client; else pkill -x client; fi
        nohup ./client >> /dev/null 2>&1 &
    fi
	echo -e ${Green_font_prefix}"重启完成-请重新添加配置"${Font_color_suffix}
	echo -e ${Green_font_prefix}"http://${SERVER_IP}:${CLIENT_WEB_PORT}/resources/add_client.html"${Font_color_suffix}
}

#重启服务端
chongqi_server(){
    cd /root
    if command -v systemctl >/dev/null 2>&1 && systemctl status vnet-server.service >/dev/null 2>&1; then
        systemctl restart vnet-server.service
    else
        if command -v killall >/dev/null 2>&1; then killall server; else pkill -x server; fi
    	nohup ./server >> /dev/null 2>&1 &
    fi
	echo -e ${Green_font_prefix}"重启完成-请重新添加配置"${Font_color_suffix}
	echo -e ${Green_font_prefix}"http://${SERVER_IP}:${SERVER_WEB_PORT}/resources/add_server.html"${Font_color_suffix}
}

#开启关闭web访问
onoffweb(){
  clear
echo && echo -e " 安全部分，开启或关闭8080/8081端口
 实现web页面开关，避免他人恶意篡改 
  
————————————请选择要执行的功能————————————
 ${Green_font_prefix}1.${Font_color_suffix} 开启web页面访问
 ${Green_font_prefix}2.${Font_color_suffix} 关闭web页面访问 
 ${Green_font_prefix}3.${Font_color_suffix} 返回上级菜单

————————————————————————————————"&& echo

	
echo
read -p " 请输入数字 [1-3]:" num2
case "$num2" in
	1)
    OnWeb
	;;
	2)
    OffWeb
	;;
	3)
	start_menu
	;;
	*)
	clear
	echo -e "${Error}:请输入正确数字 [1-3]"
	sleep 5s
	onoffweb
	;;	
esac
}
#开启关闭web
OnWeb(){
	iptables -D INPUT -p tcp --dport 8080 -j ACCEPT
    iptables -D INPUT -p tcp --dport 8081 -j ACCEPT
	iptables -D INPUT -p tcp -m tcp --dport 8081 -j DROP
    iptables -D INPUT -p tcp -m tcp --dport 8080 -j DROP
    iptables -D INPUT -p tcp --dport ${CLIENT_WEB_PORT} -j ACCEPT
    iptables -D INPUT -p tcp --dport ${SERVER_WEB_PORT} -j ACCEPT
	iptables -D INPUT -p tcp -m tcp --dport ${SERVER_WEB_PORT} -j DROP
    iptables -D INPUT -p tcp -m tcp --dport ${CLIENT_WEB_PORT} -j DROP
	iptables -A INPUT -p tcp --dport ${CLIENT_WEB_PORT} -j ACCEPT
	iptables -A INPUT -p tcp --dport ${SERVER_WEB_PORT} -j ACCEPT
	clear
	echo -e "防火墙设置完成"
	echo -e ${Green_font_prefix}"已开启web访问"${Font_color_suffix}
	echo -e "如果客户端使用NAT机器，自行将8080替换成你自己的端口"
    refresh_server_ip
	echo -e 客户端 ${Green_font_prefix}"http://${SERVER_IP}:${CLIENT_WEB_PORT}/resources/add_client.html"${Font_color_suffix}
	echo -e 服务端 ${Green_font_prefix}"http://${SERVER_IP}:${SERVER_WEB_PORT}/resources/add_server.html"${Font_color_suffix}
    save_firewall
}
OffWeb(){
	iptables -D INPUT -p tcp --dport 8080 -j ACCEPT
    iptables -D INPUT -p tcp --dport 8081 -j ACCEPT
	iptables -D INPUT -p tcp -m tcp --dport 8081 -j DROP
    iptables -D INPUT -p tcp -m tcp --dport 8080 -j DROP
    iptables -D INPUT -p tcp --dport ${CLIENT_WEB_PORT} -j ACCEPT
    iptables -D INPUT -p tcp --dport ${SERVER_WEB_PORT} -j ACCEPT
	iptables -D INPUT -p tcp -m tcp --dport ${SERVER_WEB_PORT} -j DROP
    iptables -D INPUT -p tcp -m tcp --dport ${CLIENT_WEB_PORT} -j DROP
	iptables -A INPUT -p tcp -m tcp --dport ${CLIENT_WEB_PORT} -j DROP
    iptables -A INPUT -p tcp -m tcp --dport ${SERVER_WEB_PORT} -j DROP
	clear
	echo -e "防火墙设置完成"
	echo -e ${hongsewenzi}"已关闭web访问"${Font_color_suffix}
    save_firewall
}
#防火墙和必要组件
suidaoanquan(){
    if [ -f /etc/os-release ]; then . /etc/os-release; fi
    if [[ "$ID" == "centos" || "$ID_LIKE" == *"rhel"* ]]; then
        systemctl stop firewalld 2>/dev/null
        systemctl mask firewalld 2>/dev/null
        yum install -y iptables iptables-services zip unzip curl wget psmisc
        FIREWALL_SAVE_CMD="service iptables save"
    else
        apt-get update -y
        apt-get install -y iptables iptables-persistent zip unzip curl wget psmisc
        FIREWALL_SAVE_CMD="netfilter-persistent save"
    fi
    iptables -F
    iptables -X
    iptables -P INPUT ACCEPT
    if command -v netfilter-persistent >/dev/null 2>&1; then
        netfilter-persistent save
    else
        ${FIREWALL_SAVE_CMD} >/dev/null 2>&1 || { mkdir -p /etc/iptables; iptables-save > /etc/iptables/rules.v4; }
    fi
    echo -e "防火墙设置完成"
    cd /root/
    rm -rf /root/client
    rm -rf /root/resources
    rm -rf /root/server
    rm -rf /root/tunnel.zip
}

xiezai_client(){
    if command -v systemctl >/dev/null 2>&1 && [ -f /etc/systemd/system/vnet-client.service ]; then
        systemctl disable --now vnet-client.service >/dev/null 2>&1
        rm -f /etc/systemd/system/vnet-client.service
        systemctl daemon-reload
    fi
    cd /root/
    rm -rf /root/client
    echo -e ${Green_font_prefix}"已卸载控制端"${Font_color_suffix}
}

xiezai_server(){
    if command -v systemctl >/dev/null 2>&1 && [ -f /etc/systemd/system/vnet-server.service ]; then
        systemctl disable --now vnet-server.service >/dev/null 2>&1
        rm -f /etc/systemd/system/vnet-server.service
        systemctl daemon-reload
    fi
    cd /root/
    rm -rf /root/server
    echo -e ${Green_font_prefix}"已卸载服务端"${Font_color_suffix}
}

show_status(){
    refresh_server_ip
    echo -e "IP: ${SERVER_IP}"
    if command -v systemctl >/dev/null 2>&1; then
        client_state="$(get_unit_state vnet-client.service)"
        server_state="$(get_unit_state vnet-server.service)"
        echo -e "客户端: ${client_state}"
        echo -e "服务端: ${server_state}"
    else
        if pgrep -x client >/dev/null 2>&1; then echo -e "客户端: 运行中"; else echo -e "客户端: 未运行"; fi
        if pgrep -x server >/dev/null 2>&1; then echo -e "服务端: 运行中"; else echo -e "服务端: 未运行"; fi
    fi
    if [ "${client_state}" = "active" ]; then
        echo -e 客户端 ${Green_font_prefix}"http://${SERVER_IP}:${CLIENT_WEB_PORT}/resources/add_client.html"${Font_color_suffix}
    fi
    if [ "${server_state}" = "active" ] || [ "${server_state}" = "activating" ]; then
        echo -e 服务端 ${Green_font_prefix}"http://${SERVER_IP}:${SERVER_WEB_PORT}/resources/add_server.html"${Font_color_suffix}
    fi
}

set_ports(){
    echo -e "当前客户端端口: ${CLIENT_WEB_PORT}, 服务端端口: ${SERVER_WEB_PORT}"
    read -p "请输入新的客户端端口(回车保留当前): " new_client_port
    read -p "请输入新的服务端端口(回车保留当前): " new_server_port
    if [ -n "$new_client_port" ]; then
        if echo "$new_client_port" | grep -Eq '^[0-9]{1,5}$' && [ "$new_client_port" -ge 1 ] && [ "$new_client_port" -le 65535 ]; then
            CLIENT_WEB_PORT="$new_client_port"
        else
            echo -e "${Error}:客户端端口不合法"
            sleep 2
        fi
    fi
    if [ -n "$new_server_port" ]; then
        if echo "$new_server_port" | grep -Eq '^[0-9]{1,5}$' && [ "$new_server_port" -ge 1 ] && [ "$new_server_port" -le 65535 ]; then
            SERVER_WEB_PORT="$new_server_port"
        else
            echo -e "${Error}:服务端端口不合法"
            sleep 2
        fi
    fi
    save_config
    refresh_server_ip
    echo -e ${Green_font_prefix}"已更新端口"${Font_color_suffix}
    echo -e 客户端 ${Green_font_prefix}"http://${SERVER_IP}:${CLIENT_WEB_PORT}/resources/add_client.html"${Font_color_suffix}
    echo -e 服务端 ${Green_font_prefix}"http://${SERVER_IP}:${SERVER_WEB_PORT}/resources/add_server.html"${Font_color_suffix}
}
#添加快捷启动命令
kuaijiemingling(){
sed -i "s/alias vnet='bash \/root\/vnet.sh'//g"  ~/.bashrc
echo "alias vnet='bash /root/vnet.sh'" >> ~/.bashrc
source ~/.bashrc
}

#这里开始
require_root
load_config
cd /root/
start_menu
