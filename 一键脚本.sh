#!/bin/bash

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
PLAIN='\033[0m'

red(){
    echo -e "\033[31m\033[01m$1\033[0m"
}

green(){
    echo -e "\033[32m\033[01m$1\033[0m"
}

yellow(){
    echo -e "\033[33m\033[01m$1\033[0m"
}

REGEX=("debian" "ubuntu" "centos|red hat|kernel|oracle linux|alma|rocky" "'amazon linux'" "fedora")
RELEASE=("Debian" "Ubuntu" "CentOS" "CentOS" "Fedora")
PACKAGE_UPDATE=("apt-get update" "apt-get update" "yum -y update" "yum -y update" "yum -y update")
PACKAGE_INSTALL=("apt -y install" "apt -y install" "yum -y install" "yum -y install" "yum -y install")
PACKAGE_REMOVE=("apt -y remove" "apt -y remove" "yum -y remove" "yum -y remove" "yum -y remove")
PACKAGE_UNINSTALL=("apt -y autoremove" "apt -y autoremove" "yum -y autoremove" "yum -y autoremove" "yum -y autoremove")

CMD=("$(grep -i pretty_name /etc/os-release 2>/dev/null | cut -d \" -f2)" "$(hostnamectl 2>/dev/null | grep -i system | cut -d : -f2)" "$(lsb_release -sd 2>/dev/null)" "$(grep -i description /etc/lsb-release 2>/dev/null | cut -d \" -f2)" "$(grep . /etc/redhat-release 2>/dev/null)" "$(grep . /etc/issue 2>/dev/null | cut -d \\ -f1 | sed '/^[ ]*$/d')") 

for i in "${CMD[@]}"; do
    SYS="$i" && [[ -n $SYS ]] && break
done

for ((int = 0; int < ${#REGEX[@]}; int++)); do
    if [[ $(echo "$SYS" | tr '[:upper:]' '[:lower:]') =~ ${REGEX[int]} ]]; then
        SYSTEM="${RELEASE[int]}" && [[ -n $SYSTEM ]] && break
    fi
done

[[ $EUID -ne 0 ]] && red "注意：请在root用户下运行脚本" && exit 1
[[ -z $SYSTEM ]] && red "不支持VPS的当前系统，请使用主流操作系统" && exit 1


certificate(){
    clear
    echo -e " 即将进行Acme证书申请，请提前注册好Zerossl账号(邮箱)，并将VPS进行域名托管"
    echo -e " Zerossl网站介绍:https://app.zerossl.com/dashboard"
    echo " -------------"
    read -p "确定继续吗？(Y/N): " choice
    case "$choice" in
            [Yy])
              # 步骤1：安装域名证书申请脚本
              curl https://get.acme.sh | sh

              # 步骤2：检测80端口占用情况
              check_80

              # 步骤3：申请证书
              read -p "请输入你Zerossl账号: " youxiang
              ~/.acme.sh/acme.sh --register-account -m $youxiang

              read -p "请输入你的托管域名: " yuming
              ~/.acme.sh/acme.sh  --issue -d $yuming   --standalone

              # 步骤4：下载证书及密钥
              ~/.acme.sh/acme.sh --installcert -d $yuming --key-file /root/private.key --fullchain-file /root/cert.crt
              echo "/root/cert.crt   公钥"     
              echo "/root/private.key    密钥"
              ;;
            [Nn])
              echo "已取消" ;;
            *)
              echo "无效的选择，请输入 Y 或 N。" ;;
          esac
}

check_80(){
    if [[ -z $(type -P lsof) ]]; then
        ${PACKAGE_UPDATE[int]}
        ${PACKAGE_INSTALL[int]} lsof
    fi
    
    yellow "正在检测80端口是否占用..."
    sleep 1
    
    if [[  $(lsof -i:"80" | grep -i -c "listen") -eq 0 ]]; then
        green "检测到目前80端口未被占用"
        sleep 1
    else
        red "检测到目前80端口被其他程序被占用，以下为占用程序信息"
        lsof -i:"80"
        read -rp "如需结束占用进程请按Y，按其他键则退出 [Y/N]: " yn
        if [[ $yn =~ "Y"|"y" ]]; then
            lsof -i:"80" | awk '{print $2}' | grep -v "PID" | xargs kill -9
            sleep 1
        else
            exit 1
        fi
    fi
}



