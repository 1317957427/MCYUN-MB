#!/bin/bash
# 检查当前用户是否为 root 用户
if [ $(id -u) -ne 0 ]; then
    echo -e "\033[31m需要 root 权限执行此脚本，请使用 sudo 或者切换到 root 用户。\033[0m"
    exit 1
fi
# 如果当前用户是 root 用户，则执行脚本的主体部分
echo -e "\033[33m当前用户是 root 用户，开始执行 MCSManager 安装脚本。\033[0m"
# Config
mcsmanager_install_path="/opt/mcsmanager"
mcsmanager_donwload_addr="https://github.com/1317957427/MCYUN-MB/releases/download/V1.0/mcsmanager_linux_release.tar.gz"
node="v14.19.1"
zh=$(
    [[ $(locale -a) =~ "zh" ]] && echo 1
    export LANG=zh_CN.UTF-8 || echo 0
)

error=""
arch=$(uname -m)

printf "\033c"

# print func
echo_cyan() {
  printf '\033[1;36m%b\033[0m\n' "$@"
}
echo_red() {
  printf '\033[1;31m%b\033[0m\n' "$@"
}

echo_green() {
  printf '\033[1;32m%b\033[0m\n' "$@"
}

echo_cyan_n() {
  printf '\033[1;36m%b\033[0m' "$@"
}

echo_yellow() {
  printf '\033[1;33m%b\033[0m\n' "$@"
}

# script info
echo_cyan "+----------------------------------------------------------------------
| MC云 Installer
+----------------------------------------------------------------------
| Copyright © 2023 MC云.
+----------------------------------------------------------------------
| Contributors: Nuomiaa, CreeperKong, Unitwk, FunnyShadow
+----------------------------------------------------------------------

We will use servers in the USA to speed up your installation!
我们将使用美国地区的服务器来加速您的安装速度！
"

Red_Error() {
  echo '================================================='
  printf '\033[1;31;40m%b\033[0m\n' "$@"
  echo '================================================='
  exit 1
}


Install_Node() {
  echo_cyan_n "[+] 正在安装 Node.JS... "

  rm -irf "$node_install_path"

  cd /opt || exit

  rm -rf  node-"$node"-linux-"$arch".tar.gz

  wget https://npmmirror.com/mirrors/node/"$node"/node-"$node"-linux-"$arch".tar.gz

  tar -zxf node-"$node"-linux-"$arch".tar.gz

  rm -rf node-"$node"-linux-"$arch".tar.gz

  if [ -f "$node_install_path"/bin/node ] && [ "$("$node_install_path"/bin/node -v)" == "$node" ]
  then
    echo_green "Success"
  else
    echo_red "Failed"
    Red_Error "[x] Node 安装失败!"
  fi

  echo
  echo_yellow "=============== 欢迎使用 Node.JS ==============="
  echo_yellow " node: $("$node_install_path"/bin/node -v)"
  echo_yellow " npm: v$(/usr/bin/env "$node_install_path"/bin/node "$node_install_path"/bin/npm -v)"
  echo_yellow "=============== 安装成功 Node.JS ==============="
  echo

  sleep 3
}


Install_MCSManager() {
  echo_cyan "[+] 正在安装 MC云面板..."

  # stop service
  systemctl stop mcsm-{web,daemon}

  # delete service
  rm -rf /etc/systemd/system/mcsm-daemon.service
  rm -rf /etc/systemd/system/mcsm-web.service
  systemctl daemon-reload

  mkdir -p ${mcsmanager_install_path} || exit

  # cd /opt/mcsmanager
  cd ${mcsmanager_install_path} || exit


  # donwload MCSManager release
  wget ${mcsmanager_donwload_addr}
  tar -zxf mcsmanager_linux_release.tar.gz -o
  rm -rf "${mcsmanager_install_path}/mcsmanager_linux_release.tar.gz"
  
  # echo "[→] cd daemon"
  cd daemon || exit

  echo_cyan "[+] 正在安装 MC云-守护程序..."
  /usr/bin/env "$node_install_path"/bin/node "$node_install_path"/bin/npm install  --registry=https://registry.npmmirror.com --production > npm_install_log

  # echo "[←] cd .."
  cd ../web || exit

  echo_cyan "[+] 正在安装 MC云-网页面板..."
  /usr/bin/env "$node_install_path"/bin/node "$node_install_path"/bin/npm install  --registry=https://registry.npmmirror.com --production > npm_install_log

  echo
  echo_yellow "=============== 欢迎使用 MC云 面板 ==============="
  echo_green " Daemon: ${mcsmanager_install_path}/daemon"
  echo_green " Web: ${mcsmanager_install_path}/web"
  echo_yellow "=============== 安装成功 MC云 面板 ==============="
  echo
  echo_green "[+] MC云-面板 安装成功!"

  sleep 3
}

