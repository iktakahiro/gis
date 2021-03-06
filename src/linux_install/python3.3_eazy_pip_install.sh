#!/bin/bash -e

## Python3.3 インストール
cd /usr/local/src
wget http://www.python.org/ftp/python/3.3.2/Python-3.3.2.tgz
tar zxvf Python-3.3.2.tgz
cd Python-3.3.2
./configure \
--prefix=/usr/local/python \
--enable-shared
make && make install

echo "/usr/local/python/lib" >> /etc/ld.so.conf
ldconfig

ln -s /usr/local/python/bin/python3 /usr/local/bin/python

## eazy_install（distribute） インストール
cd /usr/local/src
wget https://pypi.python.org/packages/source/d/distribute/distribute-0.7.3.zip
unzip distribute-0.7.3.zip
python distribute-0.7.3/setup.py install

ln -s /usr/local/python/bin/easy_install /usr/local/bin/easy_install

## pip インストール
/usr/local/bin/easy_install pip
ln -s /usr/local/python/bin/pip /usr/local/bin/pip

exit 0