Alist(){
    clear
    echo -e " 1. Alist安装"
    echo -e " 2. Alist更新"
    echo -e " 3. Alist卸载"
    echo " -------------"
    echo -e " ${GREEN}0.${PLAIN} 返回上一级菜单"
    echo ""
    read -rp " 请输入选项 [0-3]:" menuInput
    case $menuInput in
        1) curl -fsSL "https://alist.nn.ci/v3.sh" | bash -s install ;;
        2) curl -fsSL "https://alist.nn.ci/v3.sh" | bash -s update ;;
        3) curl -fsSL "https://alist.nn.ci/v3.sh" | bash -s uninstall ;;
        0) menu4 ;;
        *) exit 1 ;;
    esac
}



BBR(){
    clear
    echo -e " 1. BBR加速4合一脚本"
    echo -e " 2. BBR3"
    echo -e " 3. 检测BBR是否开启"
    echo -e " 4. 检测BBR3是否开启"
    echo " -------------"
    echo -e " ${GREEN}0.${PLAIN} 返回上一级菜单"
    echo ""
    read -rp " 请输入选项 [0-4]:" menuInput
    case $menuInput in
        1) wget -N --no-check-certificate "https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/tcp.sh" && chmod +x tcp.sh && ./tcp.sh ;;
        2) 
          if dpkg -l | grep -q 'linux-xanmod'; then
            while true; do
                  clear
                  kernel_version=$(uname -r)
                  echo "您已安装xanmod的BBRv3内核"
                  echo "当前内核版本: $kernel_version"

                  echo ""
                  echo "内核管理"
                  echo "------------------------"
                  echo "1. 更新BBRv3内核              2. 卸载BBRv3内核"
                  echo "------------------------"
                  echo "0. 返回上一级选单"
                  echo "------------------------"
                  read -p "请输入你的选择: " sub_choice

                  case $sub_choice in
                      1)
                        apt purge -y 'linux-*xanmod1*'
                        update-grub

                        apt update -y
                        apt install -y wget gnupg

                        # wget -qO - https://dl.xanmod.org/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes
                        wget -qO - https://raw.githubusercontent.com/kejilion/sh/main/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes

                        # 步骤3：添加存储库
                        echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | tee /etc/apt/sources.list.d/xanmod-release.list

                        # version=$(wget -q https://dl.xanmod.org/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')
                        version=$(wget -q https://raw.githubusercontent.com/kejilion/sh/main/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')

                        apt update -y
                        apt install -y linux-xanmod-x64v$version

                        echo "XanMod内核已更新。重启后生效"
                        rm -f /etc/apt/sources.list.d/xanmod-release.list
                        rm -f check_x86-64_psabi.sh*

                        reboot

                          ;;
                      2)
                        apt purge -y 'linux-*xanmod1*'
                        update-grub
                        echo "XanMod内核已卸载。重启后生效"
                        reboot
                          ;;
                      0)
                          break  # 跳出循环，退出菜单
                          ;;

                      *)
                          break  # 跳出循环，退出菜单
                          ;;

                  esac
            done
        else

          clear
          echo "请备份数据，将为你升级Linux内核开启BBR3"
          echo "官网介绍: https://xanmod.org/"
          echo "------------------------------------------------"
          echo "仅支持Debian/Ubuntu 仅支持x86_64架构"
          echo "VPS是512M内存的，请提前添加1G虚拟内存，防止因内存不足失联！"
          echo "------------------------------------------------"
          read -p "确定继续吗？(Y/N): " choice

          case "$choice" in
            [Yy])
            if [ -r /etc/os-release ]; then
                . /etc/os-release
                if [ "$ID" != "debian" ] && [ "$ID" != "ubuntu" ]; then
                    echo "当前环境不支持，仅支持Debian和Ubuntu系统"
                    break
                fi
            else
                echo "无法确定操作系统类型"
                break
            fi

            # 检查系统架构
            arch=$(dpkg --print-architecture)
            if [ "$arch" != "amd64" ]; then
              echo "当前环境不支持，仅支持x86_64架构"
              break
            fi

            apt update -y
            apt install -y wget gnupg

            # wget -qO - https://dl.xanmod.org/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes
            wget -qO - https://raw.githubusercontent.com/kejilion/sh/main/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes

            # 步骤3：添加存储库
            echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | tee /etc/apt/sources.list.d/xanmod-release.list

            # version=$(wget -q https://dl.xanmod.org/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')
            version=$(wget -q https://raw.githubusercontent.com/kejilion/sh/main/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')

            apt update -y
            apt install -y linux-xanmod-x64v$version

            # 步骤5：启用BBR3
            	cat > /etc/sysctl.conf << EOF
            	net.core.default_qdisc=fq_pie
            	net.ipv4.tcp_congestion_control=bbr
EOF
            	sysctl -p
            echo "XanMod内核安装并BBR3启用成功。重启后生效"
            rm -f /etc/apt/sources.list.d/xanmod-release.list
            rm -f check_x86-64_psabi.sh*
            reboot

              ;;
            [Nn])
              echo "已取消"
              ;;
            *)
              echo "无效的选择，请输入 Y 或 N。"
              ;;
          esac
        fi
              ;;

        3) lsmod | grep bbr ;;
        4) depmod && modinfo tcp_bbr ;;
        0) menu1 ;;
        *) exit 1 ;;
    esac
}



