#!/bin/bash

set +e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}[!] 请使用 root 用户运行该脚本！${NC}"
    exit 1
fi

BANNER="
#########################################################
#                    CTF_ENV                            #
#               用于快速安装和配置各种安全工具          #
#                                                       #
#                                   Version: 1.0.0      #
#                                   Author: iami233     #
#             Repo: https://github.com/5ime/ctf_env     #
#########################################################
"

echo -e "${CYAN}$BANNER${NC}"

installTools() {
    echo -e "${CYAN}[+] 安装必要工具...${NC}"
    apt install -y git libssl-dev libffi-dev build-essential libpcap-dev libmcrypt4 libmhash2
    if [ $? -ne 0 ]; then
        echo -e "${RED}[!] 安装失败：E: Unable to locate package${NC}"
        read -p "是否切换源并重试？(y/n): " choice
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            updateSources
            echo -e "${CYAN}[+] 重新安装必要工具..."
            apt install -y git libssl-dev libffi-dev build-essential
            if [ $? -ne 0 ]; then
                echo -e "${RED}[!] 安装依然失败，请检查源配置${NC}"
                exit 1
            else
                echo -e "${GREEN}[✓] 必要工具安装完成${NC}"
            fi
        else
            echo -e "${RED}[!] 用户选择不切换源，退出${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}[✓] 必要工具安装完成${NC}"
    fi
}

updateSources() {
    echo -e "${CYAN}[+] 更新 APT 源...${NC}"
    mv /etc/apt/sources.list /etc/apt/sources.list.bak
    cat <<EOF > /etc/apt/sources.list
deb http://mirrors.aliyun.com/kali kali-rolling main non-free contrib
deb-src http://mirrors.aliyun.com/kali kali-rolling main non-free contrib
EOF
    apt-get update -y
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}[!] 更新源失败，可能是 GPG 密钥问题。${NC}"
        read -p "是否尝试更换 GPG 密钥并重新更新？(y/n): " choice
        if [[ "$choice" == "y" ]]; then
            echo -e "${CYAN}[+] 更新 GPG 密钥...${NC}"
            wget -q -O - https://archive.kali.org/archive-key.asc | apt-key add -
            apt-get update -y
            if [[ $? -eq 0 ]]; then
                echo -e "${GREEN}[✓] GPG 密钥更新成功，APT 源更新完成。${NC}"
            else
                echo -e "${RED}[!] GPG 密钥更新失败，请手动检查。${NC}"
            fi
        else
            echo -e "${RED}[!] 用户选择不更新 GPG 密钥，退出安装。${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}[✓] APT 源更新成功${NC}"
    fi
}

installAndVerify() {
    local name=$1
    local installCmd=$2
    local verifyCmd=$3

    echo -e "${CYAN}[+] 安装 ${name}...${NC}"
    eval "$installCmd"
    
    eval "$verifyCmd"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[✓] ${name} 安装成功${NC}"
    else
        echo -e "${RED}[!] ${name} 安装失败${NC}"
    fi
}

installSsh() {
    echo -e "${CYAN}[+] 启动并自启 SSH...${NC}"
    systemctl start ssh
    update-rc.d ssh enable
    echo -e "${GREEN}[✓] SSH 服务已启动${NC}"
}

installPython() {
    echo -e "${CYAN}[+] 安装 Python 及 pip...${NC}"
    apt install -y python2 python3 python3-pip build-essential libssl-dev libffi-dev
    wget https://bootstrap.pypa.io/pip/2.7/get-pip.py
    python2 get-pip.py
    mkdir -p /root/.pip
    cat <<EOF > /root/.pip/pip.conf
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
[install]
trusted-host = pypi.tuna.tsinghua.edu.cn
EOF
    python3 -m pip install --upgrade pip
    python2 -m pip install --upgrade pip
    echo -e "${GREEN}[✓] Python 及 pip 安装完成${NC}"
}

installDocker() {
    echo -e "${CYAN}[+] 安装 Docker...${NC}"
    apt-get install -y docker.io docker-compose
    mkdir -p /etc/docker
    cat <<EOF > /etc/docker/daemon.json
{
    "registry-mirrors": [
        "https://registry.docker-cn.com",
        "http://hub-mirror.c.163.com",
        "https://docker.mirrors.ustc.edu.cn",
        "https://cr.console.aliyun.com",
        "https://mirror.ccs.tencentyun.com"
    ]
}
EOF
    systemctl daemon-reload
    systemctl restart docker
    echo -e "${GREEN}[✓] Docker 安装并配置完成${NC}"
}

