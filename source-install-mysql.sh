#!/bin/bash
#author pengw
#time 2019-11-05
######################################
#                  环境              #
#           1.  CentOS6.6            #
#           2.  MySQL5.5             #
#                                    #
######################################    

echo '确认你的系统类型是否为 CentOS  Y/N ?'
read os_type

if [ $os_type != 'Y' -a $os_type != 'y' ]
then
   echo '退出成功'
   exit
fi

#安装依赖
yum -y install gcc gcc-c++ gcc-g77 autoconf automake zlib* fiex* libxml* ncurses-devel libmcrypt* libtool-ltdl-devel* make cmake curl freetype libjpeg-turbo libjpeg-turbo-devel openjpeg-libs libpng gd ncurses

#获取rpm安装的mysql列表
rpm_mysql_list=`rpm -qa | grep mysql`

#删除rpm安装的mysql
for mysql_package in $rpm_mysql_list
do
    rpm -e "$mysql_package" --nodeps
done

#用户mysql是否存在
id mysql >& /dev/null
if [ $? -ne 0 ]
then
    #添加用户
    useradd mysql -s /sbin/nologin
fi

#是否安装wegt
rpm -qa | grep wget
if [ $? -ne 0 ]
then
    yum -y install wget
fi


#下载MySQL源码
wget https://cdn.mysql.com//Downloads/MySQL-5.5/mysql-5.5.62.tar.gz

if [ $? -ne 0 ]
then
   echo '源码 mysql-5.5.62.tar.gz 下载失败'
   exit
fi

#解压mysql源码包
tar -zxvf mysql-5.5.62.tar.gz
if [ $? -ne 0 ]
then
    echo 'mysql-5.5.62.tar.gz解压失败'
    exit
fi

#解压成功，进入mysql-5.5.62的目录
cd mysql-5.5.62

#编译
cmake . -DCMAKE_INSTALL_PREFIX=/usr/local/mysql \
-DMYSQL_DATADIR=/usr/local/mysql/data \
-DSYSCONFDIR=/etc \
-DWITH_MYISAM_STORAGE_ENGINE=1 \
-DWITH_INNOBASE_STORAGE_ENGINE=1 \
-DWITH_MEMORY_STORAGE_ENGINE=1 \
-DWITH_READLINE=1 \
-DMYSQL_UNIX_ADDR=/var/lib/mysql/mysql.sock \
-DMYSQL_TCP_PORT=3306 \
-DENABLED_LOCAL_INFILE=1 \
-DWITH_PARTITION_STORAGE_ENGINE=1 \
-DEXTRA_CHARSETS=all \
-DDEFAULT_CHARSET=utf8 \
-DDEFAULT_COLLATION=utf8_general_ci

if [ $? -ne 0 ]
then
    echo 'cmake 失败'
    exit
fi


#安装
make && make install

if [ $? -ne 0 ]
then 
    echo 'MySQL安装失败'
    exit
fi

#改变所有者的目录
chown -R mysql.mysql /usr/local/mysql

#注册服务
cd /usr/local/mysql/support-files

cp mysql.server /etc/rc.d/init.d/mysqld


使用默认配置文件
cp my-small.cnf /etc/my.cnf
#让chkconfig管理mysql服务
chkconfig --add mysqld
# 给mysqld授权执行 
chmod a+x /etc/init.d/mysqld #或者使用 setfacl -m u:root:rwx /etc/init.d/mysqld
#开机启动
chkconfig mysqld on


#初始化数据库
cd /usr/local/mysql/scripts 
./mysql_install_db --user=mysql --basedir=/usr/local/mysql --datadir=/usr/local/mysql/data

#创建目录存放mysql.sock
mkdir -p /var/lib/mysql

#mysql目录的组和用户设置为mysql
chown -R mysql:mysql /var/lib/mysql

#启动mysql服务
service mysqld start

echo '######################################################'
echo '#              恭喜你 MySQL安装成功                  #'
echo '#                                                    #'  
echo '#      1. 切换到 cd /usr/local/mysql/bin 目录下面    #'
echo '#      2. 运行mysql即 ./mysqld - uroot -p 回车       #'
echo '#      3. 密码默认为空 回车                          #'
echo '#                                                    #'  
echo '######################################################