setChinese(){
    chattr -i /etc/locale.gen
    cat > '/etc/locale.gen' << EOF
zh_CN.UTF-8 UTF-8
zh_TW.UTF-8 UTF-8
en_US.UTF-8 UTF-8
ja_JP.UTF-8 UTF-8
EOF
    locale-gen
    update-locale
    chattr -i /etc/default/locale
    cat > '/etc/default/locale' << EOF
LANGUAGE="zh_CN.UTF-8"
LANG="zh_CN.UTF-8"
LC_ALL="zh_CN.UTF-8"
EOF
    export LANGUAGE="zh_CN.UTF-8"
    export LANG="zh_CN.UTF-8"
    export LC_ALL="zh_CN.UTF-8"
}



view_cert(){
    [[ -z $(~/.acme.sh/acme.sh -v 2>/dev/null) ]] && yellow "未安装acme.sh, 无法执行操作!" && exit 1
    bash ~/.acme.sh/acme.sh --list
    back2menu
}



revoke_cert() {
    [[ -z $(~/.acme.sh/acme.sh -v 2>/dev/null) ]] && yellow "未安装acme.sh, 无法执行操作!" && exit 1
    bash ~/.acme.sh/acme.sh --list
    read -rp "请输入要撤销的域名证书 (复制Main_Domain下显示的域名): " domain
    [[ -z $domain ]] && red "未输入域名，无法执行操作!" && exit 1
    if [[ -n $(bash ~/.acme.sh/acme.sh --list | grep $domain) ]]; then
        bash ~/.acme.sh/acme.sh --revoke -d ${domain} --ecc
        bash ~/.acme.sh/acme.sh --remove -d ${domain} --ecc
        rm -rf ~/.acme.sh/${domain}_ecc
        rm -f /root/cert.crt /root/private.key
        green "撤销${domain}的域名证书成功"
        back2menu
    else
        red "未找到${domain}的域名证书, 请自行检查!"
        back2menu
    fi
}



