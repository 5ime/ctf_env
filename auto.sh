#!/bin/bash

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
    "registry-mirrors":
    [
        "https://hub-mirror.c.163.com/",
        "https://docker.mirrors.ustc.edu.cn/"
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

clear
# verify

python2 -m pip -V

if [ $? -eq 0 ]; then
    echo -e "\033[32m python2 pip is installed \033[0m"
else
    # 输出黄色字体
    echo -e "\033[36m python2 pip is not installed \033[0m"
fi

docker -v && docker-compose -v

if [ $? -eq 0 ]; then
    echo -e "\033[32m docker and docker-compose is installed \033[0m"
else
    echo -e "\033[36m docker and docker-compose is not installed \033[0m"
fi

echo 'import pwn' > test.py && python2 test.py && python3 test.py && rm test.py

if [ $? -eq 0 ]; then
    echo -e "\033[32m pwntools is installed \033[0m"
else
    echo -e "\033[36m pwntools is not installed \033[0m"
fi

if [ -d "/usr/share/wordlists/Fuzzing" ]; then
    echo -e "\033[32m SecLists is installed \033[0m"
else
    echo -e "\033[36m SecLists is not installed \033[0m"
fi

if [ -f "/usr/share/wordlists/rockyou.txt" ]; then
    echo -e "\033[32m rockyou is unzipped \033[0m"
else
    echo -e "\033[36m rockyou is not unzipped \033[0m"
fi

which zsteg

if [ $? -eq 0 ]; then
    echo -e "\033[32m zsteg is installed \033[0m"
else
    echo -e "\033[36m zsteg is not installed \033[0m"
fi

which steghide

if [ $? -eq 0 ]; then
    echo -e "\033[32m steghide is installed \033[0m"
else
    echo -e "\033[36m steghide is not installed \033[0m"
fi

echo 'import Crypto' > test.py && && python3 test.py && rm test.py

if [ $? -eq 0 ]; then
    echo -e "\033[32m pycrypto is installed \033[0m"
else
    echo -e "\033[36m pycrypto is not installed \033[0m"
fi

echo 'import gmpy2' > test.py && python3 test.py && rm test.py

if [ $? -eq 0 ]; then
    echo -e "\033[32m gmpy2 is installed \033[0m"
else
    echo -e "\033[36m gmpy2 is not installed \033[0m"
fi

which dirsearch

if [ $? -eq 0 ]; then
    echo -e "\033[32m dirsearch is installed \033[0m"
else
    echo -e "\033[36m dirsearch is not installed \033[0m"
fi

docker images | grep remnux/ciphey

if [ $? -eq 0 ]; then
    echo -e "\033[32m Ciphey is installed \033[0m"
else
    echo -e "\033[36m Ciphey is not installed \033[0m"
fi
