#!/bin/bash -e

## Python3.3 インストール
cd /usr/local/src
wget http://www.python.org/ftp/python/3.3.0/Python-3.3.0.tgz
tar zxvf Python-3.3.0.tgz
cd Python-3.3.0
./configure \
--prefix=/usr/local/python \
--enable-shared
make && make install

echo "/usr/local/python/lib" >> /etc/ld.so.conf
ldconfig

ln -s /usr/local/python/bin/python3 /usr/local/bin/python

## eazy_install インストール
cd /usr/local/src
wget http://pypi.python.org/packages/source/d/distribute/distribute-0.6.34.tar.gz
tar zxvf distribute-0.6.34.tar.gz
/usr/local/bin/python distribute-0.6.34/setup.py install

ln -s /usr/local/python/bin/easy_install /usr/local/bin/easy_install

## pip インストール
/usr/local/bin/easy_install pip
ln -s /usr/local/python/bin/pip /usr/local/bin/pip

exit 0