switch_provider(){
    yellow "请选择证书提供商, 默认通过 Letsencrypt.org 来申请证书 "
    yellow "如果证书申请失败, 例如一天内通过 Letsencrypt.org 申请次数过多, 可选 BuyPass.com 或 ZeroSSL.com 来申请."
    echo -e " ${GREEN}1.${PLAIN} Letsencrypt.org"
    echo -e " ${GREEN}2.${PLAIN} BuyPass.com"
    echo -e " ${GREEN}3.${PLAIN} ZeroSSL.com"
    read -rp "请选择证书提供商 [1-3，默认1]: " provider
    case $provider in
        2) bash ~/.acme.sh/acme.sh --set-default-ca --server buypass && green "切换证书提供商为 BuyPass.com 成功！" ;;
        3) bash ~/.acme.sh/acme.sh --set-default-ca --server zerossl && green "切换证书提供商为 ZeroSSL.com 成功！" ;;
        *) bash ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt && green "切换证书提供商为 Letsencrypt.org 成功！" ;;
    esac
    back2menu
}



menu() {
    clear
    echo "#############################################################"
    echo -e "#                   ${RED}VPS科学上网环境搭建${PLAIN}                     #"
    echo -e "# ${GREEN}作者${PLAIN}: GDK                                                 #"
    echo -e "# ${GREEN}博客${PLAIN}: gdkvip.blogspot.com                                #"
    echo -e "# ${GREEN}GitHub${PLAIN}: https://github.com/Que-God                       #"
    echo "#############################################################"
    echo ""
    echo -e " ${GREEN}1.${PLAIN} VPS系统相关"
    echo -e " ${GREEN}2.${PLAIN} VPS流媒体解锁查询"
    echo -e " ${GREEN}3.${PLAIN} ACME证书相关"
    echo -e " ${GREEN}4.${PLAIN} 面板搭建"
	echo -e " ${GREEN}5.${PLAIN} 设置脚本启动快捷键"
    echo " -------------"
    echo -e " ${GREEN}0.${PLAIN} 退出脚本"
    read -rp "请输入选项 [0-5]: " NumberInput
    case "$NumberInput" in
        1) menu1 ;;
        2) menu2 ;;
        3) menu3 ;;
        4) menu4 ;;
        5) 
		    clear
            read -p "请输入你的快捷按键: " kuaijiejian
            echo "alias $kuaijiejian='curl -sS -O https://raw.githubusercontent.com/kejilion/sh/main/kejilion.sh && chmod +x kejilion.sh && ./kejilion.sh'" >> ~/.bashrc
            echo "快捷键已添加。请重新启动终端，或运行 'source ~/.bashrc' 以使修改生效。"
			;;
        0)
        clear
        exit
        ;;
        *)echo "无效的输入!"
    esac
}