Create_Service() {
  echo_cyan "[+] 创建 MC云 服务成功..."

  echo "
[Unit]
Description=MCSManager Daemon

[Service]
WorkingDirectory=/opt/mcsmanager/daemon
ExecStart=${node_install_path}/bin/node app.js
ExecReload=/bin/kill -s QUIT $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
Environment=\"PATH=${PATH}\"

[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/mcsm-daemon.service

  echo "
[Unit]
Description=MCSManager Web

[Service]
WorkingDirectory=/opt/mcsmanager/web
ExecStart=${node_install_path}/bin/node app.js
ExecReload=/bin/kill -s QUIT $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
Environment=\"PATH=${PATH}\"

[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/mcsm-web.service

  systemctl daemon-reload
  systemctl enable mcsm-daemon.service --now
  systemctl enable mcsm-web.service --now

  sleep 3

  printf "\n\n"
  echo_yellow "=================================================================="
  if [ "$zh" == 1 ]; then
    echo_green "安装已完成！欢迎使用 MC云 面板！"
    echo_yellow " "
    echo_cyan_n "控制面板地址：   "
    echo_yellow "http://你的公网IP:23333"
    echo_red "你必须开放 23333（面板）和 24444（守护进程用）端口，控制面板需要这两个端口才能正常工作。"
    echo_yellow " "
    echo_cyan "下面是常用的几个命令："
    echo_cyan "启动面板 systemctl start mcsm-{daemon,web}.service"
    echo_cyan "停止面板 systemctl stop mcsm-{daemon,web}.service"
    echo_cyan "重启面板 systemctl restart mcsm-{daemon,web}.service"
    echo_yellow " "
    echo_cyan "官方文档（必读）：https://www.mcwzsc.shop/"
    echo_yellow "=================================================================="
  else
    echo_yellow "=================================================================="
    echo_green "Installation is complete! Welcome to the MCYUN panel!"
    echo_yellow " "
    echo_cyan_n "HTTP Web Service:        "; echo_yellow "http://<Your IP>:23333"
    echo_cyan_n "Daemon Address:          "; echo_yellow "ws://<Your IP>:24444"
    echo_red "You must expose ports 23333 and 24444 to use the service properly on the Internet."
    echo_yellow " "
    echo_cyan "Usage:"
    echo_cyan "systemctl start mcsm-{daemon,web}.service"
    echo_cyan "systemctl stop mcsm-{daemon,web}.service"
    echo_cyan "systemctl restart mcsm-{daemon,web}.service"
    echo_yellow " "
    echo_green "Official Document: https://www.mcwzsc.shop/"
    echo_yellow "=================================================================="
  fi
}



# Environmental inspection
if [ "$arch" == x86_64 ]; then
  arch=x64
  #echo "[-] x64 architecture detected"
elif [ $arch == aarch64 ]; then
  arch=arm64
  #echo "[-] 64-bit ARM architecture detected"
elif [ $arch == arm ]; then
  arch=armv7l
  #echo "[-] 32-bit ARM architecture detected"
elif [ $arch == ppc64le ]; then
  arch=ppc64le
  #echo "[-] IBM POWER architecture detected"
elif [ $arch == s390x ]; then
  arch=s390x
  #echo "[-] IBM LinuxONE architecture detected"
else
  Red_Error "[x] 安装失败,安装失败,不知道为什么,阿巴阿巴!"
  Red_Error "[x] 安装失败试试手动安装吧: https://github.com/1317957427/MCYUN-MB"
  exit
fi

# Define the variable Node installation directory
node_install_path="/opt/node-$node-linux-$arch"

# Check network connection
echo_cyan "[-] 网络问题,网络问题请换一个网络试试看: $arch"

# Install related software
echo_cyan_n "[+] 正在安装依赖库(git,tar)... "
if [ -x "$(command -v yum)" ]; then yum install -y git tar > error;
elif [ -x "$(command -v apt-get)" ]; then apt-get install -y git tar > error;
elif [ -x "$(command -v pacman)" ]; then pacman -Syu --noconfirm git tar > error;
elif [ -x "$(command -v zypper)" ]; then sudo zypper --non-interactive install git tar > error;
fi

# Determine whether the relevant software is installed successfully
if [[ -x "$(command -v git)" && -x "$(command -v tar)" ]]
  then
    echo_green "Success"
  else
    echo_red "Failed"
    echo "$error"
    Red_Error "[x] 安装失败,请手动安装 git 和 tar 就可以了!"
    exit
fi


# Install the Node environment
Install_Node

# Install MCSManager
Install_MCSManager

# Create MCSManager background service
Create_Service
