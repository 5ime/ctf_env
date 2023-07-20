#!/bin/bash
set +e
# start ssh
systemctl start ssh
update-rc.d ssh enable
echo -e "\033[32m SSH is running \033[0m"
sleep 3

# apt source
mv /etc/apt/sources.list /etc/apt/sources.list.bak
cat > /etc/apt/sources.list << EOF
deb http://mirrors.ustc.edu.cn/kali kali-rolling main non-free contrib
deb-src http://mirrors.ustc.edu.cn/kali kali-rolling main non-free contrib
EOF

# apt update and upgrade
apt-get update -y && apt-get upgrade -y
clear
echo -e "\033[32m apt update and upgrade is done \033[0m"
sleep 3

# tools
apt install git libssl-dev libffi-dev build-essential -y
clear
echo -e "\033[32m git libssl-dev libffi-dev build-essential is installed \033[0m"
sleep 3

# python2 pip
wget https://bootstrap.pypa.io/pip/2.7/get-pip.py
python2 get-pip.py
clear
sleep 3

# pip source
if [ ! -d "/root/.pip" ]; then
    mkdir /root/.pip
fi
cat > /root/.pip/pip.conf << EOF
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
[install]
trusted-host = pypi.tuna.tsinghua.edu.cn
EOF

pip config list
clear
echo -e "\033[32m pip source is changed \033[0m"
sleep 3

# pip2 and pip3
pip3 install --upgrade setuptools && python3 -m pip install --upgrade pip && pip2 install --upgrade setuptools && python2 -m pip install --upgrade pip
clear
echo -e "\033[32m pip2 and pip3 is upgraded \033[0m"
sleep 3

# docker and docker-compose
apt-get install docker.io -y
apt-get install docker-compose -y

# docker source
if [ ! -d "/etc/docker" ]; then
    mkdir /etc/docker
fi

cat > /etc/docker/daemon.json <<-'EOF'
{
    "registry-mirrors" : [
    "https://registry.docker-cn.com",
    "http://hub-mirror.c.163.com",
    "https://docker.mirrors.ustc.edu.cn",
    "https://cr.console.aliyun.com",
    "https://mirror.ccs.tencentyun.com"
  ]
}
EOF

sudo systemctl daemon-reload
sudo systemctl restart docker
clear
echo -e "\033[32m docker source is changed \033[0m"
sleep 3

# pwntools
pip3 install --upgrade pwntools && pip2 install --upgrade pwntools

# SecLists
git clone https://github.com/danielmiessler/SecLists.git && cd SecLists && mv * /usr/share/wordlists/ && cd .. && rm -rf SecLists

# rockyou
gzip -d /usr/share/wordlists/rockyou.txt.gz

# zsteg
gem install zsteg

# steghide
apt-get install steghide -y

# pycrypto
pip3 install pycrypto

# gmpy2
pip3 install gmpy2

# dirsearch
apt install dirsearch -y

# Ciphey
docker run -it --rm remnux/ciphey

# Stegseek
wget https://github.com/RickdeJager/stegseek/releases/download/v0.6/stegseek_0.6-1.deb && dpkg -i stegseek_0.6-1.deb && rm stegseek_0.6-1.deb

clear
# verify
not_installed=""
installed=""

declare -a software=("pip2" "docker" "docker-compose" "zsteg" "steghide" "dirsearch" "stegseek")

for i in "${software[@]}"
do
    which $i
    if [ $? -eq 0 ]; then
        installed+="$i\n"
    else
        not_installed+="$i\n"
    fi
done

if python2 -c "import pwn" &>/dev/null && python3 -c "import pwn" &>/dev/null; then
    installed+="pwntools\n"
else
    not_installed+="pwntools\n"
fi

if [ -d "/usr/share/wordlists/Fuzzing" ]; then
    installed+="SecLists\n"
else
    not_installed+="SecLists\n"
fi

if [ -f "/usr/share/wordlists/rockyou.txt" ]; then
    installed+="rockyou\n"
else
    not_installed+="rockyou\n"
fi

if python3 -c "import Crypto" &>/dev/null; then
    installed+="pycrypto\n"
else
    not_installed+="pycrypto\n"
fi

if python3 -c "import gmpy2" &>/dev/null; then
    installed+="gmpy2\n"
else
    not_installed+="gmpy2\n"
fi

docker images | grep remnux/ciphey

if [ $? -eq 0 ]; then
    installed+="Ciphey\n"
else
    not_installed+="Ciphey\n"
fi

clear
echo -e "\033[32m installed: \033[0m"
echo -e $installed
echo -e "\033[36m not installed: \033[0m"
echo -e $not_installed