menu1(){
    clear
	while true; do
    echo "#############################################################"
    echo -e "#                   ${RED}VPS系统相关${PLAIN}                             #"
    echo -e "# ${GREEN}作者${PLAIN}: GDK                                                 #"
    echo -e "# ${GREEN}博客${PLAIN}: gdkvip.blogspot.com                                 #"
    echo -e "# ${GREEN}GitHub${PLAIN}: https://github.com/Que-God                        #"
    echo "#############################################################"
    echo ""
    echo -e " ${GREEN}1.${PLAIN} 修改登录方式为 root + 密码"
    echo -e " ${GREEN}2.${PLAIN} 开放系统防火墙端口"
    echo -e " ${GREEN}3.${PLAIN} 切换系统语言为中文"
    echo -e " ${GREEN}4.${PLAIN} 安装更新运行环境(Debian/Ubuntu)"
    echo -e " ${GREEN}5.${PLAIN} BBR加速"
    echo -e " ${GREEN}6.${PLAIN} 一键DD系统"
    echo -e " ${GREEN}7.${PLAIN} 系统信息查询"
    echo " -------------"
    echo -e " ${GREEN}0.${PLAIN} 返回主菜单"
    echo ""
    read -rp " 请输入选项 [0-7]:" menuInput
    case $menuInput in
        1) wget -N --no-check-certificate https://raw.githubusercontent.com/misaka-gh/rootLogin/master/root.sh && bash root.sh ;;
        2)
            clear
            iptables -P INPUT ACCEPT
            iptables -P FORWARD ACCEPT
            iptables -P OUTPUT ACCEPT
            iptables -F

            apt purge -y iptables-persistent > /dev/null 2>&1
            apt purge -y ufw > /dev/null 2>&1
            yum remove -y firewalld > /dev/null 2>&1
            yum remove -y iptables-services > /dev/null 2>&1

            echo "端口已全部开放"

            ;;
        3) setChinese ;;
        4) apt update -y && apt install -y curl && apt install -y socat ;;
        5) BBR ;;
        6)
          clear
          echo "请备份数据，将为你重装系统，预计花费15分钟。"
          read -p "确定继续吗？(Y/N): " choice

          case "$choice" in
            [Yy])
              while true; do
                read -p "请选择要重装的系统:  1. Debian12 | 2. Ubuntu20.04 : " sys_choice

                case "$sys_choice" in
                  1)
                    xitong="-d 12"
                    break  # 结束循环
                    ;;
                  2)
                    xitong="-u 20.04"
                    break  # 结束循环
                    ;;
                  *)
                    echo "无效的选择，请重新输入。"
                    ;;
                esac
              done

              read -p "请输入你重装后的密码: " vpspasswd
              if command -v apt &>/dev/null; then
                  apt update -y && apt install -y wget
              elif command -v yum &>/dev/null; then
                  yum -y update && yum -y install wget
              else
                  echo "未知的包管理器!"
              fi
              bash <(wget --no-check-certificate -qO- 'https://moeclub.org/attachment/LinuxShell/InstallNET.sh') $xitong -v 64 -p $vpspasswd -port 22
              ;;
            [Nn])
              echo "已取消"
              ;;
            *)
              echo "无效的选择，请输入 Y 或 N。"
              ;;
          esac
              ;;

        7)
          clear
          # 函数: 获取IPv4和IPv6地址
          fetch_ip_addresses() {
            ipv4_address=$(curl -s ipv4.ip.sb)
            # ipv6_address=$(curl -s ipv6.ip.sb)
            ipv6_address=$(curl -s --max-time 2 ipv6.ip.sb)

          }

          # 获取IP地址
          fetch_ip_addresses

          if [ "$(uname -m)" == "x86_64" ]; then
            cpu_info=$(cat /proc/cpuinfo | grep 'model name' | uniq | sed -e 's/model name[[:space:]]*: //')
          else
            cpu_info=$(lscpu | grep 'Model name' | sed -e 's/Model name[[:space:]]*: //')
          fi

          cpu_usage=$(top -bn1 | grep 'Cpu(s)' | awk '{print $2 + $4}')
          cpu_usage_percent=$(printf "%.2f" "$cpu_usage")%

          cpu_cores=$(nproc)

          mem_info=$(free -b | awk 'NR==2{printf "%.2f/%.2f MB (%.2f%%)", $3/1024/1024, $2/1024/1024, $3*100/$2}')

          disk_info=$(df -h | awk '$NF=="/"{printf "%d/%dGB (%s)", $3,$2,$5}')

          country=$(curl -s ipinfo.io/country)
          city=$(curl -s ipinfo.io/city)

          isp_info=$(curl -s ipinfo.io/org)

          cpu_arch=$(uname -m)

          hostname=$(hostname)

          kernel_version=$(uname -r)

          congestion_algorithm=$(sysctl -n net.ipv4.tcp_congestion_control)
          queue_algorithm=$(sysctl -n net.core.default_qdisc)

          # 尝试使用 lsb_release 获取系统信息
          os_info=$(lsb_release -ds 2>/dev/null)

          # 如果 lsb_release 命令失败，则尝试其他方法
          if [ -z "$os_info" ]; then
            # 检查常见的发行文件
            if [ -f "/etc/os-release" ]; then
              os_info=$(source /etc/os-release && echo "$PRETTY_NAME")
            elif [ -f "/etc/debian_version" ]; then
              os_info="Debian $(cat /etc/debian_version)"
            elif [ -f "/etc/redhat-release" ]; then
              os_info=$(cat /etc/redhat-release)
            else
              os_info="Unknown"
            fi
          fi

          clear
          output=$(awk 'BEGIN { rx_total = 0; tx_total = 0 }
              NR > 2 { rx_total += $2; tx_total += $10 }
              END {
                  rx_units = "Bytes";
                  tx_units = "Bytes";
                  if (rx_total > 1024) { rx_total /= 1024; rx_units = "KB"; }
                  if (rx_total > 1024) { rx_total /= 1024; rx_units = "MB"; }
                  if (rx_total > 1024) { rx_total /= 1024; rx_units = "GB"; }

                  if (tx_total > 1024) { tx_total /= 1024; tx_units = "KB"; }
                  if (tx_total > 1024) { tx_total /= 1024; tx_units = "MB"; }
                  if (tx_total > 1024) { tx_total /= 1024; tx_units = "GB"; }

                  printf("总接收: %.2f %s\n总发送: %.2f %s\n", rx_total, rx_units, tx_total, tx_units);
              }' /proc/net/dev)


          current_time=$(date "+%Y-%m-%d %I:%M %p")


          swap_used=$(free -m | awk 'NR==3{print $3}')
          swap_total=$(free -m | awk 'NR==3{print $2}')

          if [ "$swap_total" -eq 0 ]; then
              swap_percentage=0
          else
              swap_percentage=$((swap_used * 100 / swap_total))
          fi

          swap_info="${swap_used}MB/${swap_total}MB (${swap_percentage}%)"

          runtime=$(cat /proc/uptime | awk -F. '{run_days=int($1 / 86400);run_hours=int(($1 % 86400) / 3600);run_minutes=int(($1 % 3600) / 60); if (run_days > 0) printf("%d天 ", run_days); if (run_hours > 0) printf("%d时 ", run_hours); printf("%d分\n", run_minutes)}')

          echo ""
          echo "系统信息查询"
          echo "------------------------"
          echo "主机名: $hostname"
          echo "运营商: $isp_info"
          echo "------------------------"
          echo "系统版本: $os_info"
          echo "Linux版本: $kernel_version"
          echo "------------------------"
          echo "CPU架构: $cpu_arch"
          echo "CPU型号: $cpu_info"
          echo "CPU核心数: $cpu_cores"
          echo "------------------------"
          echo "CPU占用: $cpu_usage_percent"
          echo "物理内存: $mem_info"
          echo "虚拟内存: $swap_info"
          echo "硬盘占用: $disk_info"
          echo "------------------------"
          echo "$output"
          echo "------------------------"
          echo "网络拥堵算法: $congestion_algorithm $queue_algorithm"
          echo "------------------------"
          echo "公网IPv4地址: $ipv4_address"
          echo "公网IPv6地址: $ipv6_address"
          echo "------------------------"
          echo "地理位置: $country $city"
          echo "系统时间: $current_time"
          echo "------------------------"
          echo "系统运行时长: $runtime"
          echo

          ;;
		0) menu ;;
        *) echo "无效的输入!" ;;
    esac
    echo -e "\033[0;32m操作完成\033[0m"
    echo "按任意键继续..."
    read -n 1 -s -r -p ""
    echo ""
    clear
    done
    ;;
}



