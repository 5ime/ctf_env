# start ssh
systemctl start ssh
echo "SSH is running"

# apt source
mv /etc/apt/sources.list /etc/apt/sources.list.bak
cat > /etc/apt/sources.list << EOF
deb http://mirrors.ustc.edu.cn/kali kali-rolling main non-free contrib
deb-src http://mirrors.ustc.edu.cn/kali kali-rolling main non-free contrib
EOF

# apt update and upgrade
apt-get update -y && apt-get upgrade -y
clear
echo "apt update and upgrade is done"

# tools
apt install git libssl-dev libffi-dev build-essential -y
clear
echo "git libssl-dev libffi-dev build-essential is installed"

# python2 pip
wget https://bootstrap.pypa.io/pip/2.7/get-pip.py
python2 get-pip.py
python2 -m pip -V

if [ $? -eq 0 ]; then
    echo "python2 pip is installed"
else
    echo "python2 pip is not installed"
fi

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
echo "pip source is changed"

# pip2 and pip3
pip3 install --upgrade setuptools && python3 -m pip install --upgrade pip && pip2 install --upgrade setuptools && python2 -m pip install --upgrade pip
echo "pip2 and pip3 is upgraded"

# docker and docker-compose
apt-get install docker.io -y
apt-get install docker-compose -y
docker -v && docker-compose -v
if [ $? -eq 0 ]; then
    echo "docker and docker-compose is installed"
else
    echo "docker and docker-compose is not installed"
fi

# docker source
if [ ! -d "/etc/docker" ]; then
    mkdir /etc/docker
fi

cat > /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://ustc-edu-cn.mirror.aliyuncs.com/"]
}
EOF

sudo systemctl daemon-reload
sudo systemctl restart docker

echo "docker source is changed"

# pwntools
pip3 install --upgrade pwntools && pip2 install --upgrade pwntools
echo 'import pwn' > test.py && python2 test.py && python3 test.py && rm test.py
if [ $? -eq 0 ]; then
    echo "pwntools is installed"
else
    echo "pwntools is not installed"
fi

# SecLists
git clone https://github.com/danielmiessler/SecLists.git && cd SecLists && mv * /usr/share/wordlists/ && cd .. && rm -rf SecLists
if [ -d "/usr/share/wordlists/Fuzzing" ]; then
    echo "SecLists is installed"
else
    echo "SecLists is not installed"
fi

# rockyou
gzip -d /usr/share/wordlists/rockyou.txt.gz
if [ -f "/usr/share/wordlists/rockyou.txt" ]; then
    echo "rockyou is unzipped"
else
    echo "rockyou is not unzipped"
fi

# zsteg
gem install zsteg
zsteg -h
if [ $? -eq 0 ]; then
    echo "zsteg is installed"
else
    echo "zsteg is not installed"
fi

# steghide
apt-get install steghide -y
steghide --help
if [ $? -eq 0 ]; then
    echo "steghide is installed"
else
    echo "steghide is not installed"
fi

# pycrypto
pip3 install pycrypto
echo 'import Crypto' > test.py && && python3 test.py && rm test.py
if [ $? -eq 0 ]; then
    echo "pycrypto is installed"
else
    echo "pycrypto is not installed"
fi