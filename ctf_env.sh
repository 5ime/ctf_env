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

echo -e "${CYAN}
#########################################################
#                    CTF_ENV                            #
#               用于快速安装和配置各种安全工具          #
#                                                       #
#                                   Version: 1.0.1      #
#                                   Author: iami233     #
#             Repo: https://github.com/5ime/ctf_env     #
#########################################################
${NC}"

# 通用安装和验证函数
installAndVerify() {
    local name=$1
    local installCmd=$2
    local verifyCmd=$3

    echo -e "${CYAN}[+] 安装 ${name}...${NC}"
    if eval "$installCmd"; then
        if eval "$verifyCmd" &>/dev/null; then
            echo -e "${GREEN}[✓] ${name} 安装成功${NC}"
        else
            echo -e "${RED}[!] ${name} 验证失败${NC}"
        fi
    else
        echo -e "${RED}[!] ${name} 安装失败${NC}"
    fi
}

# 安装必要工具
installTools() {
    echo -e "${CYAN}[+] 安装必要工具...${NC}"
    if ! apt install -y git libssl-dev libffi-dev build-essential libpcap-dev libmcrypt4 libmhash2; then
        echo -e "${RED}[!] 安装失败，是否切换源并重试？(y/n)${NC}"
        read -r choice
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            updateSources
            apt install -y git libssl-dev libffi-dev build-essential || { echo -e "${RED}[!] 安装失败，请检查源配置${NC}"; exit 1; }
        else
            echo -e "${RED}[!] 用户选择不切换源，退出${NC}"
            exit 1
        fi
    fi
    echo -e "${GREEN}[✓] 必要工具安装完成${NC}"
}

# 更新APT源
updateSources() {
    echo -e "${CYAN}[+] 更新 APT 源...${NC}"
    mv /etc/apt/sources.list /etc/apt/sources.list.bak
    cat <<EOF > /etc/apt/sources.list
deb http://mirrors.aliyun.com/kali kali-rolling main non-free contrib
deb-src http://mirrors.aliyun.com/kali kali-rolling main non-free contrib
EOF
    if ! apt-get update -y; then
        echo -e "${RED}[!] 更新源失败，是否尝试更换 GPG 密钥并重新更新？(y/n)${NC}"
        read -r choice
        if [[ "$choice" == "y" ]]; then
            echo -e "${CYAN}[+] 更新 GPG 密钥...${NC}"
            wget -q -O - https://archive.kali.org/archive-key.asc | apt-key add -
            apt-get update -y && echo -e "${GREEN}[✓] GPG 密钥更新成功${NC}" || echo -e "${RED}[!] GPG 密钥更新失败${NC}"
        else
            echo -e "${RED}[!] 用户选择不更新 GPG 密钥，退出安装${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}[✓] APT 源更新成功${NC}"
    fi
}

# 配置SSH服务
installSsh() {
    systemctl start ssh
    update-rc.d ssh enable
}

# 安装Python环境
installPython() {
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
}

# 安装Docker环境
installDocker() {
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
}

# 安装Stegseek
installStegseek() {
    wget -O stegseek.deb https://github.com/RickdeJager/stegseek/releases/download/v0.6/stegseek_0.6-1.deb
    dpkg -i stegseek.deb
    rm stegseek.deb
}

# 安装Crackle
installCrackle() {
    git clone --depth 1 https://github.com/mikeryan/crackle.git
    cd crackle && make && make install && cd .. && rm -rf crackle
}

# 定义安装选项（名称:安装命令:验证命令）
declare -A install_options=(
    ["SSH服务"]="installSsh:systemctl status ssh"
    ["更新APT源"]="updateSources:cat /etc/apt/sources.list | grep aliyun"
    ["Python环境"]="installPython:python3 -V"
    ["Docker环境"]="installDocker:docker --version"
    ["Pwntools"]="python3 -m pip install pwntools && python2 -m pip install pwntools:python3 -c 'import pwn'"
    ["SecLists"]="git clone --depth 1 https://github.com/danielmiessler/SecLists.git && mv SecLists /usr/share/wordlists/ && rm -rf SecLists:ls /usr/share/wordlists/Fuzzing"
    ["Rockyou字典"]="gzip -d /usr/share/wordlists/rockyou.txt.gz:ls /usr/share/wordlists/rockyou.txt"
    ["Zsteg"]="gem install zsteg:which zsteg"
    ["Steghide"]="apt install -y steghide:which steghide"
    ["Pycrypto"]="python3 -m pip install pycrypto:python3 -c 'import Crypto'"
    ["Gmpy2"]="python3 -m pip install gmpy2:python3 -c 'import gmpy2'"
    ["Dirsearch"]="apt install -y dirsearch:which dirsearch"
    ["Ciphey"]="docker run --rm remnux/ciphey:docker images | grep remnux/ciphey"
    ["Stegseek"]="installStegseek:which stegseek"
    ["Outguess"]="apt install -y outguess:which outguess"
    ["Crackle"]="installCrackle:which crackle"
)

# 获取选项名称数组
options=($(printf '%s\n' "${!install_options[@]}" | sort))

# 询问是否安装必备工具
echo -e "${YELLOW}[?] 是否安装必备工具？(git libssl-dev libffi-dev build-essential libpcap-dev libmcrypt4 libmhash2)${NC}"
read -p "输入 y 确认安装，n 跳过: " install_deps

if [[ "$install_deps" == "y" || "$install_deps" == "Y" ]]; then
    # 安装必要工具
    installTools
else
    echo -e "${YELLOW}[!] 跳过必备工具安装${NC}"
fi

# 主菜单循环
while true; do
    echo -e "${CYAN}[+] 请选择要安装的组件（输入数字1-${#options[@]}，或 q 退出）:${NC}"
    for i in "${!options[@]}"; do
        echo "$((i+1)). ${options[$i]}"
    done
    read -p "输入选项: " choice

    if [[ "$choice" == "q" ]]; then
        echo -e "${YELLOW}[!] 用户退出安装${NC}"
        break
    elif [[ "$choice" -ge 1 && "$choice" -le ${#options[@]} ]]; then
        selected_option="${options[$((choice-1))]}"
        IFS=':' read -r install_cmd verify_cmd <<< "${install_options[$selected_option]}"
        installAndVerify "$selected_option" "$install_cmd" "$verify_cmd"
    else
        echo -e "${RED}[!] 无效选项，请输入数字1-${#options[@]}或 q 退出${NC}"
    fi
done

echo -e "${GREEN}[✓] 所有选定组件安装完成${NC}"