menu2(){
    clear
	while true; do
    echo "#############################################################"
    echo -e "#                   ${RED}VPS流媒体解锁查询${PLAIN}                      #"
    echo -e "# ${GREEN}作者${PLAIN}: GDK                                             #"
    echo -e "# ${GREEN}博客${PLAIN}: gdkvip.blogspot.com                                #"
    echo -e "# ${GREEN}GitHub${PLAIN}: https://github.com/Que-God                       #"
    echo "#############################################################"
    echo ""
    echo -e " ${GREEN}1.${PLAIN} VPS流媒体全功能测试"
    echo -e " ${GREEN}2.${PLAIN} VPS奈飞解锁查询"
    echo -e " ${GREEN}3.${PLAIN} ChatGPT解锁状态检测"
    echo " -------------"
    echo -e " ${GREEN}0.${PLAIN} 返回主菜单"
    echo ""
    read -rp " 请输入选项 [0-3]:" menuInput
    case $menuInput in
        1) bash <(curl -L -s https://raw.githubusercontent.com/lmc999/RegionRestrictionCheck/main/check.sh) ;;
        2) wget -O nf https://github.com/sjlleo/netflix-verify/releases/download/v3.1.0/nf_linux_amd64 && chmod +x nf && ./nf ;;
        3)
            clear
            bash <(curl -Ls https://cdn.jsdelivr.net/gh/missuo/OpenAI-Checker/openai.sh)
            ;;
        0) menu ;;
        *) echo "无效的输入!" ;;
    esac
    echo -e "\033[0;32m操作完成\033[0m"
    echo "按任意键继续..."
    read -n 1 -s -r -p ""
    echo ""
    clear
    done
    ;;
}