installPwntools() { 
    python3 -m pip install pwntools && python2 -m pip install pwntools
}

installSecLists() { 
    git clone --depth 1 https://github.com/danielmiessler/SecLists.git && mv SecLists /usr/share/wordlists/ && rm -rf SecLists
}

installRockyou() { 
    gzip -d /usr/share/wordlists/rockyou.txt.gz
}

installZsteg() { 
    gem install zsteg
}

installSteghide() { 
    apt install -y steghide
}

installPycrypto() { 
    python3 -m pip install pycrypto
}

installGmpy2() { 
    python3 -m pip install gmpy2
}

installDirsearch() { 
    apt install -y dirsearch
}

installCiphey() { 
    docker run --rm remnux/ciphey
}

installStegseek() { 
    wget -O stegseek.deb https://github.com/RickdeJager/stegseek/releases/download/v0.6/stegseek_0.6-1.deb && dpkg -i stegseek.deb && rm stegseek.deb
}

installOutguess() { 
    apt install -y outguess
}

installCrackle() { 
    git clone --depth 1 https://github.com/mikeryan/crackle.git && cd crackle && make && make install && cd .. && rm -rf crackle
}

options=( 
    "SSH服务" 
    "更新APT源" 
    "Python环境" 
    "Docker环境" 
    "Pwntools" 
    "SecLists" 
    "Rockyou字典" 
    "Zsteg" 
    "Steghide" 
    "Pycrypto" 
    "Gmpy2" 
    "Dirsearch" 
    "Ciphey" 
    "Stegseek" 
    "Outguess" 
    "Crackle"
)

PS3="请选择要安装的组件（输入数字1-16，q退出）："  

installTools

if [ $? -ne 0 ]; then
    exit 1
fi

while true; do
    echo -e "${CYAN}[+] 请选择要安装的组件（输入数字1-16，或 q 退出）:${NC}"
    for i in "${!options[@]}"; do
        echo "$((i+1)). ${options[$i]}"
    done
    read -p "输入选项: " choice

    if [[ "$choice" == "q" ]]; then
        echo -e "${YELLOW}[!] 用户退出安装，退出脚本。${NC}"
        break
    elif [[ "$choice" -ge 1 && "$choice" -le 16 ]]; then
        case $choice in
            1) installAndVerify "SSH服务" "installSsh" "systemctl status ssh" ;;
            2) installAndVerify "更新APT源" "updateSources" "cat /etc/apt/sources.list | grep aliyun" ;;
            3) installAndVerify "Python环境" "installPython" "python3 -V" ;;
            4) installAndVerify "Docker环境" "installDocker" "docker --version" ;;
            5) installAndVerify "Pwntools" "installPwntools" "python3 -c 'import pwn'" ;;
            6) installAndVerify "SecLists" "installSecLists" "ls /usr/share/wordlists/Fuzzing" ;;
            7) installAndVerify "Rockyou字典" "installRockyou" "ls /usr/share/wordlists/rockyou.txt" ;;
            8) installAndVerify "Zsteg" "installZsteg" "which zsteg" ;;
            9) installAndVerify "Steghide" "installSteghide" "which steghide" ;;
            10) installAndVerify "Pycrypto" "installPycrypto" "python3 -c 'import Crypto'" ;;
            11) installAndVerify "Gmpy2" "installGmpy2" "python3 -c 'import gmpy2'" ;;
            12) installAndVerify "Dirsearch" "installDirsearch" "which dirsearch" ;;
            13) installAndVerify "Ciphey" "installCiphey" "docker images | grep remnux/ciphey" ;;
            14) installAndVerify "Stegseek" "installStegseek" "which stegseek" ;;
            15) installAndVerify "Outguess" "installOutguess" "which outguess" ;;
            16) installAndVerify "Crackle" "installCrackle" "which crackle" ;;
        esac
    else
        echo -e "${RED}[!] 无效选项，请输入数字1-16或 q 退出。${NC}"
    fi
done

echo -e "${GREEN}[✓] 所有选定组件安装完成${NC}"