menu3(){
    clear
	while true; do
    echo "#############################################################"
    echo -e "#                   ${RED}ACME证书相关${PLAIN}                           #"
    echo -e "# ${GREEN}作者${PLAIN}: GDK                                               #"
    echo -e "# ${GREEN}博客${PLAIN}: gdkvip.blogspot.com                                 #"
    echo -e "# ${GREEN}GitHub${PLAIN}: https://github.com/Que-God                        #"
    echo "#############################################################"
    echo ""
    echo -e " ${GREEN}1.${PLAIN} 证书申请"
    echo -e " ${GREEN}2.${PLAIN} 查看已申请的证书"
    echo -e " ${GREEN}3.${PLAIN} 撤销并删除已申请的证书"
    echo -e " ${GREEN}4.${PLAIN} 切换证书颁发机构"
    echo " -------------"
    echo -e " ${GREEN}0.${PLAIN} 返回主菜单"
    echo ""
    read -rp " 请输入选项 [0-4]:" menuInput
    case $menuInput in
        1) certificate ;;
        2) view_cert ;;
        3) revoke_cert ;;
        4) switch_provider ;;
        0) menu ;;
        *) echo "无效的输入!" ;;
    esac
    echo -e "\033[0;32m操作完成\033[0m"
    echo "按任意键继续..."
    read -n 1 -s -r -p ""
    echo ""
    clear
    done
    ;;
}



menu4(){
    clear
	while true; do
    echo "#############################################################"
    echo -e "#                   ${RED}常用面板搭建${PLAIN}                            #"
    echo -e "# ${GREEN}作者${PLAIN}: GDK                                                 #"
    echo -e "# ${GREEN}博客${PLAIN}: gdkvip.blogspot.com                                 #"
    echo -e "# ${GREEN}GitHub${PLAIN}: https://github.com/Que-God                        #"
    echo "#############################################################"
    echo ""
    echo -e " ${GREEN}1.${PLAIN} X-UI面板"
    echo -e " ${GREEN}2.${PLAIN} Alist面板"
    echo " -------------"
    echo -e " ${GREEN}0.${PLAIN} 返回主菜单"
    echo ""
    read -rp " 请输入选项 [0-2]:" menuInput
    case $menuInput in
        1) bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh) ;;
        2) Alist ;;
        0) menu ;;
        *) echo "无效的输入!" ;;
    esac
    echo -e "\033[0;32m操作完成\033[0m"
    echo "按任意键继续..."
    read -n 1 -s -r -p ""
    echo ""
    clear
    done
    ;;
}